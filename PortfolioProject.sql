
--DATA EXPLORATION

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

----------------------------------------------
--DATA CLEANING

Select *
From PortfolioProject..NashvilleHousing

--Standardize Data Format

Select SaleDate, CONVERT(Date,SaleDate)
From PortfolioProject..NashvilleHousing

ALTER TABLE [PortfolioProject].[dbo].[NashvilleHousing]
ADD SaleDateConverted Date

Update [PortfolioProject].[dbo].[NashvilleHousing]
SET SaleDateConverted = CONVERT(Date,SaleDate)

Select SaleDateConverted, CONVERT(Date,SaleDate)
From PortfolioProject..NashvilleHousing

--Populate Property Address Data

Select *
From PortfolioProject..NashvilleHousing
Order By ParcelID --ParcelID ve Property Address ayný satýrlar var.


Select a.ParcelId, a.PropertyAddress, b.ParcelId, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject..NashvilleHousing a
Join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject..NashvilleHousing a
Join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null

-- Breaking out PropertyAddress into Individual Columns (PropertySplitAddress, PropertySplitCity)
Select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
	,SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address
From PortfolioProject..NashvilleHousing 


ALTER TABLE [PortfolioProject].[dbo].[NashvilleHousing]
ADD PropertySplitAddress nvarchar(255);

Update [PortfolioProject].[dbo].[NashvilleHousing]
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)


ALTER TABLE [PortfolioProject].[dbo].[NashvilleHousing]
ADD PropertySplitCity nvarchar(255);

Update [PortfolioProject].[dbo].[NashvilleHousing]
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


-- Breaking out OwnerAddress into Individual Columns (OwnerAddress, OwnerCity, OwnerState)
Select *
From PortfolioProject..NashvilleHousing

Select 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
From PortfolioProject..NashvilleHousing


ALTER TABLE [PortfolioProject].[dbo].[NashvilleHousing]
ADD OwnerAddress nvarchar(255);

Update [PortfolioProject].[dbo].[NashvilleHousing]
SET OwnerAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)


ALTER TABLE [PortfolioProject].[dbo].[NashvilleHousing]
ADD OwnerCity nvarchar(255);

Update [PortfolioProject].[dbo].[NashvilleHousing]
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)


ALTER TABLE [PortfolioProject].[dbo].[NashvilleHousing]
ADD OwnerState nvarchar(255);

Update [PortfolioProject].[dbo].[NashvilleHousing]
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


-- Change Y and N to Yes and No in "SoldAsVacant" field
Select * 
From PortfolioProject..NashvilleHousing


Select Distinct(SoldAsVacant), COUNT(SoldAsVacant)
From PortfolioProject..NashvilleHousing
Group By SoldAsVacant
Order By 2


Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' Then 'Yes'
       When SoldAsVacant = 'N' Then 'No'
	   Else SoldAsVacant
	   END 
From PortfolioProject..NashvilleHousing

Update [PortfolioProject].[dbo].[NashvilleHousing]
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' Then 'Yes'
						When SoldAsVacant = 'N' Then 'No'
						Else SoldAsVacant
						END 
	
Select Distinct(SoldAsVacant), COUNT(SoldAsVacant)
From PortfolioProject..NashvilleHousing
Group By SoldAsVacant
Order By 2


--Remove Duplicates

Select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 ORDER BY UniqueId
				 ) row_num
From PortfolioProject..NashvilleHousing
Order By ParcelID

--With CTE
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 ORDER BY UniqueId
				 ) row_num
From PortfolioProject..NashvilleHousing
)

--DELETE
--From RowNumCTE
--Where row_num > 1 
	
Select *
From RowNumCTE
Where row_num > 1 
Order By ParcelID

--Delete Unused Columns

Select *
From PortfolioProject..NashvilleHousing

ALTER TABLE [PortfolioProject].[dbo].[NashvilleHousing]
DROP COLUMN  PropertyAddress, SaleDate, OwnerAddress, TaxDistrict

Select *
From PortfolioProject..NashvilleHousing

