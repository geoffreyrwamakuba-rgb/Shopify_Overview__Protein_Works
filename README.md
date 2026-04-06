# Shopify Overview - Protein Works

## Executive Summary
The dashboard provides a high-level overview of revenue, profitability, customer behaviour, and marketing efficiency, enabling stakeholders to quickly identify growth drivers and optimisation opportunities.

Tools Used: SQL, Python, Tableau

Data Sources: Data model based on Shopify, Google Analytics 4, Facebook Ads, Instagram & TikTok Analytics schemas. All data is synthetic.

## Dashboard
![alt text](https://github.com/geoffreyrwamakuba-rgb/Shopify_Overview__Protein_Works/blob/f2aa037cc5a0b398a106300f9993ae0ae7dff884/Revenue%20Dashboard.png)

## Business Problem
DTC ecommerce platforms face several key challenges:
- Understanding whether growth is driven by new customer acquisition or repeat purchasing
- Measuring the efficiency of marketing spend across channels
- Identifying which products and categories drive profitability
- Consolidating fragmented data across marketing and sales into a single source of truth
  
## Methodology
### Data Source
Python was used to generate realistic synthetic datasets
The data model is based on schemas from:
- Shopify (orders, products, customers)
- Google Analytics 4 (sessions, traffic sources)
- Facebook Ads, Instagram, and TikTok (campaign performance)
- The dataset includes 50k+ orders

The data is structured using a star schema:
- Fact tables: orders, line items, sessions, ad spend
- Dimension tables: customer, product, channel, campaign, date

Realism was introduced through Seasonality trends in demand and spend & Conversion rates tied to traffic sources

![alt text](https://github.com/geoffreyrwamakuba-rgb/Shopify_Overview__Protein_Works/blob/main/Ecommerce_Data_Model.svg)

### SQL Analysis
SQL was used to transform raw data into analytics-ready tables powering the dashboard.

Key transformations include:
- Creation of daily KPI tables (revenue, profit, AOV, conversion rate)
- Channel and traffic source performance (sessions, orders, CVR)
- Product and category aggregations (revenue, profit, rankings)
- Customer metrics (repeat rate, repurchase time, retention)
- Marketing efficiency metrics (LTV, CAC, ROAS)

Advanced SQL techniques used:
- CTEs for modular transformations
- Window functions (e.g. LAG, DENSE_RANK) for YoY analysis and ranking
- Joins across fact and dimension tables
- Null handling and defensive calculations (NULLIF, COALESCE)

## Key Insights & Recommendations
### Insight 1 – Returning customer rate is exceptionally high (93% in 2025, +33% YoY)
The business shows very strong customer retention, with returning customers making up the vast majority of the customer base in 2025. This indicates high product satisfaction and strong repeat purchase behaviour.
However, such a high repeat rate may also suggest slowing new customer acquisition, which could limit future growth.
### Recommendation:
- Invest in new customer acquisition channels (paid social, influencer, partnerships) to rebalance growth
- Leverage strong retention by introducing subscription or replenishment models for frequently purchased products
- Use high-LTV repeat customers in lookalike audiences to scale acquisition efficiently

### Insight 2 – Instagram and TikTok are the strongest conversion drivers within Paid Social
Among paid social channels, Instagram (20.6% CVR) and TikTok (17.2% CVR) significantly outperform Facebook (11.3%).
This indicates that newer, more visual platforms are more effective at converting traffic, not just driving volume.
### Recommendation:
- Reallocate budget from Facebook → Instagram & TikTok
- Scale high-performing creatives on these platforms
- Use TikTok/Instagram as primary conversion channels, not just awareness
