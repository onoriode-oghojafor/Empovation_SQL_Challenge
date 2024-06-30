-- Total Number of Orders Per Customer
SELECT s.Customer_Key,c.Name,COUNT(DISTINCT s.Order_Number) AS No_of_order
FROM sales AS s
JOIN customers AS c
USING (Customer_Key)
GROUP BY s.Customer_Key, c.Name
ORDER BY No_of_order DESC;

-- List of products sold in 2020
SELECT DISTINCT p.Product_name
FROM sales As s
JOIN products AS p
USING (Product_Key)
WHERE Order_Date BETWEEN '2020-01-01' AND '2020-12-31';

-- Details of customer from the city California
SELECT *
FROM customers
WHERE City = 'California' AND State_Code = 'CA';

-- Total Quantity Sold for Product with Poduct_Key 2115
SELECT Product_Key, SUM(Quantity) AS Quantity_sold
FROM sales
WHERE Product_Key = 2115
GROUP BY Product_Key;

-- Top 5 Stores with most sales transactions.
SELECT Store_Key, COUNT(*) AS Quantity_sold
FROM sales
GROUP BY Store_Key
ORDER BY Quantity_sold DESC
LIMIT 5;