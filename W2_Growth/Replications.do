************************
*** REPLICATION FILE
************************

* Harunobu Saijo, Jan Vogler

clear
*cd "C:\Users\Jan\OneDrive\Documents\GitHub\ps750\W2_Growth"
clear
cd "/Users/baika/Downloads/Replication_Files/Regressions"


************************
*** REPLICATION OF TABLE 1
************************
*This table uses a purely cross-sectional analysis using data from 2010 to establish that both natural resource exports and manufacturing/services are positively associated with urbanization

use gjv, clear 

*Regression (1)
xi: reg urbrate mfgserv_gdp2010 nrx2_mean [pw=pop] if year == 2010, robust
*Urbanization is regressed with OLS on manufactures as a percent of GDP in 2010, and the mean natural resource exports as percent of GDP from 1960 to 2010
*The regressions include weights by population and utilize  robust SEs

*Regression (2)
xi: reg urbrate mfgserv_gdp2010 nrx2_mean i.continent [pw=pop] if year == 2010, robust 
*This column runs the same regression as Table 1 (1) but adds FEs for continents. The magnitude of the coefficients goes down somewhat but the effect is still highly statistically significant. 
 
*Regression (3)
xi: reg urbrate mfgserv_gdp2010 nrx2_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*This column adds "time invariant" controls, to test for robustness 
*It adds possible proxies for policies that may raise urban wages outside of the mechanisms presented in the model through "urban-biased" policies, primacy2010 and auto
*These include primacy rate in 2010, or the ratio between the largest and second-largest city, an indicator for observations with POLITY IV scores lower than -5 for 2010 as a measure of regime type; POLITY classifies such regimes as either closed anocracy or autocracy. 
*To control for possible systematic differences in the way urbanization rates are calculated, the authors add controls for definitions of cities. "i.type" is a categorical variable that mutually exclusively and exhaustively categorizes each observation into administrative, threshold, threshold and administrative, and threshold plus condition.
*Furthermore, the interaction with i.threshold and threshold_level adds the actual magnitude of the threshold where such a threshold is used to define cities 
*the other controls are for area, population, and dummies for whether the country is a small island or not and one for landlocked countries
*To account for "pressures and disasters", conflict is added as a dummy variable for countries that experienced civil or interstate war since 1960, drought measures how many droughts there were per s	uare kilometer since 1960, and the r2density measures the annual population growth rate in 1960-2010 in percents as a "control for land pressure"

*Regression (4)
xi: reg urbrate mfgserv_gdp2010 nrx2_mean nrx1960 urbrate1960 primacy2010 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Column 4 adds "initial conditions" which are resource exports as a percent of GDP in 1960 (nrx1960) and the urbanization rate in 1960 (urbrate1960)

*Regression (5)
xi: reg urbrate mfgserv_gdp2010 nrx2_mean i.region nrx1960 urbrate1960 primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Column 5 adds region FEs which also means that the continent FEs added in column 2 are taken out 



************************
*** REPLICATION OF TABLE 2
************************
*To further test for robustness, the authors add more control variables. The results are robust to most but not all of these controls.  
use gjv, clear

*Panel A

*Regression (1)
xi: reg urbrate mfgserv_gdp2010 nrx2_mean i.region nrx1960 urbrate1960 primacy2010 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Baseline regression for comparison, same as Table 1, Regression 5 
*In the text the authors say that this is the same regression as Regression 5 but in Table 1 Regression 5, the area fixed effects are dropped, whereas here three of the i.regions are dropped instead, but the coefficient of interest does not change

*Regression (2)
xi: reg urbrate mfgserv_gdp2010 nrx2_mean i.region nrx1960 urbrate1960 gvtexp10 primacy2010 cerealy_mean citystate english french german spanish portuguese italian dutch belgian communist desert forest_area i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Additional control variables: km^2 of forested land (forest), dummies for countries with large deserts (desert) and for city states (citystate), dummy variables for colonial history by colonizer (english french german spanish portuguese italian dutch belgian), communist or ex-communist (communist), and share of government expenditures in GDP for 2010 to measure urban biased policies (gvtexp10)

*Regression (3)
xi: reg urbrate mfgserv_gdp2010 nrx2_mean i.region nrx1960 urbrate1960 primacy2010 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010 & (country != "China" & country != "India" & country != "China" & country != "India" & country != "Indonesia" & country != "Brazil" & country != "Pakistan" & country != "Nigeria" & country != "Bangladesh" & country != "Japan" & country != "Mexico"), robust
*Same specification as Table 1 Regression 5, but with observations dropped for countries with populations above 100 million (China, India, Indonesia, Brazil, Pakistan, Nigeria, Bangladesh, Japan, Mexico)

*Regression (4)
xi: reg urbrate mfgserv_gdp2010 nrx2_mean i.region nrx1960 urbrate1960 primacy2010 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought  if year == 2010, robust
*Same specification as Table 1 Regression 5, but without country weights

*Regression (5)
gen africamena = (continent == "Africa" | continent == "MENA")
xi: reg urbrate mfgserv_gdp2010 nrx2_mean i.region nrx1960 urbrate1960 primacy2010 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010 & africamena == 1, robust
*Same specification as Table 1 Regression 5, but only with Africa and MENA countries 

*Regression (6)
xi: reg urbrate mfgserv_gdp2010 nrx2_mean i.region nrx1960 urbrate1960 primacy2010 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010 & africamena == 0, robust
*Same specification as Table 1 Regression 5, but only with Asian and LAC countries

*The authors further test for robustness by using alternative definitions of key concepts
*Panel B

*Regression (1)
xi: reg urbrate mfgserv_gdp2010 nrx2010 i.region nrx1960 urbrate1960 primacy2010 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Replaces mean natural resource exports as percent of GDP from 1960 to 2010 with natural resource exports in 2010

*Regression (2)
xi: reg urbrate mfgserv_gdp2010 min_mean i.region nrx1960 urbrate1960 primacy2010 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Only considers average share of fuel and mineral exports as percent of GDP from 1960 to 2010 (excludes cash crops and forestry exports)

*Regression (3)
xi: reg urbrate mfgserv_gdp2010 nrx_mean i.region nrx1960 urbrate1960 primacy2010 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Includes agricultural exports (both subsistence and cash crops) when calculating resource exports as percent of GDP from 1960 to 2010

*Regression (4)
 xi: reg urbrate mfgserv_gdp2010 rrents_mean i.region nrx1960 urbrate1960 primacy2010 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Replaces mean natural resource exports as percent of GDP from 1960 to 2010 with resource rents as percent of GDP from 1960 to 2010 

*Regression (5)
xi: reg urbrate mfgserv_gdp2010 mfgx_mean nrx2_mean i.region nrx1960 urbrate1960 primacy2010 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Control for industrial and service exports as percent of GDP in 2010 replaced with industrial and service exports as percent of GDP averaged through 1960-2010 as proxy for industrialization

*Regression (6)
xi: reg urbrate lmfg_value2 lnrx_value2 primacy2010 urbrate1960 lnrx_value19602 i.region i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Uses log value mfg and service GDP in 2010 per capita instead of GDP shares as proxy for industrialization

*The authors test for heterogenous effects by disaggregating resource exports as percentage of GDP and then interacting it with a dummy variable for that country's primary export if it is one of those categories
*Categories are oil/gas, diamonds, gold/copper, other mineral product, and cocoa-forestry
*Panel C
xi: reg urbrate mfgserv_gdp2010 nrx2oilgas nrx2diam nrx2goldcopp nrx2otm nrx2coc nrx2ot i.region nrx1960 urbrate1960 primacy2010 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust



************************
*** REPLICATION OF TABLE 3
************************
*Panel analysis of the data with six periods (1960, 1970, 1980, 1990, 2000, 2010); estimate relationship between resource exports in the last period with urbanization (urbanization rate for that period) in the subsequent period
*All regressions have country and year FEs, SEs clustered at country level, still uses population weights
use gjv, clear

drop if country == "Bahamas" | country == "China, Macao SAR" | country == "Eritrea" | country == "Somalia"
*Countries dropped for missingness

*Regression (1)
xi: areg urbrate nrx_previous mfg_previous mfgserv_gdp2010t i.year [pw=pop] if (year == 1970 | year == 1980 | year == 1990 | year == 2000 | year == 2010), robust absorb(country) cluster(country)
*Urbanization rate regressed on natural resource exports of the previous period, manufactures and services in 2010 interacted with time trend, manufacturing exports of the previous period as percentage of GDP, with country and year FEs
 
*Regression (2)
xi: areg urbrate nrx_previous mfg_previous mfgserv_gdp2010t i.year i.continent*i.year [pw=pop] if (year == 1970 | year == 1980 | year == 1990 | year == 2000 | year == 2010), robust absorb(country) cluster(country)
*Includes area-year FEs (i.continent*i.year)

*Regression (3)
xi: areg urbrate nrx_previous mfg_previous mfgserv_gdp2010t i.year i.continent*i.year primacy_prev auto_prev drought_prev r2density_prev popgrowthrate_prev conflict_prev pop [pw=pop] if (year == 1970 | year == 1980 | year == 1990 | year == 2000 | year == 2010), robust absorb(country) cluster(country)
*Includes time-varying controls which are primacy in previous period (primacy_prev), dummy that is 1 when previous period was "mostly autocratic" (auto_prev), number of droughts per square km between the last period and the current period (drought_prev), "rural push factors" that include rural population density per arable land in 1000s (r2density_prev), population growth for previous period (popgrowth_prev), dummy variable that equals 1 if country has  experienced conflict since prevoius period (conflict_prev)

*Regression (4)
xi: areg urbrate nrx_previous mfg_previous mfgserv_gdp2010t i.year i.continent*i.year primacy_prev nrx1960t urbrate1960t auto_prev drought_prev r2density_prev pop popgrowthrate_prev conflict_prev [pw=pop] if (year == 1970 | year == 1980 | year == 1990 | year == 2000 | year == 2010), robust absorb(country) cluster(country)
*Controls for initial conditions which are natural resource exports in 1960 and urbanization rate in 1960, each interacted with the time trend to allow the effect to vary between periods

*Regression (5)
xi: areg urbrate nrx_previous mfg_previous mfgserv_gdp2010t i.year i.continent*i.year primacy_prev i.year*i.region nrx1960t urbrate1960t auto_prev drought_prev pop r2density_prev popgrowthrate_prev conflict_prev [pw=pop] if (year == 1970 | year == 1980 | year == 1990 | year == 2000 | year == 2010), robust absorb(country) cluster(country)
*Adds region FEs interacted with year FEs which controls for time-variant trends within the region; regions finer than areas used in regression 2



************************
*** REPLICATION OF TABLE 4
************************
*Further investigation of causality using same panel structure as used in Table 3 
use gjv, clear

drop if country == "Bahamas" | country == "China, Macao SAR" | country == "Eritrea" | country == "Somalia"
*Countries dropped for missingness

*Regression (1)
xi: areg urbrate nrx_previous mfg_previous mfgserv_gdp2010t i.year i.continent*i.year primacy_prev i.year*i.region nrx1960t urbrate1960t auto_prev drought_prev pop r2density_prev popgrowthrate_prev conflict_prev [pw=pop] if (year == 1970 | year == 1980 | year == 1990 | year == 2000 | year == 2010), robust absorb(country) cluster(country)
*Same as Table 3 Regression 1

*Regression (2)
xi: areg nrx2_x_gdp nrx_previous mfg_previous mfgserv_gdp2010t i.year i.continent*i.year primacy_prev i.year*i.region nrx1960t urbrate1960t auto_prev drought_prev pop r2density_prev popgrowthrate_prev conflict_prev [pw=pop] if (year == 1970 | year == 1980 | year == 1990 | year == 2000 | year == 2010), robust absorb(country) cluster(country)
*Effect of natural resource exports from the previous period on urbanization in the next period, no significant effect as commodity prices are volatile while urbanization relatively steady

*Regression (3)
xi: areg nrx2_x_gdp urb_previous mfg_previous mfgserv_gdp2010t i.year i.continent*i.year primacy_prev i.year*i.region nrx1960t urbrate1960t auto_prev drought_prev pop r2density_prev popgrowthrate_prev conflict_prev [pw=pop] if (year == 1970 | year == 1980 | year == 1990 | year == 2000 | year == 2010), robust absorb(country) cluster(country)
*Effect of urbanization in the previous period on current natural resource exports, no significant effect

*Regression (4)
xi: areg urbrate nrx2_x_gdp mfg_previous mfgserv_gdp2010t i.year i.continent*i.year primacy_prev i.year*i.region nrx1960t urbrate1960t auto_prev drought_prev pop r2density_prev popgrowthrate_prev conflict_prev [pw=pop] if (year == 1970 | year == 1980 | year == 1990 | year == 2000 | year == 2010), robust absorb(country) cluster(country)
*Effect of current natural resource exports on current urbanization rate, no significant effect 

*Regression (5)
xi: ivreg2 urbrate (nrx_previous = discov_post comm_p) mfg_previous mfgserv_gdp2010t nrx1960t urbrate1960t i.year i.region*i.year i.continent*i.year primacy_prev auto_prev drought_prev r2density_prev popgrowthrate_prev conflict_prev pop i.country [pw=pop] if (year == 1970 | year == 1980 | year == 1990 | year == 2000 | year == 2010), robust cluster(country) first
*Instrumental variable to estimate causal effect of natural resources on urbanization rate; nrx_previous is used as an instrument, a dummy variable for all observations where natural resources have been discovered, comm_p is a variable for price shocks also used as such

*Regression (6)
xi: ivreg2 urbrate (nrx_previous = discov_post comm_p) mfg_previous mfgserv_gdp2010t nrx1960t urbrate1960t i.year i.region*i.year i.continent*i.year primacy_prev auto_prev drought_prev r2density_prev popgrowthrate_prev conflict_prev pop i.country [pw=pop] if (year == 1970 | year == 1980 | year == 1990 | year == 2000 | year == 2010) & nrx2_mean > 10, robust cluster(country) first
*same as above but restricted to countries whose natural resource exports as percent of GDP has been, on average, been above ten percent



************************
*** REPLICATION OF TABLE 5
************************
*Looking at the consequences of resource-led urbanization using cross-sectional data, controls same as in table 1
use gjv, clear

*Regression (1)
xi: reg lpcgdp_mean mfgserv_gdp2010 nrx2_mean i.region primacy2010 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Estimates effect of natural resource exports (nrx2_mean) on mean log gdp/capita (lpcgdp_mean) holding constant the level of manufactures and services  (mfgserv_gdp2010)

*Regression (2)
xi: reg urbrate mfgserv_gdp2010 nrx2_mean i.region primacy2010 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Looks at the effect of resource exports on urbanization rate

*Regression (3)
xi: reg urbrate lpcgdp_mean mfgserv_gdp2010 nrx2_mean i.region primacy2010 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Adds income as control variale to regression 2

*Regression (4)
 xi: reg food00s_2 mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.region primacy2010 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Estimate effect of resource exports (nrx2_mean) on food imports (food00s_2), controlling for urbanization and income per capita with area and region FEs

*Regression (5)
xi: reg mfg00s_2 mfgserv_gdp2010 nrx2_mean urbrate primacy2010 lpcgdp_mean i.continent i.region i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Estimate effect of resource exports on manufactures imports (mfg00s_2), controlling for urbanization and income per capita with area and region FEs

*Regression (6)
xi: reg servm00s mfgserv_gdp2010 nrx2_mean urbrate primacy2010 lpcgdp_mean i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Estimate effect of resource exports on service imports (servm00s)



************************
*** REPLICATION OF TABLE 6
************************
*Similar setup as table 5, only now the DV is composition of urban employment, Panel A includes area FE and Panel B includes region FE 
*Errors are robust SE and population weighted
use gjv, clear

*Column (1)
*Panel A
xi: reg manfire_u mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust

*Panel B
xi: reg manfire_u mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.region i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Estimates effect of natural resource exports on employment share of manufactures and FIRE sectors

*Column (2)
*Panel A
xi: reg wrtupsutscu mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust

*Panel B
xi: reg wrtupsutscu mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.region i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Estimates effect of natural resource exports and manufactures and services as percentage of GDP on employment share of commerce and personal services

*Column (3)
*Panel A
xi: reg gsu mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust

*Panel B
xi: reg gsu mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Estimates effect of natural resource exports and manufactures and services as percentage of GDP on employment share of government services

*Column (4)
*Panel A
xi: reg manfire_c mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust

*Panel B
xi: reg manfire_c mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.region i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Estimates effect of natural resource exports and manufactures and services as percentage of GDP on employment share of manufactures and FIRE sectors, in the largest city 

keep if year == 2010

*Column (5)
*Panel A
xi: reg lmfg_prod mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust

*Panel B
xi: reg lmfg_prod mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Estimates effect of natural resource exports and manufactures and services as percentage of GDP on labor producitivity in manufacturing (lmfg_prod) 

*Column (6)
*Panel A
xi: reg lserv_prod mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust

*Panel B
xi: reg lserv_prod mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Estimates effect of natural resource exports and manufactures and services as percentage of GDP on labor producitivity in services(lmfg_serv) 



************************
*** REPLICATION OF TABLE 7
************************
*Similar setup as table 6, Panel A includes area FE and Panel B includes region FE; estimates marginal  effects of resource exports and manufacturing/services on city outcomes 
use gjv, clear

*Column (1)
*Panel A
xi: reg gini mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust

*Panel B
xi: reg gini mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Estimates effect of natural resource exports and manufactures and services as percentage of GDP on total GINI

*Column (2)
*Panel A
xi: reg ugini mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust

*Panel B
xi: reg ugini mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Estimates effect of natural resource exports and manufactures and services as percentage of GDP on urban GINI

*Column (3)
*Panel A
xi: reg primacy2010 urbrate lpcgdp_mean mfgserv_gdp2010 nrx2_mean i.continent primacy1960 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust

*Panel B
xi: reg primacy2010 urbrate lpcgdp_mean mfgserv_gdp2010 nrx2_mean i.region primacy1960 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Estimates effect of natural resource exports and manufactures and services as percentage of GDP on urban primacy rate based on the largest city (ratio of largest to second largest city)

*Column (4)
*Panel A
xi: reg primfive urbrate lpcgdp_mean mfgserv_gdp2010 nrx2_mean i.continent primacy1960 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust

*Panel B
xi: reg primfive urbrate lpcgdp_mean mfgserv_gdp2010 nrx2_mean i.region primacy1960 i.continent i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Estimates effect of natural resource exports and manufactures and services as percentage of GDP on primacy based on the five largest cities

*Column (5)
*Panel A
xi: reg yrs_educ mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust

*Panel B
xi: reg yrs_educ mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.region i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010 & ccode != "QAT", robust
*Estimates effect of natural resource exports and manufactures and services as percentage of GDP on years of education

*Column (6)
*Panel A
xi: reg returns_immi mfgserv_gdp2010 nrx2_mean urbrate n_immig lpcgdp_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust

*Panel B
xi: reg returns_immi mfgserv_gdp2010 nrx2_mean urbrate n_immig lpcgdp_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Estimates effect of natural resource exports and manufactures and services as percentage of GDP on returns to education

*Column (7)
*Panel A
xi: reg expatistan mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust

*Panel B
xi: reg expatistan mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
*Estimates effect of natural resource exports and manufactures and services as percentage of GDP on expat price index in the largest city



************************
*** REPLICATION OF TABLE 8
************************
*Similar setup as table 5, only now the DV is composition of urban employment
*Errors are robust SE and population weighted
*Panel A runs area FEs
*Panel B runs the same model as Table 5 Regression 6 with region FEs
*Panel C controls for mean income 1960-2010 and the urbanization rate in 2010
use gjv, clear

*Regression (1)
xi: reg urbanp1 mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) replace
test mfgserv-nrx = 0

xi: reg urbanp1 mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
test mfgserv-nrx = 0

xi: reg urbanp1 mfgserv_gdp2010 nrx2_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
*DV is urban poverty headcount ratio

*Regression (2)
xi: reg urbanp2 mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
test mfgserv-nrx = 0

xi: reg urbanp2 mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
test mfgserv-nrx = 0

xi: reg urbanp2 mfgserv_gdp2010 nrx2_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
*DV is % urban poverty gap 

*Regression (3)
xi: reg slum mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
test mfgserv-nrx = 0

xi: reg slum mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
test mfgserv-nrx = 0

xi: reg slum mfgserv_gdp2010 nrx2_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
*DV is % slum share

*Regression (4)
xi: reg urban_water mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
test mfgserv-nrx = 0

xi: reg urban_water mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
test mfgserv-nrx = 0

xi: reg urban_water mfgserv_gdp2010 nrx2_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
*DV is % of urban population with improved water source

*Regression (5)
xi: reg urban_sani mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
test mfgserv-nrx = 0

xi: reg urban_sani mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
test mfgserv-nrx = 0

xi: reg urban_sani mfgserv_gdp2010 nrx2_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
*DV is % of urban population with improved sanitation facilities

*Regression (6)
xi: reg sufficien mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
test mfgserv-nrx = 0

xi: reg sufficien mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
test mfgserv-nrx = 0

xi: reg sufficien mfgserv_gdp2010 nrx2_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
*DV is % of urban population with sufficient living area

*Regression (7)
xi: reg nonufuels mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.continent primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
test mfgserv-nrx = 0

xi: reg nonufuels mfgserv_gdp2010 nrx2_mean urbrate lpcgdp_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
test mfgserv-nrx = 0

xi: reg nonufuels mfgserv_gdp2010 nrx2_mean i.region primacy2010 i.type i.threshold|threshold_level smallisland area r2density popgrowthrate pop auto conflict landlocked drought [pw=pop] if year == 2010, robust
outreg2 nrx2_mean mfgserv_gdp2010 lpcgdp_mean urbrate using table_8.xls, se nocons coefastr bdec(2) adjr2 noni nolabel bracket title(Effect, "") nonotes addnote("", Robust standard errors clustered at the district level in parentheses, * significant at 10%; ** significant at 5%; *** significant at 1%) append
*DV is % of urban population  with non-solid fuels as energy
