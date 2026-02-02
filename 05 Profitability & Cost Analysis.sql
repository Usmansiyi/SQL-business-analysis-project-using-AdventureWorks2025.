use AdventureWorks2025;

--5. Profitability & Cost Analysis

--What is the gross profit by product, category, and year?

SELECT P.Name AS ProductName
       ,PC.Name AS ProductCategory
       ,YEAR(SH.OrderDate) Years
       ,CAST(SUM(S.LineTotal) AS decimal(10,2)) AS Revenue
       ,CAST(SUM(P.StandardCost * S.OrderQty) AS decimal(10,2)) AS COGS
       ,CAST(SUM(S.LineTotal) - SUM(P.StandardCost * S.OrderQty) AS decimal(10,2)) AS GrossProfit
FROM Sales.SalesOrderDetail S
JOIN Sales.SalesOrderHeader SH
ON S.SalesOrderID=SH.SalesOrderID
JOIN Production.Product P
ON P.ProductID = S.ProductID
JOIN Production.ProductSubcategory PS
ON P.ProductSubcategoryID = PS.ProductSubcategoryID
JOIN Production.ProductCategory PC
ON PS.ProductCategoryID = PC.ProductCategoryID
GROUP BY P.Name,PC.Name,YEAR(OrderDate)
ORDER BY Years,ProductCategory, GrossProfit DESC;

--Which products have negative or shrinking margins?

SELECT  P.Name ProductName
       ,CAST(SUM(S.LineTotal) AS decimal(10,2)) AS Revenue
       ,CAST(SUM(P.StandardCost * S.OrderQty) AS decimal(10,2)) AS COGS
       ,CAST(((SUM(S.LineTotal) - SUM(P.StandardCost * S.OrderQty))*100)
       /SUM(CASE WHEN S.LineTotal>0 THEN S.LineTotal ELSE NULL END) AS decimal(10,2)) AS GrossProfitMargin
FROM Sales.SalesOrderDetail S
JOIN Production.Product P
ON P.ProductID = S.ProductID
GROUP BY P.Name
HAVING CAST(((SUM(S.LineTotal) - SUM(P.StandardCost * S.OrderQty))*100)
       /SUM(CASE WHEN S.LineTotal>0 THEN S.LineTotal ELSE NULL END) AS decimal(10,2)) < 0
ORDER BY GrossProfitMargin;

WITH GrossProfit AS
(SELECT  P.Name ProductName
       ,YEAR(SH.OrderDate) Years
       ,CAST(SUM(S.LineTotal) AS decimal(10,2)) AS Revenue
       ,CAST(SUM(P.StandardCost * S.OrderQty) AS decimal(10,2)) AS COGS
       ,CAST(((SUM(S.LineTotal) - SUM(P.StandardCost * S.OrderQty))*100)
       /SUM(CASE WHEN S.LineTotal>0 THEN S.LineTotal ELSE NULL END) AS decimal(10,2)) AS GrossProfitMargin
FROM Sales.SalesOrderDetail S
JOIN Sales.SalesOrderHeader SH
ON S.SalesOrderID=SH.SalesOrderID
JOIN Production.Product P
ON P.ProductID = S.ProductID
GROUP BY P.Name,YEAR(OrderDate)),
    MarginTrend AS
(SELECT ProductName
       ,Years
       ,GrossProfitMargin AS ProfitMargin
       ,LAG(GrossProfitMargin) OVER(PARTITION BY ProductName ORDER BY Years) AS PrevProfitMargin
FROM GrossProfit)
SELECT ProductName
       ,Years
       ,PrevProfitMargin
       ,ProfitMargin AS CurrentProfitMargin
FROM MarginTrend
WHERE ProfitMargin<PrevProfitMargin
AND PrevProfitMargin IS NOT NULL
ORDER BY ProductName,Years;

--How do discounts affect profit margins?

SELECT  P.Name
        ,AVG(S.UnitPrice) AS AvgPrice
        ,AVG(P.StandardCost) AS AvgCost
        ,AVG(S.UnitPrice * 1-S.UnitPriceDiscount) AS AvgDiscountedPrice
        ,CAST(AVG(S.UnitPrice-P.StandardCost)*100/NULLIF(AVG(S.UnitPrice),0) AS decimal(10,2)) AS MarginRateWithoutDiscount
        ,CAST(AVG((S.UnitPrice * 1-S.UnitPriceDiscount)-P.StandardCost)*100
        /NULLIF(AVG((S.UnitPrice * 1-S.UnitPriceDiscount)),0) AS decimal(10,2)) AS MarginRateWithDiscount
FROM Sales.SalesOrderDetail S
JOIN Sales.SalesOrderHeader SH
ON S.SalesOrderID=SH.SalesOrderID
JOIN Production.Product P
ON P.ProductID = S.ProductID
GROUP BY P.Name;

--What is the profit per customer?

SELECT SH.CustomerID
       ,CAST(((SUM(S.LineTotal) - SUM(P.StandardCost * S.OrderQty))) AS decimal(10,2)) AS Profit
FROM Sales.SalesOrderDetail S
JOIN Sales.SalesOrderHeader SH
ON S.SalesOrderID=SH.SalesOrderID
JOIN Production.Product P
ON P.ProductID = S.ProductID
GROUP BY SH.CustomerID
ORDER BY Profit DESC;

--Which territories are high-revenue but low-profit?

SELECT SH.TerritoryID
       ,CAST(SUM(S.LineTotal) AS decimal(10,2)) AS Revenue
       ,CAST(SUM(P.StandardCost * S.OrderQty) AS decimal(10,2)) AS COGS
       ,CAST(((SUM(S.LineTotal) - SUM(P.StandardCost * S.OrderQty))) AS decimal(10,2)) AS Profit
FROM Sales.SalesOrderDetail S
JOIN Sales.SalesOrderHeader SH
ON S.SalesOrderID=SH.SalesOrderID 
JOIN Production.Product P
ON P.ProductID = S.ProductID
GROUP BY SH.TerritoryID
HAVING SUM(S.LineTotal) > 10000000
AND (SUM(S.LineTotal) - SUM(P.StandardCost * S.OrderQty)) < 5000000
ORDER BY Profit DESC;
