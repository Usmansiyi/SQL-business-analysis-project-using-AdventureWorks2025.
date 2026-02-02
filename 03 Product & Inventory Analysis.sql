use AdventureWorks2025;

--3. Product & Inventory Analysis

--Which products have the highest profit margin?

SELECT  Name
       ,ListPrice
       ,(ListPrice -StandardCost) * 100/ (CASE WHEN ListPrice > 0 THEN ListPrice ELSE NULL END) AS ProfitMargin
FROM  Production.Product
ORDER BY 3 DESC;

--What products are frequently purchased together?

SELECT P1.Name AS Product1
       ,P2.Name AS Product2
       ,COUNT(*) AS No_PurchasedTogether
FROM Sales.SalesOrderDetail S1
JOIN Sales.SalesOrderDetail S2
ON S1.SalesOrderID=S2.SalesOrderID
AND S1.ProductID > S2.ProductID
JOIN Production.Product P1
ON P1.ProductID = S1.ProductID
JOIN Production.Product P2
ON P2.ProductID = S2.ProductID
GROUP BY P1.Name,P2.Name
ORDER BY 3 DESC;

--Which products have low sales but high inventory levels?

WITH Sales AS 
                (SELECT P.ProductID
                        ,P.Name
                        ,SUM(S.OrderQty) AS Orders
                FROM Sales.SalesOrderDetail S
                JOIN Production.Product P
                ON P.ProductID = S.ProductID
                GROUP BY P.ProductID,P.Name),
Inventory AS
                (SELECT P.ProductID
                        ,P.Name
                        ,SUM(I.Quantity) AS iQty
                FROM Production.ProductInventory I
                JOIN Production.Product P
                ON P.ProductID = I.ProductID
                GROUP BY P.ProductID,P.Name)
SELECT S.ProductID
       ,S.Name
       ,S.Orders
       ,I.iQty
FROM Sales S JOIN Inventory I
ON S.ProductID = I.ProductID
WHERE S.Orders < 50
AND I.iQty > (SELECT SUM(Quantity)/COUNT(*) FROM Production.ProductInventory);

--What is the inventory turnover rate by product?

WITH Sales AS 
                (SELECT P.ProductID
                        ,P.Name
                        ,SUM(S.OrderQty) AS Orders
                FROM Sales.SalesOrderDetail S
                JOIN Production.Product P
                ON P.ProductID = S.ProductID
                GROUP BY P.ProductID,P.Name),
Inventory AS
                (SELECT P.ProductID
                        ,P.Name
                        ,SUM(I.Quantity) AS iQty
                FROM Production.ProductInventory I
                JOIN Production.Product P
                ON P.ProductID = I.ProductID
                GROUP BY P.ProductID,P.Name)
SELECT S.ProductID
       ,S.Name
       ,S.Orders
       ,I.iQty
       ,CAST(S.Orders*1.0 /(CASE WHEN I.iQty > 0 THEN I.iQty ELSE NULL END) AS decimal(5,2)) AS TurnOverRate
FROM Sales S LEFT JOIN Inventory I
ON S.ProductID = I.ProductID;

--Which products are out of stock or below reorder point?

SELECT P.ProductID
       ,P.Name
       ,SUM(I.Quantity) AS iQty
       ,P.ReorderPoint AS ReorderPoint
FROM Production.ProductInventory I
JOIN Production.Product P
ON P.ProductID = I.ProductID
GROUP BY P.ProductID,P.Name,P.ReorderPoint
HAVING SUM(I.Quantity)=0
OR SUM(I.Quantity) < P.ReorderPoint;


--What categories generate the highest profit, not just revenue?

SELECT PC.Name
       ,SUM(S.LineTotal) AS Revenue
       ,SUM(P.StandardCost * S.OrderQty) AS COGS
       ,(SUM(S.LineTotal) - SUM(P.StandardCost * S.OrderQty)) AS Profit
FROM Sales.SalesOrderDetail S
JOIN Production.Product P
ON P.ProductID = S.ProductID
JOIN Production.ProductSubcategory PS
ON P.ProductSubcategoryID = PS.ProductSubcategoryID
JOIN Production.ProductCategory PC
ON PS.ProductCategoryID = PC.ProductCategoryID
GROUP BY PC.Name
ORDER BY 4 DESC;


--Which products should be discontinued or promoted based on performance?

WITH ProductPerformance AS 
    (SELECT P.Name
       ,SUM(S.LineTotal) AS Revenue
       ,SUM(P.StandardCost * S.OrderQty) AS COGS
       ,(SUM(S.LineTotal) - SUM(P.StandardCost * S.OrderQty)) AS Profit
       ,SUM(S.OrderQty) UnitSold 
    FROM Sales.SalesOrderDetail S
    RIGHT JOIN Production.Product P
    ON P.ProductID = S.ProductID
    GROUP BY P.Name)
SELECT Name
       ,COALESCE(UnitSold,0) AS UnitSold
       ,COALESCE(Profit,0) AS Profit
       ,CASE WHEN UnitSold < 100 AND Profit < 1000 OR Revenue IS NULL THEN 'ConsiderDiscontinuing'
             WHEN UnitSold > 200 AND Profit > 2000 THEN 'Promote/InvestMore'
             ELSE 'Monitor' END AS Recommendation
FROM ProductPerformance
ORDER BY Recommendation DESC; 