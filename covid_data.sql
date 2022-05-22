select count(distinct(location)) from covid_data..coviddeaths


select sum(cast(total_deaths as float)) from covid_data..coviddeaths
where total_deaths is not null
group by location;

--severity percentage by country
select location,(sum(cast(total_deaths as bigint))/sum(total_cases))*100
from covid_data..coviddeaths
group by location
order by 1

--total cases by country

select location, max(total_cases) as Total_cases, max(total_deaths) as Total_deaths
from covid_data..coviddeaths
group by location
order by Total_cases 



--percentage of population infected with covid

select location, max(population) as population, max(total_cases) as total_cases, 
concat(round((max(total_cases)/max(population))*100, 2),'%') as infection_rate
from covid_data..coviddeaths
group by location
order by 2 desc


--percentage of casualty per country

select location, max(population) as population, max(total_deaths) as total_deaths_count, 
concat(round((max(total_deaths)/max(population))*100, 2),'%') as percentage_dead
from covid_data..coviddeaths
group by location
order by 2 desc


--combining tables covid_deaths and covid_vaccinations
select *
from covid_data..coviddeaths as d
join covid_data..covidvaccinations as v
on d.location=v.location and
d.date=v.date


--total vaccinations per country against the total cases

select 
d.location, max(v.date) as latest_date, max(population) as population, max(d.total_cases) as total_cases, 
max(v.total_vaccinations) as total_vaccinations
from covid_data..coviddeaths as d
join covid_data..covidvaccinations as v
on d.location=v.location and
d.date=v.date
group by d.location
order by total_cases desc


--vaccination data of france

select location, date, gdp_per_capita,
total_vaccinations, new_vaccinations
from covid_data..covidvaccinations
where location='France' and total_vaccinations is not null



--
select d.location, d.date, d.population, v.new_vaccinations, 
sum(cast(v.new_vaccinations as bigint)) over (partition by d.location) as cumulative_vaccination_count
from covid_data..coviddeaths as d
join covid_data..covidvaccinations as v
on d.location=v.location
and d.date=v.date
where d.location='france'


select d.location, max(v.total_vaccinations) from covid_data..coviddeaths as d
join covid_data..covidvaccinations as v
on d.location=v.location
where d.location='France'
group by d.location

--cumulative sum of new vaccinations per day per location

select d.location,d.date,d.population, v.new_vaccinations,
sum(cast(v.new_vaccinations as bigint)) over 
(partition by d.location order by d.location, d.date) as cumulative_vaccination_count
from covid_data..coviddeaths as d
join covid_data..covidvaccinations as v
on d.location=v.location
and d.date=v.date


--percentage of population vacccinated each 
select d.location, d.date, d.population, v.new_vaccinations, 
sum(cast(v.new_vaccinations as bigint)) over 
(partition by d.location order by d.location, d.date) as cumulative_vaccination_count
from covid_data..coviddeaths as d 
join covid_data..covidvaccinations as v
on d.date=v.date and d.location=v.location


--CTE (Cumulative vaccination count)


with VaccPerPop(location, Date,Population, new_vaccinations,Cumulative_vaccination_count)
as (
select d.location, d.date, d.population, v.new_vaccinations, 
sum(cast(v.new_vaccinations as bigint)) over (partition by d.location order by d.location, d.date ) as cumulative_vaccination_count
from covid_data..coviddeaths as d
join covid_data..covidvaccinations as v
on d.date=v.date and d.location =v.location
)
select  location, Date,(Cumulative_vaccination_count/Population)*100 as percentage_population_vaccinted_per_day
from VaccPerPop


--Total percent ofpopulation vaccinated

with VaccPerPop(location, Date,Population, new_vaccinations,Cumulative_vaccination_count)
as (
select d.location, d.date, d.population, v.new_vaccinations, 
sum(cast(v.new_vaccinations as bigint)) over (partition by d.location order by d.location, d.date ) as cumulative_vaccination_count
from covid_data..coviddeaths as d
join covid_data..covidvaccinations as v
on d.date=v.date and d.location =v.location
)

select location, max((Cumulative_vaccination_count/Population))*100 as percentage_population_vaccinted_per_day from VaccPerPop
group by location


--temp table

create table #PopulationVaccinated
(location nvarchar(200),
date datetime,
population numeric,
new_vaccination numeric,
cumulative_new_vaccinations numeric
)

Insert into #PopulationVaccinated
Select d.location, d.date, d.population, v.new_vaccinations, 
sum(cast(v.new_vaccinations as bigint)) over (partition by d.location order by d.location, d.date ) as cumulatice_new_vaccinations
from covid_data..coviddeaths as d
join covid_data..covidvaccinations as v
on d.date=v.date and d.location=v.location

select location, max((cumulative_new_vaccinations/population)*100), max(date)
from #PopulationVaccinated
group by location


--creating views for data visulation on tableau

create view PopulationVaccinated as 
Select d.location, d.date, d.population, v.new_vaccinations, 
sum(cast(v.new_vaccinations as bigint)) over (partition by d.location order by d.location, d.date ) as cumulatice_new_vaccinations
from covid_data..coviddeaths as d
join covid_data..covidvaccinations as v
on d.date=v.date and d.location=v.location


select * from PopulationVaccinated