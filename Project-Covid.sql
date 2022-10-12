/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not NULL
ORDER BY 3,4


-- Reviewing data to see what we are going to be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
Order By 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying after contraction in the countries

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%states'
    AND continent is not NULL
Order By 1,2


-- Total Cases vs Populations
-- Percentage of population infected with covid

SELECT Location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
Order By 1,2

-- Countries with Highest Infection Rate compared to Population

SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
GROUP BY location, population
Order By PercentPopulationInfected DESC


-- Countries with Highest Death Count per Population

SELECT Location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
GROUP BY location
Order By TotalDeathCount DESC


-- Breaking things down by Continent

-- Querying Continents with the Highest Death Count per Population

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is null
GROUP BY location
Order By TotalDeathCount DESC


-- Global Numbers

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths
    , SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
GROUP BY date
Order By 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one covid vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
    , SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- Using CTE to perform calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
    , SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent is not null
)

Select *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


-- Using Temp Table to perform calculation on partition by in previous query
 
DROP TABLE if EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
    , SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
    ON dea.location = vac.location
    and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating view to store data for later visualizations

CREATE OR ALTER VIEW PercentPopulationVaccinated AS

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
    , SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent is not NULL
