/*

COVID-19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

select * 
from Project..CovidDeaths
where continent is not null
order by 3,4

select * 
from Project..CovidVaccinations
order by 3,4


-- Select data to start with
select location, date, total_cases, new_cases, total_deaths, population
from Project..CovidDeaths
order by 1,2


 -- Shows the likelihood of dying if contacted COVID
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from Project..CovidDeaths
--where location like '%state%'
order by 1,2


 -- Shows the percentage of population infected by COVID
select location, date, total_cases, population, (total_cases/population)*100 as InfectedPercentage
from Project..CovidDeaths
--where location like '%state%'
order by 1,2


 -- Shows the country with highest infection rate per population
select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as InfectedPercentage
from Project..CovidDeaths
group by location, population
order by InfectedPercentage desc


select location, population, date, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as InfectedPercentage
from Project..CovidDeaths
group by location, population, date
order by InfectedPercentage desc


 -- Shows the country with the highest death count per population
select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from Project..CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc


 -- Shows the country with the highest death count per continent
select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from Project..CovidDeaths
where continent is not null 
and location not in ('World', 'European Union', 'International')
group by continent
order by TotalDeathCount desc


 -- Shows the global numbers
select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from Project..CovidDeaths
where continent is not null
order by 1,2


 -- Join both table
select * 
from Project..CovidDeaths dea
join Project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date


 -- Total Population vs Vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from Project..CovidDeaths dea
join Project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


 -- Show the population percentage that has received at least 1 vaccine
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(bigint, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from Project..CovidDeaths dea
join Project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


 -- Use CTE to perform calculation on partition by in previous query
With PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(bigint, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from Project..CovidDeaths dea
join Project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select *, (RollingPeopleVaccinated/population)*100
from PopVsVac


 -- Use Temp Table 
drop table if exists #VaccinatedPopulationPercentage
create table #VaccinatedPopulationPercentage
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
insert into #VaccinatedPopulationPercentage
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(bigint, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from Project..CovidDeaths dea
join Project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select *, (RollingPeopleVaccinated/population)*100
from #VaccinatedPopulationPercentage


 -- Create view to store data for visualizations
Create view VaccinatedPopulationPercentage as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(bigint, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from Project..CovidDeaths dea
join Project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date

select *
from VaccinatedPopulationPercentage

