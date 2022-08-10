/* 
    Doing Data Cleaning & 
	Visualization for TATA_Forage project 
	Total 4 questions were asked in the project
*/


-- Data is too big, so viewing only first 300's
SELECT TOP 300 * 
FROM PortfolioProject1..['Online Retail$'] 
ORDER BY Invoicedate


/* 
	Changing Date format
*/ 

SELECT InvoiceDate, CONVERT (Date, InvoiceDate) as Invoice_Date
FROM PortfolioProject1..['Online Retail$']

-- This step is pretty much general for each steps for adding new columns derived from these columns
ALTER TABLE ['Online Retail$']
ADD Invoice_Date Date;

UPDATE PortfolioProject1..['Online Retail$']
	SET Invoice_Date = CONVERT (Date, InvoiceDate) 


SELECT DISTINCT Description
FROM PortfolioProject1..['Online Retail$'] 

--This condition must be applied to every part of the code to make data tidy and relevant
SELECT * 
FROM PortfolioProject1..['Online Retail$'] 
WHERE Quantity > 0 
	AND UnitPrice >= 0

-- Now we are going to do data manipualtion and visualization acc to the Questions asked
/* Q.1
	The CEO of the retail store is interested to view the time series of the revenue data for the year 2011 only. 
	He would like to view granular data by looking into revenue for each month. 
	The CEO is interested in viewing the seasonal trends and wants to dig deeper into why these trends occur. 
	This analysis will be helpful for the CEO to forecast for the next year.
*/ 

--Breaking Invoice_Date column to extract out months

SELECT 
	PARSENAME(REPLACE(Invoice_Date, '-' , '.') , 3),
	PARSENAME(REPLACE(Invoice_Date, '-' , '.') , 2),
	PARSENAME(REPLACE(Invoice_Date, '-' , '.') , 1)
FROM PortfolioProject1..['Online Retail$']
ORDER BY Invoice_Date

ALTER TABLE PortfolioProject1..['Online Retail$']
	ADD 
		Invoice_year INT,
		Invoice_month INT,
		Invoice_day INT ;

UPDATE PortfolioProject1..['Online Retail$']
	SET	
		Invoice_year = PARSENAME(REPLACE(Invoice_Date, '-' , '.') , 3),
		Invoice_month = PARSENAME(REPLACE(Invoice_Date, '-' , '.') , 2),
		Invoice_day = PARSENAME(REPLACE(Invoice_Date, '-' , '.') , 1) ;

-- To see that changes occured or not
SELECT TOP 300 * 
FROM PortfolioProject1..['Online Retail$'] 
ORDER BY Invoicedate

-- The result of below query is stored in excel to make the visualization in 'Tableau'
SELECT
	DISTINCT Invoice_month, 
	--Invoice_year, 
	SUM(UnitPrice) 
					OVER (
						   PARTITION BY Invoice_year,
										Invoice_month 
							ORDER BY 
									Invoice_month
							)  AS Revenue
FROM PortfolioProject1..['Online Retail$']
WHERE 
	Invoice_year = 2011 
	AND Quantity > 0
	AND UnitPrice >= 0
--ORDER BY 1 



/*	Q.2
	The CMO is interested in viewing the top 10 countries which are generating the highest revenue. 
	Additionally, the CMO is also interested in viewing the quantity sold along with the revenue generated. 
	The CMO does not want to have the United Kingdom in this visual.
*/ 

-- The result of below query is stored in excel to make the visualization in 'Tableau'
WITH 
	Top_CTE
AS
(
SELECT
	DISTINCT Country, 
	--Invoice_year, 
	SUM(UnitPrice) 
					OVER (
						   PARTITION BY Country
							ORDER BY 
									Country
							)  AS Revenue_per_country ,
	SUM(Quantity) 
					OVER (
						   PARTITION BY Country
							ORDER BY 
									Country
							)  AS Tot_Quantity_per_Country

FROM PortfolioProject1..['Online Retail$']
WHERE  
	Country <> 'United Kingdom'
	AND Quantity > 0
	AND UnitPrice >= 0
)

SELECT TOP 10 *
FROM Top_CTE
ORDER BY Revenue_per_country DESC


/* Q.3
	The CMO of the online retail store wants to view the information on the top 10 customers by revenue.
	He is interested in a visual that shows the greatest revenue generating customer at the start &
		gradually declines to the lower revenue generating customers. 
	The CMO wants to target the higher revenue generating customers and ensure that they remain satisfied with their products.
*/

-- The result of below query is stored in excel to make the visualization in 'Tableau'
WITH 
	customer_CTE
AS
(
SELECT
	DISTINCT CustomerID, 
	Country, 
	SUM(UnitPrice) 
					OVER (
						   PARTITION BY 
										CustomerID
							ORDER BY 
									CustomerID
							)  AS Revenue_per_customer ,
	SUM(Quantity) 
					OVER (
						   PARTITION BY 
										CustomerID
							ORDER BY 
									CustomerID
							)  AS Total_quntity_by_customer 

FROM PortfolioProject1..['Online Retail$']
WHERE  
	CustomerID > 0
	AND Quantity > 0
	AND UnitPrice >= 0
) 

SELECT TOP 10 *
FROM customer_CTE 
ORDER BY 3 DESC


/* Q.4
	The CEO is looking to gain insights on the demand for their products. 
	He wants to look at all countries and see which regions have the greatest demand for their products. 
	Once the CEO gets an idea of the regions that have high demand, he will initiate an expansion strategy 
	which will allow the company to target these areas and generate more business from these regions. 
	He wants to view the entire data on a single view without the need to scroll or 
		hover over the data points to identify the demand. 
	There is no need to show data for the United Kingdom as the CEO is more interested in viewing the countries that have expansion opportunities.
*/


-- Doing by Country vise
-- The result of below query is stored in excel to make the visualization in 'Tableau'
WITH 
	Map_CTE
AS
(
SELECT
	DISTINCT Country, 
	--Invoice_year, 
	SUM(UnitPrice) 
					OVER (
						   PARTITION BY Country
							ORDER BY 
									Country
							)  AS Revenue_per_country ,
	SUM(Quantity) 
					OVER (
						   PARTITION BY Country
							ORDER BY 
									Country
							)  AS Total_Quantity_per_Country

FROM PortfolioProject1..['Online Retail$']
WHERE  
	Country <> 'United Kingdom'
	AND Quantity > 0
	AND UnitPrice >= 0
)
SELECT *
FROM Map_CTE
ORDER BY Total_Quantity_per_Country DESC


--Doing Continent vise 
-- First, making the continent column and assigning it rto each country 
ALTER TABLE PortfolioProject1..['Online Retail$']
ADD Continent nvarchar(255);

UPDATE PortfolioProject1..['Online Retail$']
	SET Continent = CASE 
					WHEN Country = 'Netherlands' or 
							Country = 'EIRE' or 
							Country = 'Germany' or 
							Country = 'France' or 
							Country = 'Sweden' or 
							Country = 'Switzerland' or
							Country = 'Spain' or 
							Country = 'Belgium' or
							Country = 'Norway' or 
							Country = 'Portugal' or 
							Country = 'Finland' or 
							Country = 'Channel Islands' or 
							Country = 'Denmark' or 
							Country = 'Italy' or 
							Country = 'Cyprus' or 
							Country = 'Austria' or 
							Country = 'Poland' or 
							Country = 'Iceland' or 
							Country = 'Greece' or 
							Country = 'Malta' or 
							Country = 'Czech Republic' or 
							Country = 'Lithuania' or 
							Country = 'European Community' OR 
							Country = 'United Kingdom' 
						THEN 'Europe' 
					WHEN Country = 'Australia' 
						THEN 'Australia' 
					WHEN Country = 'Japan' or 
							Country = 'Singapore' or 
							Country = 'Hong Kong' or 
							Country = 'Israel' or 
							Country = 'United Arab Emirates' or 
							Country = 'Lebanon' or 
							Country = 'Bahrain' or
							Country = 'Saudi Arabia'
						THEN 'Asia' 
					WHEN Country = 'Canada' or 
							Country = 'USA' 
						THEN 'North America' 
					WHEN Country = 'Brazil' 
						THEN 'South America'
					WHEN Country = 'RSA' 
						THEN 'Africa' 
					ELSE Continent 
					END

WITH 
	Continent_CTE
AS
(
SELECT
	DISTINCT Continent, 
	--Invoice_year, 
	SUM(UnitPrice) 
					OVER (
						   PARTITION BY Continent
							ORDER BY 
									Continent
							)  AS Revenue_per_continent ,
	SUM(Quantity) 
					OVER (
						   PARTITION BY Continent
							ORDER BY 
									Continent
							)  AS Total_Quantity_per_continent

FROM PortfolioProject1..['Online Retail$']
WHERE  
	Country <> 'United Kingdom'
	-- United kingdom is excluded from visualization as company had branches there 
	AND Quantity > 0
	AND UnitPrice >= 0
)
SELECT *
FROM Continent_CTE
ORDER BY Total_Quantity_per_continent DESC
