clear
clear matrix
set more off
set matsize 800
set mem 200m
capture log close

	
	* This table makes the summary statistics, including the observed weather variation
	* We list the proportion of observations that are certain degree above/below average
	* 1) Raw
	* 2) After removing year FE
	* 3) After removing region * year FE
	
	* Degrees 
	* lOOK AT +- 0.25 degrees, +- 0.5 degrees, +- 0.75 +- 1 degrees, +- 1.25 degrees, +- 1.5 degrees
	
	
capture program drop makestars
program define makestars, rclass
	syntax , Pointest(real) PVal(real) [bdec(integer 3)]
	**** Formats the coefficient with stars
	****

	local fullfloat = `bdec' + 1
	
	local outstr = string(`pointest',"%`fullfloat'.`bdec'f")
	
	if `pval' <= 0.01 {
		local outstr = "`outstr'" + "***"
	}
	else if `pval' <= 0.05 {
		local outstr = "`outstr'" + "**"
	}
	else if `pval' <= 0.1 {
		local outstr = "`outstr'" + "*"
	}	
		
	return local coeff = "`outstr'"
		
end

global rfe = 1 /*1 for region*year, 2 for year only*/
global maineffectsonly = 0 /*1 to drop all interactions*/


* This sample is the sample of all countries 
* Init GDP is defined based on your first year in the data
* Must have at least 20 years of GDP data
use climate_panel, clear


  

* restrict to 2003
keep if year <= 2003

encode parent, g(parent_num)

gen lgdp=ln(rgdpl)

encode fips60_06, g(cc_num)
sort country_code year
tsset cc_num year

g lngdpwdi = ln(gdpLCU)

*calculate GDP growth
gen temp1 = l.lngdpwdi
gen g=lngdpwdi-temp1
replace g = g * 100 
drop temp1
summarize g

g lnag = ln(gdpWDIGDPAGR) 
g lnind = ln(gdpWDIGDPIND) 
g lninvest = ln(rgdpl*ki/100)

foreach X in ag ind gdpwdi invest {
	g g`X' = (ln`X' - l.ln`X')*100
}


* Drop if less than 20 yrs of GDP data
g tempnonmis = 1 if g != .
replace tempnonmis = 0 if g == .
bys fips60_06: egen tempsumnonmis = sum(tempnonmis)
drop if tempsumnonmis  < 20
	
* Make sure all subcomponents are non-missing in a given year
g misdum = 0
for any ag ind : replace misdum = 1 if gX == .
for any ag ind : replace gX = . if misdum == 1


preserve
keep if lnrgdpl_t0 < . 
bys fips60_06: keep if _n == 1 
xtile initgdpbin = ln(lnrgdpl_t0), nq(2)
keep fips60_06 initgdpbin
tempfile tempxtile
save `tempxtile',replace
restore

mmerge fips60_06 using `tempxtile', type(n:1)
tab initgdpbin, g(initxtilegdp)


preserve
keep if wtem50 < . 
bys fips60_06: keep if _n == 1 
xtile initwtem50bin = wtem50 , nq(2)
keep fips60_06 initwtem50bin
save `tempxtile',replace
restore

mmerge fips60_06 using `tempxtile', type(n:1)
tab initwtem50bin, g(initxtilewtem)

preserve
keep if year == 1995
sort fips60_06 year
by fips60_06: keep if _n == 1
g temp = gdpSHAREAG 
*replace temp = ag_share0 if temp == .
xtile initagshare1995 = ln(temp), nq(2)
replace initagshare1995 = . if gdpSHAREAG == .
keep fips60_06 initagshare1995 
tempfile tempxtile
save `tempxtile',replace
restore

mmerge fips60_06 using `tempxtile', type(n:1)
tab initagshare1995 , g(initxtileagshare)


tsset



foreach Y in wtem wpre  {
	gen `Y'Xlnrgdpl_t0 =`Y'*lnrgdpl_t0 
	for var initxtile*: gen `Y'_X =`Y'*X
		
	label var `Y'Xlnrgdpl_t0 "`Y'.*inital GDP pc"
	for var initxtile*: label var `Y'_X "`Y'* X"
}


capture {
	for var wtem* wpre*: g fdX = X - l.X \ label var fdX "Change in X"
	for var wtem* wpre*: g L1X = l1.X 
	for var wtem* wpre*: g L2X = l2.X 
	for var wtem* wpre*: g L3X = l3.X 
	for var wtem* wpre*: g L4X = l4.X 
	for var wtem* wpre*: g L5X = l5.X 
	for var wtem* wpre*: g L6X = l6.X 
	for var wtem* wpre*: g L7X = l7.X 
	for var wtem* wpre*: g L8X = l8.X 
	for var wtem* wpre*: g L9X = l9.X 
	for var wtem* wpre*: g L10X = l10.X
	 
}

	tab year, gen (yr)
local numyears = r(r) - 1


if $rfe == 1 {
	foreach X of num 1/`numyears' {
			foreach Y in MENA SSAF LAC WEOFF EECA SEAS {
				quietly gen RY`X'X`Y'=yr`X'*_`Y'
				quietly tab RY`X'X`Y'
			}
			quietly gen RYPX`X'=yr`X'*initxtilegdp1
		}
}
else if $rfe == 2 {
	foreach X of num 1/`numyears' {
			quietly gen RY`X'=yr`X'
			
		}
}


	for var wtem wpre: bys fips60_06: egen Xcountrymean = mean(X)
	for var wtem wpre: g X_withoutcountrymean = X-Xcountrymean 
	
	for var wtem wpre: bys year: egen tempX_yr = mean(X_withoutcountrymean)
	for var wtem wpre: g X_withoutcountryyr = X_withoutcountrymean - tempX_yr
	
	g region = 0
	replace region = 1 if _MENA == 1
	replace region = 2 if _SSAF == 1
	replace region = 3 if _LAC == 1
	replace region = 4 if _WEOFF == 1
	replace region = 5 if _EECA == 1
	replace region = 6 if _SEAS == 1

	egen regionyear = group(region year)
	for var wtem wpre: bys regionyear: egen tempX_regionyr = mean(X_withoutcountryyr)
	for var wtem wpre: g X_withoutcountryregionyr = X_withoutcountryyr - tempX_regionyr
	
	g outcategory = ""
	for num 1/8: g outcolX = . \ format outcolX %4.3f
	
	g tempnum = _n
	
	local row = 1
	
	replace outcategory = "Raw data" if tempnum == `row'
	
	for num .25 .5 .75 1 1.25 1.5 \ num 1/6: replace outcolY = X if tempnum == `row'
	
	local row = `row' + 1
	foreach varname of var wtem_withoutcountrymean wtem_withoutcountryyr wtem_withoutcountryregionyr {
		local column = 1 	
		qui count if `varname' != .
		local numobs = r(N)
		replace outcategory = "`varname'" if tempnum == `row'
		foreach thresh of num .25 .5 .75 1 1.25 1.5 {
			qui count if abs(`varname') >= `thresh' & `varname' != .
			local numabovethresh = r(N)
			local percentabovethresh = `numabovethresh' / `numobs'
			qui replace outcol`column' = `percentabovethresh' if tempnum == `row'
			local column = `column' + 1
		}
		local row = `row' + 1 
	}
	
	local row = `row' + 1
	for num 1 2 3 4 5 6 \ num 1/6: replace outcolY = X if tempnum == `row'
	
	local row = `row' + 1
	foreach varname of var wpre_withoutcountrymean wpre_withoutcountryyr wpre_withoutcountryregionyr {
		local column = 1 	
		qui count if `varname' != .
		local numobs = r(N)
		replace outcategory = "`varname'" if tempnum == `row'
		foreach thresh of num 1 2 3 4 5 6 {
			qui count if abs(`varname') >= `thresh' & `varname' != .
			local numabovethresh = r(N)
			local percentabovethresh = `numabovethresh' / `numobs'
			qui replace outcol`column' = `percentabovethresh' if tempnum == `row'
			local column = `column' + 1
		}
		local row = `row' + 1 
	}
	
	outsheet outcategory outcol? using table1.out if tempnum <= `row', replace
	

