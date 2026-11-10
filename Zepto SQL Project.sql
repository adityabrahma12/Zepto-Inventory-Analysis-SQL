

CREATE TABLE zepto_table ( 
sku_id SERIAL PRIMARY KEY,
category VARCHAR, 
name VARCHAR NOT NULL,
mrp NUMERIC, 
discount_percent NUMERIC, 
available_quantity INT,
discounted_selling_price NUMERIC,
weight_in_gms INT,
out_of_stock BOOLEAN,
quantity INT
);

Select * from zepto_table;

-- Data Exploration

-- Check for Null Values 
SELECT * FROM zepto_table 
WHERE name IS NULL 
OR category IS NULL 
OR mrp IS NULL 
OR discount_percent IS NULL 
OR discounted_selling_price IS NULL 
OR weight_in_gms IS NULL 
OR available_quantity IS NULL 
OR out_of_stock IS NULL 
OR quantity IS NULL;

-- Check Distinct Product Catagories
SELECT DISTINCT category FROM zepto_table
ORDER BY category;

-- Check In Stock and Out of Stock Products
SELECT out_of_stock, COUNT(sku_id) FROM zepto_table 
GROUP BY out_of_stock;

-- Check Duplicate Product Names (Multi SKU)
SELECT name, COUNT(sku_id) AS number_of_skus FROM zepto_table
GROUP BY name HAVING COUNT(sku_id)> 1
ORDER BY number_of_skus DESC;

-- Data Cleaning & Transformation

-- Check Invalid 0 Priced Records
SELECT * FROM zepto_table
WHERE mrp = 0 OR discounted_selling_price = 0;

-- Delete Rows with 0 Priced Records
DELETE FROM zepto_table
WHERE mrp = 0
OR discounted_selling_price = 0;

-- Convert Paise to Rupees
UPDATE zepto_table
SET mrp = mrp / 100, 
discounted_selling_price = discounted_selling_price / 100;

-- Rounding off Decimal Places
UPDATE zepto_table
SET mrp = ROUND((mrp), 2),
discounted_selling_price = ROUND((discounted_selling_price), 2);

-- Data Analysis & Key Insights

-- Top 10 Best Value Products by Percentage
SELECT DISTINCT name, mrp, discount_percent FROM zepto_table
ORDER BY discount_percent
DESC LIMIT 10;

-- Out of Stock items with Highest MRP
SELECT DISTINCT name, mrp FROM zepto_table 
WHERE out_of_stock = TRUE AND mrp> 300 
ORDER BY mrp DESC;

-- Total Estimated Revenue by Category
SELECT category, SUM(discounted_selling_price * available_quantity) AS total_revenue 
FROM zepto_table 
GROUP BY category 
ORDER BY total_revenue DESC;

-- Higest Priced Products with Low Discounts
SELECT DISTINCT name, mrp, discount_percent FROM zepto_table
WHERE mrp> 500 AND discount_percent< 10 
ORDER BY mrp DESC, discount_percent DESC;

-- Tpo 5 Categories with Highest Average Discount
SELECT category, ROUND(AVG(discount_percent), 2) AS average_discount 
FROM zepto_table
GROUP BY category 
ORDER BY average_discount DESC 
LIMIT 5;

-- Price per gram for products weighing above 100g
SELECT DISTINCT name, weight_in_gms, discounted_selling_price, 
ROUND(discounted_selling_price / weight_in_gms, 2) AS price_per_gram 
FROM zepto_table
WHERE weight_in_gms>= 100 
ORDER BY price_per_gram;

-- Product Segmentation by Weight Category
SELECT DISTINCT name, weight_in_gms, 
CASE 
WHEN weight_in_gms< 1000 THEN 'low' 
WHEN weight_in_gms< 5000 THEN 'medium'
ELSE 'bulk' 
END AS weight_category 
FROM zepto_table;

-- Catagory wise Contribution to Total Warehouse Inventory
SELECT category, SUM(weight_in_gms * available_quantity) AS total_weight 
FROM zepto_table 
GROUP BY category 
ORDER BY total_weight DESC;

-- Categories wise Stockout Level
SELECT category, COUNT(sku_id) AS low_stock_product_count 
FROM zepto_table
WHERE out_of_stock = FALSE 
AND available_quantity< 5 
GROUP BY category HAVING COUNT(sku_id)> 3 
ORDER BY low_stock_product_count DESC;

-- Total Discount per Category
SELECT category, 
SUM(mrp * available_quantity) AS total_mrp_value, 
SUM(discounted_selling_price * available_quantity) AS total_selling_value, 
SUM((mrp - discounted_selling_price) * available_quantity) AS total_discount_given 
FROM zepto_table
WHERE out_of_stock = FALSE 
GROUP BY category ORDER BY total_discount_given DESC;

-- Discount Tiering & Revenue Contribution
SELECT CASE WHEN discount_percent>= 40 THEN 'High Discount (40%+)' 
WHEN discount_percent>= 20 THEN 'Moderate Discount (20-39%)' 
ELSE 'Low/No Discount (<20%)' 
END AS discount_tier, 
COUNT(sku_id) AS total_skus, 
SUM(available_quantity) AS total_units, 
SUM(discounted_selling_price * available_quantity) AS total_potential_revenue 
FROM zepto_table WHERE out_of_stock = FALSE
GROUP BY 1 
ORDER BY total_potential_revenue DESC;

-- Heavy Items with Deep Discounts
SELECT name, weight_in_gms, mrp, discounted_selling_price, discount_percent 
FROM zepto_table WHERE weight_in_gms>= 1000 
AND discount_percent>= 30 
ORDER BY weight_in_gms DESC, discount_percent DESC;

-- Under Stock categories, with High Product Varities
SELECT category, COUNT(sku_id) AS total_skus, 
SUM(available_quantity) AS total_available_units, 
ROUND(AVG(available_quantity), 2) AS avg_units_per_product 
FROM zepto_table WHERE out_of_stock = FALSE 
GROUP BY category HAVING COUNT(sku_id)>= 10 
AND AVG(available_quantity)< 10 
ORDER BY avg_units_per_product ASC;