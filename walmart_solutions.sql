-- Create Schema --

DROP TABLE IF EXISTS walmart;

CREATE TABLE walmart (
invoice_id int,
branch	varchar(15),
city	varchar(35),
category	varchar(40),
unit_price	numeric,
quantity	int,
total	numeric,
date	date,
time	time,
payment_method	varchar(25),
rating	numeric,
profit_margin numeric
);

SELECT * FROM walmart;

-- Business Problems --

-- Problem 1 
-- Find all different payment methods and number of transactions, number of qty sold

SELECT payment_method, COUNT(invoice_id) AS transaction_count, SUM(quantity) AS quantity_sold
FROM walmart
GROUP BY payment_method;

-- Problem 2
-- Identify the highest-rated category in each branch, displaying the branch, category and AVG Rating

WITH rank_cte
AS
	(SELECT branch,
			category,
			ROUND(AVG(rating),2) AS avg_rating,
			RANK() OVER(PARTITION BY branch ORDER BY ROUND(AVG(rating),2) DESC) AS category_rank
	FROM walmart
	GROUP BY branch, category)
SELECT branch, category, avg_rating
FROM rank_cte
WHERE category_rank = 1;

-- Problem 3
-- Identify the busiest day of the week for each branch based on the number of transactions

WITH day_cte
AS
	(SELECT 
		branch,
		TO_CHAR(date, 'Day') AS day,
		COUNT(invoice_id) AS transaction_count,
		RANK() OVER (PARTITION BY branch ORDER BY COUNT(invoice_id) DESC) AS busy_rank
	FROM walmart
	GROUP BY branch, day
	ORDER BY branch, transaction_count DESC)
SELECT branch, day, transaction_count
FROM day_cte
WHERE busy_rank = 1;

-- Problem 4
-- Calculate the total quantity of items sold per payment method. List payment_method and total_quantity.

SELECT payment_method, SUM(quantity) AS total_quantity
FROM walmart
GROUP BY payment_method;

-- Problem 5
-- Determine the average, minimum, and maximum rating of category for each city. 
-- List the city, average_rating, min_rating, and max_rating.

SELECT city, category, ROUND(AVG(rating), 2) AS avg_rating, MIN(rating) AS min_rating, MAX(rating) AS max_rating
FROM walmart
GROUP BY city, category
ORDER BY city, avg_rating DESC;

-- Problem 6
-- Calculate the total profit for each category by considering total_profit as
-- (unit_price * quantity * profit_margin). 

SELECT category, ROUND(SUM(profit), 2) AS total_profit
FROM	
	(SELECT category, total*profit_margin AS profit
	FROM walmart)
GROUP BY category
ORDER BY total_profit DESC;

-- Problem 7
-- Determine the most common payment method for each Branch. 

WITH payment_cte
AS
	(SELECT 
		branch,
		payment_method,
		COUNT(invoice_id) AS transaction_count,
		RANK() OVER(PARTITION BY branch ORDER BY COUNT(invoice_id) DESC) AS payment_rank
	FROM walmart
	GROUP BY branch, payment_method)
SELECT branch, payment_method, transaction_count
FROM payment_cte
WHERE payment_rank = 1;

-- Problem 8
--  Categorize sales into 3 shifts MORNING, AFTERNOON, EVENING and find out each of the shift and number of invoices

WITH shift_cte
AS
	(SELECT 
		invoice_id,
		total,
		time,
		CASE 
			WHEN time BETWEEN '00:00:00' AND '11:59:59' THEN 'Morning'
			WHEN time BETWEEN '12:00:00' AND '17:59:59' THEN 'Afternoon'
			ELSE 'Evening'
		END AS shift 
	FROM walmart)
SELECT shift, SUM(total) AS total_sales, COUNT(invoice_id) AS transaction_count
FROM shift_cte
GROUP BY shift;

-- Problem 9
-- Identify the 5 branches with the highest % decrease in 
-- revenue compared to last year (current year 2023 and last year 2022)

WITH cte_2023
AS
	(SELECT branch, SUM(total) AS sales_2023
	FROM walmart
	WHERE date BETWEEN '2023-01-01' AND '2023-12-31'
	GROUP BY branch),
cte_2022
AS
	(SELECT branch, SUM(total) AS sales_2022
	FROM walmart
	WHERE date BETWEEN '2022-01-01' AND '2022-12-31'
	GROUP BY branch)
SELECT 
	cte_2023.branch,
	sales_2022,
	sales_2023,
	ROUND((sales_2023-sales_2022)/sales_2022*100, 2) AS percent_change
FROM cte_2023
LEFT JOIN cte_2022
ON cte_2023.branch = cte_2022.branch
ORDER BY percent_change
LIMIT 5;

-- Problem 10 (Bonus Question)
-- Calculate and display the monthly sales, previous month's sales and cumulative sales for each month.

WITH sales_cte AS
	(SELECT
		EXTRACT(YEAR FROM date) as year,
		EXTRACT(MONTH FROM date) as month,
		ROUND(SUM(total)) AS total_sales
	FROM walmart
	GROUP BY year, month
	ORDER BY year, month),
cumulative_cte AS
	(SELECT 
		ROW_NUMBER() OVER(ORDER BY year, month, total_sales) AS row_num,
		year,
		month,
		total_sales,
		ROUND(SUM(total_sales) OVER(PARTITION BY year ORDER BY year, month, total_sales)) AS cumulative_sales,
		ROUND(LAG(total_sales) OVER(ORDER BY year, month, total_sales)) AS prev_sales
	FROM sales_cte)
SELECT *
FROM cumulative_cte;










