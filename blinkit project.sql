SELECT 
    c.customer_id,
    c.customer_name,
    o.order_date,
    c.customer_segment,
    o.payment_method,
    c.area,
    c.total_orders,
    d.delivery_date,
    ROUND(SUM(o.order_total), 2) AS order_payment_value
FROM
    blinkit_customers c
        JOIN
    blinkit_orders o ON c.customer_id = o.customer_id
        JOIN
    blinkit_delivery_performance d ON o.order_id = d.order_id
GROUP BY c.customer_id , c.customer_name , o.order_date , c.customer_segment , c.area , c.total_orders , o.payment_method , d.delivery_date;


SELECT 
    c.customer_id,
    c.customer_name,
    p.product_name,
    MAX(i.quantity) Total_quantity,
    ROUND(SUM(p.price), 2) Total_price,
    o.payment_method,
    o.delivery_status
FROM
    blinkit_db.blinkit_customers c
        JOIN
    blinkit_db.blinkit_orders o ON c.customer_id = o.customer_id
        JOIN
    blinkit_db.blinkit_order_items i ON o.order_id = i.order_id
        JOIN
    blinkit_db.blinkit_products p ON i.product_id = p.product_id
GROUP BY c.customer_id , c.customer_name , p.product_name , i.quantity , p.price , o.payment_method , o.delivery_status
ORDER BY Total_price DESC;


SELECT 
    o.order_id,
    o.customer_id,
    o.order_total,
    d.delivery_status,
    CASE
        WHEN d.delivery_status < 'On-Time' THEN 'Yes'
        ELSE 'No'
    END AS Delivery_Flag
FROM
    blinkit_orders o
        JOIN
    blinkit_delivery_performance d ON o.order_id = d.order_id;
    
SELECT 
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS total_orders,
    SUM(o.order_total) AS total_spent,
    m.campaign_name,
    m.conversion_status
FROM
    blinkit_customers c
        JOIN
    blinkit_orders o ON c.customer_id = o.customer_id
        LEFT JOIN
    blinkit_marketing_performance m ON o.campaign_id = m.campaign_id
GROUP BY c.customer_id , c.customer_name , m.campaign_name , m.conversion_status;

#/ How many deliveries are completed on time versus delayed, and 
-- what is the average remaining time difference between promised and actual delivery?

SELECT 
    Delivery_Status,
    COUNT(*) AS Total_Orders
FROM (
    SELECT 
        order_id,
        CASE
            WHEN promised_delivery_time > actual_delivery_time THEN 'On Time'
            WHEN promised_delivery_time < actual_delivery_time THEN 'Delay'
            ELSE 'Equal'
        END AS Delivery_Status
    FROM 
        blinkit_db.blinkit_orders
) as sub
GROUP BY 
    Delivery_Status;
    
select 
      o.delivery_status,
      count(o.order_id)
from blinkit_orders o   
group by o.delivery_status;
    
    
-- CRM (Customer Relationship Management)

-- CLV (Customer Lifetime Value)
#/ Which customer segments (Champions, Loyal, Potential Loyalists, New Customers) 
-- generate the highest total revenue across their lifespan, and how does their average 
-- order value compare?

SELECT 
    c.customer_id,
    c.customer_name,
    YEAR(o.order_date) AS Customer_Lifespan,
    COUNT(o.order_id) total_orders,
    ROUND(SUM(o.order_total) / COUNT(o.order_id),2) Total_Average,
    ROUND(SUM(o.order_total) / COUNT(o.order_id) * COUNT(o.order_id),2) as Total_Lifespan_amount,
     CASE
        WHEN  COUNT(o.order_id) between 5 and 10 THEN "Champions_Customer"
        WHEN COUNT(o.order_id)  between 4 and 5 THEN"Potential_loyalist"
        WHEN COUNT(o.order_id)  between 3 and 4 THEN "loyal_Customer"
        WHEN COUNT(o.order_id)  between 1 and 2 THEN "New Customer"
        ELSE "No Order"
    END AS Ranks
FROM
    blinkit_orders o
        JOIN
    blinkit_customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id , c.customer_name , YEAR(o.order_date)
order by  Total_Lifespan_amount desc
limit 5;


--  RFM (Recency Frequency Monetary) on Customers
#/ Which customers have placed the most recent and frequent orders, 
-- and how much revenue (monetary value) do they contribute compared to others?

SELECT 
    c.customer_id,
    c.customer_name,
    MAX(o.order_date) AS recency,
    count(o.order_id) AS frequency,
    ROUND(SUM(o.order_total), 2) AS monetary,
    ROUND(SUM(o.order_total) / COUNT(o.order_id), 2) AS avg_order_value,
     CASE
        WHEN COUNT(o.order_id) between 9 and 15 THEN "Champions_Customer"
        WHEN COUNT(o.order_id)  between 7 and 9 THEN"Potential_loyalist"
        WHEN COUNT(o.order_id)  between 4 and 6 THEN "loyal_Customer"
        WHEN COUNT(o.order_id)  between 1 and 3 THEN "New Customer"
        ELSE "No Order"
    END AS Ranks
FROM
    blinkit_customers c
        JOIN
    blinkit_orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id , c.customer_name
ORDER BY frequency DESC
limit 5;

#/ Which regions generate the highest conversion rates from marketing campaigns 
-- into customer orders, and how do they compare year over year?

SELECT 
    c.area AS Region_sale,
    YEAR(l.order_date) AS Campaign_date,
     sum(p.clicks) as Total_clicks,
    COUNT(l.order_id) AS Total_Order_Respones,
    ROUND(SUM(l.order_total), 2) AS Total_amount,
    Round(sum(p.conversions)/ sum(p.clicks) * 100,2) as Conversion_rate
FROM
    blinkit_customers c
        LEFT JOIN
    blinkit_orders l ON c.customer_id = l.customer_id
        JOIN
    blinkit_marketing_performance p ON l.campaign_id = p.campaign_id
GROUP BY c.area , YEAR(l.order_date)
ORDER BY Total_Order_Respones DESC
LIMIT 5;


#/ Which customers are at the highest risk of churn based on the number of days since their last order, 
-- and how does their total order history compare?

SELECT 
    c.customer_id,
    c.customer_name,
    MAX(o.order_date) AS last_order,
    datediff(curdate(),MAX(o.order_date)) AS days_since_last_order,
    COUNT(o.order_id) AS Total_orders,
    CASE
        WHEN DATEDIFF(curdate(),MAX(o.order_date)) <= 500 THEN "Champion Customer"
        WHEN DATEDIFF( curdate(),MAX(o.order_date)) <= 600 THEN "Potential Customer"
        WHEN DATEDIFF(curdate(),MAX(o.order_date)) <= 800 THEN "loyal Customer"
        ELSE "New Customer"
    END AS Ranks
FROM
    blinkit_orders o
        JOIN
    blinkit_customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id , customer_name
ORDER BY Total_orders DESC , days_since_last_order;





-- ERP (Enterprice Resources Planning)
-- Which products have the highest total orders, and how long has it been since their last sale, 
-- indicating potential inventory or demand issues?

SELECT 
    p.product_id,
    p.product_name,
    MAX(o.order_date) last_order,
    DATEDIFF(CURDATE(), MAX(o.order_date)) AS days_since_last_order,
    COUNT(o.order_id) AS Total_orders,
    CASE
        WHEN DATEDIFF(CURDATE(), MAX(o.order_date)) <= 450 THEN 1
        WHEN DATEDIFF(CURDATE(), MAX(o.order_date)) <= 500 THEN 2
        WHEN DATEDIFF(CURDATE(), MAX(o.order_date)) <= 550 THEN 3
        WHEN DATEDIFF(CURDATE(), MAX(o.order_date)) <= 600 THEN 4
        WHEN DATEDIFF(CURDATE(), MAX(o.order_date)) <= 650 THEN 5
        ELSE 0
    END AS Ranks
FROM
    blinkit_orders o
        JOIN
    blinkit_order_items i ON o.order_id = i.order_id
        JOIN
    blinkit_products p ON i.product_id = p.product_id
GROUP BY p.product_id , p.product_name
ORDER BY Total_Orders DESC
limit 5;


-- ERP (Enterprise Resources Planning) RFM(Recency Frequency Monatory)
#/ Which products have not been ordered recently, 
-- how much revenue have they historically generated, and which ones are at risk of churn in the product portfolio?

 select
 p.product_id,p.product_name,
     max(o.order_date) Recently_Order,
	 count(distinct o.order_id) AS days_since_recently_order,
    round(sum(o.order_total),2) as Total_Amount,
    RANK() OVER (PARTITION BY p.product_name ORDER BY SUM(o.order_total)desc) AS product_rank
FROM
    blinkit_orders o
    join blinkit_order_items i on o.order_id = i.order_id
    join blinkit_products p on i.product_id = p.product_id
GROUP BY p.product_id,p.product_name
order by days_since_recently_order desc
limit 5;

#/ Which products within each category generate the highest profit margins, 
-- and how do their sales quantities and average profit per unit compare
 
 SELECT
 p.category, p.product_name,
 count(o.quantity) AS Total_quantity,
 round(sum(p.max_retail_price - p.price),2) as Total_Profit,
 round(avg(p.max_retail_price - p.price),2) as Total_Average,
 RANK() OVER (PARTITION BY p.category ORDER BY SUM(o.unit_price)desc) AS product_rank
 FROM blinkit_order_items o 
      JOIN
 blinkit_products p ON o.product_id = p.product_id 
 GROUP BY p.category, p.product_name
 order by Total_Profit desc
 limit 10;


 #/ Which campaign platforms deliver the highest conversion rates year over year, and 
 -- how effectively are they driving customer interest into actual sales?
 
SELECT 
    l.conversion_status AS Platforms,
    YEAR(l.campaign_date) AS Campaign_date,
     sum(l.clicks) as Total_Clicks,
    count(o.order_id) as Total_Order_Respones,
    round(sum(o.order_total),2) as Total_Amount,
   ROUND(SUM(l.conversions)/(SUM(l.clicks))*100,2) AS conversion_rate
FROM
    blinkit_marketing_performance l
        LEFT JOIN
    blinkit_orders o ON l.campaign_id = o.campaign_id
GROUP BY l.conversion_status , YEAR(l.campaign_date)
ORDER BY Campaign_date DESC;

 

#/ How have yearly sales, gross profit, and net profit trended over time, and 
-- what impact do inventory costs and damaged stock have on overall profitability?

SELECT 
    YEAR(l.order_date) Years,
    COUNT(l.order_id) AS Total_orders,
    ROUND(SUM(l.order_total), 2) AS Total_Revenue,
    ROUND(SUM(l.order_total - o.unit_price), 2) AS Total_Gross_profit,
    ROUND(SUM(l.order_total - o.unit_price) - SUM(o.unit_price * i.damaged_stock),
            2) AS Total_Net_Profit,
    ROUND(SUM(o.unit_price), 2) AS Cost_of_Goods,
    AVG(i.stock_received) AS Total_avg_inventory,
    ROUND(SUM(o.unit_price * i.stock_received), 2) AS cost_of_stock_inventory,
    ROUND(SUM(o.unit_price * i.damaged_stock), 2) AS cost_of_damaged_inventory
FROM
    blinkit_inventory i
        JOIN
    blinkit_order_items o ON i.product_id = o.product_id
        JOIN
    blinkit_orders l ON o.order_id = l.order_id
GROUP BY YEAR(l.order_date);



SELECT 
    YEAR(l.order_date) Years,
    COUNT(l.order_id) AS Total_orders,
    ROUND(SUM(l.order_total), 2) AS Total_Revenue,
    ROUND(SUM(l.order_total - o.unit_price), 2) AS Total_Gross_profit,
    ROUND(SUM(l.order_total - o.unit_price) - SUM(o.unit_price * i.damaged_stock),
            2) AS Total_Net_Profit,
    ROUND(SUM(o.unit_price), 2) AS Cost_of_Goods,
    AVG(i.stock_received) AS Total_avg_inventory,
    ROUND(SUM(o.unit_price * i.stock_received), 2) AS cost_of_stock_inventory,
    ROUND(SUM(o.unit_price * i.damaged_stock), 2) AS cost_of_damaged_inventory
FROM
    blinkit_inventorynew i
        JOIN
    blinkit_order_items o ON i.product_id = o.product_id
        JOIN
    blinkit_orders l ON o.order_id = l.order_id
GROUP BY YEAR(l.order_date)




