
Select *
From PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4

Select *
From PortfolioProject..CovidVaccinations
order by 3,4

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
Order By 1,2

---- Total Cases vs Total Deaths

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%Turkey%' and continent is not null
Order By 1,2

---- Total Cases vs Population

Select Location, date, total_cases, population, (total_cases/population)*100 as CasePercentage
From PortfolioProject..CovidDeaths
Where location like '%Turkey%' and continent is not null
Order By 1,2

-- Countries with Highest Infection Rate compared to Population

Select Location, MAX(total_cases) as HighestInfectedCount, population, MAX((total_cases/population))*100 as PercentPopuationInfected 
From PortfolioProject..CovidDeaths
Where continent is not null
--Where location like '%Turkey%'
Group By location, population
Order By PercentPopuationInfected DESC

-- Countries with Highest Death Count per Population

Select Location, MAX(CAST(total_deaths as int)) as TotalDeathCount 
From PortfolioProject..CovidDeaths
--Where location like '%Turkey%'
Where continent is not null
Group By location
Order By TotalDeathCount DESC

-- Contintents with the highest death count per population

Select continent, max(cast(total_deaths as int)) as TotalDeathCount 
From PortfolioProject..CovidDeaths
--Where location like '%Turkey%'
Where continent is not null
Group By continent
Order By TotalDeathCount DESC

-- GLOBAL NUMBERS

Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths
, SUM(cast(new_deaths as int))/SUM(new_cases) as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
--Group By date
Order By 1,2

---------------------------------------------------
-- Total Population vs Vaccinations
-- Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition By dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null 
--and dea.location like '%Turkey%'
Order By 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopulationVsVaccinated(Continent, Location, Date, Popuation, New_Vaccinations, RollingPeopleVaccinated)
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition By dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null 
--and dea.location like '%Turkey%'
--Order By 2,3
)
Select *, (RollingPeopleVaccinated/Popuation)*100
From PopulationVsVaccinated


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated 
(
Continent nvarchar(255),
Location nvarchar(255), 
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition By dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null 
--and dea.location like '%Turkey%'
--Order By 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition By dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null 
--and dea.location like '%Turkey%'
--Order By 2,3

Select *
From PercentPopulationVaccinated