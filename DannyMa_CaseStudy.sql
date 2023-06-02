--CREATE SCHEMA dannys_diner;
--use dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1), 
  order_date DATE, 
  product_id INTEGER
);

INSERT INTO sales (
  customer_id, order_date, product_id
) 
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

CREATE TABLE menu (
  product_id INTEGER, 
  product_name VARCHAR(5), 
  price INTEGER
);

INSERT INTO menu (product_id, product_name, price) 
VALUES 
  (1, 'sushi', 10), 
  (2, 'curry', 15), 
  (3, 'ramen', 12);


CREATE TABLE members (
  customer_id VARCHAR(1), 
  join_date DATE
);

INSERT INTO members (customer_id, join_date) 
VALUES 
  ('A', '2021-01-07'), 
  ('B', '2021-01-09');

select * from sales;
select * from menu
select * from members

--query 1 What is the total amount each customer spent at the restaurant?
select s.customer_id, SUM(price) as total_amount
from sales s inner join 
menu m on s.product_id=m.product_id
group by customer_id

--query 2 How many days has each customer visited the restaurant?
select customer_id, COUNT(distinct order_date) as days_visted
from sales
group by customer_id;

--query 3 What was the first item from the menu purchased by each customer?
with cte as 
	(select customer_id, order_date,product_name, dense_rank() over (partition by customer_id order by s.order_date) as rn
	 from sales s inner join 
	 menu m on s.product_id=m.product_id)
select customer_id, product_name
from cte
where rn =1
group by customer_id,product_name

--query 4 What is the most purchased item on the menu and how many times was it purchased by all customers?
select top 1 product_name, COUNT(s.product_id) as no_of_times_item_purchased
from sales s inner join 
menu m on s.product_id=m.product_id
group by product_name
order by no_of_times_item_purchased desc

--query 5 Which item was the most popular for each customer?
with cte1 as
(select customer_id,product_name, count(product_name) as count_item, DENSE_RANK() over (partition by customer_id order by count(product_name) desc) as rn  
from sales s inner join 
menu m on s.product_id=m.product_id
group by customer_id,product_name)
select customer_id,product_name,count_item
from cte1
where rn=1

--query 6 Which item was purchased first by the customer after they became a member?
with item_first as
(select s.customer_id,order_date,join_date,product_name,m1.product_id, DENSE_RANK() over (partition by s.customer_id order by s.order_date) as rn
from sales s inner join
members m on s.customer_id=m.customer_id join menu m1 on s.product_id=m1.product_id
where order_date>=join_date)
select customer_id, product_name, order_date
from item_first
where rn=1

--query 7 Which item was purchased just before the customer became a member?
with item_purchased as
(select s.customer_id,order_date,join_date,product_name,m1.product_id, DENSE_RANK() over (partition by s.customer_id order by s.order_date desc) as rn
from sales s inner join
members m on s.customer_id=m.customer_id join menu m1 on s.product_id=m1.product_id
where order_date<join_date)
select customer_id, product_name, order_date, join_date
from item_purchased
where rn =1

--query 8 What is the total items and amount spent for each member before they became a member?
select s.customer_id,count(distinct s.product_id) as total_items, sum(price) as amount_spent
from sales s inner join 
members m on s.customer_id=m.customer_id join menu m1 on s.product_id=m1.product_id
where order_date<join_date
group by s.customer_id

--query 9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select customer_id, sum(case when product_name='sushi' then price*10*2 else price*10 end) as points
from sales s inner join 
menu m on s.product_id=m.product_id
group by customer_id

--query 10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id,
       SUM(case when order_date BETWEEN join_date AND DATEADD(day, 6,join_date) then price*10*2 
				when product_name = 'sushi'then price*10*2
				else price*10 end )AS points
from sales s inner join 
members m on s.customer_id=m.customer_id join menu m1 on s.product_id=m1.product_id
where order_date<='2021-01-31' and order_date>=join_date
group by s.customer_id

--Bonus questions [Join All The Things]
select s.customer_id, order_date, product_name, price, case when order_date>=join_date then 'Y' else 'N' end as member
from members m right join 
sales s  on s.customer_id=m.customer_id inner join menu m1 on s.product_id=m1.product_id

--Rank All The Things
with rank_table as 
(select s.customer_id, order_date, product_name, price, case when order_date>=join_date then 'Y' else 'N' end as member
from members m right join 
sales s  on s.customer_id=m.customer_id inner join menu m1 on s.product_id=m1.product_id)
select *, case when member='N' then NUll else DENSE_RANK() over (partition by customer_id,member order by order_date) end as ranking
from rank_table;
