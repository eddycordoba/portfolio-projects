 --Explore Covid Deaths Table
 SELECT * 
 FROM `sql-covid-data-exploration.covid_data.covid_deaths` 
 where continent is not null
 Order By 3,4 
 LIMIT 1000
 
 --Explore Covid Vaccinations Table
 SELECT * 
 FROM `sql-covid-data-exploration.covid_data.covid_vaccinations` 
 Order By 3,4 
 LIMIT 1000
 
-- Select Data that we are going to be using 

 Select location,date, total_cases, new_cases, total_deaths, population
 from `sql-covid-data-exploration.covid_data.covid_deaths` 
 where continent is not null
 Order By 1,2
 limit 1000

 -- Looking at Total Cases vs Total Deaths
 -- Shows the probability of dying if you contract covid in your country

 Select location,date, total_cases, total_deaths, (total_deaths/total_cases) *100 as death_percentage
 from `sql-covid-data-exploration.covid_data.covid_deaths` 
 where location like '%States%'
 and continent is not null
 Order By 1,2

 -- Looking at Total Cases vs Population
 -- shows what percentage of population got covid

 Select location,date, population,total_cases, (total_cases/population) *100 as infected_percentage
 from `sql-covid-data-exploration.covid_data.covid_deaths` 
 where location like '%States%'
 and continent is not null
 Order By 1,2

-- Looking at countries with highest infection rate compared to population

Select location,population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population)) *100 as percent_population_infected
from `sql-covid-data-exploration.covid_data.covid_deaths`
--where location like '%Mexico%'
Group by location, population
order by percent_population_infected desc


-- Showing Countries with Highest Death Count Record per Population


Select location,population, MAX(total_deaths) as highest_deaths_count
from `sql-covid-data-exploration.covid_data.covid_deaths`
where continent is not null
--where location like '%Mexico%'
Group by 1,2
order by highest_deaths_count desc


-- Lets Break Things Down By Continent

-- Showing continents with highest death count 

Select continent, max(total_deaths) as total_deaths_count
from `sql-covid-data-exploration.covid_data.covid_deaths`
where continent is not null
Group by continent
order by total_deaths_count desc

-- Many new deaths counts were still not added in the previous query for every continent
-- The following query shows accurate death count of continents

SELECT location,sum(new_deaths) as new_total_deaths_count
  FROM `sql-covid-data-exploration.covid_data.covid_deaths` 
  where continent is null and location Not In ('World','European Union','International')
  group by location
  order by new_total_deaths_count desc 



-- Global Numbers
-- Shows global Death Percentage 

Select  sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, sum(new_deaths)/sum(new_cases)* 100 as death_percentage
from `sql-covid-data-exploration.covid_data.covid_deaths`
where continent is not null
order by 1,2


-- Using both tables to extract insights
-- This shows our base query of the Join we need to analyze both tables

Select *
From `sql-covid-data-exploration.covid_data.covid_deaths` as dea
Join `sql-covid-data-exploration.covid_data.covid_vaccinations` as vac
  On dea.location = vac.location
  and dea.date = vac.date
  limit 1000


-- Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(vac.new_vaccinations) Over (Partition by dea.location order by dea.location,
dea.date) as rolling_people_vaccinated
--,(rolling_people_vaccinated/population)*100
From `sql-covid-data-exploration.covid_data.covid_deaths` as dea
Join `sql-covid-data-exploration.covid_data.covid_vaccinations` as vac
  On dea.location = vac.location
  and dea.date = vac.date
  where dea.continent is not null
  order by 2,3

-- USING CTE

With population_vs_vaccinations 
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(vac.new_vaccinations) Over (Partition by dea.location order by dea.location,
dea.date) as rolling_people_vaccinated
--,(rolling_people_vaccinated/population)*100
From `sql-covid-data-exploration.covid_data.covid_deaths` as dea
Join `sql-covid-data-exploration.covid_data.covid_vaccinations` as vac
  On dea.location = vac.location
  and dea.date = vac.date
  where dea.continent is not null
  order by 2,3
)
Select *, (rolling_people_vaccinated/population)*100 as percentage_vaccinated
From population_vs_vaccinations


-- Or, we could USE TEMP TABLE

-- Use a random table name for the temporary table
CREATE Temporary TABLE  temp_percent_population_vaccinated (
  continent STRING,
  location STRING,
  date DATE,
  population NUMERIC,
  new_vaccinations NUMERIC,
  rolling_people_vaccinated NUMERIC
);

INSERT INTO temp_percent_population_vaccinated
SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM
  `sql-covid-data-exploration.covid_data.covid_deaths` AS dea
JOIN
  `sql-covid-data-exploration.covid_data.covid_vaccinations` AS vac
ON
  dea.location = vac.location
  AND dea.date = vac.date
WHERE
  dea.continent IS NOT NULL;

SELECT *,
  (rolling_people_vaccinated / population) * 100 AS percent_population_vaccinated
FROM
   temp_percent_population_vaccinated;

-- Drop the temporary table when no longer needed
DROP TABLE IF EXISTS temp_percent_population_vaccinated



 -- Creating View to store data for visualizatons later on 

 Create View `sql-covid-data-exploration.covid_data.temp_percent_population_vaccinated` as
SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM
  `sql-covid-data-exploration.covid_data.covid_deaths` AS dea
JOIN
  `sql-covid-data-exploration.covid_data.covid_vaccinations` AS vac
ON
  dea.location = vac.location
  AND dea.date = vac.date
WHERE
  dea.continent IS NOT NULL
