clear
clear matrix
clear mata
set more off
set matsize 800
set mem 200m
capture log close

*************************
***----WDI sample
*************************

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
*to take care of serial correlation

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

*--Create a region x year variable for clustering

g region=""
foreach X in _MENA   _SSAF   _LAC    _WEOFF  _EECA _SEAS {
	replace region="`X'" if `X'==1
}

g regionyear=region+string(year)
encode regionyear, g(rynum)	


*--column 1

cgmreg g wtem RY* i.cc_num, cluster(parent_num rynum)
outreg2 wtem using Table2cluster, excel less(0) nocons bdec(3) replace title("Logs")

if $maineffectsonly != 1 {

*Column2
cgmreg g wtem wtem_initxtilegdp1 RY* i.cc_num, cluster(parent_num rynum)

lincom wtem + wtem_initxtilegdp1
local temeffectpoor_coeff = r(estimate)
local temeffectpoor_se= r(se)
test wtem + wtem_initxtilegdp1 = 0
local temeffectpoor_p = r(p)
	
outreg2 wtem wtem_initxtilegdp1 using Table2cluster, excel less(0) nocons bdec(3)  append adec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p')


*Column 3
cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1 RY* i.cc_num, cluster(parent_num rynum)

lincom wtem + wtem_initxtilegdp1
local temeffectpoor_coeff = r(estimate)
local temeffectpoor_se= r(se)
test wtem + wtem_initxtilegdp1 = 0
local temeffectpoor_p = r(p)

lincom wpre + wpre_initxtilegdp1
local preeffectpoor_coeff = r(estimate)
local preeffectpoor_se= r(se)
test wpre + wpre_initxtilegdp1 = 0
local preeffectpoor_p = r(p)
			
outreg2 wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  using Table2cluster, excel less(0) nocons bdec(3)  append adec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p',"Pre effect on poor countries",`preeffectpoor_coeff',"SE2",`preeffectpoor_se',"p2", `preeffectpoor_p')


*Column 4

cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1 wtem_initxtilewtem2 wpre_initxtilewtem2 RY* i.cc_num, cluster(parent_num rynum)

lincom wtem + wtem_initxtilegdp1
local temeffectpoor_coeff = r(estimate)
local temeffectpoor_se= r(se)
test wtem + wtem_initxtilegdp1 = 0
local temeffectpoor_p = r(p)

lincom wpre + wpre_initxtilegdp1
local preeffectpoor_coeff = r(estimate)
local preeffectpoor_se= r(se)
test wpre + wpre_initxtilegdp1 = 0
local preeffectpoor_p = r(p)
	
	
outreg2 wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1 wtem_initxtilewtem2 wpre_initxtilewtem2 using Table2cluster, excel less(0) nocons bdec(3)  append adec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p',"Pre effect on poor countries",`preeffectpoor_coeff',"SE2",`preeffectpoor_se',"p2", `preeffectpoor_p')


*Column 5
cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1 wtem_initxtileagshare2 wpre_initxtileagshare2 RY* i.cc_num, cluster(parent_num rynum)

lincom wtem + wtem_initxtilegdp1
local temeffectpoor_coeff = r(estimate)
local temeffectpoor_se= r(se)
test wtem + wtem_initxtilegdp1 = 0
local temeffectpoor_p = r(p)

lincom wpre + wpre_initxtilegdp1
local preeffectpoor_coeff = r(estimate)
local preeffectpoor_se= r(se)
test wpre + wpre_initxtilegdp1 = 0
local preeffectpoor_p = r(p)
	
	
outreg2 wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1 wtem_initxtileagshare2 wpre_initxtileagshare2 using Table2cluster, excel less(0) nocons bdec(3)  append adec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p',"Pre effect on poor countries",`preeffectpoor_coeff',"SE2",`preeffectpoor_se',"p2", `preeffectpoor_p')

}

