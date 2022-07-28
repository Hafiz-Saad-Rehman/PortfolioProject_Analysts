/*
Covid 19 Data Exploration 
   Covid 19 Exploration in regards to the Smoking and its impact on Smokers
Skills used: Joins, CTE's,CTE's within CTE's (Kinda nested CTE's),
             Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/


SELECT * 
FROM PortfolioProject1..CovidDeaths 
where continent is null 
ORDER BY 3, 4 

 Select * 
 From PortfolioProject1..CovidVaccinations
order by 3, 4

-- Selecting specific columns out of data 
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject1..CovidDeaths
order by 1,2

-- Looking at total_cases vs total_deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) as death_over_cases
FROM PortfolioProject1..CovidDeaths
ORDER BY 1,2 

-- likelihood of dying if you had covid in a region
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_over_cases_r
FROM PortfolioProject1..CovidDeaths
WHERE continent is not NULL
--WHERE location LIKE '%Pakistan%'
ORDER BY 1,2 

--Looking at total_cases vs Population 
SELECT location, date, total_cases, Population, (total_cases/population)*100 as cases_over_pop_r
FROM PortfolioProject1..CovidDeaths
WHERE location LIKE '%Pakistan%'
AND continent is not NULL
ORDER BY cases_over_pop_r  DESC

--Countries with highest infection rate 
SELECT location, Population, MAX(total_cases) as Highest_infection ,MAX((total_cases/population)*100) as pop_infected
FROM PortfolioProject1..CovidDeaths
--WHERE location LIKE '%Pakistan%'
WHERE continent is not NULL
GROUP BY location, population
ORDER BY pop_infected  DESC

-- Highest death count per population 
SELECT location, Population, MAX(total_deaths) as highest_Death , MAX(total_deaths/population)*100 as pop_died
FROM portfolioProject1..CovidDeaths
WHERE continent is not NULL
GROUP BY location, population
--we also have to add population in group by, else it gives error that "it is not contained in either an aggregate function or the GROUP BY clause".
ORDER BY pop_died DESC 
-- There's an error in output because total_deaths column is nchar and not of integer type

SELECT DISTINCT location, MAX(Population), MAX(CAST (total_deaths AS int)) as highest_Death 
FROM portfolioProject1..CovidDeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY 1 

--ISSUE IN LOCATION COLUMN OF DATA, SOLVING THAT BELOW
SELECT *
FROM PortfolioProject1..CovidDeaths
WHERE continent is not NULL
ORDER BY 3,4


--LET's BREAK THINGS DOWN BY CONTINENT 
SELECT continent, MAX (CONVERT (int , total_deaths)) as DEATH
FROM PortfolioProject1..CovidDeaths
WHERE continent is not NULL 
GROUP BY continent 
ORDER BY DEATH DESC

-- by looking at the data, we realize its not perfect 
-- for the purpose of hierarchy and the purposes of drill down effect in tableau

SELECT location, MAX (CONVERT (int , total_deaths)) as DEATH
FROM PortfolioProject1..CovidDeaths
WHERE continent is NULL 
GROUP BY location 
ORDER BY DEATH DESC
--below code will help in visualizating how this is correct 
SELECT * 
FROM PortfolioProject1..CovidDeaths 
where continent is null 
ORDER BY 3, 4 

--GLO


--Introducing another dataset related to covid
SELECT *
FROM PortfolioProject1..CovidVaccinations

--Looking at Total population vs Vaccination 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject1..CovidDeaths AS dea
JOIN PortfolioProject1..CovidVaccinations AS vac
-- because population column reside in Death sheet
	ON dea.location = vac.location
	AND dea.date = vac.date 
WHERE dea.continent is not NULL 
ORDER BY 2,3  

--Now we are gonna find our own total vaccination count 
SELECT dea.location, MAX(dea.population), SUM(CAST (vac.new_vaccinations AS int))  AS totr
FROM PortfolioProject1..CovidDeaths AS dea
JOIN PortfolioProject1..CovidVaccinations AS vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is not NULL 
GROUP BY dea.location
ORDER BY 2
-- This tells the entire vaccination of each particular country


--Now finding the rolling count of the total_vaccinations
SELECT dea.continent, dea.location,dea.date ,dea.population, vac.new_vaccinations
, SUM(CONVERT (int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject1..CovidDeaths dea
JOIN PortfolioProject1..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY vac.new_vaccinations ASC 

--keeping track of the previous vaccinations count to ensure True data
With Previous_count_vac 
( 
	Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated
	)
AS 
(
SELECT dea.continent, dea.location,dea.date ,dea.population, vac.new_vaccinations
, SUM(CONVERT (int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject1..CovidDeaths dea
JOIN PortfolioProject1..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is not NULL
--ORDER BY vac.new_vaccinations ASC 
)
SELECT Continent, Location, Date,Population,(RollingPeopleVaccinated-New_vaccinations) as Previos_Vacc ,New_vaccinations, RollingPeopleVaccinated
FROM Previous_count_vac


-- USING CTE Method
--bcaz we can't use a column we just created in the same query 
WITH Pop_vs_Vac (Continent, Location, Date, Population, New_vaccinations ,RollingPeopleVaccinated) 
AS 
(
 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
 , SUM(CAST(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY 
			dea.location, dea.date ) as RollingPeopleVaccinated 
 FROM PortfolioProject1..CovidDeaths dea
 JOIN PortfolioProject1..CovidVaccinations vac
	 ON dea.location = vac.location 
	 AND dea.date = vac.date
 WHERE dea.continent is not NULL
 )
 SELECT *, (RollingPeopleVaccinated-New_vaccinations) as Previos_Vacc, (RollingPeopleVaccinated/Population) * 100  Vac_Ov_Pop
 FROM Pop_vs_Vac 




--DOES the COUNTRY WITH GREATER NO of SMOKERS(male/female) HAVE MORE COVID IMPACT per ?
-- TEMP table 

-- for MALE smokers with rolling sum 
DROP TABLE IF EXISTS #Male_smok_Scene
CREATE TABLE #Male_Smok_Scene
(
 Continent nvarchar(255), location nvarchar(255), Date datetime, Population numeric, 
 New_Cases numeric, New_deaths nvarchar(255), Male_smokers nvarchar(255), 
 SMOOKERS numeric ,Roll_count_Case numeric, Roll_Cnt_Death numeric 
 )
INSERT INTO #Male_Smok_Scene
SELECT dea.continent, dea.location, dea.date, dea.population, dea.new_cases, dea.new_deaths, vac.male_smokers 
 , (vac.male_smokers *dea.Population)/ 100 As SMOOKERS
 , SUM(dea.new_cases) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Roll_count_Case 
 , SUM(CAST (dea.new_deaths as INT ))OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Roll_Cnt_Death 
FROM PortfolioProject1..CovidDeaths as dea
JOIN PortfolioProject1..CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date 
WHERE dea.continent is not NULL
AND dea.location LIKE '%Pakistan%'

SELECT *, (Roll_count_Case/Male_smokers)*100 as Cases, (Roll_Cnt_Death/male_smokers)*100 as DEATH_S
FROM #Male_Smok_Scene


-- for FEMALE smokers 
DROP TABLE IF EXISTS #Females_Smok_Scene
CREATE TABLE #Females_Smok_Scene
(
 Continent nvarchar(255), Location nvarchar(255), date datetime, 
 Population numeric, new_cases numeric, new_deaths nvarchar(255), 
 female_smokers nvarchar(255), F_Smokers numeric, Roll_case numeric, Roll_death numeric
)
INSERT INTO #Females_Smok_Scene
SELECT dea.continent, dea.location, dea.date, dea.population, dea.new_cases, dea.new_deaths, vac.female_smokers
 , (vac.female_smokers*population)/100 as F_Smokers
 , SUM(dea.new_cases) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as Roll_case
 , SUM(CONVERT (int, dea.new_deaths)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as Roll_Death
FROM PortfolioProject1..CovidDeaths as dea
JOIN PortfolioProject1..CovidVaccinations as vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL 
--AND dea.location LIKE '%Pakistan%'
SELECT *, (Roll_case/F_smokers)*100 as f_1, (Roll_Death/F_smokers)*100 as F_D
FROM #Females_Smok_Scene


-- All_Smokers Combined PER date
WITH Smoker_Combined_Per_date ( 
		Continent, location, Date, Population, Male_smokers, Female_Smoker, M_Smok, F_Smok 
	)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.male_smokers, vac.female_smokers
, (vac.male_smokers * dea.population) / 100 as M_smok, (vac.female_smokers * dea.population) / 100 as F_smok
 --((CAST(vac.male_smokers as int)+CAST(vac.female_smokers AS int))*dea.population)/100 as All_smokers
FROM PortfolioProject1..CovidDeaths as dea
JOIN PortfolioProject1..CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date 
WHERE dea.continent is not NULL 
--ORDER BY 2,3
)
SELECT *, (M_Smok + F_Smok) as All_Smoker
FROM Smoker_Combined_Per_date



-- for ALL SMOKERS combined (with unique locaions)
WITH Smoking_Impact2 ( 
		 location, Population, Total_cases, Total_deaths, Total_tests, Male_smokers, Female_Smoker, M_Smok, F_Smok 
	)
AS 
(
SELECT dea.location, dea.population, dea.total_cases ,dea.total_deaths, vac.total_tests, vac.male_smokers, vac.female_smokers
, (vac.male_smokers * dea.population) / 100 as M_smok, (vac.female_smokers * dea.population) / 100 as F_smok
 --((CAST(vac.male_smokers as int)+CAST(vac.female_smokers AS int))*dea.population)/100 as All_smokers
FROM PortfolioProject1..CovidDeaths as dea
JOIN PortfolioProject1..CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date 
WHERE dea.continent is not NULL 
--ORDER BY 2,3
)

SELECT DISTINCT Location, MAX(Population) Population, MAX(Total_cases) T_Cases, MAX(Total_deaths) T_Deaths
	,	MAX(Total_tests) T_Tests, MAX(Male_smokers) Perc_M_Smok, MAX(Female_Smoker) Perc_F_Smok, MAX(M_Smok) M_Smok
	,	MAX(F_Smok) F_Smok ,MAX(M_Smok + F_Smok) as All_Smok
FROM Smoking_Impact2
GROUP BY location 


--Smoking Conclusion 
WITH Smoking_Impact2 ( 
		location, Population, Total_cases, Total_deaths, Total_tests, Male_smokers, Female_Smoker, M_Smok, F_Smok, Case_P, Death_p, Test_P  
	)
AS 
(
SELECT dea.location, dea.population, dea.total_cases ,dea.total_deaths, vac.total_tests, vac.male_smokers, vac.female_smokers
, (vac.male_smokers * dea.population) / 100 as M_smok, (vac.female_smokers * dea.population) / 100 as F_smok
, (dea.total_cases/dea.population)*100 as Case_P, (dea.total_deaths/dea.population)*100 as Death_P, (vac.total_tests/dea.population)*100 as Test_P
 --((CAST(vac.male_smokers as int)+CAST(vac.female_smokers AS int))*dea.population)/100 as All_smokers
FROM PortfolioProject1..CovidDeaths as dea
JOIN PortfolioProject1..CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date 
WHERE dea.continent is not NULL 
--ORDER BY 2,3
), Smoking_Conclusion( 
         location, population, total_cases, total_deaths, total_tests, male_smokers, 
		   female_smokers, M_smok, F_smok, All_Smok, Case_P, Death_P, Test_P
    )
	AS
   (
	SELECT Location, Population, Total_cases, Total_deaths, Total_tests, Male_smokers, Female_Smoker, M_Smok, F_Smok ,(M_Smok + F_Smok) as All_Smok,  Case_P, Death_p, Test_P
	FROM Smoking_Impact2 
	)
SELECT DISTINCT location, MAX(Population) Population, MAX(Total_cases) Total_cases, MAX(Total_deaths) Total_deaths, MAX(Total_tests) Total_tests
		, MAX(Male_smokers) Male_Smokers, MAX(Female_Smokers) Female_Smokers, MAX(M_smok) M_Smok, MAX(F_smok) F_Smok, MAX(All_smok) All_Smok, MAX(Case_P) Case_P 
		, MAX(Death_P) Death_P, MAX(Test_P) Test_P, MAX(Case_P/All_Smok) as C_P_S, MAX(Death_P/All_Smok) as D_P_S, MAX(Test_P/All_Smok) as T_P_S
FROM Smoking_Conclusion 
GROUP BY location
ORDER BY location ASC


--NOW CREATING 'VIEW' OF Interesting stuff


-- likelihood of dying if you had covid in a region
-- View 1
CREATE VIEW death_Cases_Dying_Scenario as
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_over_cases_r
FROM PortfolioProject1..CovidDeaths
WHERE continent is not NULL
--WHERE location LIKE '%Pakistan%'
--ORDER BY 1,2 


-- Looking at total_cases vs Population 
-- View 2
CREATE VIEW Case_Vs_Pop AS
SELECT location, date, total_cases, Population, (total_cases/population)*100 as cases_over_pop_r
FROM PortfolioProject1..CovidDeaths
WHERE location LIKE '%Pakistan%'
AND continent is not NULL
--ORDER BY cases_over_pop_r  DESC


-- Countries with highest infection rate 
-- View 3
CREATE VIEW H_Infect_Rate AS
SELECT location, Population, MAX(total_cases) as Highest_infection ,MAX((total_cases/population)*100) as pop_infected
FROM PortfolioProject1..CovidDeaths
--WHERE location LIKE '%Pakistan%'
WHERE continent is not NULL
GROUP BY location, population
--ORDER BY pop_infected  DESC


-- Highest death count per population 
-- View 4
CREATE VIEW H_Dead_Cnt AS
SELECT DISTINCT location, MAX(Population) Population, MAX(CAST (total_deaths AS int)) as highest_Death 
FROM portfolioProject1..CovidDeaths
WHERE continent is not NULL
GROUP BY location
--ORDER BY 1 


--LET's break things down by Continent
-- for the purpose of hierarchy and the purposes of drill down effect in tableau
-- View 5
CREATE VIEW Continent_View AS
SELECT location, MAX (CONVERT (int , total_deaths)) as DEATH
FROM PortfolioProject1..CovidDeaths
WHERE continent is NULL 
GROUP BY location 
--ORDER BY DEATH DESC


-- Looking at Total population vs Vaccination 
-- View 6
CREATE VIEW Vac_Vs_Pop AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject1..CovidDeaths AS dea
JOIN PortfolioProject1..CovidVaccinations AS vac
-- because population column reside in Death sheet
	ON dea.location = vac.location
	AND dea.date = vac.date 
WHERE dea.continent is not NULL 
--ORDER BY 2,3  


-- Now we are gonna find our own total vaccination count 
-- View 7
CREATE VIEW Vac_Of_Each_Country AS
SELECT dea.location, MAX(dea.population) Population, SUM(CAST (vac.new_vaccinations AS int))  AS totr
FROM PortfolioProject1..CovidDeaths AS dea
JOIN PortfolioProject1..CovidVaccinations AS vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is not NULL 
GROUP BY dea.location
--ORDER BY 2
-- This tells the entire vaccination of each particular country


-- All_Smokers Combined View PER date
-- View 8
CREATE VIEW Smoker_Combined_Per_date as
WITH Smoker_Combined_Per_date ( 
		Continent, location, Date, Population, Male_smokers, Female_Smoker, M_Smok, F_Smok 
	)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.male_smokers, vac.female_smokers
, (vac.male_smokers * dea.population) / 100 as M_smok, (vac.female_smokers * dea.population) / 100 as F_smok
 --((CAST(vac.male_smokers as int)+CAST(vac.female_smokers AS int))*dea.population)/100 as All_smokers
FROM PortfolioProject1..CovidDeaths as dea
JOIN PortfolioProject1..CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date 
WHERE dea.continent is not NULL 
--ORDER BY 2,3
)
SELECT *, (M_Smok + F_Smok) as All_Smoker
FROM Smoker_Combined_Per_date


-- for ALL SMOKERS combined (with unique locaions)
-- View 9
CREATE VIEW Smoker_Combined_Impact AS
WITH Smoking_Impact2 ( 
		 location, Population, Total_cases, Total_deaths, Total_tests, Male_smokers, Female_Smoker, M_Smok, F_Smok 
	)
AS 
(
SELECT dea.location, dea.population, dea.total_cases ,dea.total_deaths, vac.total_tests, vac.male_smokers, vac.female_smokers
, (vac.male_smokers * dea.population) / 100 as M_smok, (vac.female_smokers * dea.population) / 100 as F_smok
 --((CAST(vac.male_smokers as int)+CAST(vac.female_smokers AS int))*dea.population)/100 as All_smokers
FROM PortfolioProject1..CovidDeaths as dea
JOIN PortfolioProject1..CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date 
WHERE dea.continent is not NULL 
--ORDER BY 2,3
)

SELECT DISTINCT Location, MAX(Population) Population, MAX(Total_cases) T_Cases, MAX(Total_deaths) T_Deaths
	,	MAX(Total_tests) T_Tests, MAX(Male_smokers) Perc_M_Smok, MAX(Female_Smoker) Perc_F_Smok, MAX(M_Smok) M_Smok
	,	MAX(F_Smok) F_Smok ,MAX(M_Smok + F_Smok) as All_Smok
FROM Smoking_Impact2
GROUP BY location 




-- SMOKING CONCLUSION VIEW
-- View 10 
CREATE VIEW Smoking_Conclusion as 
WITH Smoking_Impact2 ( 
		location, Population, Total_cases, Total_deaths, Total_tests, Male_smokers, Female_Smoker, M_Smok, F_Smok, Case_P, Death_p, Test_P  
	)
AS 
(
SELECT dea.location, dea.population, dea.total_cases ,dea.total_deaths, vac.total_tests, vac.male_smokers, vac.female_smokers
, (vac.male_smokers * dea.population) / 100 as M_smok, (vac.female_smokers * dea.population) / 100 as F_smok
, (dea.total_cases/dea.population)*100 as Case_P, (dea.total_deaths/dea.population)*100 as Death_P, (vac.total_tests/dea.population)*100 as Test_P
 --((CAST(vac.male_smokers as int)+CAST(vac.female_smokers AS int))*dea.population)/100 as All_smokers
FROM PortfolioProject1..CovidDeaths as dea
JOIN PortfolioProject1..CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date 
WHERE dea.continent is not NULL 
--ORDER BY 2,3
), Smoking_Conclusion( 
         location, population, total_cases, total_deaths, total_tests, male_smokers, 
		   female_smokers, M_smok, F_smok, All_Smok, Case_P, Death_P, Test_P
    )
	AS
   (
	SELECT Location, Population, Total_cases, Total_deaths, Total_tests, Male_smokers, Female_Smoker, M_Smok, F_Smok ,(M_Smok + F_Smok) as All_Smok,  Case_P, Death_p, Test_P
	FROM Smoking_Impact2 
	)
SELECT DISTINCT location, MAX(Population) Population, MAX(Total_cases) Total_cases, MAX(Total_deaths) Total_deaths, MAX(Total_tests) Total_tests
 , MAX(Male_smokers) Male_Smokers, MAX(Female_Smokers) Female_Smokers, MAX(M_smok) M_Smok, MAX(F_smok) F_Smok, MAX(All_smok) All_Smok, MAX(Case_P) Case_P 
 , MAX(Death_P) Death_P, MAX(Test_P) Test_P, MAX(Case_P/All_Smok) as C_P_S, MAX(Death_P/All_Smok) as D_P_S, MAX(Test_P/All_Smok) as T_P_S
FROM Smoking_Conclusion 
GROUP BY location
--ORDER BY location ASC

