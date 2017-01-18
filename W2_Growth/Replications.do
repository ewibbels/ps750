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
*All regressions have country and year FEs 

drop if country == "Bahamas" | country == "China, Macao SAR" | country == "Eritrea" | country == "Somalia"
*Countries dropped for missingness

*Regression (1)

 
