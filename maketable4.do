clear
clear matrix
clear mata
set more off
set matsize 800
set mem 200m
capture log close


capture program drop createsamplefirstyear
program define createsamplefirstyear
	* This sample is the sample of all countries 
	* Init GDP is defined based on your first year in the data
	use climate_panel, clear
		
	* restrict to 2003
	keep if year <= 2003
	
	encode parent, g(parent_num)
	
	* generate log gdp
	gen lgdp=ln(rgdpl)
	g lngdpwdi = ln(gdpLCU)
	
	* create numeric country code
	encode fips60_06, g(cc_num)
	sort country_code year
	tsset cc_num year
		
	*calculate GDP growth (WDI)
	gen temp1 = l.lngdpwdi
	gen g=lngdpwdi-temp1
	replace g = g * 100 
	drop temp1
	summarize g
	
	g lnag = ln(gdpWDIGDPAGR) 
	g lnind = ln(gdpWDIGDPIND) 
	
	foreach X in ag ind gdpwdi {
		g g`X' = (ln`X' - l.ln`X')*100
	}
	
	* Make sure all subcomponents are non-missing in a given year
	g misdum = 0
	for any ag ind : replace misdum = 1 if gX == .
	for any ag ind : replace gX = . if misdum == 1
	
	* Generate initial gdp bins
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
	
	* generate initial temperature bins
	preserve
	keep if wtem50 < . 
	bys fips60_06: keep if _n == 1 
	xtile initwtem50bin = wtem50 , nq(2)
	keep fips60_06 initwtem50bin
	save `tempxtile',replace
	restore
	
	mmerge fips60_06 using `tempxtile', type(n:1)
	tab initwtem50bin, g(initxtilewtem)
	
	* generate initial ag share bins
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
	
		
	* generate lags
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
	foreach X in _MENA   _SSAF   _LAC    _WEOFF  _EECA   _SEAS {
		replace region="`X'" if `X'==1
	}
	
	g regionyear=region+string(year)
	encode regionyear, g(rynum)	
	
end

capture program drop createsamplemain
program define createsamplemain
	* This sample is the sample of all countries 
	* Init GDP is defined based on your first year in the data
	* Must have at least 20 years of GDP data
	use climate_panel, clear
	
	  
	
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

createsamplemain

	g rowtitle = ""
	for num 1/15: g outcolX = ""
	g indexnum = _n
	
	replace rowtitle = "Results with no lags" if indexnum == 1
	replace rowtitle = "Tem immed. effect -- poor" if indexnum == 2
	replace rowtitle = "Tem immed. effect -- rich" if indexnum == 4
	replace rowtitle = "Pre immed. eeffect -- poor" if indexnum == 6
	replace rowtitle = "Pre immed. effect -- rich" if indexnum == 8
	replace rowtitle = "Num obs." if indexnum == 10
	
	replace rowtitle = "Results with 1 lag" if indexnum == 11
	replace rowtitle = "Tem growth effect -- poor" if indexnum == 12
	replace rowtitle = "Tem growth effect -- rich" if indexnum == 14
	replace rowtitle = "Pre growth effect -- poor" if indexnum == 16
	replace rowtitle = "Pre growth effect -- rich" if indexnum == 18
	replace rowtitle = "Num obs." if indexnum == 20
	
	replace rowtitle = "Results with 5 lags" if indexnum == 21
	replace rowtitle = "Tem growth effect -- poor" if indexnum == 22
	replace rowtitle = "Tem growth effect -- rich" if indexnum == 24
	replace rowtitle = "Pre growth effect -- poor" if indexnum == 26
	replace rowtitle = "Pre growth effect -- rich" if indexnum == 28	
	replace rowtitle = "Num obs." if indexnum == 30
		
	replace rowtitle = "Results with 10 lags" if indexnum == 31
	replace rowtitle = "Tem growth effect -- poor" if indexnum == 32
	replace rowtitle = "Tem growth effect -- rich" if indexnum == 34
	replace rowtitle = "Pre growth effect -- poor" if indexnum == 36
	replace rowtitle = "Pre growth effect -- rich" if indexnum == 38	
	replace rowtitle = "Num obs." if indexnum == 40		

	
	**********************************************
	* Column 1: repeat preferred specificaion
	**********************************************

	label var outcol1 "Preferred specification"
	local colnum = 1
	
	
	* No lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
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
	
	
	* 1 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 20
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
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Pre - rich
	lincom wpre  + L1wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wpre + L1wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	
	* 5 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 30
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	* Pre - rich
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 29
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre= 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 28
	
	
	* 10 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 /* 
	*/ L6wtem L6wtem_initxtilegdp1 L6wpre L6wpre_initxtilegdp1 /*
	*/ L7wtem L7wtem_initxtilegdp1 L7wpre L7wpre_initxtilegdp1 /*
	*/ L8wtem L8wtem_initxtilegdp1 L8wpre L8wpre_initxtilegdp1 /*
	*/ L9wtem L9wtem_initxtilegdp1 L9wpre L9wpre_initxtilegdp1 /*
	*/ L10wtem L10wtem_initxtilegdp1 L10wpre L10wpre_initxtilegdp1 /*				
	*/ RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 40
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 + L6wtem + L6wtem_initxtilegdp1 + L7wtem + L7wtem_initxtilegdp1 + L8wtem + L8wtem_initxtilegdp1 + L9wtem + L9wtem_initxtilegdp1 + L10wtem + L10wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 33
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1+ L6wtem + L6wtem_initxtilegdp1 + L7wtem + L7wtem_initxtilegdp1 + L8wtem + L8wtem_initxtilegdp1 + L9wtem + L9wtem_initxtilegdp1 + L10wtem + L10wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 32
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 35
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 34
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 + L6wpre + L6wpre_initxtilegdp1 + L7wpre + L7wpre_initxtilegdp1 + L8wpre + L8wpre_initxtilegdp1 + L9wpre + L9wpre_initxtilegdp1 + L10wpre + L10wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 37
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 + L6wpre + L6wpre_initxtilegdp1 + L7wpre + L7wpre_initxtilegdp1 + L8wpre + L8wpre_initxtilegdp1 + L9wpre + L9wpre_initxtilegdp1 + L10wpre + L10wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 36
	
	* Pre - rich
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 39
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 38

		
	*******************************************
	* Column 2: Just Region*Year FE	
	*******************************************


	local colnum = 2
	label var outcol`colnum' "Poor*Year, Region*Year FE"
	
	* No lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  RY1* RY2* RY3* RY4* i.cc_num, cluster(parent_num rynum)
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
	
	
	
	* 1 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1  RY1* RY2* RY3* RY4* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 20
	
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
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Pre - rich
	lincom wpre  + L1wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wpre + L1wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	
	* 5 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 RY1* RY2* RY3* RY4* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 30
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	* Pre - rich
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 29
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre= 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 28
		
	* 10 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 /* 
	*/ L6wtem L6wtem_initxtilegdp1 L6wpre L6wpre_initxtilegdp1 /*
	*/ L7wtem L7wtem_initxtilegdp1 L7wpre L7wpre_initxtilegdp1 /*
	*/ L8wtem L8wtem_initxtilegdp1 L8wpre L8wpre_initxtilegdp1 /*
	*/ L9wtem L9wtem_initxtilegdp1 L9wpre L9wpre_initxtilegdp1 /*
	*/ L10wtem L10wtem_initxtilegdp1 L10wpre L10wpre_initxtilegdp1 /*				
 	*/ RY1* RY2* RY3* RY4* i.cc_num, cluster(parent_num rynum)

	replace outcol`colnum' = string(e(N)) if indexnum == 40
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 + L6wtem + L6wtem_initxtilegdp1 + L7wtem + L7wtem_initxtilegdp1 + L8wtem + L8wtem_initxtilegdp1 + L9wtem + L9wtem_initxtilegdp1 + L10wtem + L10wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 33
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1+ L6wtem + L6wtem_initxtilegdp1 + L7wtem + L7wtem_initxtilegdp1 + L8wtem + L8wtem_initxtilegdp1 + L9wtem + L9wtem_initxtilegdp1 + L10wtem + L10wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 32
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 35
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 34
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 + L6wpre + L6wpre_initxtilegdp1 + L7wpre + L7wpre_initxtilegdp1 + L8wpre + L8wpre_initxtilegdp1 + L9wpre + L9wpre_initxtilegdp1 + L10wpre + L10wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 37
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 + L6wpre + L6wpre_initxtilegdp1 + L7wpre + L7wpre_initxtilegdp1 + L8wpre + L8wpre_initxtilegdp1 + L9wpre + L9wpre_initxtilegdp1 + L10wpre + L10wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 36
	
	* Pre - rich
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 39
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 38
	
	
	
	*****************************
	* Column 3: Year FE
	*****************************
	
	local colnum = 3
	label var outcol`colnum' "Year FE"
	
	* No lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  yr* i.cc_num, cluster(parent_num rynum)
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
	
	
	
	* 1 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1  yr* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 20
	
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
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Pre - rich
	lincom wpre  + L1wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wpre + L1wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	
	* 5 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 yr* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 30
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	* Pre - rich
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 29
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre= 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 28
	
	disp "HERE3"
	* 10 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 /* 
	*/ L6wtem L6wtem_initxtilegdp1 L6wpre L6wpre_initxtilegdp1 /*
	*/ L7wtem L7wtem_initxtilegdp1 L7wpre L7wpre_initxtilegdp1 /*
	*/ L8wtem L8wtem_initxtilegdp1 L8wpre L8wpre_initxtilegdp1 /*
	*/ L9wtem L9wtem_initxtilegdp1 L9wpre L9wpre_initxtilegdp1 /*
	*/ L10wtem L10wtem_initxtilegdp1 L10wpre L10wpre_initxtilegdp1 /*				
 	*/ yr* i.cc_num, cluster(parent_num rynum)
	disp "HERE3a"
	replace outcol`colnum' = string(e(N)) if indexnum == 40
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 + L6wtem + L6wtem_initxtilegdp1 + L7wtem + L7wtem_initxtilegdp1 + L8wtem + L8wtem_initxtilegdp1 + L9wtem + L9wtem_initxtilegdp1 + L10wtem + L10wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 33
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1+ L6wtem + L6wtem_initxtilegdp1 + L7wtem + L7wtem_initxtilegdp1 + L8wtem + L8wtem_initxtilegdp1 + L9wtem + L9wtem_initxtilegdp1 + L10wtem + L10wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 32
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 35
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 34
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 + L6wpre + L6wpre_initxtilegdp1 + L7wpre + L7wpre_initxtilegdp1 + L8wpre + L8wpre_initxtilegdp1 + L9wpre + L9wpre_initxtilegdp1 + L10wpre + L10wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 37
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 + L6wpre + L6wpre_initxtilegdp1 + L7wpre + L7wpre_initxtilegdp1 + L8wpre + L8wpre_initxtilegdp1 + L9wpre + L9wpre_initxtilegdp1 + L10wpre + L10wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 36
	
	* Pre - rich
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 39
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 38	
	
	
	
	
	**************************************
	* Column 4: Country specific trends
	**************************************
	
	quietly tab cc_num, gen(ctrycode)
  local numcountry = r(r) - 1
 
	  foreach X of num 1/`numcountry' {
  	quietly gen yc`X'=year*ctrycode`X'
  }
   	
	local colnum = 4
	label var outcol`colnum' "Country specific trends"


	* No lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  RY* yc* i.cc_num, cluster(parent_num rynum)
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
	
	
	
	* 1 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1  RY* yc* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 20
	
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
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Pre - rich
	lincom wpre  + L1wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wpre + L1wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	
	* 5 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 RY* yc* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 30
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	* Pre - rich
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 29
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre= 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 28

	disp "HERE4"
	* 10 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 /* 
	*/ L6wtem L6wtem_initxtilegdp1 L6wpre L6wpre_initxtilegdp1 /*
	*/ L7wtem L7wtem_initxtilegdp1 L7wpre L7wpre_initxtilegdp1 /*
	*/ L8wtem L8wtem_initxtilegdp1 L8wpre L8wpre_initxtilegdp1 /*
	*/ L9wtem L9wtem_initxtilegdp1 L9wpre L9wpre_initxtilegdp1 /*
	*/ L10wtem L10wtem_initxtilegdp1 L10wpre L10wpre_initxtilegdp1 /*				
 	*/ RY* yc* i.cc_num, cluster(parent_num rynum)
	disp "HERE4a"
	replace outcol`colnum' = string(e(N)) if indexnum == 40
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 + L6wtem + L6wtem_initxtilegdp1 + L7wtem + L7wtem_initxtilegdp1 + L8wtem + L8wtem_initxtilegdp1 + L9wtem + L9wtem_initxtilegdp1 + L10wtem + L10wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 33
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1+ L6wtem + L6wtem_initxtilegdp1 + L7wtem + L7wtem_initxtilegdp1 + L8wtem + L8wtem_initxtilegdp1 + L9wtem + L9wtem_initxtilegdp1 + L10wtem + L10wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 32
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 35
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 34
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 + L6wpre + L6wpre_initxtilegdp1 + L7wpre + L7wpre_initxtilegdp1 + L8wpre + L8wpre_initxtilegdp1 + L9wpre + L9wpre_initxtilegdp1 + L10wpre + L10wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 37
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 + L6wpre + L6wpre_initxtilegdp1 + L7wpre + L7wpre_initxtilegdp1 + L8wpre + L8wpre_initxtilegdp1 + L9wpre + L9wpre_initxtilegdp1 + L10wpre + L10wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 36
	
	* Pre - rich
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 39
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 38	

	*********************************
	* Column 5: Balanced panel 1971 
	*********************************
	* Uses same rich / poor definition but adds balanced panel
	tempfile tempsample
	save `tempsample',replace
	
	* Restrict to balanced sample
	capture drop temp*
	drop if (year < 1980 | year > 2003) 
	drop indexnum
	g indexnum = _n
	
	tsset cc_num year
	tsfill, full
	g tempmis = 1 if g == .
	replace tempmis = 0 if g != .
	bys cc_num: egen tempanymis = sum(tempmis)
	
	drop if tempanymis != 0
	
	
	local colnum = 5
	label var outcol`colnum' "Balanced Panel"
	
	* No lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
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
	
	
	* 1 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 20
	
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
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Pre - rich
	lincom wpre  + L1wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wpre + L1wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	
	* 5 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 30
	
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	* Pre - rich
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 29
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre= 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 28

	disp "HERE5"
	* 10 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 /* 
	*/ L6wtem L6wtem_initxtilegdp1 L6wpre L6wpre_initxtilegdp1 /*
	*/ L7wtem L7wtem_initxtilegdp1 L7wpre L7wpre_initxtilegdp1 /*
	*/ L8wtem L8wtem_initxtilegdp1 L8wpre L8wpre_initxtilegdp1 /*
	*/ L9wtem L9wtem_initxtilegdp1 L9wpre L9wpre_initxtilegdp1 /*
	*/ L10wtem L10wtem_initxtilegdp1 L10wpre L10wpre_initxtilegdp1 /*				
 	*/ RY* i.cc_num, cluster(parent_num rynum)
 	disp "HERE5a"
	replace outcol`colnum' = string(e(N)) if indexnum == 40
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 + L6wtem + L6wtem_initxtilegdp1 + L7wtem + L7wtem_initxtilegdp1 + L8wtem + L8wtem_initxtilegdp1 + L9wtem + L9wtem_initxtilegdp1 + L10wtem + L10wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 33
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1+ L6wtem + L6wtem_initxtilegdp1 + L7wtem + L7wtem_initxtilegdp1 + L8wtem + L8wtem_initxtilegdp1 + L9wtem + L9wtem_initxtilegdp1 + L10wtem + L10wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 32
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 35
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 34
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 + L6wpre + L6wpre_initxtilegdp1 + L7wpre + L7wpre_initxtilegdp1 + L8wpre + L8wpre_initxtilegdp1 + L9wpre + L9wpre_initxtilegdp1 + L10wpre + L10wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 37
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 + L6wpre + L6wpre_initxtilegdp1 + L7wpre + L7wpre_initxtilegdp1 + L8wpre + L8wpre_initxtilegdp1 + L9wpre + L9wpre_initxtilegdp1 + L10wpre + L10wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 36
	
	* Pre - rich
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 39
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 38	


	
	keep indexnum outcol`colnum'
	keep if indexnum <= 40
	
	tempfile tempcolresults
	save `tempcolresults', replace
	use `tempsample',replace
	drop outcol`colnum'
	mmerge indexnum using `tempcolresults'
	tab _merge
	drop _merge
	

	**********************************
	* Column 6: Entire sample
	**********************************

	tempfile tempsample
	save `tempsample',replace
	
	*---Need to open the dataset with the full sample
	createsamplefirstyear
	
	capture {
		for var wtem* wpre*: g L6X = l6.X 
		for var wtem* wpre*: g L7X = l7.X 
		for var wtem* wpre*: g L8X = l8.X 
		for var wtem* wpre*: g L9X = l9.X 
		for var wtem* wpre*: g L10X = l10.X 
	}

	local colnum = 6
	
	g outcol`colnum' = ""
	label var outcol`colnum' "Full sample"
	g indexnum = _n
	
	* No lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
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
	
	
	* 1 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 20
	
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
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Pre - rich
	lincom wpre  + L1wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wpre + L1wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	
	* 5 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 30
	
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	* Pre - rich
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 29
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre= 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 28
	
	disp "HERE6"
	* 10 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 /* 
	*/ L6wtem L6wtem_initxtilegdp1 L6wpre L6wpre_initxtilegdp1 /*
	*/ L7wtem L7wtem_initxtilegdp1 L7wpre L7wpre_initxtilegdp1 /*
	*/ L8wtem L8wtem_initxtilegdp1 L8wpre L8wpre_initxtilegdp1 /*
	*/ L9wtem L9wtem_initxtilegdp1 L9wpre L9wpre_initxtilegdp1 /*
	*/ L10wtem L10wtem_initxtilegdp1 L10wpre L10wpre_initxtilegdp1 /*				
 	*/ RY* i.cc_num, cluster(parent_num rynum)
	disp "HERE6a"
	replace outcol`colnum' = string(e(N)) if indexnum == 40
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 + L6wtem + L6wtem_initxtilegdp1 + L7wtem + L7wtem_initxtilegdp1 + L8wtem + L8wtem_initxtilegdp1 + L9wtem + L9wtem_initxtilegdp1 + L10wtem + L10wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 33
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1+ L6wtem + L6wtem_initxtilegdp1 + L7wtem + L7wtem_initxtilegdp1 + L8wtem + L8wtem_initxtilegdp1 + L9wtem + L9wtem_initxtilegdp1 + L10wtem + L10wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 32
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 35
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 34
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 + L6wpre + L6wpre_initxtilegdp1 + L7wpre + L7wpre_initxtilegdp1 + L8wpre + L8wpre_initxtilegdp1 + L9wpre + L9wpre_initxtilegdp1 + L10wpre + L10wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 37
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 + L6wpre + L6wpre_initxtilegdp1 + L7wpre + L7wpre_initxtilegdp1 + L8wpre + L8wpre_initxtilegdp1 + L9wpre + L9wpre_initxtilegdp1 + L10wpre + L10wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 36
	
	* Pre - rich
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 39
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 38	


	
	
	keep indexnum outcol`colnum'
	keep if indexnum <= 40
	
	tempfile tempcolresults
	save `tempcolresults', replace
	use `tempsample',replace
	drop outcol`colnum'
	mmerge indexnum using `tempcolresults'
	tab _merge
	drop _merge

	**************************
	* Column 7: PWT data
	**************************
		
	local colnum = 7
	label var outcol`colnum' "PWT data"
	
	* No lags
	cgmreg gpwt wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
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
	
	
	* 1 lags
	cgmreg gpwt wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 20
	
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
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Pre - rich
	lincom wpre  + L1wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wpre + L1wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	
	* 5 lags
	cgmreg gpwt wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 30
	
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	* Pre - rich
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 29
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre= 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 28

	disp "HERE7"
	* 10 lags
	cgmreg gpwt wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 /* 
	*/ L6wtem L6wtem_initxtilegdp1 L6wpre L6wpre_initxtilegdp1 /*
	*/ L7wtem L7wtem_initxtilegdp1 L7wpre L7wpre_initxtilegdp1 /*
	*/ L8wtem L8wtem_initxtilegdp1 L8wpre L8wpre_initxtilegdp1 /*
	*/ L9wtem L9wtem_initxtilegdp1 L9wpre L9wpre_initxtilegdp1 /*
	*/ L10wtem L10wtem_initxtilegdp1 L10wpre L10wpre_initxtilegdp1 /*				
 	*/ RY* i.cc_num, cluster(parent_num rynum)
	disp "HERE7a"
	replace outcol`colnum' = string(e(N)) if indexnum == 40
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 + L6wtem + L6wtem_initxtilegdp1 + L7wtem + L7wtem_initxtilegdp1 + L8wtem + L8wtem_initxtilegdp1 + L9wtem + L9wtem_initxtilegdp1 + L10wtem + L10wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 33
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1+ L6wtem + L6wtem_initxtilegdp1 + L7wtem + L7wtem_initxtilegdp1 + L8wtem + L8wtem_initxtilegdp1 + L9wtem + L9wtem_initxtilegdp1 + L10wtem + L10wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 32
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 35
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 34
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 + L6wpre + L6wpre_initxtilegdp1 + L7wpre + L7wpre_initxtilegdp1 + L8wpre + L8wpre_initxtilegdp1 + L9wpre + L9wpre_initxtilegdp1 + L10wpre + L10wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 37
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 + L6wpre + L6wpre_initxtilegdp1 + L7wpre + L7wpre_initxtilegdp1 + L8wpre + L8wpre_initxtilegdp1 + L9wpre + L9wpre_initxtilegdp1 + L10wpre + L10wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 36
	
	* Pre - rich
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 39
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 38	

	



	* Column 8
	***********
	****Area weighted
	***********
	
	tempfile tempsample
	save `tempsample',replace
	
	
	mmerge fips60_06 year using AreaWeightedClimate, type(1:1) 
	
	drop if _merge == 2
	
	g temptem = wtem
	g temppre = wpre 
	
	drop wtem* wpre*
	g wtem = atem 
	g wpre = apre / 100 * 12
	***NOTE: wpre is in annual 100m, but apre is in mm per month

	
	* We only have pop-weighted data for st vincent
	* Given that this country is so small they are the same, use the pop-weighted data
	replace wtem = temptem if fips60_06 == "VC" & wtem == .
	replace wpre = temppre if fips60_06 == "VC" & wpre == .
	label var wtem "temperature"
	label var wpre "precipitation"
	
	*gen temperature/precip x initial GDP bin
	foreach Y in wtem wpre  {
	gen `Y'Xlnrgdpl_t0 =`Y'*lnrgdpl_t0 
	for var initxtile*: gen `Y'_X =`Y'*X
		
	label var `Y'Xlnrgdpl_t0 "`Y'.*inital GDP pc"
	for var initxtile*: label var `Y'_X "`Y'* X"
	}

	
	* make lags
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
		
	local colnum = 8
	label var outcol`colnum' "Area weighted"
	
	* No lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
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
	
	
	* 1 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 20
	
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
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Pre - rich
	lincom wpre  + L1wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wpre + L1wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	
	* 5 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 RY* i.cc_num, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 30
	
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	* Pre - rich
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 29
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre= 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 28
	
	disp "HERE8"
	* 10 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 /* 
	*/ L6wtem L6wtem_initxtilegdp1 L6wpre L6wpre_initxtilegdp1 /*
	*/ L7wtem L7wtem_initxtilegdp1 L7wpre L7wpre_initxtilegdp1 /*
	*/ L8wtem L8wtem_initxtilegdp1 L8wpre L8wpre_initxtilegdp1 /*
	*/ L9wtem L9wtem_initxtilegdp1 L9wpre L9wpre_initxtilegdp1 /*
	*/ L10wtem L10wtem_initxtilegdp1 L10wpre L10wpre_initxtilegdp1 /*				
 	*/ RY* i.cc_num, cluster(parent_num rynum)
	disp "HERE8a"
	replace outcol`colnum' = string(e(N)) if indexnum == 40
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 + L6wtem + L6wtem_initxtilegdp1 + L7wtem + L7wtem_initxtilegdp1 + L8wtem + L8wtem_initxtilegdp1 + L9wtem + L9wtem_initxtilegdp1 + L10wtem + L10wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 33
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1+ L6wtem + L6wtem_initxtilegdp1 + L7wtem + L7wtem_initxtilegdp1 + L8wtem + L8wtem_initxtilegdp1 + L9wtem + L9wtem_initxtilegdp1 + L10wtem + L10wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 32
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 35
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 34
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 + L6wpre + L6wpre_initxtilegdp1 + L7wpre + L7wpre_initxtilegdp1 + L8wpre + L8wpre_initxtilegdp1 + L9wpre + L9wpre_initxtilegdp1 + L10wpre + L10wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 37
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 + L6wpre + L6wpre_initxtilegdp1 + L7wpre + L7wpre_initxtilegdp1 + L8wpre + L8wpre_initxtilegdp1 + L9wpre + L9wpre_initxtilegdp1 + L10wpre + L10wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 36
	
	* Pre - rich
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 39
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 38	
	
	keep indexnum outcol`colnum'
	keep if indexnum <= 40
	
	tempfile tempcolresults
	save `tempcolresults', replace
	use `tempsample',replace
	drop outcol`colnum'
	mmerge indexnum using `tempcolresults'
	tab _merge
	drop _merge


	**********************************************
	* Column 9: Main specification, Africa only
	**********************************************


	tempfile tempsample
	save `tempsample',replace

	
	local colnum = 9
	label var outcol`colnum' "Africa Only"
		
	* No lags
	cgmreg g wtem wpre i.cc_num  yr* if _SSAF==1 & initgdpbin==1, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 10
	
	* Tem - poor
	lincom wtem 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 3
	local pe = r(estimate)
	test wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 2
	
	* Pre - poor
	lincom wpre 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 7
	local pe = r(estimate)
	test wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 6
	
	
	* 1 lags
	cgmreg g wtem wpre L1wtem L1wpre i.cc_num  yr* if _SSAF==1  & initgdpbin==1, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 20
	
	* Tem - poor
	lincom wtem + L1wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 13
	local pe = r(estimate)
	test wtem + L1wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 12
	
	* Pre - poor
	lincom wpre  + L1wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wpre + L1wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	
	* 5 lags
	cgmreg g wtem wpre L1wtem L1wpre L2wtem L2wpre L3wtem L3wpre L4wtem L4wpre L5wtem L5wpre i.cc_num yr* if _SSAF==1 & initgdpbin==1, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 30

	* Tem - poor
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	* Pre - poor
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre= 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	
	* 10 lags
	cgmreg g wtem wpre L1wtem L1wpre L2wtem L2wpre L3wtem L3wpre L4wtem L4wpre L5wtem L5wpre L6wtem L6wpre L7wtem L7wpre L8wtem L8wpre L9wtem L9wpre L10wtem L10wpre i.cc_num yr* if _SSAF==1 & initgdpbin==1, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 40
	* Tem - poor
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 33
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 32
	
	* Pre - poor
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 37
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 36

	list indexnum outcol`colnum' in 1/40

	keep indexnum outcol`colnum'
	keep if indexnum <= 40


	tempfile tempcolresults
	save `tempcolresults', replace
	use `tempsample',replace
	drop outcol`colnum'
	mmerge indexnum using `tempcolresults'
	tab _merge
	drop _merge
	
	list indexnum outcol`colnum' in 1/40

	**********************************************
	* Column 10: Main specification, Excluding Africa
	**********************************************

	tempfile tempsample
	save `tempsample',replace
	
	local colnum = 10
	label var outcol`colnum' "Excluding Africa"
		
	* No lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1 i.cc_num  RY* if _SSAF==0, cluster(parent_num rynum)
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
	
	
	* 1 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 i.cc_num  RY* if _SSAF==0, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 20
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
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 17
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 16
	
	* Pre - rich
	lincom wpre  + L1wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 19
	local pe = r(estimate)
	test wpre + L1wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 18
	
	
	* 5 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 RY* i.cc_num if _SSAF==0, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 30
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 23
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 22
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 25
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 24
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 27
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 26
	
	* Pre - rich
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 29
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre= 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 28
	
	
	* 10 lags
	cgmreg g wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  L1wtem L1wtem_initxtilegdp1 L1wpre L1wpre_initxtilegdp1 L2wtem L2wtem_initxtilegdp1 L2wpre L2wpre_initxtilegdp1 L3wtem L3wtem_initxtilegdp1 L3wpre L3wpre_initxtilegdp1 L4wtem L4wtem_initxtilegdp1 L4wpre L4wpre_initxtilegdp1 L5wtem L5wtem_initxtilegdp1 L5wpre L5wpre_initxtilegdp1 /* 
	*/ L6wtem L6wtem_initxtilegdp1 L6wpre L6wpre_initxtilegdp1 /*
	*/ L7wtem L7wtem_initxtilegdp1 L7wpre L7wpre_initxtilegdp1 /*
	*/ L8wtem L8wtem_initxtilegdp1 L8wpre L8wpre_initxtilegdp1 /*
	*/ L9wtem L9wtem_initxtilegdp1 L9wpre L9wpre_initxtilegdp1 /*
	*/ L10wtem L10wtem_initxtilegdp1 L10wpre L10wpre_initxtilegdp1 i.cc_num /*				
	*/ RY* if _SSAF==0, cluster(parent_num rynum)
	replace outcol`colnum' = string(e(N)) if indexnum == 40
	* Tem - poor
	lincom wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1 + L6wtem + L6wtem_initxtilegdp1 + L7wtem + L7wtem_initxtilegdp1 + L8wtem + L8wtem_initxtilegdp1 + L9wtem + L9wtem_initxtilegdp1 + L10wtem + L10wtem_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 33
	local pe = r(estimate)
	test wtem + wtem_initxtilegdp1 + L1wtem + L1wtem_initxtilegdp1 + L2wtem + L2wtem_initxtilegdp1 + L3wtem + L3wtem_initxtilegdp1 + L4wtem + L4wtem_initxtilegdp1 + L5wtem + L5wtem_initxtilegdp1+ L6wtem + L6wtem_initxtilegdp1 + L7wtem + L7wtem_initxtilegdp1 + L8wtem + L8wtem_initxtilegdp1 + L9wtem + L9wtem_initxtilegdp1 + L10wtem + L10wtem_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 32
	
	* Tem - rich
	lincom wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 35
	local pe = r(estimate)
	test wtem + L1wtem + L2wtem + L3wtem + L4wtem + L5wtem + L6wtem + L7wtem + L8wtem + L9wtem + L10wtem = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 34
	
	* Pre - poor
	lincom wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 + L6wpre + L6wpre_initxtilegdp1 + L7wpre + L7wpre_initxtilegdp1 + L8wpre + L8wpre_initxtilegdp1 + L9wpre + L9wpre_initxtilegdp1 + L10wpre + L10wpre_initxtilegdp1
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 37
	local pe = r(estimate)
	test wpre + wpre_initxtilegdp1 + L1wpre + L1wpre_initxtilegdp1 + L2wpre + L2wpre_initxtilegdp1 + L3wpre + L3wpre_initxtilegdp1 + L4wpre + L4wpre_initxtilegdp1 + L5wpre + L5wpre_initxtilegdp1 + L6wpre + L6wpre_initxtilegdp1 + L7wpre + L7wpre_initxtilegdp1 + L8wpre + L8wpre_initxtilegdp1 + L9wpre + L9wpre_initxtilegdp1 + L10wpre + L10wpre_initxtilegdp1 = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 36
	
	* Pre - rich
	lincom wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre
	replace outcol`colnum' = "(" + string(r(se),"%4.3f") + ")" if  indexnum == 39
	local pe = r(estimate)
	test wpre + L1wpre + L2wpre + L3wpre + L4wpre + L5wpre + L6wpre + L7wpre + L8wpre + L9wpre + L10wpre = 0
	local pval = r(p)
	makestars,pointest(`pe') pval(`pval')
	replace outcol`colnum' = r(coeff) if indexnum == 38

		
	keep indexnum outcol`colnum'
	keep if indexnum <= 40
	
	tempfile tempcolresults
	save `tempcolresults', replace
	use `tempsample',replace
	drop outcol`colnum'
	mmerge indexnum using `tempcolresults'
	tab _merge
	drop _merge
	
	outsheet indexnum rowtitle outcol1 outcol2 outcol3 outcol4 outcol5 outcol6 outcol7 outcol8 outcol9 outcol10 using Table4.out if indexnum <= 40, replace noquote 


