use AdventureWorks2025;

--6. Geographic & Territory Insights

--What is the sales distribution by country, state, and city?

SELECT C.Name AS Country
       ,SP.Name AS 'State'
       ,A.City AS City
       ,CAST(SUM(S.SubTotal) AS decimal(10,2)) AS Revenue
FROM Sales.SalesOrderHeader S
JOIN Person.Address A
ON S.ShipToAddressID = A.AddressID
JOIN Person.StateProvince SP
ON A.StateProvinceID = SP.StateProvinceID
JOIN Person.CountryRegion C
ON C.CountryRegionCode = SP.CountryRegionCode
GROUP BY C.Name, SP.Name, A.City
ORDER BY Country,State,City,Revenue DESC;


--Which regions have the highest growth rate?

WITH RegionRevenueTrend AS
(SELECT T.Name AS Region
       ,YEAR(S.OrderDate) YEAR
       ,SUM(S.TotalDue) AS Revenue
FROM Sales.SalesOrderHeader S
JOIN Sales.SalesTerritory T
ON S.TerritoryID = T.TerritoryID
GROUP BY T.Name,YEAR(S.OrderDate)),
GrowthCalc AS
(SELECT Region
       ,YEAR
       ,Revenue
       ,LAG(Revenue) OVER(PARTITION BY Region ORDER BY YEAR) AS PrevRevenue
FROM RegionRevenueTrend)
SELECT Region
       ,YEAR
       ,PrevRevenue
       ,Revenue
       ,CAST(((Revenue-PrevRevenue)*100)/NULLIF(PrevRevenue,0)AS decimal(10,2)) AS Growth
FROM GrowthCalc
WHERE PrevRevenue IS NOT NULL
ORDER BY Growth DESC;

--Overall Growth (FirstYear TO LastYear)
WITH RegionRevenueTrend AS
(SELECT T.Name AS Region
       ,YEAR(S.OrderDate) YEAR
       ,SUM(S.TotalDue) AS Revenue
FROM Sales.SalesOrderHeader S
JOIN Sales.SalesTerritory T
ON S.TerritoryID = T.TerritoryID
GROUP BY T.Name,YEAR(S.OrderDate)),
Bounds AS
(SELECT Region
       ,MIN(YEAR) AS FirstYear
       ,MAX(YEAR) AS LastYear
 FROM RegionRevenueTrend
 GROUP BY Region)
 SELECT B.Region
        ,B.FirstYear
        ,B.LastYear
        ,First.Revenue AS FirstYearRevenue
        ,Last.Revenue AS CurrentYearRevenue
        ,CAST(((Last.Revenue-First.Revenue)*100)/First.Revenue AS decimal(10,2)) GrowthRate
 FROM Bounds B
 JOIN RegionRevenueTrend First
 ON B.Region= First.Region AND B.FirstYear=First.YEAR
 JOIN RegionRevenueTrend Last
 ON B.Region= Last.Region AND B.LastYear=Last.YEAR
 ORDER BY GrowthRate DESC;

--Which territories have the highest average order value?

SELECT T.Name AS Region
       ,ROUND(SUM(S.TotalDue)/COUNT(S.SalesOrderID),2) AS AOV
FROM Sales.SalesOrderHeader S
JOIN Sales.SalesTerritory T
ON S.TerritoryID = T.TerritoryID
GROUP BY T.Name
ORDER BY AOV DESC;

--Where should we expand sales operations based on demand?

WITH Demand AS
            (SELECT T.Name AS Region
                     ,SUM(SD.OrderQty) AS TotalOrders
                     ,CAST(SUM(S.TotalDue) AS decimal(20,2)) AS TotalSales
              FROM Sales.SalesOrderDetail SD
              JOIN Sales.SalesOrderHeader S
              ON SD.SalesOrderID = S.SalesOrderID
              JOIN Sales.SalesTerritory T
              ON S.TerritoryID = T.TerritoryID
              GROUP BY T.Name),
TerritoryGrowth AS
            (SELECT T.Name AS Region
                    ,YEAR(S.OrderDate) AS SalesYear
                    ,SUM(S.TotalDue) AS TotalSales
            FROM Sales.SalesOrderDetail SD
            JOIN Sales.SalesOrderHeader S
            ON SD.SalesOrderID = S.SalesOrderID
            JOIN Sales.SalesTerritory T
            ON S.TerritoryID = T.TerritoryID
            GROUP BY T.Name,YEAR(S.OrderDate)),
GrowthCalc AS
            (SELECT Region
                    ,SalesYear
                    ,LAG(TotalSales) OVER(PARTITION BY Region ORDER BY SalesYear) AS PrevYearSales
                    ,TotalSales
                    ,CAST((TotalSales - LAG(TotalSales) OVER(PARTITION BY Region ORDER BY SalesYear))*100
                   /LAG(TotalSales) OVER(PARTITION BY Region ORDER BY SalesYear) AS decimal(10,2)) AS GrowthRate
             FROM TerritoryGrowth)
SELECT D.Region
       ,D.TotalOrders
       ,D.TotalSales
       ,CAST(AVG(G.GrowthRate) AS decimal(10,2)) AS AvgGrowthRate
FROM Demand D
LEFT JOIN GrowthCalc G
ON D.Region = G.Region
GROUP BY D.Region, D.TotalOrders, D.TotalSales
ORDER BY AvgGrowthRate DESC,TotalSales DESC;
