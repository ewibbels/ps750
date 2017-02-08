clear
clear matrix
set more off
set matsize 800
set mem 200m
capture log close

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

	***************************************************************************
    *Generate poverty categories per year
	preserve
	keep if rgdpl < . 
	bys fips60_06: keep if _n == 1 
	xtile gdpbin = ln(rgdpl), nq(2)
	keep fips60_06 gdpbin
	tempfile tempxtile
	save `tempxtile',replace
	restore
	
	mmerge fips60_06 using `tempxtile', type(n:1)
	tab gdpbin, g(initxtilegdp)
	***************************************************************************
	
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
		gen `Y'Xrgdpl =`Y'*rgdpl
		for var initxtile*: gen `Y'_X =`Y'*X
			
		label var `Y'Xrgdpl "`Y'.*GDP pc"
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

capture program drop maketable3
program define maketable3
	syntax anything(name=filename)

	********
	* 0 lags, 1 lag, 3 lags, 5 lags, 10 lags
	********
	
	label var wtem_initxtilegdp1 "Temp * Poor"
	label var wtem_initxtilegdp2 "Temp * Rich"
	label var wpre_initxtilegdp1 "Precip. * Poor"
	label var wpre_initxtilegdp2 "Precip * Rich"
	
	for num 1/10: label var LXwtem_initxtilegdp1 "LX: Temp * Poor"
	for num 1/10: label var LXwtem_initxtilegdp2 "LX: Temp * Rich"
	for num 1/10: label var LXwpre_initxtilegdp1 "LX: Precip. * Poor"
	for num 1/10: label var LXwpre_initxtilegdp2 "LX: Precip * Rich"

	* no lags
	cgmreg g wtem_initxtilegdp1 wtem_initxtilegdp2 RY* i.cc_num, cluster(parent_num rynum)
	lincom wtem_initxtilegdp1
	local temeffectpoor_coeff = r(estimate)
	local temeffectpoor_se= r(se)
	test wtem_initxtilegdp1 = 0
	local temeffectpoor_p = r(p)
	
	lincom wtem_initxtilegdp2
	local temeffectrich_coeff = r(estimate)
	local temeffectrich_se= r(se)
	test wtem_initxtilegdp2 = 0
	local temeffectrich_p = r(p)
						

end

createsamplemain
maketable3 table3

********************************************************************************

****************************    Model with 1 Lag   *****************************

********************************************************************************
clear
clear matrix
set more off
set matsize 800
set mem 200m
capture log close

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

	***************************************************************************
    *Generate poverty categories per year
	preserve
	keep if rgdpl < . 
	bys fips60_06: keep if _n == 1 
	xtile gdpbin = ln(rgdpl), nq(2)
	keep fips60_06 gdpbin
	tempfile tempxtile
	save `tempxtile',replace
	restore
	
	mmerge fips60_06 using `tempxtile', type(n:1)
	tab gdpbin, g(initxtilegdp)
	***************************************************************************
	
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
		gen `Y'Xrgdpl =`Y'*rgdpl
		for var initxtile*: gen `Y'_X =`Y'*X
			
		label var `Y'Xrgdpl "`Y'.*GDP pc"
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

capture program drop maketable3
program define maketable3
	syntax anything(name=filename)

	********
	* 0 lags, 1 lag, 3 lags, 5 lags, 10 lags
	********
	
	label var wtem_initxtilegdp1 "Temp * Poor"
	label var wtem_initxtilegdp2 "Temp * Rich"
	label var wpre_initxtilegdp1 "Precip. * Poor"
	label var wpre_initxtilegdp2 "Precip * Rich"
	
	for num 1/10: label var LXwtem_initxtilegdp1 "LX: Temp * Poor"
	for num 1/10: label var LXwtem_initxtilegdp2 "LX: Temp * Rich"
	for num 1/10: label var LXwpre_initxtilegdp1 "LX: Precip. * Poor"
	for num 1/10: label var LXwpre_initxtilegdp2 "LX: Precip * Rich"

	* 1 lags
	cgmreg g wtem_initxtilegdp1 L1wtem_initxtilegdp1 wtem_initxtilegdp2 L1wtem_initxtilegdp2 RY* i.cc_num, cluster(parent_num rynum)
	lincom wtem_initxtilegdp1 + L1wtem_initxtilegdp1 
	local temeffectpoor_coeff = r(estimate)
	local temeffectpoor_se= r(se)
	test wtem_initxtilegdp1 + L1wtem_initxtilegdp1 = 0
	local temeffectpoor_p = r(p)
	
	lincom wtem_initxtilegdp2 + L1wtem_initxtilegdp2 
	local temeffectrich_coeff = r(estimate)
	local temeffectrich_se= r(se)
	test wtem_initxtilegdp2 + L1wtem_initxtilegdp2 = 0
	local temeffectrich_p = r(p)
		
						
end

createsamplemain
maketable3 table3

********************************************************************************

****************************    Model with 5 Lag   *****************************

********************************************************************************
clear
clear matrix
set more off
set matsize 800
set mem 200m
capture log close

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

	***************************************************************************
    *Generate poverty categories per year
	preserve
	keep if rgdpl < . 
	bys fips60_06: keep if _n == 1 
	xtile gdpbin = ln(rgdpl), nq(2)
	keep fips60_06 gdpbin
	tempfile tempxtile
	save `tempxtile',replace
	restore
	
	mmerge fips60_06 using `tempxtile', type(n:1)
	tab gdpbin, g(initxtilegdp)
	***************************************************************************
	
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
		gen `Y'Xrgdpl =`Y'*rgdpl
		for var initxtile*: gen `Y'_X =`Y'*X
			
		label var `Y'Xrgdpl "`Y'.*GDP pc"
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

capture program drop maketable3
program define maketable3
	syntax anything(name=filename)

	********
	* 0 lags, 1 lag, 3 lags, 5 lags, 10 lags
	********
	
	label var wtem_initxtilegdp1 "Temp * Poor"
	label var wtem_initxtilegdp2 "Temp * Rich"
	label var wpre_initxtilegdp1 "Precip. * Poor"
	label var wpre_initxtilegdp2 "Precip * Rich"
	
	for num 1/10: label var LXwtem_initxtilegdp1 "LX: Temp * Poor"
	for num 1/10: label var LXwtem_initxtilegdp2 "LX: Temp * Rich"
	for num 1/10: label var LXwpre_initxtilegdp1 "LX: Precip. * Poor"
	for num 1/10: label var LXwpre_initxtilegdp2 "LX: Precip * Rich"

		* 5 lags
	cgmreg g wtem_initxtilegdp1 L1wtem_initxtilegdp1 L2wtem_initxtilegdp1 L3wtem_initxtilegdp1 L4wtem_initxtilegdp1 L5wtem_initxtilegdp1 wtem_initxtilegdp2 L1wtem_initxtilegdp2 L2wtem_initxtilegdp2 L3wtem_initxtilegdp2 L4wtem_initxtilegdp2 L5wtem_initxtilegdp2 RY* i.cc_num, cluster(parent_num rynum)
	lincom wtem_initxtilegdp1 + L1wtem_initxtilegdp1 + L2wtem_initxtilegdp1 + L3wtem_initxtilegdp1 + L4wtem_initxtilegdp1 + L5wtem_initxtilegdp1 
	local temeffectpoor_coeff = r(estimate)
	local temeffectpoor_se= r(se)
	test wtem_initxtilegdp1 + L1wtem_initxtilegdp1 + L2wtem_initxtilegdp1 + L3wtem_initxtilegdp1 + L4wtem_initxtilegdp1 + L5wtem_initxtilegdp1 = 0
	local temeffectpoor_p = r(p)
		
	lincom wtem_initxtilegdp2 + L1wtem_initxtilegdp2 + L2wtem_initxtilegdp2 + L3wtem_initxtilegdp2 + L4wtem_initxtilegdp2 + L5wtem_initxtilegdp2 
	local temeffectrich_coeff = r(estimate)
	local temeffectrich_se= r(se)
	test wtem_initxtilegdp2 + L1wtem_initxtilegdp2 + L2wtem_initxtilegdp2 + L3wtem_initxtilegdp2 + L4wtem_initxtilegdp2 + L5wtem_initxtilegdp2 = 0
	local temeffectrich_p = r(p)
		
						
end

createsamplemain
maketable3 table3

********************************************************************************

****************************   Model with 10 Lags   ****************************

********************************************************************************
clear
clear matrix
set more off
set matsize 800
set mem 200m
capture log close

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

	***************************************************************************
    *Generate poverty categories per year
	preserve
	keep if rgdpl < . 
	bys fips60_06: keep if _n == 1 
	xtile gdpbin = ln(rgdpl), nq(2)
	keep fips60_06 gdpbin
	tempfile tempxtile
	save `tempxtile',replace
	restore
	
	mmerge fips60_06 using `tempxtile', type(n:1)
	tab gdpbin, g(initxtilegdp)
	***************************************************************************
	
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
		gen `Y'Xrgdpl =`Y'*rgdpl
		for var initxtile*: gen `Y'_X =`Y'*X
			
		label var `Y'Xrgdpl "`Y'.*GDP pc"
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

capture program drop maketable3
program define maketable3
	syntax anything(name=filename)

	********
	* 0 lags, 1 lag, 3 lags, 5 lags, 10 lags
	********
	
	label var wtem_initxtilegdp1 "Temp * Poor"
	label var wtem_initxtilegdp2 "Temp * Rich"
	label var wpre_initxtilegdp1 "Precip. * Poor"
	label var wpre_initxtilegdp2 "Precip * Rich"
	
	for num 1/10: label var LXwtem_initxtilegdp1 "LX: Temp * Poor"
	for num 1/10: label var LXwtem_initxtilegdp2 "LX: Temp * Rich"
	for num 1/10: label var LXwpre_initxtilegdp1 "LX: Precip. * Poor"
	for num 1/10: label var LXwpre_initxtilegdp2 "LX: Precip * Rich"

	* 10 lags
	cgmreg g wtem_initxtilegdp1 L1wtem_initxtilegdp1 L2wtem_initxtilegdp1 L3wtem_initxtilegdp1 L4wtem_initxtilegdp1 L5wtem_initxtilegdp1 L6wtem_initxtilegdp1 L7wtem_initxtilegdp1 L8wtem_initxtilegdp1 L9wtem_initxtilegdp1 L10wtem_initxtilegdp1 wtem_initxtilegdp2 L1wtem_initxtilegdp2 L2wtem_initxtilegdp2 L3wtem_initxtilegdp2 L4wtem_initxtilegdp2 L5wtem_initxtilegdp2 L6wtem_initxtilegdp2 L7wtem_initxtilegdp2 L8wtem_initxtilegdp2 L9wtem_initxtilegdp2 L10wtem_initxtilegdp2 RY* i.cc_num, cluster(parent_num rynum)
	lincom wtem_initxtilegdp1 + L1wtem_initxtilegdp1 + L2wtem_initxtilegdp1 + L3wtem_initxtilegdp1 + L4wtem_initxtilegdp1 + L5wtem_initxtilegdp1 + L6wtem_initxtilegdp1 + L7wtem_initxtilegdp1 + L8wtem_initxtilegdp1 + L9wtem_initxtilegdp1 + L10wtem_initxtilegdp1 
	local temeffectpoor_coeff = r(estimate)
	local temeffectpoor_se= r(se)
	test wtem_initxtilegdp1 + L1wtem_initxtilegdp1 + L2wtem_initxtilegdp1 + L3wtem_initxtilegdp1 + L4wtem_initxtilegdp1 + L5wtem_initxtilegdp1 + L6wtem_initxtilegdp1 + L7wtem_initxtilegdp1 + L8wtem_initxtilegdp1 + L9wtem_initxtilegdp1 + L10wtem_initxtilegdp1 = 0
	local temeffectpoor_p = r(p)
		
	lincom wtem_initxtilegdp2 + L1wtem_initxtilegdp2 + L2wtem_initxtilegdp2 + L3wtem_initxtilegdp2 + L4wtem_initxtilegdp2 + L5wtem_initxtilegdp2 + L6wtem_initxtilegdp2 + L7wtem_initxtilegdp2 + L8wtem_initxtilegdp2 + L9wtem_initxtilegdp2 + L10wtem_initxtilegdp2
	local temeffectrich_coeff = r(estimate)
	local temeffectrich_se= r(se)
	test wtem_initxtilegdp2 + L1wtem_initxtilegdp2 + L2wtem_initxtilegdp2 + L3wtem_initxtilegdp2 + L4wtem_initxtilegdp2 + L5wtem_initxtilegdp2 + L6wtem_initxtilegdp2 + L7wtem_initxtilegdp2 + L8wtem_initxtilegdp2 + L9wtem_initxtilegdp2 + L10wtem_initxtilegdp2= 0
	local temeffectrich_p = r(p)
	
						
end

createsamplemain
maketable3 table3

********************************************************************************
	* Add precipitation
********************************************************************************

clear
clear matrix
set more off
set matsize 800
set mem 200m
capture log close

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

	***************************************************************************
    *Generate poverty categories per year
	preserve
	keep if rgdpl < . 
	bys fips60_06: keep if _n == 1 
	xtile gdpbin = ln(rgdpl), nq(2)
	keep fips60_06 gdpbin
	tempfile tempxtile
	save `tempxtile',replace
	restore
	
	mmerge fips60_06 using `tempxtile', type(n:1)
	tab gdpbin, g(initxtilegdp)
	***************************************************************************
	
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
		gen `Y'Xrgdpl =`Y'*rgdpl
		for var initxtile*: gen `Y'_X =`Y'*X
			
		label var `Y'Xrgdpl "`Y'.*GDP pc"
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

capture program drop maketable3
program define maketable3
	syntax anything(name=filename)

	********
	* 0 lags, 1 lag, 3 lags, 5 lags, 10 lags
	********
	
	label var wtem_initxtilegdp1 "Temp * Poor"
	label var wtem_initxtilegdp2 "Temp * Rich"
	label var wpre_initxtilegdp1 "Precip. * Poor"
	label var wpre_initxtilegdp2 "Precip * Rich"
	
	for num 1/10: label var LXwtem_initxtilegdp1 "LX: Temp * Poor"
	for num 1/10: label var LXwtem_initxtilegdp2 "LX: Temp * Rich"
	for num 1/10: label var LXwpre_initxtilegdp1 "LX: Precip. * Poor"
	for num 1/10: label var LXwpre_initxtilegdp2 "LX: Precip * Rich"

	* no lags
	cgmreg g wtem_initxtilegdp1 wtem_initxtilegdp2    wpre_initxtilegdp1 wpre_initxtilegdp2 RY* i.cc_num, cluster(parent_num rynum)
	lincom wtem_initxtilegdp1
	local temeffectpoor_coeff = r(estimate)
	local temeffectpoor_se= r(se)
	test wtem_initxtilegdp1 = 0
	local temeffectpoor_p = r(p)
	
	lincom wtem_initxtilegdp2
	local temeffectrich_coeff = r(estimate)
	local temeffectrich_se= r(se)
	test wtem_initxtilegdp2 = 0
	local temeffectrich_p = r(p)
						

end

createsamplemain
maketable3 table3

********************************************************************************

****************************    Model with 1 Lag   *****************************

********************************************************************************
clear
clear matrix
set more off
set matsize 800
set mem 200m
capture log close

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

	***************************************************************************
    *Generate poverty categories per year
	preserve
	keep if rgdpl < . 
	bys fips60_06: keep if _n == 1 
	xtile gdpbin = ln(rgdpl), nq(2)
	keep fips60_06 gdpbin
	tempfile tempxtile
	save `tempxtile',replace
	restore
	
	mmerge fips60_06 using `tempxtile', type(n:1)
	tab gdpbin, g(initxtilegdp)
	***************************************************************************
	
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
		gen `Y'Xrgdpl =`Y'*rgdpl
		for var initxtile*: gen `Y'_X =`Y'*X
			
		label var `Y'Xrgdpl "`Y'.*GDP pc"
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

capture program drop maketable3
program define maketable3
	syntax anything(name=filename)

	********
	* 0 lags, 1 lag, 3 lags, 5 lags, 10 lags
	********
	
	label var wtem_initxtilegdp1 "Temp * Poor"
	label var wtem_initxtilegdp2 "Temp * Rich"
	label var wpre_initxtilegdp1 "Precip. * Poor"
	label var wpre_initxtilegdp2 "Precip * Rich"
	
	for num 1/10: label var LXwtem_initxtilegdp1 "LX: Temp * Poor"
	for num 1/10: label var LXwtem_initxtilegdp2 "LX: Temp * Rich"
	for num 1/10: label var LXwpre_initxtilegdp1 "LX: Precip. * Poor"
	for num 1/10: label var LXwpre_initxtilegdp2 "LX: Precip * Rich"

	* 1 lags
	cgmreg g wtem_initxtilegdp1 L1wtem_initxtilegdp1 wtem_initxtilegdp2 L1wtem_initxtilegdp2           wpre_initxtilegdp1 L1wpre_initxtilegdp1 wpre_initxtilegdp2 L1wpre_initxtilegdp2   RY* i.cc_num, cluster(parent_num rynum)
	lincom wtem_initxtilegdp1 + L1wtem_initxtilegdp1 
	local temeffectpoor_coeff = r(estimate)
	local temeffectpoor_se= r(se)
	test wtem_initxtilegdp1 + L1wtem_initxtilegdp1 = 0
	local temeffectpoor_p = r(p)
	
	lincom wtem_initxtilegdp2 + L1wtem_initxtilegdp2 
	local temeffectrich_coeff = r(estimate)
	local temeffectrich_se= r(se)
	test wtem_initxtilegdp2 + L1wtem_initxtilegdp2 = 0
	local temeffectrich_p = r(p)
		
						
end

createsamplemain
maketable3 table3

********************************************************************************

****************************    Model with 5 Lag   *****************************

********************************************************************************
clear
clear matrix
set more off
set matsize 800
set mem 200m
capture log close

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

	***************************************************************************
    *Generate poverty categories per year
	preserve
	keep if rgdpl < . 
	bys fips60_06: keep if _n == 1 
	xtile gdpbin = ln(rgdpl), nq(2)
	keep fips60_06 gdpbin
	tempfile tempxtile
	save `tempxtile',replace
	restore
	
	mmerge fips60_06 using `tempxtile', type(n:1)
	tab gdpbin, g(initxtilegdp)
	***************************************************************************
	
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
		gen `Y'Xrgdpl =`Y'*rgdpl
		for var initxtile*: gen `Y'_X =`Y'*X
			
		label var `Y'Xrgdpl "`Y'.*GDP pc"
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

capture program drop maketable3
program define maketable3
	syntax anything(name=filename)

	********
	* 0 lags, 1 lag, 3 lags, 5 lags, 10 lags
	********
	
	label var wtem_initxtilegdp1 "Temp * Poor"
	label var wtem_initxtilegdp2 "Temp * Rich"
	label var wpre_initxtilegdp1 "Precip. * Poor"
	label var wpre_initxtilegdp2 "Precip * Rich"
	
	for num 1/10: label var LXwtem_initxtilegdp1 "LX: Temp * Poor"
	for num 1/10: label var LXwtem_initxtilegdp2 "LX: Temp * Rich"
	for num 1/10: label var LXwpre_initxtilegdp1 "LX: Precip. * Poor"
	for num 1/10: label var LXwpre_initxtilegdp2 "LX: Precip * Rich"

	* 5 lags
	cgmreg g wtem_initxtilegdp1 L1wtem_initxtilegdp1 L2wtem_initxtilegdp1 L3wtem_initxtilegdp1 L4wtem_initxtilegdp1 L5wtem_initxtilegdp1 wtem_initxtilegdp2 L1wtem_initxtilegdp2 L2wtem_initxtilegdp2 L3wtem_initxtilegdp2 L4wtem_initxtilegdp2 L5wtem_initxtilegdp2           wpre_initxtilegdp1 L1wpre_initxtilegdp1 L2wpre_initxtilegdp1 L3wpre_initxtilegdp1 L4wpre_initxtilegdp1 L5wpre_initxtilegdp1 wpre_initxtilegdp2 L1wpre_initxtilegdp2 L2wpre_initxtilegdp2 L3wpre_initxtilegdp2 L4wpre_initxtilegdp2 L5wpre_initxtilegdp2 RY* i.cc_num, cluster(parent_num rynum)
	lincom wtem_initxtilegdp1 + L1wtem_initxtilegdp1 + L2wtem_initxtilegdp1 + L3wtem_initxtilegdp1 + L4wtem_initxtilegdp1 + L5wtem_initxtilegdp1 
	local temeffectpoor_coeff = r(estimate)
	local temeffectpoor_se= r(se)
	test wtem_initxtilegdp1 + L1wtem_initxtilegdp1 + L2wtem_initxtilegdp1 + L3wtem_initxtilegdp1 + L4wtem_initxtilegdp1 + L5wtem_initxtilegdp1 = 0
	local temeffectpoor_p = r(p)
		
	lincom wtem_initxtilegdp2 + L1wtem_initxtilegdp2 + L2wtem_initxtilegdp2 + L3wtem_initxtilegdp2 + L4wtem_initxtilegdp2 + L5wtem_initxtilegdp2 
	local temeffectrich_coeff = r(estimate)
	local temeffectrich_se= r(se)
	test wtem_initxtilegdp2 + L1wtem_initxtilegdp2 + L2wtem_initxtilegdp2 + L3wtem_initxtilegdp2 + L4wtem_initxtilegdp2 + L5wtem_initxtilegdp2 = 0
	local temeffectrich_p = r(p)
		
						
end

createsamplemain
maketable3 table3

********************************************************************************

****************************   Model with 10 Lags   ****************************

********************************************************************************
clear
clear matrix
set more off
set matsize 800
set mem 200m
capture log close

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

	***************************************************************************
    *Generate poverty categories per year
	preserve
	keep if rgdpl < . 
	bys fips60_06: keep if _n == 1 
	xtile gdpbin = ln(rgdpl), nq(2)
	keep fips60_06 gdpbin
	tempfile tempxtile
	save `tempxtile',replace
	restore
	
	mmerge fips60_06 using `tempxtile', type(n:1)
	tab gdpbin, g(initxtilegdp)
	***************************************************************************
	
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
		gen `Y'Xrgdpl =`Y'*rgdpl
		for var initxtile*: gen `Y'_X =`Y'*X
			
		label var `Y'Xrgdpl "`Y'.*GDP pc"
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

capture program drop maketable3
program define maketable3
	syntax anything(name=filename)

	********
	* 0 lags, 1 lag, 3 lags, 5 lags, 10 lags
	********
	
	label var wtem_initxtilegdp1 "Temp * Poor"
	label var wtem_initxtilegdp2 "Temp * Rich"
	label var wpre_initxtilegdp1 "Precip. * Poor"
	label var wpre_initxtilegdp2 "Precip * Rich"
	
	for num 1/10: label var LXwtem_initxtilegdp1 "LX: Temp * Poor"
	for num 1/10: label var LXwtem_initxtilegdp2 "LX: Temp * Rich"
	for num 1/10: label var LXwpre_initxtilegdp1 "LX: Precip. * Poor"
	for num 1/10: label var LXwpre_initxtilegdp2 "LX: Precip * Rich"

	* 10 lags
	cgmreg g wtem_initxtilegdp1 L1wtem_initxtilegdp1 L2wtem_initxtilegdp1 L3wtem_initxtilegdp1 L4wtem_initxtilegdp1 L5wtem_initxtilegdp1 L6wtem_initxtilegdp1 L7wtem_initxtilegdp1 L8wtem_initxtilegdp1 L9wtem_initxtilegdp1 L10wtem_initxtilegdp1 wtem_initxtilegdp2 L1wtem_initxtilegdp2 L2wtem_initxtilegdp2 L3wtem_initxtilegdp2 L4wtem_initxtilegdp2 L5wtem_initxtilegdp2 L6wtem_initxtilegdp2 L7wtem_initxtilegdp2 L8wtem_initxtilegdp2 L9wtem_initxtilegdp2 L10wtem_initxtilegdp2 wpre_initxtilegdp1 L1wpre_initxtilegdp1 L2wpre_initxtilegdp1 L3wpre_initxtilegdp1 L4wpre_initxtilegdp1 L5wpre_initxtilegdp1 L6wpre_initxtilegdp1 L7wpre_initxtilegdp1 L8wpre_initxtilegdp1 L9wpre_initxtilegdp1 L10wpre_initxtilegdp1 wpre_initxtilegdp2 L1wpre_initxtilegdp2 L2wpre_initxtilegdp2 L3wpre_initxtilegdp2 L4wpre_initxtilegdp2 L5wpre_initxtilegdp2 L6wpre_initxtilegdp2 L7wpre_initxtilegdp2 L8wpre_initxtilegdp2 L9wpre_initxtilegdp2 L10wpre_initxtilegdp2 RY* i.cc_num, cluster(parent_num rynum)
	lincom wtem_initxtilegdp1 + L1wtem_initxtilegdp1 + L2wtem_initxtilegdp1 + L3wtem_initxtilegdp1 + L4wtem_initxtilegdp1 + L5wtem_initxtilegdp1 + L6wtem_initxtilegdp1 + L7wtem_initxtilegdp1 + L8wtem_initxtilegdp1 + L9wtem_initxtilegdp1 + L10wtem_initxtilegdp1 
	local temeffectpoor_coeff = r(estimate)
	local temeffectpoor_se= r(se)
	test wtem_initxtilegdp1 + L1wtem_initxtilegdp1 + L2wtem_initxtilegdp1 + L3wtem_initxtilegdp1 + L4wtem_initxtilegdp1 + L5wtem_initxtilegdp1 + L6wtem_initxtilegdp1 + L7wtem_initxtilegdp1 + L8wtem_initxtilegdp1 + L9wtem_initxtilegdp1 + L10wtem_initxtilegdp1 = 0
	local temeffectpoor_p = r(p)
		
	lincom wtem_initxtilegdp2 + L1wtem_initxtilegdp2 + L2wtem_initxtilegdp2 + L3wtem_initxtilegdp2 + L4wtem_initxtilegdp2 + L5wtem_initxtilegdp2 + L6wtem_initxtilegdp2 + L7wtem_initxtilegdp2 + L8wtem_initxtilegdp2 + L9wtem_initxtilegdp2 + L10wtem_initxtilegdp2
	local temeffectrich_coeff = r(estimate)
	local temeffectrich_se= r(se)
	test wtem_initxtilegdp2 + L1wtem_initxtilegdp2 + L2wtem_initxtilegdp2 + L3wtem_initxtilegdp2 + L4wtem_initxtilegdp2 + L5wtem_initxtilegdp2 + L6wtem_initxtilegdp2 + L7wtem_initxtilegdp2 + L8wtem_initxtilegdp2 + L9wtem_initxtilegdp2 + L10wtem_initxtilegdp2 = 0
	local temeffectrich_p = r(p)
	
						
end

createsamplemain
maketable3 table3
