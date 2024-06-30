-- Impact of store size on sales volume
Select st.Store_Key, st.State, st.Square_Meters, SUM(s.Quantity) AS Sales
FROM stores AS st
JOIN sales AS s
USING (Store_Key)
GROUP BY st.Store_Key, st.state, st.Square_Meters
ORDER BY Sales DESC;

-- Customer Segmentation by purchase Behavior and demographics
WITH Demographics AS (SELECT s.Customer_Key, c.Country, c.Gender, ROUND(SUM(s.Quantity * p.unit_Price * e.Exchange),2) AS Total_spend
					  FROM sales AS s
					  JOIN exchange_rates AS e
					  ON s.Currency_Code = e.Currency_Code AND s.Order_Date = e.Date
                      LEFT JOIN products AS p
                      ON s.Product_Key = p.Product_Key
                      LEFT JOIN customers AS c
                      ON s.Customer_Key = c.Customer_Key
                      GROUP BY s.Customer_Key, c.Country, c.Gender),
Customer_behavior AS ( SELECT Customer_Key, CASE WHEN Total_spend <= 500 THEN "Very low spenders"
			           WHEN Total_spend <= 1000  THEN "Low spenders"
                       WHEN Total_spend <= 2000 THEN "Medium spenders"
                       WHEN Total_spend <= 4000 THEN "High spenders"
                       ELSE "Very high spenders" END AS Purchase_behavior
					   FROM Demographics)
SELECT Country, Gender, Purchase_behavior, Total_spend, COUNT(Customer_Key) AS Customers
FROM Demographics
JOIN Customer_behavior 
USING (Customer_Key)
GROUP BY Country, Gender, Purchase_behavior, Total_spend
ORDER BY Country ASC;

-- Ranking stores by sales volume
SELECT Store_Key,
       SUM(Quantity) AS Total_Sales_Volume,
       RANK() OVER (ORDER BY SUM(Quantity) DESC) AS Sales_Rank
FROM Sales
GROUP BY Store_Key
ORDER BY Sales_Rank;

-- Running Total of Sales Over Time
SELECT Order_date, SUM(Quantity) AS Daily_total, 
	   SUM(SUM(Quantity)) OVER(ORDER BY Order_Date) AS Running_total
FROM sales
GROUP BY Order_Date;

-- Lifetime value(LTV) of customers by country
WITH Customer_ltv AS (SELECT s.Customer_Key, ROUND(SUM(s.Quantity * p.Unit_Price), 2) AS Life_time_value
					  FROM sales AS s
					  JOIN products AS p
					  USING (Product_Key)
					  GROUP BY s.Customer_Key)
SELECT c.Country, ROUND(AVG(cl.Life_time_Value), 2) AS AverageLTV, 
       RANK() OVER (ORDER BY AVG(cl.Life_time_Value) DESC) AS Country_rank
FROM customers AS c
JOIN Customer_ltv AS cl
USING (Customer_Key)
GROUP BY c.Country;

-- Customer's lifetime value
SELECT s.Customer_Key, ROUND(SUM(s.Quantity * p.Unit_Price), 2) AS Life_time_value
FROM sales AS s
JOIN products AS p
USING (Product_Key)
GROUP BY s.Customer_Key
ORDER BY Life_time_value DESC;