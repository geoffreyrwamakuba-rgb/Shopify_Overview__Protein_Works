# Shopify-Overview - Protein-Works

## Executive Summary
The dashboard provides a high-level overview of revenue, profitability, customer behaviour, and marketing efficiency, enabling stakeholders to quickly identify growth drivers and optimisation opportunities.

Tools Used: SQL, Python, Tableau

Data Sources: Data model based on Shopify, Google Analytics 4, Facebook Ads, Instagram & TikTok Analytics schemas. All data is synthetic.

## Dashboard
![alt text](https://github.com/geoffreyrwamakuba-rgb/Revenue-Churn-Analysis-for-a-SaaS-Fintech/blob/main/Dashboard%20Image.png?raw=true)

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

[Insert data model image here]

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
### Insight 1 – MRR Growth Is Driven More by Expansion Than New Sales
- Across most months, Expansion MRR > New MRR.
- Existing customers are increasing seats or upgrading plans.
- Customer Success and product experience are strong expansion drivers.
### Recommendation – Double down on expansion motions
- Identify features correlated with expansion (e.g., corporate cards, reimbursement workflows (Uber & Deliveroo)).
- Implement “adoption nudges” for companies with <60% seat activation.
### Insight 2 – Significant Drop in Retention after the first year
- Strong onboarding but weak customer loyalty
- Competitors may be pulling customers away
### Recommendation – Differentiate products and track customers 
- Expand offering (audit automation or AI receipt extraction)
- Improve UX — expense tools with poor UX churn the fastest
- Create engagement triggers for low-activity or recently contracted accounts

## Next Steps
- Incorporate real-world data sources (e.g. Shopify API, GA4 exports)
- Design A/B test for new product offering
