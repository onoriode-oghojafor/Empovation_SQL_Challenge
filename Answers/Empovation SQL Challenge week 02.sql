-- Average Price of Products in a Category
SELECT Category,ROUND(AVG(Unit_Price), 2) AS AVG_Price
FROM products
GROUP BY Category;

-- Customer Purchases by Gender
SELECT c.Gender, COUNT(DISTINCT s.Order_Number) AS No_of_orders
FROM sales AS s
JOIN customers AS c
USING (Customer_Key)
GROUP BY c.Gender;

-- List of Products Not Sold
SELECT p.Product_Key, p.Product_Name
FROM products AS p
LEFT JOIN sales As s
USING(Product_Key)
WHERE s.Product_Key IS NULL;

-- Currency Conversion for Orders
SELECT s.Order_Number, ROUND(SUM(s.Quantity * p.unit_Price * e.Exchange),2) AS Total_Order_Value
FROM sales AS s
LEFT JOIN exchange_rates AS e
ON s.Currency_Code = e.Currency_Code AND s.Order_Date = e.Date
LEFT JOIN products AS p
ON s.Product_Key = p.Product_Key
WHERE s.Currency_Code NOT LIKE 'USD'
GROUP BY s.Order_Number;