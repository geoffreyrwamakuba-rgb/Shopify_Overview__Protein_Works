DROP TABLE IF EXISTS ecommerce.agg_daily_kpis;
DROP TABLE IF EXISTS ecommerce.agg_category_performance;
DROP TABLE IF EXISTS ecommerce.agg_profit_over_time;
DROP TABLE IF EXISTS ecommerce.agg_channel_performance;
DROP TABLE IF EXISTS ecommerce.agg_product_ranking;
DROP TABLE IF EXISTS ecommerce.agg_customer_metrics;

SELECT * from ecommerce.fact_orders;
---------------------------------------------------------------------------------------
-- 1.agg_daily_kpis
---------------------------------------------------------------------------------------
-- date
-- revenue
-- profit
-- orders
-- customers
-- sessions
-- conversion_rate   -- orders / sessions
-- aov               -- revenue / orders
-- SELECT DATE_PART('year',order_date), sum(total_price) FROM ecommerce.fact_orders as o GROUP BY DATE_PART('year',order_date);

CREATE TABLE ecommerce.agg_daily_kpis AS
WITH orders AS (
    SELECT 
        DATE(order_date) AS "date",
        COUNT(DISTINCT order_id) AS orders,
        SUM(total_price) AS revenue
    FROM ecommerce.fact_orders
    GROUP BY 1
),
profit AS (
    SELECT 
        DATE(o.order_date) AS date,
        SUM(li.profit) AS profit
    FROM ecommerce.fact_line_items li
    JOIN ecommerce.fact_orders o 
        ON li.order_key = o.order_key
    GROUP BY 1
),
sessions AS (
    SELECT 
        session_date AS date,
        COUNT(*) AS sessions
    FROM ecommerce.fact_sessions
    GROUP BY 1
),
customers AS (
    SELECT 
        DATE(order_date) AS date,
        COUNT(DISTINCT customer_key) AS customers
    FROM ecommerce.fact_orders
    GROUP BY 1
)

SELECT 
    d.date,
    COALESCE(o.revenue, 0) AS revenue,
    COALESCE(p.profit, 0) AS profit,
    COALESCE(o.orders, 0) AS orders,
    COALESCE(c.customers, 0) AS customers,
    COALESCE(s.sessions, 0) AS sessions,
	CASE WHEN s.sessions > 0 
	THEN round(COALESCE(o.orders,0)::DECIMAL / s.sessions,3) ELSE 0 END AS conversion_rate,
	CASE WHEN o.orders > 0 
	THEN round(COALESCE(o.revenue,0) / o.orders,2) ELSE 0 END AS aov
FROM ecommerce.dim_date d
LEFT JOIN orders o ON d.date = o.date
LEFT JOIN profit p ON d.date = p.date
LEFT JOIN sessions s ON d.date = s.date
LEFT JOIN customers c ON d.date = c.date;

select * from ecommerce.agg_daily_kpis;

drop table if exists ecommerce.agg_daily_kpis2;
CREATE TABLE ecommerce.agg_daily_kpis2 AS
WITH AGG2 AS ( 
SELECT date_part('year',"date") as "Year", sum(revenue) as year_revenue,
sum(profit) as year_profit, sum(orders) as year_orders
from ecommerce.agg_daily_kpis group by date_part('year',"date") order by date_part('year',"date"))

SELECT "Year", year_revenue,
LAG(year_revenue) OVER (ORDER BY "Year") as prev_revenue,
ROUND((year_revenue - LAG(year_revenue) OVER (ORDER BY "Year"))
/ NULLIF(LAG(year_revenue) OVER (ORDER BY "Year"),0),3) AS revenue_yoy,
year_profit,
LAG(year_profit) OVER (ORDER BY "Year") as prev_profit,
ROUND((year_profit - LAG(year_profit) OVER (ORDER BY "Year"))
/ NULLIF(LAG(year_profit) OVER (ORDER BY "Year"),0),3) AS profit_yoy,
year_orders,
LAG(year_orders) OVER (ORDER BY "Year") as prev_orders,
ROUND((year_orders - LAG(year_orders) OVER (ORDER BY "Year"))
/ NULLIF(LAG(year_orders) OVER (ORDER BY "Year"),0),3) AS orders_yoy
from AGG2;

SELECT * FROM ecommerce.agg_daily_kpis2;

-- select date_part('year',"date") as "year",sum(revenue),
-- sum("profit"), sum("sessions") from ecommerce.agg_daily_kpis
-- group by date_part('year',"date") order by "year" asc;
--------------------------------------------------------------------------------------
-- 2. agg_category_performance
---------------------------------------------------------------------------------------

CREATE TABLE ecommerce.agg_category_performance AS
SELECT 
    d.year,
    p.category,
    SUM(li.profit) AS profit,
    SUM(li.line_item_total) AS revenue,
	COUNT(DISTINCT o.order_id) AS orders
FROM ecommerce.fact_line_items li
JOIN ecommerce.fact_orders o 
    ON li.order_key = o.order_key
JOIN ecommerce.dim_products p 
    ON li.product_key = p.product_key
JOIN ecommerce.dim_date d 
    ON DATE(o.order_date) = d.date
GROUP BY 1,2;

select * from ecommerce.agg_category_performance;

---------------------------------------------------------------------------------------
-- 3. agg_profit_over_time
---------------------------------------------------------------------------------------
drop table if exists ecommerce.agg_profit_over_time; 
CREATE TABLE ecommerce.agg_profit_over_time AS
SELECT 
    d.year,
	date_trunc('month',d.date)::DATE as "month",
    p.category,
    SUM(li.profit) AS profit,
	SUM(li.line_item_total) AS revenue,
	COUNT(DISTINCT o.order_id) AS orders
FROM ecommerce.fact_line_items li
JOIN ecommerce.fact_orders o 
    ON li.order_key = o.order_key
JOIN ecommerce.dim_products p 
    ON li.product_key = p.product_key
JOIN ecommerce.dim_date d 
    ON DATE(o.order_date) = d.date
GROUP BY 1,2,3 order by 2;

select * from ecommerce.agg_profit_over_time;
-- select date_trunc('month',"date"), sum(profit), category 
-- from ecommerce.agg_profit_over_time 
-- group by category, date_trunc('month',"date") order by date_trunc('month',"date");
-- select * from ecommerce.dim_date;

---------------------------------------------------------------------------------------
-- 4. agg_channel_performance
---------------------------------------------------------------------------------------
CREATE TABLE ecommerce.agg_channel_performance AS
WITH sessions AS (
    SELECT 
        d.year,
        fs.source_key,
        COUNT(*) AS sessions
    FROM ecommerce.fact_sessions fs
    JOIN ecommerce.dim_date d 
        ON fs.session_date = d.date
    GROUP BY 1,2
),
orders AS (
    SELECT 
        d.year,
        fs.source_key,
        COUNT(DISTINCT fo.order_id) AS orders
    FROM ecommerce.fact_orders fo
    JOIN ecommerce.fact_sessions fs 
        ON fo.session_key = fs.session_key
    JOIN ecommerce.dim_date d 
        ON DATE(fo.order_date) = d.date
    GROUP BY 1,2
)

SELECT 
    s.year,
    ts.source_name,
    c.channel_name,
    s.sessions,
    COALESCE(o.orders, 0) AS orders,
    
    CASE 
        WHEN s.sessions > 0 
        THEN COALESCE(o.orders, 0)::DECIMAL / s.sessions 
        ELSE 0 
    END AS conversion_rate

FROM sessions s
LEFT JOIN orders o 
    ON s.source_key = o.source_key
    AND s.year = o.year
JOIN ecommerce.dim_traffic_source ts 
    ON s.source_key = ts.source_key
JOIN ecommerce.dim_channel c 
    ON ts.channel_key = c.channel_key;
	
SELECT * FROM ecommerce.agg_channel_performance WHERE year=2025;
---------------------------------------------------------------------------------------
-- 5 agg_product_ranking 
---------------------------------------------------------------------------------------
DROP TABLE IF EXISTS ecommerce.agg_product_ranking;
CREATE TABLE ecommerce.agg_product_ranking AS
WITH product_metrics AS (
    SELECT 
        d.year,
        p.product_key,
        p.product_name,
        p.category,
        SUM(li.profit) AS total_profit,
        SUM(li.line_item_total) AS total_revenue,
		COUNT(DISTINCT o.order_id) AS total_orders
    FROM ecommerce.fact_line_items li
    JOIN ecommerce.fact_orders o 
        ON li.order_key = o.order_key
    JOIN ecommerce.dim_products p 
        ON li.product_key = p.product_key
    JOIN ecommerce.dim_date d 
        ON DATE(o.order_date) = d.date
    GROUP BY 1,2,3,4
)

SELECT 
    year,
    product_key,
    product_name,
    category,
    total_profit,
    total_revenue,
	total_orders,

    DENSE_RANK() OVER (
        PARTITION BY year 
        ORDER BY total_profit DESC
    ) AS profit_rank,

    DENSE_RANK() OVER (
        PARTITION BY year 
        ORDER BY total_revenue DESC
    ) AS revenue_rank,
	DENSE_RANK() OVER (
	    PARTITION BY year 
	    ORDER BY total_orders DESC
    ) AS orders_rank
FROM product_metrics;

SELECT * FROM ecommerce.agg_product_ranking where profit_rank<=5;
---------------------------------------------------------------------------------------
-- 6. agg_customer_metrics --- change date for year
---------------------------------------------------------------------------------------

drop table if exists ecommerce.agg_customer_metrics; 
CREATE TABLE ecommerce.agg_customer_metrics AS
WITH customer_orders AS (
    SELECT 
        customer_key,
        DATE(order_date) AS date,
        COUNT(*) OVER (PARTITION BY customer_key ORDER BY order_date) AS order_number
    FROM ecommerce.fact_orders
),

ct2 as ( SELECT
    date_part('year',date) as year,
    COUNT(DISTINCT CASE WHEN order_number > 1 THEN customer_key END) AS returning_customers,
    COUNT(DISTINCT customer_key) AS total_customers,
    
    CASE WHEN COUNT(DISTINCT customer_key) > 0 
        THEN round(COUNT(DISTINCT CASE WHEN order_number > 1 THEN customer_key END)::DECIMAL
             / COUNT(DISTINCT customer_key),3)
        ELSE 0
    END AS returning_rate
	FROM customer_orders GROUP BY date_part('year',date))

SELECT "year", returning_customers, total_customers, returning_rate,
	coalesce(returning_rate,0) - coalesce(lag(returning_rate,1) over(order by "year"),0) AS Rate_Yoy

FROM ct2;

SELECT * FROM ecommerce.agg_customer_metrics;

COPY ecommerce.agg_daily_kpis TO 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\Agg files\agg_daily_kpis.csv'
WITH (FORMAT csv, HEADER true);

COPY ecommerce.agg_daily_kpis2 TO 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\Agg files\agg_daily_kpis2.csv'
WITH (FORMAT csv, HEADER true);

COPY ecommerce.agg_category_performance TO 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\Agg files\agg_category_performance.csv'
WITH (FORMAT csv, HEADER true);

COPY ecommerce.agg_profit_over_time TO 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\Agg files\agg_profit_over_time.csv'
WITH (FORMAT csv, HEADER true);

COPY ecommerce.agg_channel_performance TO 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\Agg files\agg_channel_performance.csv'
WITH (FORMAT csv, HEADER true);

COPY ecommerce.agg_product_ranking TO 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\Agg files\agg_product_ranking.csv'
WITH (FORMAT csv, HEADER true);

COPY ecommerce.agg_customer_metrics TO 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\Agg files\agg_customer_metrics.csv'
WITH (FORMAT csv, HEADER true);

