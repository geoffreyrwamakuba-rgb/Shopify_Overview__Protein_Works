DROP TABLE IF EXISTS ecommerce.agg_ltv_cac_monthly;
select * from ecommerce.dim_customer;
---------------------------------------------------------------------------------------
-- 1.agg_ltv_cac_monthly
---------------------------------------------------------------------------------------
DROP TABLE IF EXISTS ecommerce.agg_ltv_cac_monthly;
CREATE TABLE ecommerce.agg_ltv_cac_monthly AS
WITH revenue AS (
    SELECT 
        date_trunc('month', o.order_date)::DATE AS month,
        SUM(o.total_price) AS revenue
    FROM ecommerce.fact_orders o
    GROUP BY 1
),
new_customers AS (
    SELECT 
        date_trunc('month', first_order_date)::DATE AS month,
        COUNT(*) AS new_customers
    FROM ecommerce.dim_customer
    GROUP BY 1
),
spend AS (
    SELECT 
        date_trunc('month', spend_date)::DATE AS month,
        SUM(daily_spend) AS spend
    FROM ecommerce.fact_ad_spend
    GROUP BY 1
),
final_cte AS (
    SELECT 
        r.month,
        EXTRACT(YEAR FROM r.month) AS year,
        EXTRACT(MONTH FROM r.month) AS month_number,
        TO_CHAR(r.month, 'Mon') AS month_name,

        r.revenue,
        s.spend,
        n.new_customers,

        CASE WHEN n.new_customers > 0 
            THEN COALESCE(r.revenue,0) / n.new_customers ELSE 0 END AS ltv,

        CASE WHEN n.new_customers > 0 
            THEN COALESCE(s.spend,0) / n.new_customers ELSE 0 END AS cac

    FROM revenue r
    LEFT JOIN spend s ON r.month = s.month
    LEFT JOIN new_customers n ON r.month = n.month
)

SELECT 
    year,
    month_number,
    month_name,
    ROUND(ltv / NULLIF(cac,0),2) AS ltv_cac
FROM final_cte;
SELECT * FROM ecommerce.agg_ltv_cac_monthly;
---------------------------------------------------------------------------------------
-- 2.agg_ltv_cac_by_source
---------------------------------------------------------------------------------------
DROP TABLE IF EXISTS ecommerce.agg_ltv_cac_by_source;

CREATE TABLE ecommerce.agg_ltv_cac_by_source AS
WITH revenue AS (
    SELECT 
        fs.source_key,
        SUM(o.total_price) AS revenue
    FROM ecommerce.fact_orders o
    JOIN ecommerce.fact_sessions fs 
        ON o.session_key = fs.session_key
    GROUP BY 1
),
spend AS (
    SELECT 
        source_key,
        SUM(daily_spend) AS spend
    FROM ecommerce.fact_ad_spend
    GROUP BY 1
),
customers AS (
    SELECT 
        fs.source_key,
        COUNT(DISTINCT o.customer_key) AS customers
    FROM ecommerce.fact_orders o
    JOIN ecommerce.fact_sessions fs 
        ON o.session_key = fs.session_key
    GROUP BY 1
)

SELECT 
    ts.source_name,
    r.revenue,
    s.spend,
    c.customers,

    r.revenue / NULLIF(c.customers,0) AS ltv,
    s.spend / NULLIF(c.customers,0) AS cac,
    r.revenue / NULLIF(s.spend,0) AS roas

FROM revenue r
LEFT JOIN spend s ON r.source_key = s.source_key
LEFT JOIN customers c ON r.source_key = c.source_key
JOIN ecommerce.dim_traffic_source ts 
    ON r.source_key = ts.source_key;

select * from ecommerce.agg_ltv_cac_by_source;
---------------------------------------------------------------------------------------
-- 3.agg_marketing_kpis
---------------------------------------------------------------------------------------
DROP TABLE IF EXISTS ecommerce.agg_marketing_kpis;

CREATE TABLE ecommerce.agg_marketing_kpis AS
WITH spend AS (
    SELECT 
        d.year,
        SUM(fas.daily_spend) AS total_spend,
        SUM(fas.daily_budget) AS total_budget,
        SUM(fas.conversions) AS conversions,
        SUM(fas.clicks) AS clicks
    FROM ecommerce.fact_ad_spend fas
    JOIN ecommerce.dim_date d 
        ON fas.spend_date = d.date
    GROUP BY 1
),
revenue AS (
    SELECT 
        d.year,
        SUM(o.total_price) AS revenue
    FROM ecommerce.fact_orders o
    JOIN ecommerce.dim_date d 
        ON DATE(o.order_date) = d.date
    GROUP BY 1
)

SELECT 
    s.year,
    s.total_spend,
	round((s.total_spend/lag(s.total_spend,1) over(order by s.year) - 1),4) AS spend_yoy,
    s.total_budget,
	round((s.total_budget/lag(s.total_budget,1) over(order by s.year) - 1),4) AS budget_yoy,
    round(s.total_spend / NULLIF(s.total_budget,0),4) AS budget_utilisation,
    
    s.conversions,
    s.clicks,
    s.conversions::DECIMAL / NULLIF(s.clicks,0) AS cvr,
    r.revenue,
    r.revenue / NULLIF(s.total_spend,0) AS roas,
	round((r.revenue / NULLIF(s.total_spend,0)/lag(r.revenue / NULLIF(s.total_spend,0),1) over(order by s.year) - 1),4) AS roas_yoy

FROM spend s
LEFT JOIN revenue r 
    ON s.year = r.year;

SELECT * FROM ecommerce.agg_marketing_kpis;

---------------------------------------------------------------------------------------
-- 4. agg_marketing_channel_perf
---------------------------------------------------------------------------------------
DROP TABLE IF EXISTS ecommerce.agg_marketing_channel_perf;

CREATE TABLE ecommerce.agg_marketing_channel_perf AS
WITH spend AS (
    SELECT 
        source_key,
        SUM(daily_spend) AS spend,
        SUM(daily_budget) AS budget
    FROM ecommerce.fact_ad_spend
    GROUP BY 1
),
sessions AS (
    SELECT 
        source_key,
        COUNT(*) AS sessions,
        SUM(converted::INT) AS conversions
    FROM ecommerce.fact_sessions
    GROUP BY 1
),
revenue AS (
    SELECT 
        fs.source_key,
        SUM(o.total_price) AS revenue
    FROM ecommerce.fact_orders o
    JOIN ecommerce.fact_sessions fs 
        ON o.session_key = fs.session_key
    GROUP BY 1
)

SELECT 
    ts.source_name,
    s.spend,
    s.budget,
    s.spend / NULLIF(s.budget,0) AS budget_utilisation,
    se.sessions,
    se.conversions,
    se.conversions::DECIMAL / NULLIF(se.sessions,0) AS cvr,
    r.revenue,
    r.revenue / NULLIF(s.spend,0) AS roas

FROM spend s
JOIN sessions se ON s.source_key = se.source_key
LEFT JOIN revenue r ON s.source_key = r.source_key
JOIN ecommerce.dim_traffic_source ts 
    ON s.source_key = ts.source_key;

select * from ecommerce.agg_marketing_channel_perf;
---------------------------------------------------------------------------------------
-- 5. agg_customer_kpis
---------------------------------------------------------------------------------------
DROP TABLE IF EXISTS ecommerce.agg_customer_kpis;

CREATE TABLE ecommerce.agg_customer_kpis AS
WITH customer_orders AS (
    SELECT 
        o.customer_key,
        o.order_date,
        d.year,
        LAG(o.order_date) OVER (
            PARTITION BY o.customer_key 
            ORDER BY o.order_date
        ) AS prev_order_date
    FROM ecommerce.fact_orders o
    JOIN ecommerce.dim_date d 
        ON DATE(o.order_date) = d.date
),

yearly_metrics AS (
    SELECT 
        year,

        -- repeat customers (had previous order BEFORE this one)
        COUNT(DISTINCT CASE 
            WHEN prev_order_date IS NOT NULL THEN customer_key 
        END) AS repeat_customers,

        COUNT(DISTINCT customer_key) AS total_customers,

        AVG(order_date - prev_order_date) AS avg_repurchase_time

    FROM customer_orders
    GROUP BY 1
),

revenue AS (
    SELECT 
        d.year,
        SUM(CASE 
            WHEN c.lifetime_orders > 1 THEN o.total_price 
            ELSE 0 
        END) AS repeat_revenue,
        SUM(o.total_price) AS total_revenue
    FROM ecommerce.fact_orders o
    JOIN ecommerce.dim_customer c 
        ON o.customer_key = c.customer_key
    JOIN ecommerce.dim_date d 
        ON DATE(o.order_date) = d.date
    GROUP BY 1
),

final_cte AS (
    SELECT 
        y.year,
        r.repeat_revenue,
        r.total_revenue,

        r.repeat_revenue / NULLIF(r.total_revenue,0) AS repeat_revenue_pct,

        y.repeat_customers,
        y.total_customers,

        y.repeat_customers::DECIMAL 
            / NULLIF(y.total_customers,0) AS repeat_rate,

        y.avg_repurchase_time

    FROM yearly_metrics y
    JOIN revenue r 
        ON y.year = r.year
)

SELECT 
    *,
	total_revenue/total_customers AS Lifetime_value,
	((total_revenue/total_customers)/(lag(total_revenue/total_customers)over(order by year))-1) AS LTV_yoy,
	EXTRACT(DAY FROM avg_repurchase_time)::FLOAT AS AVG_Repurchase_Time2,

    -- YoY changes
    LAG(repeat_revenue) OVER (ORDER BY year) AS prev_repeat_revenue,
    (repeat_revenue - LAG(repeat_revenue) OVER (ORDER BY year)) 
        / NULLIF(LAG(repeat_revenue) OVER (ORDER BY year),0) AS repeat_revenue_yoy,

    LAG(repeat_rate) OVER (ORDER BY year) AS prev_repeat_rate,
    (repeat_rate - LAG(repeat_rate) OVER (ORDER BY year)) 
        / NULLIF(LAG(repeat_rate) OVER (ORDER BY year),0) AS repeat_rate_yoy,

    LAG(EXTRACT(DAY FROM avg_repurchase_time)::FLOAT) OVER (ORDER BY year) AS prev_repurchase_time,
    (EXTRACT(DAY FROM avg_repurchase_time)::FLOAT - LAG(EXTRACT(DAY FROM avg_repurchase_time)::FLOAT) OVER (ORDER BY year))/NULLIF(LAG(EXTRACT(DAY FROM avg_repurchase_time)::FLOAT) OVER (ORDER BY year),0) AS repurchase_time_yoy

FROM final_cte;

select * from ecommerce.agg_customer_kpis;
---------------------------------------------------------------------------------------
-- 6. agg_new_vs_repeat
---------------------------------------------------------------------------------------
DROP TABLE IF EXISTS ecommerce.agg_new_vs_repeat;

CREATE TABLE ecommerce.agg_new_vs_repeat AS (
WITH CTE_1 AS (
SELECT 
    date_trunc('month', o.order_date)::DATE AS month,
    
    COUNT(DISTINCT CASE WHEN c.lifetime_orders = 1 THEN o.customer_key END) AS new_customers,
    
    COUNT(DISTINCT CASE WHEN c.lifetime_orders > 1 THEN o.customer_key END) AS repeat_customers

FROM ecommerce.fact_orders o
JOIN ecommerce.dim_customer c 
    ON o.customer_key = c.customer_key
GROUP BY 1)

SELECT "month",
    new_customers,
	repeat_customers,
	(repeat_customers::FLOAT/(new_customers::FLOAT+repeat_customers::FLOAT)) AS repeat_customer_percentage
FROM CTE_1);

SELECT * FROM ecommerce.agg_new_vs_repeat;

---------------------------------------------------------------------------------------
-- 7. ecommerce.agg_purchase_frequency
---------------------------------------------------------------------------------------
DROP TABLE IF EXISTS ecommerce.agg_purchase_frequency;

CREATE TABLE ecommerce.agg_purchase_frequency AS
WITH customer_orders AS (
    SELECT 
        customer_key,
        COUNT(*) AS purchase_count
    FROM ecommerce.fact_orders
    GROUP BY 1
)

SELECT 
    purchase_count,
    COUNT(*) AS customer_count,
    
    COUNT(*)::DECIMAL 
        / SUM(COUNT(*)) OVER () AS pct_customers

FROM customer_orders
GROUP BY 1
ORDER BY 1;

select * from ecommerce.agg_purchase_frequency;

---------------------------------------------------------------------------------------
-- Save Files
---------------------------------------------------------------------------------------

-- ecommerce.agg_ltv_cac_monthly
-- agg_ltv_cac_monthly
COPY ecommerce.agg_ltv_cac_monthly TO 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\Agg files\agg_ltv_cac_monthly.csv'
WITH (FORMAT csv, HEADER true);

-- agg_ltv_cac_by_source
COPY ecommerce.agg_ltv_cac_by_source TO 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\Agg files\agg_ltv_cac_by_source'
WITH (FORMAT csv, HEADER true);

-- agg_marketing_kpis
COPY ecommerce.agg_marketing_kpis TO 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\Agg files\agg_marketing_kpis.csv'
WITH (FORMAT csv, HEADER true);

-- agg_marketing_channel_perf
COPY ecommerce.agg_marketing_channel_perf TO 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\Agg files\agg_marketing_channel_perf.csv'
WITH (FORMAT csv, HEADER true);

-- agg_customer_kpis
COPY ecommerce.agg_customer_kpis TO 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\Agg files\agg_customer_kpis.csv'
WITH (FORMAT csv, HEADER true);

-- agg_new_vs_repeat
COPY ecommerce.agg_new_vs_repeat TO 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\Agg files\agg_new_vs_repeat.csv'
WITH (FORMAT csv, HEADER true);

-- ecommerce.agg_purchase_frequency
COPY ecommerce.agg_purchase_frequency TO 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\Agg files\ecommerce.agg_purchase_frequency.csv'
WITH (FORMAT csv, HEADER true);
