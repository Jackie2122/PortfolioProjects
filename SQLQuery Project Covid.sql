select *
from CovidDeaths
order by 3,4

--select *
--from CovidVaccinations
--order by 3,4


-- select data to use
select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
where continent is not null
order by 1,2


-- looking at total cases vs total deaths
-- showing chance of death if contact Covid in a country
select location, date, total_cases, new_cases, total_deaths, (CONVERT(FLOAT,total_deaths)/CONVERT(FLOAT,total_cases))*100 as death_percentage
from CovidDeaths
where location = 'China'
order by 1,2 


--looking at total cases vs population
--showing percentage of population got Covid
select location, date, CONVERT(FLOAT,total_cases), population , (CONVERT(FLOAT,total_cases)/population)*100 as case_percentage
from CovidDeaths
where location = 'China'
order by 1,2


--looking at countries with highest infection rate compared to population
select location, population,max(CONVERT(FLOAT,total_cases)) as highest_total_cases, max(CONVERT(FLOAT,total_cases))/population*100 as highestInfectionRate
from CovidDeaths
where continent is not null
group by location, population
order by highestInfectionRate desc


--looking at countries with highest death count
select location, max(CONVERT(FLOAT,total_deaths)) as total_deaths_count
from CovidDeaths
where continent is not null
group by location
order by total_deaths_count desc


--looking at continent with highest death count
select location, max(CONVERT(FLOAT,total_deaths)) as total_deaths_count
from CovidDeaths
where continent is null and location not in ('High income','Upper middle income','Lower middle income','Low income')
group by location
order by total_deaths_count desc


--globle numbers
select  date, sum(new_cases) as globle_cases_per_day, sum(new_deaths) as globle_death_per_day,
    case when sum(new_cases) <> 0 THEN sum(new_deaths)/sum(new_cases)
	else NULL 
	end as death_rate_per_day
from CovidDeaths
where continent is not null
group by date
order by death_rate_per_day desc

select sum(new_cases) as globle_cases_per_day, sum(new_deaths) as globle_death_per_day,
    case when sum(new_cases) <> 0 THEN sum(new_deaths)/sum(new_cases)
	else NULL 
	end as death_rate_per_day
from CovidDeaths
where continent is not null
order by death_rate_per_day desc


select *
from CovidVaccinations

-- looking at total population vs vaccinations

select Dea.continent, Dea.location, Dea.date, dea.population, vac.new_vaccinations, sum(convert(float,vac.new_vaccinations)) over (partition by Dea.location order by Dea.location, Dea.date) as rolling_people_vaccinated
from CovidDeaths Dea
join CovidVaccinations Vac
    on Dea.location = Vac.location
	and Dea.date = Vac.date
where Dea.continent is not null and Dea.location = 'Singapore'
group by Dea.continent, Dea.location, Dea.date, dea.population, vac.new_vaccinations
order by 2,3



--looking vaccination_rate compared to population in each country(dose per person)
--use CTE
with CTE_popvsvac(continent, location, date, population, rolling_people_vaccinated) as
(select Dea.continent, Dea.location, Dea.date, dea.population,sum(convert(float,vac.new_vaccinations)) over (partition by Dea.location order by Dea.location, Dea.date) as rolling_people_vaccinated
from CovidDeaths Dea
join CovidVaccinations Vac
    on Dea.location = Vac.location
	and Dea.date = Vac.date
where Dea.continent is not null
group by Dea.continent, Dea.location, Dea.date, dea.population, vac.new_vaccinations
)

select location, population,max(rolling_people_vaccinated)/population as vaccination_rate
from CTE_popvsvac
group by location, population
order by vaccination_rate desc

--use temp table
drop table if exists vaccination_rate_dose_per_person
create table vaccination_rate_dose_per_person
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
vaccinations numeric,
rolling_people_vaccinated numeric)

insert into vaccination_rate_dose_per_person
select Dea.continent, Dea.location, Dea.date, dea.population, convert(float,vac.new_vaccinations), sum(convert(float,vac.new_vaccinations)) over (partition by Dea.location order by Dea.location, Dea.date) as rolling_people_vaccinated
from CovidDeaths Dea
join CovidVaccinations Vac
    on Dea.location = Vac.location
	and Dea.date = Vac.date
where Dea.continent is not null
group by Dea.continent, Dea.location, Dea.date, dea.population, convert(float,vac.new_vaccinations)


select *, rolling_people_vaccinated/population as vaccination_rate
from vaccination_rate_dose_per_person


--Creating view to share data for later visualizations
drop table if exists vaccination_rate_dose_per_person;

create view vaccination_rate_dose_per_person as
select Dea.continent, Dea.location, Dea.date, dea.population, convert(float,vac.new_vaccinations) as new_vaccinations , sum(convert(float,vac.new_vaccinations)) over (partition by Dea.location order by Dea.location, Dea.date) as rolling_people_vaccinated
from CovidDeaths Dea
join CovidVaccinations Vac
    on Dea.location = Vac.location
	and Dea.date = Vac.date
where Dea.continent is not null

select *
from vaccination_rate_dose_per_person