use AdventureWorks2025;

--What is the total revenue by year, quarter, and month?

SELECT year([ModifiedDate]) Year
      ,DATEPART(QUARTER, [ModifiedDate]) QUARTER
      ,MONTH([ModifiedDate]) Month
      ,CAST(sum([LineTotal])AS decimal(10,2)) TotalRevenue
  FROM [AdventureWorks2025].[Sales].[SalesOrderDetail]
  group by year([ModifiedDate])
            ,DATEPART(QUARTER, [ModifiedDate])
            ,MONTH([ModifiedDate])
  order by 1,2,3;

--Which products generate the highest revenue?

SELECT top 1 S.[ProductID] ID
            ,A.Name name
            ,round(SUM(s.[LineTotal]),2) revenue
  FROM [AdventureWorks2025].[Production].[Product] A
  JOIN [AdventureWorks2025].[Sales].[SalesOrderDetail] S
  ON A.[ProductID]=S.[ProductID]
  group by A.Name,S.[ProductID]
  order by revenue desc; 
               --Ans=> [782	Mountain-200 Black, 38] is the product with the highest revenue	(4400592.80).

--Who are the top 10 customers by lifetime sales value?

SELECT top 10 C.CustomerID AS ID,
		      SUM(SOD.LineTotal) LSV	 
  FROM  Sales.SalesOrderHeader SOH
  INNER JOIN Sales.Customer C
  ON SOH.CustomerID=C.CustomerID
  INNER JOIN Sales.SalesOrderDetail SOD
  ON SOD.SalesOrderID=SOH.SalesOrderID
  GROUP BY C.CustomerID
  ORDER BY LSV DESC;
                 --Ans=> top 10 customers; 29818,29715,29722,30117,29614,29639,29701,29617,29994,29646

--What is the average order value (AOV) by year?

SELECT cast( sum([LineTotal])/COUNT(SalesOrderID) as decimal(6,2)) AOV
      ,year([ModifiedDate]) Year
  FROM [AdventureWorks2025].[Sales].[SalesOrderDetail]
  group by year([ModifiedDate])
  order by 2; 

--How does online sales compare to reseller sales over time?

SELECT year([ModifiedDate]) Year,
		MONTH([ModifiedDate]) MONTH,
		ROUND(SUM(SubTotal),1) as sales,
		ROUND(SUM(case when OnlineOrderFlag=1 then SubTotal else 0 end),1) as onlinesales,
		ROUND((SUM(case when OnlineOrderFlag=1 then SubTotal else 0 end)/SUM(SubTotal))*100,2) as '%onlinesales'
  FROM [AdventureWorks2025].[Sales].[SalesOrderHeader] 
  GROUP BY year([ModifiedDate]), MONTH([ModifiedDate])
  ORDER BY 1,2;

--Which sales territories contribute the most revenue?

SELECT NAME Territory,
      SUM([SalesYTD]) Revenue
  FROM [AdventureWorks2025].[Sales].[SalesTerritory]
GROUP BY NAME
ORDER BY 2 DESC;

--What percentage of total revenue comes from the top 20% of customers?

 WITH CLSV AS
        (SELECT C.CustomerID AS ID,
		        SUM(SOD.LineTotal) LSV	 
        FROM  Sales.SalesOrderHeader SOH
        INNER JOIN Sales.Customer C
        ON SOH.CustomerID=C.CustomerID
        INNER JOIN Sales.SalesOrderDetail SOD
        ON SOD.SalesOrderID=SOH.SalesOrderID
        GROUP BY C.CustomerID),
      RANKED AS 
        (SELECT *,
                NTILE(5) OVER(ORDER BY LSV DESC) RNK
        FROM CLSV)
        SELECT CONCAT( CAST((SUM(CASE WHEN RNK=1 THEN LSV ELSE 0 END)/
                SUM(LSV))*100 AS decimal(10,2)),'%') 'TOP20%Revenue'
        FROM RANKED;
        
 

--Which products have declining sales over the last 3 years?
 WITH PSV AS
  (SELECT S.[ProductID] ID
            ,A.Name name
            ,year(S.[ModifiedDate]) Year
            ,round(SUM(s.[LineTotal]),2) CurrentYear
  FROM [AdventureWorks2025].[Production].[Product] A
  JOIN [AdventureWorks2025].[Sales].[SalesOrderDetail] S
  ON A.[ProductID]=S.[ProductID]
  group by A.Name, S.[ProductID],year(S.[ModifiedDate])),
  TrendCheck as 
  (SELECT *,
           LAG(CurrentYear,1) OVER(PARTITION BY ID ORDER BY YEAR) LastYear,
           LAG(CurrentYear,2) OVER(PARTITION BY ID ORDER BY YEAR) TwoYearsAgo
    FROM PSV)
    SELECT ID
            ,Name
            ,CurrentYear
            ,LastYear
            ,TwoYearsAgo
     FROM TrendCheck
    WHERE CurrentYear < LastYear and LastYear < TwoYearsAgo; 


