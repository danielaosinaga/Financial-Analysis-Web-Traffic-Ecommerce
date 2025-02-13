### Financial analysis

#1. What are the sales per year?

SELECT
    YEAR(orders.creation_date) AS year,
    SUM(orders.price * orders.purchased_items) AS total_sales
FROM  happy_unicorn_store.orders
GROUP BY YEAR(orders.creation_date)
ORDER BY year DESC;

#2. What are the average sales for each month and year?

SELECT
    YEAR(orders.creation_date) AS year,
    MONTH(orders.creation_date) AS month,
    ROUND(AVG(orders.price * orders.purchased_items),2) AS average_sales
FROM  happy_unicorn_store.orders
GROUP BY year, month
ORDER BY 1 DESC, 2 DESC;

#3. What is the product that sells the most in monetary terms?

SELECT 	pr.id_product,	name_product, FORMAT(SUM(o.price),2) AS sales
  FROM happy_unicorn_store.orders o
INNER JOIN  happy_unicorn_store.order_item oi on o.id_order = oi.id_order
INNER JOIN happy_unicorn_store.products pr on pr.id_product = oi.id_product
GROUP BY name_product,id_product
ORDER BY SUM(o.price) DESC
LIMIT 1;

#4. What is the gross margin for each product?

SELECT DISTINCT name_product, (price-cost) as margin
FROM happy_unicorn_store.order_item oi
LEFT JOIN happy_unicorn_store.products p on p.id_product = oi.id_product;

# 5 - Can we know the release date of each product?
#Release date = date of the first sale of that product

    SELECT p.id_product, p.name_product,MIN(oi.creation_date) as date_release
     FROM happy_unicorn_store.order_item oi
LEFT JOIN happy_unicorn_store.products p on p.id_product = oi.id_product
	GROUP BY p.id_product, p.name_product;

#6. Calculate sales and margin by year and product.
# We also want to know what % each product represents of total sales.

with sales_by_product AS (
SELECT 	name_product, SUM(price) as sales 
FROM happy_unicorn_store.order_item oi
INNER JOIN happy_unicorn_store.products p on oi.id_product = p.id_product
GROUP BY name_product)
SELECT 	YEAR(oi.creation_date) as year,p.name_product,	SUM(price) as sales,	SUM(price-cost) as margin_numeric,
         sp.sales / (SELECT SUM(price) as sales FROM happy_unicorn_store.orders) as porcentage
FROM happy_unicorn_store.order_item oi
INNER JOIN happy_unicorn_store.products p on oi.id_product = p.id_product
LEFT JOIN sales_by_product sp on sp.name_product = p.name_product
GROUP BY year,name_product
ORDER BY year;

#7. What are the TOP 3 months with the highest sales?

SELECT YEAR(creation_date) as year,MONTH(creation_date) as month,FORMAT(SUM(purchased_items*price),2) as sales
FROM happy_unicorn_store.orders
GROUP BY year,month
ORDER BY sales DESC
LIMIT 3;

#8. What is the gross margin per product and what percentage does it occupy of the total margin?

SELECT pr.name_product,FORMAT(SUM(p.purchased_items*p.Price)-SUM(p.cost),0) as gross_margin ,
(SUM(p.purchased_items*p.Price)-SUM(p.cost))/(SELECT SUM(p.purchased_items*p.Price)-SUM(p.cost) FROM happy_unicorn_store.orders p) AS Percentage
FROM happy_unicorn_store.orders p
LEFT JOIN happy_unicorn_store.order_item pa on pa.id_order = p.id_order
LEFT JOIN happy_unicorn_store.products pr on pr.id_product = pa.id_product
GROUP BY name_product;

#9. What is the average gross profit margin by product line in the latest quarter of the company's data?

SELECT name_product, SUM(price-cost) as gross_margin, CONCAT(format(SUM(price-cost) / (SELECT SUM(price-cost) as gross_margin 
FROM happy_unicorn_store.orders),2)*100,'%') as percentage
FROM order_item oi
LEFT JOIN products p on p.id_product = oi.id_product
WHERE oi.creation_date >= (SELECT DATE(DATE_SUB(MAX(creation_date), INTERVAL 3 MONTH)) FROM happy_unicorn_store.orders)
GROUP BY name_product
order by gross_margin DESC;

#10. What is the percentage of returned items?

SELECT COUNT(oi.id_item_refund)/ COUNT(o.id_order) as total_orders
FROM happy_unicorn_store.orders o
LEFT JOIN happy_unicorn_store.order_item_refunds oi on oi.id_item_refund = o.id_order;
    
### Web traffic analysis
    
#11. What is the number of sessions per device type?

SELECT divice_type,COUNT(id_session_web) as number_sessions
FROM happy_unicorn_store.sessiones_web
GROUP BY divice_type;

#12. Are sessions the same as users? What is the number of unique users? And what is the number of sessions?

SELECT count(id_session_web) as sessions,count(DISTINCT id_user) as users
FROM happy_unicorn_store.sessiones_web;

#13. Which 5 months have had the most traffic on the website?

SELECT EXTRACT( YEAR_MONTH FROM creation_date) as YearMonth,
COUNT(id_session_web) as number_of_sessions
FROM happy_unicorn_store.sessiones_web
GROUP BY YearMonth
ORDER BY number_of_sessions DESC
LIMIT 5;

#14. What is the main source of traffic web?

SELECT utm_source,COUNT(id_session_web) as qty_session
FROM happy_unicorn_store.sessiones_web
GROUP BY utm_source
ORDER BY qty_session DESC
LIMIT 1;

#15. Which web traffic sources have generated the most sales?

SELECT utm_source,FORMAT(SUM(o.purchased_items*price),0) as sales
FROM happy_unicorn_store.sessiones_web w
LEFT JOIN happy_unicorn_store.orders o on o.id_session_web = w.id_session_web
GROUP BY utm_source
orDER BY SUM(purchased_items*price) DESC
LIMIT 1;

#16. Show the sales and number of sessions by traffic source as well as the percentage of the total for each metric?

SELECT utm_source,FORMAT(SUM(purchased_items*price),0) as sales,
(SUM(purchased_items*price)) / (SELECT SUM(purchased_items*price)
FROM happy_unicorn_store.orders o) as porcentage_sales,
format(COUNT(w.id_session_web),0) as qty_sessiones,COUNT(w.id_session_web) / (SELECT COUNT(w.id_session_web) 
FROM happy_unicorn_store.sessiones_web w) as porcentage_sessiones
FROM happy_unicorn_store.sessiones_web w
LEFT JOIN happy_unicorn_store.orders o on o.id_session_web = w.id_session_web
GROUP BY utm_source;

#17. What is the percentage of traffic conversion to sales?

SELECT utm_source, SUM(price) as ventas, SUM(price) / (SELECT SUM(price) as sales
 FROM happy_unicorn_store.orders) as porcentage_sales,
COUNT(w.id_session_web) as qty_sesiones,
COUNT(w.id_session_web) / (SELECT COUNT(id_session_web) 
FROM happy_unicorn_store.sessiones_web) as porcentage_sessiones
FROM happy_unicorn_store.orders o
RIGHT  JOIN happy_unicorn_store.sessiones_web w on o.id_session_web = w.id_session_web
group by utm_source;
