use AdventureWorks2025;

-- 4. Operations & Supply Chain

--What is the average order fulfillment time?

SELECT AVG(DATEDIFF(DAY,OrderDate,ShipDate)) AS AVG_FulfillmentTime
FROM Purchasing.PurchaseOrderHeader
WHERE ShipDate IS NOT NULL;

--Which vendors have the longest delivery times?

SELECT P.VendorID AS VendorID
       ,V.Name AS VendorName
       ,AVG(DATEDIFF(DAY,P.OrderDate,P.ShipDate)) AS DeliveryTime
FROM Purchasing.PurchaseOrderHeader P
JOIN Purchasing.Vendor V 
ON P.VendorID = V.BusinessEntityID
GROUP BY P.VendorID,V.Name
ORDER BY DeliveryTime DESC;

--How often do we experience late shipments?

SELECT SUM(CASE WHEN ShipDate >= DueDate THEN 1 ELSE 0 END) AS NoLateShipment
       ,CAST(SUM(CASE WHEN ShipDate >= DueDate THEN 1 ELSE 0 END)*100.0/COUNT(*) AS decimal(5,2)) LateShipmentsRatePercent  
FROM Sales.SalesOrderHeader;

--Which locations have the highest inventory holding costs?

SELECT I.LocationID
       ,L.Name LocationName 
       ,CAST(SUM(P.StandardCost * I.Quantity) AS decimal(10,2)) AS COGS    
    FROM Production.ProductInventory I
    LEFT JOIN Production.Product P
    ON P.ProductID = I.ProductID
    LEFT JOIN Production.Location L
    ON I.LocationID=L.LocationID
    GROUP BY I.LocationID,L.Name
    ORDER BY 3 DESC;

--What is the purchase cost trend by vendor?

SELECT PH.VendorID AS VendorID
       ,V.Name AS VendorName
       ,YEAR(PH.OrderDate) Years
       ,CAST(SUM(PO.LineTotal)AS decimal(10,2)) AS PurchasingCost
FROM Purchasing.PurchaseOrderHeader PH
JOIN Purchasing.PurchaseOrderDetail PO
ON PH.PurchaseOrderID=PO.PurchaseOrderID
JOIN Purchasing.Vendor V 
ON PH.VendorID = V.BusinessEntityID
GROUP BY PH.VendorID,V.Name,YEAR(PH.OrderDate)
ORDER BY PH.VendorID,Years;