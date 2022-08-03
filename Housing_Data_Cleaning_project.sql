/* 
    Cleaning data in SQL queries in 7 steps (give or take couple)  
	By the guidanace of "Alex-The Analyst"

	1- Standarize the date format in SalesDate
	2- Populate PropertyAddress Data
	3- Separate Propertyaddress into Indiviual columns(Address, City,State)
			Through SUBSTRING() Method
	4- Separating Owneraddress into Indiviual columns (Address, City,State)
			With using ParseName() Function
			Without using ParseName() Function (Used CTE) 
	5- Chagge Y and N to Yes and No in "Sold As Vacant"
			By using CASE statement
	6- Removing duplicate rows/entities
			By using Window_function() & CTE
	7- Deleting Unused columns to ease the processing/importing
*/ 
SELECT *
FROM PortfolioProject1.dbo.Nashville_House_Data



/* 
	# 1
	Standarize the date format in SalesDate
*/

-- Converting the Sale date from date_time frame to date type
SELECT Sale_Date, CONVERT (Date, Sale_Date) as Sale_Date
FROM PortfolioProject1..Nashville_House_Data
-- This part is pretty much general for each steps for adding new columns derived from these columns
ALTER TABLE Nashville_House_Data
ADD Sale_Date Date;

UPDATE PortfolioProject1..Nashville_House_Data
SET Sale_Date = CONVERT (Date, SaleDate) 



/* 
	# 2
	Populate Property Address Data
	Populate means to fill the empty points through the reference points
 */

-- This serves as the initial guess point and final tests point, and most likely in all steps ahead
SELECT *
FROM PortfolioProject1..Nashville_House_Data
WHERE PropertyAddress is NULL
ORDER BY ParcelID

SELECT a.PropertyAddress, a.ParcelID, b.ParcelID,b.PropertyAddress--, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject1..Nashville_House_Data AS a
JOIN PortfolioProject1..Nashville_House_Data AS b
	ON a.ParcelID = b.ParcelID 
	AND a.[UniqueID ] <> b.[UniqueID ] 
WHERE a.PropertyAddress is NULL
--This tells that we have reference point to populate every Null point and we define new column 

-- This actually populates the Null points in Column
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject1..Nashville_House_Data AS a
JOIN PortfolioProject1..Nashville_House_Data AS b
	ON a.ParcelID = b.ParcelID 
	AND a.[UniqueID ] <> b.[UniqueID ] 
WHERE a.PropertyAddress is NULL



/* 
	# 3
	Separate Property address data into Indiviual columns (Address, City,State)
	Through the Substring Method
	The separator(deliminer/delimiter) that intrigues us or helps us is the comma ',' inside 
	  column, it separates address and the city
*/

SELECT 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) -1 ) 
  -- , CHARINDEX(',' , PropertyAddress)  /* this is for undertsanding and learning */  
	, SUBSTRING(PropertyAddress, CHARINDEX(',' , PropertyAddress ) + 1 , LEN(PropertyAddress))
FROM PortfolioProject1..Nashville_House_Data

ALTER TABLE PortfolioProject1..Nashville_House_Data
ADD Prop_Split_Address nvarchar(255),
    Prop_Split_City NVARCHAR(255);

UPDATE PortfolioProject1..Nashville_House_Data
SET Prop_Split_Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) -1 )
	, Prop_Split_City = SUBSTRING(PropertyAddress, CHARINDEX(',' , PropertyAddress ) + 1 , LEN(PropertyAddress))



/* 
	# 4
	Separating Owner address data into Indiviual columns (Address, City,State)
	By using ParseName() function
	LIMITATION!!! It will not work for more than 4 delimited values within a string
	  only and always searches for '.' delimiter
*/

-- ParseName Only identifies '.' delimiter, so we will have to first replace our string to dot(.)
-- Also it starts counting from right to left (right-most is 1)
SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 3)
	,PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 2)
	,PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 1) 
FROM PortfolioProject1..Nashville_House_Data

ALTER TABLE PortfolioProject1..Nashville_House_Data
ADD Owner_Split_Address nvarchar(255)
    ,Owner_Split_City NVARCHAR(255)
	,Owner_Split_State nvarchar(255);

UPDATE PortfolioProject1..Nashville_House_Data
SET Owner_Split_Address = PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 3)
	,Owner_Split_City = PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 2)
	,Owner_Split_State = PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 1) ;


-- Below is the example of how to do this without ParseName function
/* 
This comment by "Gordon Linoff" on stackoverflow helped in laying the foundation of this
 -- select stuff(OwnerAddress, 1, charindex(',', OwnerAddress + ',') + 1, '')
 -- FROM PortfolioProject1..Nashville_House_Data 
*/

WITH Fun_CTE
AS 
(
SELECT 
	SUBSTRING(OwnerAddress, 1 , CHARINDEX(',' , OwnerAddress) - 1) AS pin_point
	, stuff(OwnerAddress, 1, charindex(',', OwnerAddress + ',') + 1, '') AS point_2

FROM PortfolioProject1..Nashville_House_Data 
)

SELECT 
	Pin_point
	,SUBSTRING(point_2, 1, CHARINDEX(',' , point_2) - 1)
	, SUBSTRING (point_2, CHARINDEX(',', point_2) + 1, LEN(point_2) )
FROM Fun_CTE




/* 
	# 5
	Chagge Y and N to Yes and No in "Sold As Vacant"
			Used CASE for this
*/

--  First we need to find the status of the column "SoldAsVacant"  to determine Y's are more or Yes & convert according to that
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM PortfolioProject1..Nashville_House_Data 
GROUP BY SoldAsVacant
ORDER BY 2
--This is how we determine how many unique enetiites are present

UPDATE PortfolioProject1..Nashville_House_Data
SET SoldAsVacant = CASE 
					WHEN SoldAsVacant = 'Y' THEN 'Yes'
					WHEN SoldAsVacant = 'N' THEN 'No'
					ELSE SoldAsVacant
					END
FROM PortfolioProject1..Nashville_House_Data 



/* 
	# 6
	Removing duplicate rows/entities
	By using Windows_function inside CTE (Common Table Expression)
	Window_func_name(<expr) OVER(<PARTITION_BY_clause> <ORDER_BY_clause>)
*/

WITH row_Numb_CTE 
AS 
(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference 
			ORDER BY 
					UniqueID
	                  )  AS Row_Numb
FROM PortfolioProject1..Nashville_House_Data 
--ORDER BY ParcelID
)
DELETE
FROM row_Numb_CTE
WHERE Row_Numb > 1
--ORDER BY PropertyAddress



/* 
	# 7
	Deleting Unused columns
	NOTE! We dont do this normally, we only view those and use view
*/ 

SELECT *
FROM PortfolioProject1..Nashville_House_Data 

ALTER TABLE PortfolioProject1..Nashville_House_Data 
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress

