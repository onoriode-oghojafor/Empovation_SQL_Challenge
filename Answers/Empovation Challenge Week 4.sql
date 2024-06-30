-- Year-over-Year Growth in Sales per Category
-- Define the two years to be considered based on the dataset
SET @CurrentYear = (SELECT MAX(YEAR(Order_Date)) FROM Sales);
SET @PreviousYear = @CurrentYear - 1;

WITH Annual_sales AS 
	(SELECT p.Category, YEAR(Order_Date) AS Sales_year, 
			ROUND(SUM(s.Quantity * p.unit_Price * e.Exchange),2) AS Total_sales
	 FROM sales AS s
	 LEFT JOIN exchange_rates AS e
	 ON s.Currency_Code = e.Currency_Code AND s.Order_Date = e.Date
	 LEFT JOIN products AS p
	 ON s.Product_Key = p.Product_Key
	 WHERE YEAR(s.Order_Date) IN (@CurrentYear, @PreviousYear)
	 GROUP BY p.Category, YEAR(s.Order_Date)),
Yearly_growth AS
	 (SELECT Category, Sales_year, Total_sales,
             LAG(Total_sales) OVER (PARTITION BY Category ORDER BY Sales_year) AS Previous_year_sales
    FROM Annual_sales)
SELECT Category, Sales_year, Total_sales, Previous_year_sales,
    ROUND((Total_sales - Previous_year_sales) / Previous_year_sales * 100, 2) AS Yearly_growth_percentage
FROM Yearly_growth
WHERE Previous_year_sales IS NOT NULL
ORDER BY Category, Sales_year;


-- Customer’s Purchase Rank Within Store
SELECT s.Customer_Key, s.Order_Number, s.Store_Key, st.State, ROUND(SUM(s.Quantity * p.unit_Price * e.Exchange),2) AS Total_Order,
		RANK() OVER(PARTITION BY s.Store_Key ORDER BY ROUND(SUM(s.Quantity * p.unit_Price * e.Exchange),2) DESC) 
        AS Rank_of_customers
FROM sales AS s
LEFT JOIN exchange_rates AS e
ON s.Currency_Code = e.Currency_Code AND s.Order_Date = e.Date
LEFT JOIN products AS p
ON s.Product_Key = p.Product_Key
LEFT JOIN stores AS st
ON s.Store_Key = st.Store_Key
GROUP BY s.Customer_Key, s.Store_Key, st.State, s.Order_Number;


-- Customer Retention Analysis
-- Step 1: Define the current date based on the dataset
SET @Current_date = (SELECT MAX(Order_Date) FROM sales);
SET @Current_year = YEAR(@Current_date);
-- CTE to identify the first purchase for each customer.
WITH first_purchase AS 
	(SELECT Customer_Key, MIN(Order_Date) AS First_purchase_date
    FROM sales
    GROUP BY Customer_Key),
-- CTE to check for repeat purchases within three months of the initial purchase.
repeat_purchase AS 
	(SELECT fp.Customer_Key, fp.First_purchase_date, COUNT(s.Order_Date) AS Repeat_order_date
     FROM first_purchase AS fp
     LEFT JOIN sales AS s
     ON fp.Customer_Key = s.Customer_Key
		AND s.Order_Date > fp.First_purchase_date
        AND s.Order_Date <= DATE_ADD(fp.First_purchase_date, INTERVAL 3 MONTH)
	 GROUP BY fp.Customer_Key, fp.First_purchase_date),
-- CTE to classify customers into retained and non-retained.   
 customer_retention AS
	(SELECT Customer_Key,
			CASE WHEN Repeat_order_date > 0 THEN 1 ELSE 0 END AS Retained
	 FROM repeat_purchase),
-- CTE to calculate age group based on the current date     
customer_agegroup AS 
(SELECT Customer_Key, Gender, City, Country,
	   CASE WHEN TIMESTAMPDIFF(YEAR, Birthday, @CurrentDate) < 20 THEN '<20'
            WHEN TIMESTAMPDIFF(YEAR, Birthday, @CurrentDate) BETWEEN 20 AND 29 THEN '20-29'
            WHEN TIMESTAMPDIFF(YEAR, Birthday, @CurrentDate) BETWEEN 30 AND 39 THEN '30-39'
            WHEN TIMESTAMPDIFF(YEAR, Birthday, @CurrentDate) BETWEEN 40 AND 49 THEN '40-49'
            ELSE '50+'
        END AS Age_group
FROM customers),
-- CTE to calculate the percentage of retained customers by gender, age group, and location
retention_percentage AS
	(SELECT cg.Age_group, cg.Gender, cg.City, cg.Country,
			 COUNT(cr.Customer_Key) AS Total_customers,
             SUM(cr.Retained) AS Retained_customers,
             (SUM(cr.Retained) / COUNT(cr.Customer_Key)) * 100 AS Retention_rate
    FROM customer_retention AS cr
    JOIN customer_agegroup AS cg
    USING (Customer_Key)
    GROUP BY cg.Age_group, cg.Gender, cg.City, cg.Country)
 -- Select the final result   
SELECT Age_group, Gender, City, Country,Total_customers, Retained_customers,
		ROUND(Retention_rate, 2) AS Retention_rate
FROM retention_percentage
ORDER BY Gender,Country;

-- Optimize the product mix for each store location to maximize sales revenue.
-- Step 1: Calculate total sales and profit for each product in each store
WITH product_sales AS 
	(SELECT s.Store_Key, s.Product_Key, p.Category, SUM(s.Quantity) AS Quantity_sold,
			SUM(s.Quantity * p.Unit_Price) AS Revenue, SUM(s.Quantity * p.Unit_Cost) AS COGS,
			SUM(s.Quantity * p.Unit_Price) - SUM(s.Quantity * p.Unit_Cost) AS Profit_margin
	 FROM sales s
     JOIN products p 
     ON s.Product_Key = p.Product_Key
     GROUP BY s.Store_Key, s.Product_Key, p.Category),
-- Step 2: Rank products within each category for each store based on sales performance and profit margins
products_ranking AS  
	(SELECT ps.Store_Key, ps.Category, ps.Product_Key, ps.Quantity_sold, ps.Revenue, ps.Profit_margin,
        RANK() OVER (PARTITION BY ps.Store_Key, ps.Category ORDER BY ps.Quantity_sold DESC,ps.Profit_margin DESC) AS Product_rank
     FROM product_sales AS ps),
-- Step 3: Calculate the optimal product assortment for each store based on sales performance, popularity and margins
optimal_product_assortment AS 
	  (SELECT pr.Store_Key, pr.Category,
        GROUP_CONCAT(pr.Product_Key ORDER BY pr.Product_rank SEPARATOR ',') AS Product_assortment,
        SUM(pr.Quantity_sold) AS TotalQuantities_sold,
        ROUND(SUM(pr.Profit_margin), 2) AS Total_profit
       FROM products_ranking pr
       GROUP BY pr.Store_Key, pr.Category)
-- Step 4: Select the final result
SELECT Store_Key, Category, Product_assortment, TotalQuantities_sold, Total_profit
FROM optimal_product_assortment
ORDER BY Store_Key, Category;

    


		

