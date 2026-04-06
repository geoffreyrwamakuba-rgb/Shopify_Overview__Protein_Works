DROP TABLE IF EXISTS ecommerce.fact_ad_spend;
DROP TABLE IF EXISTS ecommerce.fact_line_items;
DROP TABLE IF EXISTS ecommerce.fact_orders;
DROP TABLE IF EXISTS ecommerce.fact_sessions;
DROP TABLE IF EXISTS ecommerce.dim_campaign;
DROP TABLE IF EXISTS ecommerce.dim_customer;
DROP TABLE IF EXISTS ecommerce.dim_products;
DROP TABLE IF EXISTS ecommerce.dim_traffic_source;
DROP TABLE IF EXISTS ecommerce.dim_channel;
DROP TABLE IF EXISTS ecommerce.dim_date;

DROP SCHEMA IF EXISTS  ecommerce ;
CREATE SCHEMA ecommerce;

---------------------------------------------------------------------------------------
-- Create dim_date
---------------------------------------------------------------------------------------
CREATE TABLE ecommerce.dim_date (
    "date_key" INT PRIMARY KEY NOT NULL,
    "date" DATE NOT NULL,
    "day" INT NOT NULL,
	"week" INT NOT NULL,
    "month" INT NOT NULL,
    "year" INT NOT NULL,
    "is_weekend" BOOLEAN NOT NULL
);

-- SELECT * FROM ecommerce.dim_date;

---------------------------------------------------------------------------------------
-- Create dim_channel
---------------------------------------------------------------------------------------
CREATE TABLE ecommerce.dim_channel (
    channel_key INT PRIMARY KEY NOT NULL,
    channel_name VARCHAR(50) NOT NULL,
    channel_type VARCHAR(50) NOT NULL);

SELECT * FROM ecommerce.dim_channel;
---------------------------------------------------------------------------------------
-- Create dim_traffic_source
---------------------------------------------------------------------------------------
CREATE TABLE ecommerce.dim_traffic_source (
    source_key INT PRIMARY KEY NOT NULL,
    source_name VARCHAR(100) NOT NULL,
    channel_key INT NOT NULL,
    FOREIGN KEY (channel_key) REFERENCES ecommerce.dim_channel(channel_key)
);
---------------------------------------------------------------------------------------
-- Create dim_products
---------------------------------------------------------------------------------------
CREATE TABLE ecommerce.dim_products (
    product_key INT PRIMARY KEY NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    product_name VARCHAR(50) NOT NULL,
    flavour VARCHAR(50) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    "cost" DECIMAL(10,2) NOT NULL,
    margin DECIMAL(5,2) NOT NULL
);

---------------------------------------------------------------------------------------
-- Create dim_customer
---------------------------------------------------------------------------------------
CREATE TABLE ecommerce.dim_customer (
    customer_key INT PRIMARY KEY NOT NULL,
    customer_id VARCHAR(50) NOT NULL,
    "name" VARCHAR(225) NOT NULL,
    email VARCHAR(225) NOT NULL,
    first_order_date DATE NOT NULL,
    effective_start_date DATE NOT NULL,
    effective_end_date DATE,
    is_current BOOLEAN NOT NULL,
	lifetime_orders INT NOT NULL
);
---------------------------------------------------------------------------------------
-- Create dim_campaign
---------------------------------------------------------------------------------------
CREATE TABLE ecommerce.dim_campaign (
    campaign_key INT PRIMARY KEY NOT NULL,
    campaign_id VARCHAR(50) NOT NULL,
    campaign_name VARCHAR(100) NOT NULL,
    source_key INT NOT NULL,
    channel_key INT NOT NULL,
    campaign_type VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN NOT NULL,
    FOREIGN KEY (source_key) REFERENCES ecommerce.dim_traffic_source(source_key),
    FOREIGN KEY (channel_key) REFERENCES ecommerce.dim_channel(channel_key)
);
---------------------------------------------------------------------------------------
-- Create fact_sessions
---------------------------------------------------------------------------------------
CREATE TABLE ecommerce.fact_sessions (
    session_key INT PRIMARY KEY NOT NULL,
    session_id VARCHAR(50) NOT NULL,
    channel_key INT NOT NULL,
	campaign_key INT NOT NULL,
	session_date DATE NOT NULL,
    source_key INT NOT NULL,
	utm_campaign VARCHAR(100),
    converted BOOLEAN NOT NULL,
    transaction_id VARCHAR(50),
    FOREIGN KEY (channel_key) REFERENCES ecommerce.dim_channel(channel_key),
    FOREIGN KEY (source_key) REFERENCES ecommerce.dim_traffic_source(source_key)
);
---------------------------------------------------------------------------------------
-- Create fact_orders
---------------------------------------------------------------------------------------
CREATE TABLE ecommerce.fact_orders (
    order_key INT PRIMARY KEY NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    customer_key INT NOT NULL,
    session_key INT NOT NULL,
	order_date TIMESTAMP NOT NULL,
    session_id VARCHAR(50),
	total_price DECIMAL(10,2) NOT NULL,
    order_status VARCHAR(100) NOT NULL,
    FOREIGN KEY (customer_key) REFERENCES ecommerce.dim_customer(customer_key),
    FOREIGN KEY (session_key) REFERENCES ecommerce.fact_sessions(session_key)
);

---------------------------------------------------------------------------------------
-- Create fact_line_items
---------------------------------------------------------------------------------------
CREATE TABLE ecommerce.fact_line_items (
    line_item_key INT PRIMARY KEY NOT NULL,
    line_item_id VARCHAR(50) NOT NULL,
    order_key INT NOT NULL,
    product_key INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    unit_cost DECIMAL(10,2) NOT NULL,
    line_item_total DECIMAL(10,2) NOT NULL,
    line_item_cost DECIMAL(10,2) NOT NULL,
    profit DECIMAL(10,2) NOT NULL,
    profit_margin DECIMAL(5,2) NOT NULL,
    FOREIGN KEY (order_key) REFERENCES ecommerce.fact_orders(order_key),
    FOREIGN KEY (product_key) REFERENCES ecommerce.dim_products(product_key)
);

---------------------------------------------------------------------------------------
-- Create fact_ad_spend
---------------------------------------------------------------------------------------
CREATE TABLE ecommerce.fact_ad_spend (
    ad_spend_key INT PRIMARY KEY NOT NULL,
    campaign_key INT NOT NULL,
    source_key INT NOT NULL,
    channel_key INT NOT NULL,
    spend_date DATE NOT NULL,
    daily_budget DECIMAL(10,2) NOT NULL,
    daily_spend DECIMAL(10,2) NOT NULL,
    impressions INT NOT NULL,
    clicks INT,
    conversions INT NOT NULL,
    FOREIGN KEY (campaign_key) REFERENCES ecommerce.dim_campaign(campaign_key),
    FOREIGN KEY (source_key) REFERENCES ecommerce.dim_traffic_source(source_key),
    FOREIGN KEY (channel_key) REFERENCES ecommerce.dim_channel(channel_key)
);
---------------------------------------------------------------------------------------
-- COPY INTO TABLES FROM CSV files 
---------------------------------------------------------------------------------------
COPY ecommerce.dim_date
FROM 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\CSV Files\dim_date.csv'
DELIMITER ','
CSV HEADER;


COPY ecommerce.dim_customer
FROM 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\CSV Files\dim_customer.csv'
DELIMITER ','
CSV HEADER;


COPY ecommerce.dim_channel
FROM 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\CSV Files\dim_channel.csv'
DELIMITER ','
CSV HEADER;

COPY ecommerce.dim_traffic_source
FROM 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\CSV Files\dim_traffic_source.csv'
DELIMITER ','
CSV HEADER;

COPY ecommerce.dim_campaign
FROM 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\CSV Files\dim_campaign.csv'
DELIMITER ','
CSV HEADER;

COPY ecommerce.dim_products
FROM 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\CSV Files\dim_products.csv'
DELIMITER ','
CSV HEADER;

COPY ecommerce.fact_sessions
FROM 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\CSV Files\fact_sessions.csv'
DELIMITER ','
CSV HEADER;

COPY ecommerce.fact_orders
FROM 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\CSV Files\fact_orders.csv'
DELIMITER ','
CSV HEADER;

COPY ecommerce.fact_line_items
FROM 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\CSV Files\fact_line_items.csv'
DELIMITER ','
CSV HEADER;

COPY ecommerce.fact_ad_spend
FROM 'C:\Users\geoff\Downloads\Key Docs\Ecommerce Project\Data\CSV Files\fact_ad_spend.csv'
DELIMITER ','
CSV HEADER;