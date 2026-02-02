use AdventureWorks2025;

--2. Customer Analytics

--How many new customers were acquired each year?

WITH FirstDate as
(SELECT CustomerID
       ,MIN(YEAR(OrderDate)) AS YEAR   
  FROM Sales.SalesOrderHeader
GROUP BY CustomerID)
SELECT YEAR
       ,COUNT(CustomerID) AS NewCustomers
FROM FirstDate
GROUP BY YEAR
ORDER BY YEAR;

--What is the customer retention rate year-over-year?

  WITH CustYear as
    (SELECT distinct CustomerID
       ,YEAR([OrderDate]) AS YEAR  
    FROM Sales.SalesOrderHeader),
  Retention AS  
    (SELECT CY1.YEAR PrevYears
           ,COUNT(CY1.CustomerID) AS LastYearCustomers
           ,COUNT(CY2.CustomerID) AS RetainedCustomers
    FROM CustYear CY1 
    LEFT JOIN CustYear CY2
    ON CY1.CustomerID=CY2.CustomerID
    AND CY1.YEAR + 1=CY2.YEAR
    GROUP BY CY1.YEAR)
   SELECT PrevYears
           ,LastYearCustomers 
           ,RetainedCustomers
           ,CAST( RetainedCustomers*100.0/LastYearCustomers AS DECIMAL(5,2)) AS RetentionRate
    FROM Retention
    WHERE LastYearCustomers > 0
    ORDER BY 1;

--Which customers have not purchased in the last 12 months?

SELECT SC.CustomerID,MAX(SOH.OrderDate) AS DATE   
  FROM Sales.Customer SC
  LEFT JOIN Sales.SalesOrderHeader  SOH
  ON SOH.CustomerID=SC.CustomerID
GROUP BY SC.CustomerID
HAVING MAX(SOH.OrderDate) < DATEADD(MONTH,-12,GETDATE())
OR MAX(SOH.OrderDate) IS NULL
ORDER BY SC.CustomerID;

--What is the average purchase frequency per customer?

SELECT
      CAST( COUNT(*) * 1.0/COUNT(DISTINCT CustomerID) AS decimal(10,2)) AS Avg_Purc   
  FROM Sales.SalesOrderHeader;


--Which customer segments (individual vs store) generate more revenue?

SELECT CASE
       WHEN SC.StoreID IS NOT NULL THEN 'Store'
       WHEN SC.PersonID IS NOT NULL THEN 'Individual'
       ELSE 'Unknown' END AS Segments
       ,SUM(SOH.TotalDue) AS Revenue
  FROM Sales.SalesOrderHeader SOH
  JOIN Sales.Customer SC
  ON SOH.CustomerID=SC.CustomerID
  GROUP BY CASE
       WHEN SC.StoreID IS NOT NULL THEN 'Store'
       WHEN SC.PersonID IS NOT NULL THEN 'Individual'
       ELSE 'Unknown' END; 
 

--What is the customer lifetime value (CLV) by segment?
 
WITH Seg_Table  AS
  (SELECT SOH.CustomerID
     ,CASE
       WHEN SC.StoreID IS NOT NULL THEN 'Store'
       WHEN SC.PersonID IS NOT NULL THEN 'Individual'
       ELSE 'Unknown' END AS Segments
       ,SUM(SOH.TotalDue) AS  revenue
       ,COUNT(SOH.SalesOrderID) AS orders
       ,MIN(SOH.OrderDate) AS FirstDate
       ,MAX(SOH.OrderDate) AS SecondDate
  FROM Sales.SalesOrderHeader SOH
  JOIN Sales.Customer SC
  ON SOH.CustomerID=SC.CustomerID
  GROUP BY SOH.CustomerID,
            CASE
             WHEN SC.StoreID IS NOT NULL THEN 'Store'
             WHEN SC.PersonID IS NOT NULL THEN 'Individual'
             ELSE 'Unknown' END),
    CLV_calculation as (SELECT CustomerID
            ,Segments
            ,revenue/orders AS AOV
            ,CASE WHEN DATEDIFF(DAY,FirstDate,SecondDate)=0 THEN 1.0
                ELSE DATEDIFF(DAY,FirstDate,SecondDate)*1.0/360 END AS Cust_Lifetime
            ,orders/CASE WHEN DATEDIFF(DAY,FirstDate,SecondDate)=0 THEN 1.0
                     ELSE DATEDIFF(DAY,FirstDate,SecondDate)*1.0/360 END AS PurchaseFrequency
      from Seg_Table)
     SELECT Segments
            ,AVG(AOV * Cust_Lifetime * PurchaseFrequency) AOV_CLV_Segments 
      FROM CLV_calculation
      GROUP BY Segments;

--Who are the most valuable repeat customers?

SELECT TOP 10 CustomerID
            ,COUNT(SalesOrderID) AS Orders
            ,SUM(SubTotal) AS Revenue
FROM Sales.SalesOrderHeader 
GROUP BY CustomerID
HAVING COUNT(SalesOrderID)>1
ORDER BY Revenue DESC;

WITH A AS (SELECT  CustomerID
            ,DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) AS LoginMonth 
            ,LAG(DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1))
            OVER(PARTITION BY CustomerID ORDER BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)) AS PrevMonth
FROM Sales.SalesOrderHeader), 
Groups AS (SELECT CustomerID
                ,LoginMonth
                ,PrevMonth 
                ,SUM(CASE WHEN PrevMonth = DATEADD(MONTH,-1, LoginMonth) THEN 0 ELSE 1 END)
                OVER(PARTITION BY CustomerID ORDER BY LoginMonth) AS RNK FROM A),
consMonths AS (SELECT CustomerID
       ,RNK
       ,COUNT(*) AS ConsecutiveMonths
        FROM Groups GROUP BY CustomerID,RNK)
SELECT CustomerID
       ,MAX(ConsecutiveMonths) AS MaxConsecutiveMonths
       FROM consMonths GROUP BY CustomerID
       HAVING MAX(ConsecutiveMonths)  >= 5
       ORDER BY 2 DESC;
