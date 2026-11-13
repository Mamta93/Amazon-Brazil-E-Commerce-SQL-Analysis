CREATE TABLE customers(
    customer_id VARCHAR PRIMARY KEY,
    customer_unique_id VARCHAR,
    customer_zip_code_prefix INT
);
CREATE TABLE orders(
    order_id VARCHAR PRIMARY KEY,
    customer_id VARCHAR,
    order_status VARCHAR,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP
);
CREATE TABLE payments(
    order_id VARCHAR,
    payment_sequential INT,
    payment_type VARCHAR,
    payment_installments INT,
    payment_value NUMERIC
);
CREATE TABLE seller(
    seller_id VARCHAR PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR,
    seller_state VARCHAR
); 
CREATE TABLE product(
    product_id VARCHAR PRIMARY KEY,
    product_category_name VARCHAR,
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
); */
CREATE TABLE order_items(
    order_id VARCHAR,
    order_item_id INT,
    product_id VARCHAR,
    seller_id VARCHAR,
    shipping_limit_date TIMESTAMP,
    price NUMERIC,
    freight_value NUMERIC
);

/* =====================================================
                    ANALYSIS - I
===================================================== */


-- Analysis I problem 1
SELECT
    payment_type,
    ROUND(AVG(payment_value), 0) AS rounded_avg_payment
FROM payments
GROUP BY payment_type
ORDER BY rounded_avg_payment ASC;

-- Analysis I problem 2
SELECT
    payment_type,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM payments),
        1
    ) AS percentage_orders
FROM payments
GROUP BY payment_type
ORDER BY percentage_orders DESC;

-- Analysis I problem 3
SELECT
    oi.product_id,
    oi.price
FROM order_items oi
WHERE oi.price BETWEEN 100 AND 500
ORDER BY oi.price DESC;


-- Analysis I problem 4 
SELECT
    EXTRACT(MONTH FROM shipping_limit_date) AS month,
    ROUND(SUM(price), 0) AS total_sales
FROM order_items
GROUP BY month
ORDER BY total_sales DESC
LIMIT 3;


-- Analysis I problem 5
SELECT
    p.product_category_name,
    MAX(oi.price) - MIN(oi.price) AS price_difference
FROM product p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
HAVING MAX(oi.price) - MIN(oi.price) > 500
ORDER BY price_difference DESC;

-- Analysis I problem 6
SELECT
    payment_type,
    ROUND(STDDEV(payment_value), 2) AS std_deviation
FROM payments
GROUP BY payment_type
ORDER BY std_deviation ASC;

-- Analysis I problem 7
SELECT
    product_id,
    product_category_name
FROM product
WHERE product_category_name IS NULL
   OR LENGTH(TRIM(product_category_name)) = 1;

/* =====================================================
                    ANALYSIS - II
===================================================== */

-- Analysis II Problem 1

SELECT
    CASE
        WHEN payment_value < 200 THEN 'Low'
        WHEN payment_value BETWEEN 200 AND 1000 THEN 'Medium'
        ELSE 'High'
    END AS order_value_segment,
    payment_type,
    COUNT(*) AS count
FROM payments
GROUP BY order_value_segment, payment_type
ORDER BY count DESC;


-- Analysis II Problem 2

SELECT
    p.product_category_name,
    MIN(oi.price) AS min_price,
    MAX(oi.price) AS max_price,
    ROUND(AVG(oi.price), 2) AS avg_price
FROM product p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY avg_price DESC;

-- Analysis II - Problem 3

SELECT
    c.customer_unique_id,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(o.order_id) > 1
ORDER BY total_orders DESC;

-- Analysis II problem 4

SELECT
    c.customer_unique_id,
    CASE
        WHEN COUNT(o.order_id) = 1 THEN 'New'
        WHEN COUNT(o.order_id) BETWEEN 2 AND 4 THEN 'Returning'
        ELSE 'Loyal'
    END AS customer_type
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_unique_id
ORDER BY
    c.customer_unique_id;

-- Analysis II Problem 5

SELECT
    p.product_category_name,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM product p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 5;

/* =====================================================
                    ANALYSIS - III
===================================================== */

-- Analysis III Problem 1
SELECT
    season,
    ROUND(SUM(price), 2) AS total_sales
FROM
(
    SELECT
        oi.price,
        CASE
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (3,4,5)
                THEN 'Spring'
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (6,7,8)
                THEN 'Summer'
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (9,10,11)
                THEN 'Autumn'
            ELSE 'Winter'
        END AS season
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
) AS seasonal_sales
GROUP BY season
ORDER BY total_sales DESC;

-- Analysis III - Problem 2

SELECT
    product_id,
    COUNT(order_item_id) AS total_quantity_sold
FROM order_items
GROUP BY product_id
HAVING COUNT(order_item_id) >
(
    SELECT AVG(product_count)
    FROM
    (
        SELECT COUNT(order_item_id) AS product_count
        FROM order_items
        GROUP BY product_id
    ) AS avg_quantity
)
ORDER BY total_quantity_sold DESC;

-- Analysis III - Problem 3

SELECT
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
GROUP BY EXTRACT(MONTH FROM o.order_purchase_timestamp)
ORDER BY month;

-- Analysis III - Problem 4

WITH customer_orders AS
(
    SELECT
        c.customer_id,
        COUNT(o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
),

customer_types AS
(
    SELECT
        CASE
            WHEN total_orders BETWEEN 1 AND 2 THEN 'Occasional'
            WHEN total_orders BETWEEN 3 AND 5 THEN 'Regular'
            ELSE 'Loyal'
        END AS customer_type
    FROM customer_orders
)

SELECT
    customer_type,
    COUNT(*) AS count
FROM customer_types
GROUP BY customer_type
ORDER BY count DESC;

-- Analysis III - Problem 5

WITH customer_avg AS
(
    SELECT
        o.customer_id,
        ROUND(AVG(oi.price), 2) AS avg_order_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
)

SELECT
    customer_id,
    avg_order_value,
    RANK() OVER (ORDER BY avg_order_value DESC) AS customer_rank
FROM customer_avg
ORDER BY customer_rank
LIMIT 20;

-- Analysis III - Problem 6

WITH monthly_sales AS
(
    SELECT
        EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,
        ROUND(SUM(oi.price), 2) AS monthly_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY EXTRACT(MONTH FROM o.order_purchase_timestamp)
)

SELECT
    month,
    monthly_sales,
    SUM(monthly_sales) OVER (
        ORDER BY month
    ) AS cumulative_sales
FROM monthly_sales
ORDER BY month;

-- Analysis III - Problem 7

WITH monthly_sales AS (
    SELECT
        p.payment_type,
        EXTRACT(MONTH FROM o.order_purchase_timestamp) AS sale_month,
        SUM(p.payment_value) AS monthly_total
    FROM payments p
    JOIN orders o
        ON p.order_id = o.order_id
    WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
    GROUP BY
        p.payment_type,
        EXTRACT(MONTH FROM o.order_purchase_timestamp)
)

SELECT
    payment_type,
    sale_month,
    ROUND(monthly_total, 2) AS monthly_total,
    ROUND(
        (
            monthly_total -
            LAG(monthly_total) OVER (
                PARTITION BY payment_type
                ORDER BY sale_month
            )
        ) * 100.0
        /
        NULLIF(
            LAG(monthly_total) OVER (
                PARTITION BY payment_type
                ORDER BY sale_month
            ),
            0
        ),
        2
    ) AS monthly_change
FROM monthly_sales
ORDER BY payment_type, sale_month;