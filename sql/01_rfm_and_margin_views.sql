CREATE VIEW vw_RFM_and_Margin AS 
WITH CustomerBase AS (
	SELECT
		c.CustomerID,
		c.CompanyName AS CustomerName, 
		c.Country, 
		COUNT(Distinct o.OrderID) AS Frequency, 
		ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS Monetary, 
		ROUND(SUM(od.UnitPrice * od.Quantity * od.Discount), 2) AS TotalDiscountGiven, 
		CAST(julianday((SELECT MAX(OrderDate) FROM Orders)) - julianday(MAX(o.OrderDate)) AS INTEGER) AS RecencyDays
	FROM Customers c
	JOIN Orders o ON c.CustomerID = o.CustomerID
	JOIN "Order Details" od ON o.OrderID = od.OrderID
	GROUP BY c.CustomerID, c.CompanyName, c.Country
), 
RFMScores AS (
	SELECT
		*, 
		NTILE(5) OVER (ORDER BY RecencyDays DESC) AS R_Score, 
		NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score, 
		NTILE(5) OVER (ORDER BY Monetary ASC) AS M_Score
	FROM CustomerBase
)
SELECT
	*, 
	(R_Score + F_Score + M_Score) AS RFM_Total, 
	CASE
		WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'Champions'
		WHEN R_Score <= 2 AND M_Score >= 4 THEN 'At-Risk High Value'
        WHEN R_Score <= 2 AND F_Score <= 2 THEN 'Hibernating / Lost'
        WHEN F_Score >= 3 AND M_Score >= 3 THEN 'Loyal Core'
        ELSE 'Potential / Developing'
	END AS CustomerSegment, 
	ROUND(TotalDiscountGiven / NULLIF(Monetary + TotalDiscountGiven, 0), 4) AS EffectiveDiscountRate
FROM RFMScores;