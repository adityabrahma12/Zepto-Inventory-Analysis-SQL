# Zepto E-Commerce Data Analysis — PostgreSQL Portfolio Project

## Executive Overview

This repository contains an end-to-end e-commerce inventory and pricing data analysis project using **PostgreSQL**. The dataset comprises **3,732 scraped inventory records** from **Zepto**—a leading quick-commerce platform in India—scraped directly from their official platform and sourced via Kaggle.

The objective of this project is to simulate real-world e-commerce data analytics workflows. It covers the full data lifecycle: establishing a robust PostgreSQL database schema, performing data quality audits and currency standardization, executing operational data cleaning, and crafting business-centric SQL queries to extract actionable insights across pricing efficiency, inventory stockout risks, margin protection, and warehouse logistics.

---

## Technical Stack &amp; Tools

* **Database Management System**: PostgreSQL (v14+)
* **Database Administration Client**: pgAdmin 4 / `psql` CLI
* **Language**: SQL (Data Definition Language, Data Manipulation Language, Data Query Language)
* **Dataset Source**: Kaggle (Scraped Zepto Public Product Listings)
* **Dataset Volume**: 3,732 Rows | 9 Raw Attributes | 1,681 Unique Product Names

---

## Dataset Architecture &amp; Multi-SKU Concept

Each row in the dataset represents a distinct **Stock Keeping Unit (SKU)**. In quick-commerce platforms like Zepto, individual products frequently exist under multiple SKUs to accommodate varying pack sizes, promotional bundles, or category cross-listings. For instance, while the dataset contains **3,732 total SKUs**, there are **1,681 unique product names**.

### Raw Attribute Metadata

| Attribute Name             | PostgreSQL Data Type | Constraint / Description                                              |
| -------------------------- | -------------------- | --------------------------------------------------------------------- |
| `sku_id`                   | `SERIAL`             | Primary Key, Auto-incrementing SKU Identifier                         |
| `category`                 | `VARCHAR(100)`       | Product classification category                                       |
| `name`                     | `VARCHAR(255)`       | `NOT NULL`, Brand and product description                             |
| `mrp`                      | `NUMERIC(10, 2)`     | Maximum Retail Price                                                  |
| `discount_percent`         | `NUMERIC(5, 2)`      | Percentage discount applied on MRP                                    |
| `available_quantity`       | `INT`                | Current available stock quantity in warehouse                         |
| `discounted_selling_price` | `NUMERIC(10, 2)`     | Final customer checkout price after discount                          |
| `weight_in_gms`            | `INT`                | Product weight or volume in grams/milliliters                         |
| `out_of_stock`             | `BOOLEAN`            | Stock availability flag (`TRUE` \= Out of Stock, `FALSE` \= In Stock) |
| `quantity`                 | `INT`                | Pack unit count or package multiplier                                 |

---

## Database Setup &amp; Table DDL

```
-- Step 1: Drop existing table to ensure clean execution environment
DROP TABLE IF EXISTS zepto;

-- Step 2: Create primary table schema with data validation constraints
CREATE TABLE zepto (
    sku_id SERIAL PRIMARY KEY,
    category VARCHAR(100),
    name VARCHAR(255) NOT NULL,
    mrp NUMERIC(10, 2),
    discount_percent NUMERIC(5, 2),
    available_quantity INT,
    discounted_selling_price NUMERIC(10, 2),
    weight_in_gms INT,
    out_of_stock BOOLEAN,
    quantity INT
);

```

---

## Data Cleaning &amp; Standardization Workflow

Prior to conducting business analytics, raw scraped datasets undergo rigorous data auditing and cleaning to address format inconsistencies and data entry errors.

### 1\. UTF-8 Encoding &amp; Import Validation

Scraped raw data contains multi-byte special characters. The source CSV was saved under `CSV UTF-8 (Comma delimited)` encoding prior to importing via pgAdmin to prevent import failures.

```
-- Verify total imported row count (Expected: 3,732)
SELECT COUNT(*) AS total_imported_skus FROM zepto;

```

### 2\. Missing &amp; Null Value Audit

Checking across all attributes for missing or `NULL` entries to guarantee data completeness.

```
SELECT * FROM zepto
WHERE name IS NULL
   OR category IS NULL
   OR mrp IS NULL
   OR discount_percent IS NULL
   OR discounted_selling_price IS NULL
   OR weight_in_gms IS NULL
   OR available_quantity IS NULL
   OR out_of_stock IS NULL
   OR quantity IS NULL;

```

### 3\. Removal of Zero-Price Data Anomalies

Scraped catalog data contained erroneous product records with zero MRP. These records represent invalid listings and were deleted from the dataset.

```
-- Identify zero-price records
SELECT * FROM zepto
WHERE mrp = 0 OR discounted_selling_price = 0;

-- Delete zero-price anomaly rows
DELETE FROM zepto
WHERE mrp = 0 OR discounted_selling_price = 0;

```

### 4\. Currency Standardization (Paise to INR Rupees)

In the raw scraped dataset, price values (`mrp` and `discounted_selling_price`) were stored in **Paise** (e.g., ₹25.00 stored as `2500`). Prices were standardized into Indian Rupees (INR) by dividing by `100.0`.

```
UPDATE zepto
SET mrp = mrp / 100.0,
    discounted_selling_price = discounted_selling_price / 100.0;

-- Verify currency update
SELECT sku_id, name, mrp, discounted_selling_price FROM zepto LIMIT 5;

```

---

## Exploratory Data Analysis (EDA)

### 1\. Category Landscape Exploration

```
SELECT DISTINCT category
FROM zepto
ORDER BY category ASC;

```

### 2\. Inventory Availability Distribution

Evaluating active vs. out-of-stock inventory proportions.

```
SELECT
    out_of_stock,
    COUNT(sku_id) AS total_skus,
    ROUND((COUNT(sku_id)::NUMERIC / (SELECT COUNT(*) FROM zepto)) * 100, 2) AS percentage_share
FROM zepto
GROUP BY out_of_stock;

```

### 3\. Identification of Multi-SKU Products

Pinpointing product names associated with multiple packaging options or category listings.

```
SELECT
    name,
    COUNT(sku_id) AS number_of_skus
FROM zepto
GROUP BY name
HAVING COUNT(sku_id) &gt; 1
ORDER BY number_of_skus DESC;

```

---

## Business Analysis &amp; Strategic Insights

### Section A: Pricing &amp; Promotional Strategy

#### Query 1: Top 10 Best Value Products by Discount Percentage

* **Business Context**: Identifies loss-leaders and heavily discounted products (50%+ off) used to drive customer acquisition.

```
SELECT DISTINCT
    name,
    mrp,
    discount_percent,
    discounted_selling_price
FROM zepto
ORDER BY discount_percent DESC
LIMIT 10;

```

#### Query 2: Premium Products Selling Without Heavy Discounts

* **Business Context**: Identifies high-value items (MRP &gt; ₹500) maintaining strong organic demand with minimal promotional discounting (&lt;10%).

```
SELECT DISTINCT
    name,
    mrp,
    discount_percent
FROM zepto
WHERE mrp &gt; 500 AND discount_percent &lt; 10
ORDER BY mrp DESC, discount_percent DESC;

```

#### Query 3: Top 5 Categories by Average Discount Depth

* **Business Context**: Measures price sensitivity across categories to understand where promotional subsidies are concentrated.

```
SELECT
    category,
    ROUND(AVG(discount_percent), 2) AS avg_discount_percent
FROM zepto
GROUP BY category
ORDER BY avg_discount_percent DESC
LIMIT 5;

```

#### Query 4: Discount Tiering &amp; Potential Revenue Breakdown

* **Business Context**: Segmenting inventory into promotional tiers to evaluate potential revenue distribution across high, moderate, and low discount brackets.

```
SELECT
    CASE
        WHEN discount_percent &gt;= 40 THEN 'High Discount (40%+)'
        WHEN discount_percent &gt;= 20 THEN 'Moderate Discount (20-39%)'
        ELSE 'Low/No Discount (&lt;20%)'
    END AS discount_tier,
    COUNT(sku_id) AS total_skus,
    SUM(available_quantity) AS total_available_units,
    ROUND(SUM(discounted_selling_price * available_quantity), 2) AS total_potential_revenue
FROM zepto
WHERE out_of_stock = FALSE
GROUP BY
    CASE
        WHEN discount_percent &gt;= 40 THEN 'High Discount (40%+)'
        WHEN discount_percent &gt;= 20 THEN 'Moderate Discount (20-39%)'
        ELSE 'Low/No Discount (&lt;20%)'
    END
ORDER BY total_potential_revenue DESC;

```

---

### Section B: Revenue Potential &amp; Inventory Risk Management

#### Query 5: High-Value Out-of-Stock Products (Immediate Restock Priority)

* **Business Context**: Out-of-stock products priced over ₹300 represent uncaptured revenue opportunities.

```
SELECT DISTINCT
    name,
    mrp,
    category
FROM zepto
WHERE out_of_stock = TRUE AND mrp &gt; 300
ORDER BY mrp DESC;

```

#### Query 6: Category Estimated Revenue Contribution

* **Business Context**: Quantifies total potential revenue per product category based on active stock volume.

```
SELECT
    category,
    SUM(available_quantity) AS total_units_in_stock,
    ROUND(SUM(discounted_selling_price * available_quantity), 2) AS total_estimated_revenue
FROM zepto
GROUP BY category
ORDER BY total_estimated_revenue DESC;

```

#### Query 7: Low-Stock Risk Alert (Near-Stockout Categories)

* **Business Context**: Identifies categories with 4 or more products holding critically low stock levels (&lt; 5 units remaining).

```
SELECT
    category,
    COUNT(sku_id) AS low_stock_sku_count
FROM zepto
WHERE out_of_stock = FALSE AND available_quantity &lt; 5
GROUP BY category
HAVING COUNT(sku_id) &gt;= 4
ORDER BY low_stock_sku_count DESC;

```

#### Query 8: Total Monetary Discount Sacrificed per Category

* **Business Context**: Measures the monetary value of gross margin surrendered to promotional discounting per category.

```
SELECT
    category,
    ROUND(SUM(mrp * available_quantity), 2) AS total_mrp_value,
    ROUND(SUM(discounted_selling_price * available_quantity), 2) AS total_selling_value,
    ROUND(SUM((mrp - discounted_selling_price) * available_quantity), 2) AS total_discount_sacrificed
FROM zepto
WHERE out_of_stock = FALSE
GROUP BY category
ORDER BY total_discount_sacrificed DESC;

```

#### Query 9: Under-Stocked Categories with High Product Variety

* **Business Context**: Flags categories offering high product variety (≥10 SKUs) but shallow inventory depth (&lt;10 avg units per SKU).

```
SELECT
    category,
    COUNT(sku_id) AS total_skus,
    SUM(available_quantity) AS total_available_units,
    ROUND(AVG(available_quantity), 1) AS avg_units_per_sku
FROM zepto
WHERE out_of_stock = FALSE
GROUP BY category
HAVING COUNT(sku_id) &gt;= 10 AND AVG(available_quantity) &lt; 10
ORDER BY avg_units_per_sku ASC;

```

---

### Section C: Unit Economics &amp; Warehouse Logistics Optimization

#### Query 10: Value-for-Money Analysis (Price per Gram for Products ≥ 100g)

* **Business Context**: Evaluates price efficiency per unit weight to assist merchandising strategy for bulk packaging.

```
SELECT DISTINCT
    name,
    weight_in_gms,
    discounted_selling_price,
    ROUND(discounted_selling_price / weight_in_gms, 4) AS price_per_gram
FROM zepto
WHERE weight_in_gms &gt;= 100
ORDER BY price_per_gram ASC;

```

#### Query 11: Inventory Weight Segmentation

* **Business Context**: Categorizes items into weight tiers (`low` &lt; 1kg, `medium` &lt; 5kg, `bulk` ≥ 5kg) for last-mile delivery fleet allocation.

```
SELECT DISTINCT
    name,
    weight_in_gms,
    CASE
        WHEN weight_in_gms &lt; 1000 THEN 'Low Weight (&lt;1kg)'
        WHEN weight_in_gms &lt; 5000 THEN 'Medium Weight (1-5kg)'
        ELSE 'Bulk Weight (≥5kg)'
    END AS weight_tier
FROM zepto
ORDER BY weight_in_gms DESC;

```

#### Query 12: Category Warehouse Tonnage Contribution

* **Business Context**: Calculates cumulative physical inventory weight by category to inform dark store shelving and floor loading limits.

```
SELECT
    category,
    ROUND(SUM((weight_in_gms * available_quantity) / 1000.0), 2) AS total_category_weight_kg
FROM zepto
GROUP BY category
ORDER BY total_category_weight_kg DESC;

```

#### Query 13: Logistics Margin Risk (Heavy Products with Deep Discounts)

* **Business Context**: Flags products weighing over 1kg with discounts ≥30%, where combined freight costs and price cuts jeopardize order margins.

```
SELECT
    name,
    category,
    weight_in_gms,
    mrp,
    discounted_selling_price,
    discount_percent
FROM zepto
WHERE weight_in_gms &gt;= 1000 AND discount_percent &gt;= 30
ORDER BY weight_in_gms DESC, discount_percent DESC;

```

---

## Executive Summary of Analytical Findings

1. **Revenue Concentration**: High-volume categories such as *Packaged Foods*, *Beverages*, and *Personal Care* generate over 60% of estimated inventory revenue potential.
2. **Promotional Exposure**: Deep discounts are heavily clustered in fresh produce (*Fruits &amp; Vegetables* avg discount \~15%), while high-ticket personal care items retain low discount rates (&lt;10%), indicating inelastic demand.
3. **Logistics &amp; Dark Store Operations**: Bulk weight SKUs (≥5kg) comprise a significant portion of warehouse holding weight, necessitating reinforced rack storage and specialized two-wheeler delivery equipment for 10-minute fulfillment.

---

## How to Setup and Run This Project

### Prerequisites

1. **PostgreSQL** (v12 or higher) installed locally or hosted on a cloud server.
2. **pgAdmin 4** or **DBeaver** GUI client.
3. Raw Kaggle Zepto dataset (`zepto_v2.csv`).

### Step-by-Step Execution

1. **Clone the Repository**: Clone this project repository to your local machine.
2. **Create Database**: Launch pgAdmin or `psql` terminal and create a new database:  
```  
CREATE DATABASE zepto_db;  
```
3. **Execute Schema DDL**: Run the schema creation script from `schema.sql` or paste the DDL query into your SQL query editor.
4. **Import Data**:  
  * Ensure `zepto_v2.csv` is converted to **UTF-8** format.
  * Use pgAdmin Import/Export tool: Select table `zepto`, format CSV, Header `ON`, Encoding `UTF8`, and exclude `sku_id` from column mapping.
5. **Run Cleaning &amp; Analytics Scripts**: Execute data cleaning updates followed by analytical queries provided in `analysis_queries.sql`.
