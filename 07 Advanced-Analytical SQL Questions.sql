use AdventureWorks2025;

-- 7. Advanced / Analytical SQL Questions

--Rank products by revenue within each category.

WITH ProductRevenue AS 
                    (SELECT P.Name AS ProductName
                            ,PC.Name AS CategoryName
                            ,SUM(S.LineTotal) AS Revenue
                    FROM Sales.SalesOrderDetail S
                    JOIN Production.Product P
                    ON P.ProductID = S.ProductID
                    JOIN Production.ProductSubcategory PS
                    ON P.ProductSubcategoryID = PS.ProductSubcategoryID
                    JOIN Production.ProductCategory PC
                    ON PS.ProductCategoryID = PC.ProductCategoryID
                    GROUP BY P.Name,PC.Name)
SELECT ProductName
     ,CategoryName
     ,Revenue
     ,RANK() OVER(PARTITION BY CategoryName ORDER BY Revenue DESC) RNK
FROM ProductRevenue;


--Calculate month-over-month and year-over-year growth.

   --year-over-year growth
WITH TerritoryGrowth AS
            (SELECT YEAR(OrderDate) AS SalesYear
                    ,SUM(TotalDue) AS TotalSales
            FROM Sales.SalesOrderHeader 
            GROUP BY YEAR(OrderDate))
(SELECT  SalesYear-1 AS PrevSalesYear
         ,SalesYear
         ,COALESCE(LAG(TotalSales) OVER(ORDER BY SalesYear),0) AS PrevYearSales
         ,TotalSales
         ,COALESCE(
                    CAST((TotalSales - LAG(TotalSales) OVER(ORDER BY SalesYear))*100
                   /LAG(TotalSales) OVER(ORDER BY SalesYear) AS decimal(10,2)),0) AS GrowthRate
 FROM TerritoryGrowth
 );

     --month-over-month Growth
 WITH TerritoryGrowth AS
            (SELECT YEAR(OrderDate) AS SalesYear
                    ,MONTH(OrderDate) AS SalesMonth
                    ,SUM(TotalDue) AS TotalSales
            FROM Sales.SalesOrderHeader 
            GROUP BY YEAR(OrderDate),MONTH(OrderDate))
(SELECT  SalesYear-1 AS PrevSalesYear
         ,SalesMonth-1 AS PrevSalesMonth
         ,SalesYear
         ,SalesMonth
         ,COALESCE(LAG(TotalSales) OVER(ORDER BY SalesYear,SalesMonth),0) AS PrevYearSales
         ,TotalSales
         ,COALESCE(
                    CAST((TotalSales - LAG(TotalSales) OVER(ORDER BY SalesYear,SalesMonth))*100
                   /LAG(TotalSales) OVER(ORDER BY SalesYear,SalesMonth) AS decimal(10,2)),0) AS GrowthRate
 FROM TerritoryGrowth
 );


--Identify seasonality patterns in sales.

SELECT MONTH(OrderDate) AS SalesMonth
       ,DATENAME(MONTH,OrderDate) AS MonthName
       ,CAST(AVG((TotalDue))AS decimal(20,2)) AS TotalSales
FROM Sales.SalesOrderHeader 
GROUP BY MONTH(OrderDate),DATENAME(MONTH,OrderDate)
ORDER BY SalesMonth;

--Perform RFM analysis (Recency, Frequency, Monetary) for customers.

WITH RFM AS
           (SELECT C.CustomerID AS CustomerID
                    ,MAX(DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),DAY(OrderDate))) AS lastOrder
                    ,DATEDIFF(DAY,MAX(OrderDate),GETDATE()) Recency
                    ,COUNT(SalesOrderID) AS Frequency
                    ,SUM(TotalDue) AS Monetary
            FROM Sales.Customer C
            JOIN Sales.SalesOrderHeader S
            ON C.CustomerID = S.CustomerID
            GROUP BY C.CustomerID),
RFM_score AS
            (SELECT CustomerID
                    ,Recency
                    ,Frequency
                    ,Monetary
                    ,NTILE(5) OVER(ORDER BY Recency DESC) AS R_score
                    ,NTILE(5) OVER(ORDER BY Frequency ASC) AS F_score
                    ,NTILE(5) OVER(ORDER BY Monetary ASC) AS M_score
            FROM RFM)
SELECT CustomerID
       ,Recency
       ,Frequency
       ,Monetary
       ,CONCAT(R_score, F_score, M_score) RFM
FROM RFM_score
ORDER BY RFM DESC;
  

--Identify customers at risk of churn.

WITH RFM AS
           (SELECT C.CustomerID AS CustomerID
                    ,MAX(DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),DAY(OrderDate))) AS lastOrder
                    ,DATEDIFF(DAY,MAX(OrderDate),GETDATE()) Recency
                    ,COUNT(SalesOrderID) AS Frequency
                    ,SUM(TotalDue) AS Monetary
            FROM Sales.Customer C
            JOIN Sales.SalesOrderHeader S
            ON C.CustomerID = S.CustomerID
            GROUP BY C.CustomerID),
RFM_score AS
            (SELECT CustomerID
                    ,Recency
                    ,Frequency
                    ,Monetary
                    ,NTILE(5) OVER(ORDER BY Recency DESC) AS R_score
                    ,NTILE(5) OVER(ORDER BY Frequency ASC) AS F_score
                    ,NTILE(5) OVER(ORDER BY Monetary ASC) AS M_score
            FROM RFM)
SELECT CustomerID
       ,Recency
       ,Frequency
       ,Monetary
       ,CONCAT(R_score, F_score, M_score) RFM
FROM RFM_score
WHERE R_score=2 
ORDER BY RFM DESC;

--Calculate Pareto analysis (80/20 rule) on products and customers.


--Pareto analysis on products.
WITH CLSV AS
        (SELECT P.ProductID AS ProductID
		        ,P.Name AS ProductName 
                ,SUM(SOD.LineTotal) Revenue	 
        FROM  Sales.SalesOrderDetail SOD
        INNER JOIN Production.Product P
        ON SOD.ProductID = P.ProductID
        GROUP BY P.ProductID,P.Name),
      RANKED AS 
        (SELECT *
                ,SUM(Revenue) OVER() AS TotalRevenue
                ,SUM(Revenue)OVER(
                                  ORDER BY Revenue DESC 
                                  ROWS BETWEEN UNBOUNDED 
                                  PRECEDING AND CURRENT ROW) AS CummulativeRevenue
        FROM CLSV)
        SELECT ProductID
               ,ProductName
               ,CAST(Revenue AS decimal(20,2)) AS Revenue
               ,CAST(CummulativeRevenue * 100/TotalRevenue AS decimal(20,2)) AS CummulativeRevenuePercent
        FROM RANKED
        WHERE CummulativeRevenue/TotalRevenue <= 0.8
        ORDER BY 3 DESC;


--Pareto analysis on customers.
WITH CLSV AS
        (SELECT C.CustomerID AS CustomerID,
		        SUM(SOH.SubTotal) Revenue	 
        FROM  Sales.SalesOrderHeader SOH
        INNER JOIN Sales.Customer C
        ON SOH.CustomerID=C.CustomerID
        GROUP BY C.CustomerID),
      RANKED AS 
        (SELECT *
                ,SUM(Revenue) OVER() AS TotalRevenue
                ,SUM(Revenue)OVER(
                                  ORDER BY Revenue DESC ROWS 
                                  BETWEEN UNBOUNDED PRECEDING 
                                  AND CURRENT ROW) AS CummulativeRevenue
        FROM CLSV)
        SELECT CustomerID
               ,CAST(Revenue AS decimal(20,2)) AS Revenue
               ,CAST(CummulativeRevenue * 100/TotalRevenue AS decimal(20,2)) AS CummulativeRevenuePercent
        FROM RANKED
        WHERE CummulativeRevenue/TotalRevenue <= 0.8
        ORDER BY 2 DESC;

--Create a rolling 3-month average sales metric.

WITH MonthlySales AS
(SELECT DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) AS SalesMonth
       ,CAST(SUM((TotalDue)) AS decimal(20,2)) AS TotalSales
FROM Sales.SalesOrderHeader 
GROUP BY YEAR(OrderDate),MONTH(OrderDate))
SELECT SalesMonth
       ,TotalSales
       ,CAST(AVG(TotalSales) OVER(
                                  ORDER BY SalesMonth 
                                  ROWS BETWEEN 2 PRECEDING 
                                  AND CURRENT ROW) AS decimal(20,2)) AS Rolling3MonthAvgSales
FROM MonthlySales; 

-- Detect sales anomalies or sudden drops.

WITH MonthlySales AS
(SELECT DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) AS SalesMonth
       ,CAST(SUM((TotalDue)) AS decimal(20,2)) AS TotalSales
FROM Sales.SalesOrderHeader 
GROUP BY YEAR(OrderDate),MONTH(OrderDate)),
Rolling3Month AS
(SELECT SalesMonth
       ,TotalSales
       ,CAST(AVG(TotalSales) OVER(
                                  ORDER BY SalesMonth 
                                  ROWS BETWEEN 2 PRECEDING 
                                  AND CURRENT ROW) AS decimal(20,2)) AS Rolling3MonthAvgSales
FROM MonthlySales)
SELECT *
       ,CAST((TotalSales - Rolling3MonthAvgSales) * 100/Rolling3MonthAvgSales AS decimal(20,2)) AS DeviationRate
       ,CASE WHEN TotalSales < (Rolling3MonthAvgSales*0.8) THEN 'Sudden Drop'
             WHEN TotalSales > (Rolling3MonthAvgSales*1.2) THEN 'Spike' 
             ELSE 'Normal' END AS SalesStatus
FROM Rolling3Month;
