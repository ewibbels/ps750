clear
clear matrix
clear mata
set more off
set matsize 800
set mem 200m
capture log close

capture program drop createsamplemain
program define createsamplemain

	* Get the new investment data from the WDI
	insheet using WDIinvest.csv, comma clear
	reshape long v, i(countrycode countryname) j(year)
	rename countrycode country_code
	rename v WDIinvest
	drop if country_code==""
	sort country_code year
	save temp, replace

	* This sample is the sample of all countries 
	* Init GDP is defined based on your first year in the data
	* Must have at least 20 years of GDP data
	use climate_panel, clear
	mmerge country_code year using temp, type(n:1)
	drop if _merge==2 /*in WB data but not in our climate data set - many are not countries; others are outside our sample period*/
	drop _merge
	
	* restrict to 2003
	keep if year <= 2003
	
	encode parent, g(parent_num)
	
	* Generate log GDP
	gen lgdppwt=ln(rgdpl)
	g lngdpwdi = ln(gdpLCU)
	
	encode fips60_06, g(cc_num)
	sort country_code year
	tsset cc_num year
		
	*calculate GDP growth (WDI)
	gen temp1 = l.lngdpwdi
	gen g=lngdpwdi-temp1
	replace g = g * 100 
	drop temp1
	summarize g

	*calculate GDP growth (PWT)
	gen temp1 = l.lgdppwt
	gen gpwt=lgdppwt-temp1
	replace gpwt = gpwt * 100 
	drop temp1
	summarize gpwt
		
	g lnag = ln(gdpWDIGDPAGR) 
	g lnind = ln(gdpWDIGDPIND) 
		g lninvest = ln(WDIinvest)
	
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

	* Generate initial income bins
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
	
	* Generate initial temperature bins
	preserve
	keep if wtem50 < . 
	bys fips60_06: keep if _n == 1 
	xtile initwtem50bin = wtem50 , nq(2)
	keep fips60_06 initwtem50bin
	save `tempxtile',replace
	restore
	
	mmerge fips60_06 using `tempxtile', type(n:1)
	tab initwtem50bin, g(initxtilewtem)
	
	* Generate initial ag share bins
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

	*generate lags
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
	
	*generate region x year FE
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
	foreach X in _MENA   _SSAF   _LAC    _WEOFF  _EECA   _SEAS {
		replace region="`X'" if `X'==1
	}
	
	g regionyear=region+string(year)
	encode regionyear, g(rynum)		
end


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


capture program drop maketable5
program define maketable5
	syntax anything(name=filename)

	g rowtitle = ""
	for num 1/25: g outcolX = ""
	g indexnum = _n
	
	replace rowtitle = "Immediate effects" if indexnum == 1
	replace rowtitle = "Tem year 1 effect -- poor" if indexnum == 2
	replace rowtitle = "Tem year 1 effect -- rich" if indexnum == 4
	replace rowtitle = "Pre year 1 effect -- poor" if indexnum == 6
	replace rowtitle = "Pre year 1 effect -- rich" if indexnum == 8
	replace rowtitle = "Num obs." if indexnum == 10
	
	replace rowtitle = "Growth effects" if indexnum == 11
	replace rowtitle = "Tem growth effect -- poor" if indexnum == 12
	replace rowtitle = "Tem growth effect -- rich" if indexnum == 14
	replace rowtitle = "Tem year 1 effect -- poor" if indexnum == 16
	replace rowtitle = "Tem year 1 effect -- rich" if indexnum == 18
	replace rowtitle = "Pre growth effect -- poor" if indexnum == 20
	replace rowtitle = "Pre growth effect -- rich" if indexnum == 22
	replace rowtitle = "Pre immed. effect -- poor" if indexnum == 24
	replace rowtitle = "Pre immed. effect -- rich" if indexnum == 26
	
	replace rowtitle = "Num obs." if indexnum == 28
	
	* This table produces robustness versions of the main effects, the 1-lag growth efefcts 
	
	* Column 1: Agriculture
	local colnum = 1
	label var outcol`colnum' "Agriculture"
	
	* No lags
	cgmreg gag wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 10
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 3
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 2
	
	* Tem - rich
	lincom wtem 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 5
	local pe = r(estimate)
	test wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 4
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 7
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 6
	
	* Pre - rich
	lincom wpre 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 9
	local pe = r(estimate)
	test wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 8
	
	
	************************
	* 1 lags
	
	local colnum = 1
	cgmreg gag wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 28
	
	*** Growth effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 13
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 12
	
	* Tem - rich
	lincom wtem + L1wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 15
	local pe = r(estimate)
	test wtem + L1wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 14
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 21
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 20
	
	* Pre - rich
	lincom wpre  + L1wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wpre + L1wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	
	**** Year 1 effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Tem - rich
	lincom wtem 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - rich
	lincom wpre 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	
	
	
	
	*****************************
	* 3 lags
	*****************************
	local colnum = 2
	
	cgmreg gag wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1   RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 28
	
	*** Growth effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1  + L2wtem + L2wtem_initxtilegdp1  + L3wtem + L3wtem_initxtilegdp1  
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 13
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1  + L3wtem + L3wtem_initxtilegdp1  = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 12
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 15
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 14
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1  + L3wpre + L3wpre_initxtilegdp1  
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 21
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1  + L3wpre + L3wpre_initxtilegdp1  = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 20
	
	* Pre - rich
	lincom wpre  + L1wpre + L2wpre + L3wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	
	**** Year 1 effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Tem - rich
	lincom wtem 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - rich
	lincom wpre 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	
	**************************
	* 5 lags
	**************************
	local colnum = 3
		
	cgmreg gag wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 28
	
	*** Growth effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1  + L2wtem + L2wtem_initxtilegdp1  + L3wtem + L3wtem_initxtilegdp1  + L4wtem + L4wtem_initxtilegdp1  + L5wtem + L5wtem_initxtilegdp1  
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 13
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1  + L3wtem + L3wtem_initxtilegdp1  + L4wtem + L4wtem_initxtilegdp1  + L5wtem + L5wtem_initxtilegdp1  = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 12
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 15
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 14
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1  + L3wpre + L3wpre_initxtilegdp1  + L4wpre + L4wpre_initxtilegdp1  + L5wpre + L5wpre_initxtilegdp1  
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 21
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1  + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1  + L5wpre + L5wpre_initxtilegdp1   = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 20
	
	* Pre - rich
	lincom wpre  + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	
	
	**** Year 1 effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Tem - rich
	lincom wtem 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - rich
	lincom wpre 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	
	**************************
	* 10 lags
	**************************
	local colnum = 4
	
	cgmreg gag wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1  L6wtem L6wtem_initxtilegdp1 L6wpre L6wpre_initxtilegdp1  L7wtem L7wtem_initxtilegdp1 L7wpre L7wpre_initxtilegdp1  L8wtem L8wtem_initxtilegdp1 L8wpre L8wpre_initxtilegdp1  L9wtem L9wtem_initxtilegdp1 L9wpre L9wpre_initxtilegdp1  L10wtem L10wtem_initxtilegdp1 L10wpre L10wpre_initxtilegdp1 RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 28
	
	*** Growth effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1  + L2wtem + L2wtem_initxtilegdp1  + L3wtem + L3wtem_initxtilegdp1  + L4wtem + L4wtem_initxtilegdp1  + L5wtem + L5wtem_initxtilegdp1  + L6wtem + L6wtem_initxtilegdp1  + L7wtem + L7wtem_initxtilegdp1  + L8wtem + L8wtem_initxtilegdp1  + L9wtem + L9wtem_initxtilegdp1  + L10wtem + L10wtem_initxtilegdp1  
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 13
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1  + L3wtem + L3wtem_initxtilegdp1  + L4wtem + L4wtem_initxtilegdp1  + L5wtem + L5wtem_initxtilegdp1  + L6wtem + L6wtem_initxtilegdp1  + L7wtem + L7wtem_initxtilegdp1  + L8wtem + L8wtem_initxtilegdp1  + L9wtem + L9wtem_initxtilegdp1  + L10wtem + L10wtem_initxtilegdp1  = 0 
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 12
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 15
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 14
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1  + L2wpre + L2wpre_initxtilegdp1  + L3wpre + L3wpre_initxtilegdp1  + L4wpre + L4wpre_initxtilegdp1  + L5wpre + L5wpre_initxtilegdp1  + L6wpre + L6wpre_initxtilegdp1  + L7wpre + L7wpre_initxtilegdp1  + L8wpre + L8wpre_initxtilegdp1  + L9wpre + L9wpre_initxtilegdp1  + L10wpre + L10wpre_initxtilegdp1  
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 21
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1  + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1  + L5wpre + L5wpre_initxtilegdp1   + L6wpre + L6wpre_initxtilegdp1  + L7wpre + L7wpre_initxtilegdp1  + L8wpre + L8wpre_initxtilegdp1  + L9wpre + L9wpre_initxtilegdp1  + L10wpre + L10wpre_initxtilegdp1  = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 20
	
	* Pre - rich
	lincom wpre  + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	
	
	**** Year 1 effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Tem - rich
	lincom wtem 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - rich
	lincom wpre 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	
	
	
	*************************
	* Industry
	*************************
	local colnum = 5
	label var outcol`colnum' "Industry"
	
	* No lags
	cgmreg gind wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 10
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 3
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 2
	
	* Tem - rich
	lincom wtem 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 5
	local pe = r(estimate)
	test wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 4
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 7
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 6
	
	* Pre - rich
	lincom wpre 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 9
	local pe = r(estimate)
	test wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 8
	
	
	************************
	* 1 lags
	
	local colnum = 5
	cgmreg gind wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 28
	
	*** Growth effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 13
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 12
	
	* Tem - rich
	lincom wtem + L1wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 15
	local pe = r(estimate)
	test wtem + L1wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 14
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 21
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 20
	
	* Pre - rich
	lincom wpre  + L1wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wpre + L1wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	
	**** Year 1 effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Tem - rich
	lincom wtem 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - rich
	lincom wpre 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	
	
	
	
	*****************************
	* 3 lags
	*****************************
	local colnum = 6
	
	cgmreg gind wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1   RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 28
	
	*** Growth effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1  + L2wtem + L2wtem_initxtilegdp1  + L3wtem + L3wtem_initxtilegdp1  
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 13
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1  + L3wtem + L3wtem_initxtilegdp1  = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 12
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 15
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 14
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1  + L3wpre + L3wpre_initxtilegdp1  
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 21
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1  + L3wpre + L3wpre_initxtilegdp1  = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 20
	
	* Pre - rich
	lincom wpre  + L1wpre + L2wpre + L3wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	
	**** Year 1 effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Tem - rich
	lincom wtem 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - rich
	lincom wpre 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	
	**************************
	* 5 lags
	**************************
	local colnum = 7
	
	cgmreg gind wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 28
	
	*** Growth effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1  + L2wtem + L2wtem_initxtilegdp1  + L3wtem + L3wtem_initxtilegdp1  + L4wtem + L4wtem_initxtilegdp1  + L5wtem + L5wtem_initxtilegdp1  
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 13
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1  + L3wtem + L3wtem_initxtilegdp1  + L4wtem + L4wtem_initxtilegdp1  + L5wtem + L5wtem_initxtilegdp1  = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 12
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 15
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 14
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1  + L3wpre + L3wpre_initxtilegdp1  + L4wpre + L4wpre_initxtilegdp1  + L5wpre + L5wpre_initxtilegdp1  
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 21
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1  + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1  + L5wpre + L5wpre_initxtilegdp1   = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 20
	
	* Pre - rich
	lincom wpre  + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	
	
	**** Year 1 effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Tem - rich
	lincom wtem 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - rich
	lincom wpre 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	**************************
	* 10 lags
	**************************
	local colnum = 8
	
	cgmreg gind wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1  L6wtem L6wtem_initxtilegdp1 L6wpre L6wpre_initxtilegdp1  L7wtem L7wtem_initxtilegdp1 L7wpre L7wpre_initxtilegdp1  L8wtem L8wtem_initxtilegdp1 L8wpre L8wpre_initxtilegdp1  L9wtem L9wtem_initxtilegdp1 L9wpre L9wpre_initxtilegdp1  L10wtem L10wtem_initxtilegdp1 L10wpre L10wpre_initxtilegdp1 RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 28
	
	*** Growth effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1  + L2wtem + L2wtem_initxtilegdp1  + L3wtem + L3wtem_initxtilegdp1  + L4wtem + L4wtem_initxtilegdp1  + L5wtem + L5wtem_initxtilegdp1  + L6wtem + L6wtem_initxtilegdp1  + L7wtem + L7wtem_initxtilegdp1  + L8wtem + L8wtem_initxtilegdp1  + L9wtem + L9wtem_initxtilegdp1  + L10wtem + L10wtem_initxtilegdp1  
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 13
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1  + L3wtem + L3wtem_initxtilegdp1  + L4wtem + L4wtem_initxtilegdp1  + L5wtem + L5wtem_initxtilegdp1  + L6wtem + L6wtem_initxtilegdp1  + L7wtem + L7wtem_initxtilegdp1  + L8wtem + L8wtem_initxtilegdp1  + L9wtem + L9wtem_initxtilegdp1  + L10wtem + L10wtem_initxtilegdp1  = 0 
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 12
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 15
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 14
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1  + L2wpre + L2wpre_initxtilegdp1  + L3wpre + L3wpre_initxtilegdp1  + L4wpre + L4wpre_initxtilegdp1  + L5wpre + L5wpre_initxtilegdp1  + L6wpre + L6wpre_initxtilegdp1  + L7wpre + L7wpre_initxtilegdp1  + L8wpre + L8wpre_initxtilegdp1  + L9wpre + L9wpre_initxtilegdp1  + L10wpre + L10wpre_initxtilegdp1  
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 21
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1  + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1  + L5wpre + L5wpre_initxtilegdp1   + L6wpre + L6wpre_initxtilegdp1  + L7wpre + L7wpre_initxtilegdp1  + L8wpre + L8wpre_initxtilegdp1  + L9wpre + L9wpre_initxtilegdp1  + L10wpre + L10wpre_initxtilegdp1  = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 20
	
	* Pre - rich
	lincom wpre  + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	
	
	**** Year 1 effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Tem - rich
	lincom wtem 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - rich
	lincom wpre 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	
	*********************************
	* Investment
	********************************
	local colnum = 9
	label var outcol`colnum' "Investment"
	
	* No lags
	cgmreg ginvest wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 10
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 3
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 2
	
	* Tem - rich
	lincom wtem 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 5
	local pe = r(estimate)
	test wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 4
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 7
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 6
	
	* Pre - rich
	lincom wpre 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 9
	local pe = r(estimate)
	test wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 8
	
	
	************************
	* 1 lags
	
	local colnum = 9
	cgmreg ginvest wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 28
	
	*** Growth effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 13
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 12
	
	* Tem - rich
	lincom wtem + L1wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 15
	local pe = r(estimate)
	test wtem + L1wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 14
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 21
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 20
	
	* Pre - rich
	lincom wpre  + L1wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wpre + L1wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	
	**** Year 1 effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Tem - rich
	lincom wtem 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - rich
	lincom wpre 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	
	
	
	
	*****************************
	* 3 lags
	*****************************
	local colnum = 10
	
	cgmreg ginvest wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1   RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 28
	
	*** Growth effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1  + L2wtem + L2wtem_initxtilegdp1  + L3wtem + L3wtem_initxtilegdp1  
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 13
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1  + L3wtem + L3wtem_initxtilegdp1  = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 12
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 15
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 14
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1  + L3wpre + L3wpre_initxtilegdp1  
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 21
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1  + L3wpre + L3wpre_initxtilegdp1  = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 20
	
	* Pre - rich
	lincom wpre  + L1wpre + L2wpre + L3wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	
	**** Year 1 effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Tem - rich
	lincom wtem 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - rich
	lincom wpre 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	
	**************************
	* 5 lags
	**************************
	local colnum = 11
	
	cgmreg ginvest wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 28
	
	*** Growth effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1  + L2wtem + L2wtem_initxtilegdp1  + L3wtem + L3wtem_initxtilegdp1  + L4wtem + L4wtem_initxtilegdp1  + L5wtem + L5wtem_initxtilegdp1  
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 13
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1  + L3wtem + L3wtem_initxtilegdp1  + L4wtem + L4wtem_initxtilegdp1  + L5wtem + L5wtem_initxtilegdp1  = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 12
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 15
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 14
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1  + L3wpre + L3wpre_initxtilegdp1  + L4wpre + L4wpre_initxtilegdp1  + L5wpre + L5wpre_initxtilegdp1  
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 21
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1  + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1  + L5wpre + L5wpre_initxtilegdp1   = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 20
	
	* Pre - rich
	lincom wpre  + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	
	
	**** Year 1 effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Tem - rich
	lincom wtem 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - rich
	lincom wpre 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	**************************
	* 10 lags
	**************************
	local colnum = 12
	
	cgmreg ginvest wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1  L6wtem L6wtem_initxtilegdp1 L6wpre L6wpre_initxtilegdp1  L7wtem L7wtem_initxtilegdp1 L7wpre L7wpre_initxtilegdp1  L8wtem L8wtem_initxtilegdp1 L8wpre L8wpre_initxtilegdp1  L9wtem L9wtem_initxtilegdp1 L9wpre L9wpre_initxtilegdp1  L10wtem L10wtem_initxtilegdp1 L10wpre L10wpre_initxtilegdp1 RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 28
	
	*** Growth effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1  + L2wtem + L2wtem_initxtilegdp1  + L3wtem + L3wtem_initxtilegdp1  + L4wtem + L4wtem_initxtilegdp1  + L5wtem + L5wtem_initxtilegdp1  + L6wtem + L6wtem_initxtilegdp1  + L7wtem + L7wtem_initxtilegdp1  + L8wtem + L8wtem_initxtilegdp1  + L9wtem + L9wtem_initxtilegdp1  + L10wtem + L10wtem_initxtilegdp1  
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 13
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1  + L3wtem + L3wtem_initxtilegdp1  + L4wtem + L4wtem_initxtilegdp1  + L5wtem + L5wtem_initxtilegdp1  + L6wtem + L6wtem_initxtilegdp1  + L7wtem + L7wtem_initxtilegdp1  + L8wtem + L8wtem_initxtilegdp1  + L9wtem + L9wtem_initxtilegdp1  + L10wtem + L10wtem_initxtilegdp1  = 0 
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 12
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 15
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 14
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1  + L2wpre + L2wpre_initxtilegdp1  + L3wpre + L3wpre_initxtilegdp1  + L4wpre + L4wpre_initxtilegdp1  + L5wpre + L5wpre_initxtilegdp1  + L6wpre + L6wpre_initxtilegdp1  + L7wpre + L7wpre_initxtilegdp1  + L8wpre + L8wpre_initxtilegdp1  + L9wpre + L9wpre_initxtilegdp1  + L10wpre + L10wpre_initxtilegdp1  
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 21
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1  + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1  + L5wpre + L5wpre_initxtilegdp1   + L6wpre + L6wpre_initxtilegdp1  + L7wpre + L7wpre_initxtilegdp1  + L8wpre + L8wpre_initxtilegdp1  + L9wpre + L9wpre_initxtilegdp1  + L10wpre + L10wpre_initxtilegdp1  = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 20
	
	* Pre - rich
	lincom wpre  + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	
	
	**** Year 1 effects
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Tem - rich
	lincom wtem 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - rich
	lincom wpre 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	
	outsheet indexnum rowtitle outcol1 outcol2 outcol3 outcol4 outcol5 outcol6 outcol7 outcol8 outcol9 outcol10 outcol11 outcol12 using  `filename'.out if indexnum <= 28, replace noquote 
	

end

createsamplemain
maketable5 table5spatial

