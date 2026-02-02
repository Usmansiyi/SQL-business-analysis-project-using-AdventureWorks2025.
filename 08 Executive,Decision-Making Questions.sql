use AdventureWorks2025;

 -- 8. Executive / Decision-Making Questions

--Which 5 products should we prioritize next quarter?

WITH Sales AS
 (SELECT P.ProductID AS ProductID
		        ,P.Name AS ProductName 
                ,SUM(SOD.LineTotal) Revenue	
                ,COUNT(DISTINCT SOD.SalesOrderID) Orders
        FROM  Sales.SalesOrderDetail SOD
        INNER JOIN Production.Product P
        ON SOD.ProductID = P.ProductID
        GROUP BY P.ProductID,P.Name)
SELECT TOP 5 *
FROM Sales
ORDER BY Revenue DESC;
        

--Which customers deserve loyalty incentives?

WITH Sales AS
(SELECT C.CustomerID AS CustomerID
		,SUM(SOH.SubTotal) Revenue
        ,COUNT(DISTINCT SOH.SalesOrderID) Orders
        FROM  Sales.SalesOrderHeader SOH
        INNER JOIN Sales.Customer C
        ON SOH.CustomerID=C.CustomerID
        GROUP BY C.CustomerID)
SELECT TOP 5 *
FROM Sales
WHERE Orders >= 5
ORDER BY Revenue DESC;

--Where are we losing money despite high sales volume?


SELECT SH.TerritoryID
       ,CAST(COUNT(S.SalesOrderID) AS decimal(10,2)) AS SalesVolume
       ,CAST(((SUM(S.LineTotal) - SUM(P.StandardCost * S.OrderQty))) AS decimal(10,2)) AS Profit
FROM Sales.SalesOrderDetail S
JOIN Sales.SalesOrderHeader SH
ON S.SalesOrderID=SH.SalesOrderID 
JOIN Production.Product P
ON P.ProductID = S.ProductID
GROUP BY SH.TerritoryID
HAVING COUNT(S.SalesOrderID) > 5000
AND (SUM(S.LineTotal) - SUM(P.StandardCost * S.OrderQty)) < 0
ORDER BY Profit DESC;

--What are the key drivers of revenue growth?

SELECT YEAR(OrderDate) AS SalesYear
       ,COUNT(DISTINCT SalesOrderID) AS TotalOrders
       ,CAST(SUM((TotalDue)) AS decimal(20,2)) AS Revenue
       ,AVG(TotalDue) AS AOV
FROM Sales.SalesOrderHeader 
GROUP BY YEAR(OrderDate)
ORDER BY SalesYear;

--What products and regions pose the highest business risk?

SELECT P.ProductID
                        ,P.Name
                        ,SUM(S.OrderQty) AS Orders
                        ,SUM(I.Quantity) AS iVolume
                FROM Sales.SalesOrderDetail S
                JOIN Production.Product P
                ON P.ProductID = S.ProductID
                JOIN Production.ProductInventory I
                ON P.ProductID = I.ProductID
                GROUP BY P.ProductID,P.Name
                HAVING SUM(S.OrderQty) < 50
AND SUM(I.Quantity) > 1000

--What actions would you recommend to increase profitability by 10%? 

SELECT P.Name
       ,CAST(((SUM(S.LineTotal) - SUM(P.StandardCost * S.OrderQty))) AS decimal(10,2)) AS Profit
FROM Sales.SalesOrderDetail S
JOIN Production.Product P
ON P.ProductID = S.ProductID
GROUP BY P.Name
HAVING (SUM(S.LineTotal) - SUM(P.StandardCost * S.OrderQty)) < 0
ORDER BY Profit ;


SELECT P.Name
       ,CAST((SUM(S.LineTotal) - SUM(P.StandardCost * S.OrderQty))*100/SUM(P.StandardCost * S.OrderQty) AS decimal(10,2)) AS ProfitMarginPerc
       ,COUNT(S.SalesOrderID) AS Orders
FROM Sales.SalesOrderDetail S
JOIN Production.Product P
ON P.ProductID = S.ProductID
GROUP BY P.Name
HAVING (SUM(S.LineTotal) - SUM(P.StandardCost * S.OrderQty))/SUM(P.StandardCost * S.OrderQty) < 0.3
AND COUNT(S.SalesOrderID) >100
ORDER BY ProfitMarginPerc;

WITH CLSV AS
        (SELECT C.CustomerID AS CustomerID,
		        SUM(SOH.SubTotal) Revenue	 
        FROM  Sales.SalesOrderHeader SOH
        INNER JOIN Sales.Customer C
        ON SOH.CustomerID=C.CustomerID
        GROUP BY C.CustomerID)
     SELECT * FROM
        (SELECT *
                ,NTILE(5) OVER(ORDER BY Revenue DESC) AS RevenueGroup
        FROM CLSV) AS CLSV
    WHERE RevenueGroup = 1