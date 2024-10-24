--Step 1 
CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;
--Step 2
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);
--Step 3
INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
--Step 4
  CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);
--Step 5
INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
--Step 6
CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE );
--Step 7
INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
--Analysis: 

--Q1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) AS total_spend
FROM sales AS s
INNER JOIN menu AS m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id

--Q2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT (Distinct order_date) AS customer_visits
FROM sales 
GROUP BY customer_id
ORDER BY customer_id

--Q3. What was the first item from the menu purchased by each customer?

With first_item AS (
SELECT s.* , m.product_name,
Rank () over (partition by s.customer_id order by s.order_date ASC)
FROM sales AS s
INNER JOIN menu AS m ON s.product_id=m.product_id)
SELECT * FROM first_item WHERE rank = 1

--Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
m.product_name,
COUNT(m.product_id) AS Mostpurchased 
FROM sales AS s 
INNER JOIN menu AS m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY COUNT(m.product_id)

--Q5. Which item was the most popular for each customer?

With MostPopular AS (
SELECT 
s.customer_id,
m.product_name,
COUNT(m.product_id) AS Mostpopular 
FROM sales AS s 
INNER JOIN menu AS m ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
) 
SELECT customer_id, product_name, MostPopular,
RANK () over (partition by customer_id ORDER BY MostPopular DESC ) 
FROM MostPopular 

--Q6. Which item was purchased first by the customer after they became a member?

SELECT
m1.customer_id, m2.product_name, m1.join_date
FROM sales AS s
JOIN members AS m1 ON s.customer_id = m1.customer_id
JOIN menu AS m2 ON s.product_id = m2.product_id
WHERE s.order_date >= join_date 
GROUP BY m1.customer_id, m2.product_name, m1.join_date
ORDER BY m1.customer_id

-- We can solve this in 2nd way by using Rank function

With Final AS (
SELECT
m1.customer_id, m2.product_name, m1.join_date,
RANK () over (partition by m2.product_id Order By s.order_date) AS Ranking 
FROM sales AS s
Left JOIN members AS m1 ON s.customer_id = m1.customer_id
JOIN menu AS m2 ON s.product_id = m2.product_id
WHERE s.order_date >= join_date 
)
SELECT customer_id, product_name, ranking FROM Final WHERE Ranking = 1

--Q7. Which item was purchased just before the customer became a member?

WITH Final AS (
SELECT
m1.customer_id, m2.product_name, m1.join_date,
RANK () over (partition by m2.product_id Order By s.order_date) AS Ranking 
FROM sales AS s
Left JOIN members AS m1 ON s.customer_id = m1.customer_id
JOIN menu AS m2 ON s.product_id = m2.product_id
WHERE s.order_date < join_date
)
SELECT customer_id, product_name, Ranking 
FROM Final
WHERE Ranking = 1

--Q8. What is the total items and amount spent for each member before they became a member?

With memberdata AS (
SELECT
s.customer_id, 
s.order_date, 
m.product_name,
m.price
FROM sales as s
Left JOIN menu AS m ON s.product_id = m.product_id
JOIN members m1 ON s.customer_id = m1.customer_id
WHERE s.order_date < m1.join_date 
)
SELECT customer_id, COUNT(Distinct product_name) AS items, SUM(price) AS amount_spent 
FROM memberdata
GROUP BY customer_id

--Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier how many points would each customer have?

WITH points AS (
SELECT
s.customer_id,
m1.product_name,
m1.price,
CASE WHEN m1.product_name = 'sushi' THEN 2*m1.price 
  ELSE m1.price
END AS new_price
FROM sales AS s
Left JOIN menu AS m1 ON s.product_id = m1.product_id
)
SELECT customer_id, SUM(new_price) * 10 AS points
FROM points
GROUP BY customer_id

--Q10. In the first week after a customer joins the program (including their join date) 
--they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH points AS (
SELECT
s.customer_id,
m1.product_name,
m1.price,
CASE WHEN m1.product_name = 'sushi' THEN 2*m1.price 
     WHEN s.order_date between m2.join_date AND m2.join_date +interval '6 days' THEN m1.price
  ELSE m1.price
END AS new_price
FROM sales AS s
JOIN menu AS m1 ON s.product_id = m1.product_id
JOIN members AS m2 ON 	s.customer_id = m2.customer_id
WHERE s.order_date <= '2021-01-31')
SELECT customer_id, SUM(new_price) * 10 AS points
FROM points
GROUP BY customer_id

-- **BONUS**--


SELECT
s.customer_id,
s.order_date,
m1.product_name,
m1.price,
CASE
    WHEN s.order_date < m2.join_date THEN 'N'
	WHEN m2.join_date = NULL THEN 'N'
	ELSE 'Y' END AS member
FROM sales AS s
JOIN menu AS m1 ON s.product_id = m1.product_id
Left JOIN members AS m2 ON 	s.customer_id = m2.customer_id
























