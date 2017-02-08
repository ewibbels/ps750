clear
clear matrix
set more off
set matsize 800
set mem 200m
capture log close

global rfe = 1 /*1 for region*year, 2 for year only*/
global maineffectsonly = 0 /*1 to drop all interactions*/

	use climate_panel, clear
		  
	
	* restrict to 2003
	keep if year <= 2003
		
	encode parent, g(parent_num)
		
	encode fips60_06, g(cc_num)
	sort country_code year
	tsset cc_num year
	
	g lngdpwdi = ln(gdpLCU)
	g lgdppwt=ln(rgdpl)
	
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


	* create mean temperatures for different time periods
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp50sX = mean(X) if year >= 1951 & year <= 1960 \ bys fips60_06: egen mean50sX = mean(temp50sX)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp60sX = mean(X) if year >= 1961 & year <= 1970 \ bys fips60_06: egen mean60sX = mean(temp60sX)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp70sX = mean(X) if year >= 1971 & year <= 1980 \ bys fips60_06:  egen mean70sX = mean(temp70sX)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp80sX = mean(X) if year >= 1981 & year <= 1990 \ bys fips60_06:  egen mean80sX = mean(temp80sX)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp90sX = mean(X) if year >= 1991 & year <= 2000 \ bys fips60_06:  egen mean90sX = mean(temp90sX)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp00sX = mean(X) if year >= 1994 & year <= 2003 \ bys fips60_06: egen mean00sX = mean(temp00sX)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp84sX = mean(X) if year >= 1984 & year <= 1993 \ bys fips60_06: egen mean84sX = mean(temp84sX)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp64sX = mean(X) if year >= 1964 & year <= 1973 \ bys fips60_06: egen mean64sX = mean(temp64sX)
	
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp7085X = mean(X) if year >= 1970 & year <= 1985 \ bys fips60_06: egen mean7085X = mean(temp7085X)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp8600X = mean(X) if year >= 1986 & year <= 2000 \ bys fips60_06: egen mean8600X = mean(temp8600X)	
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp7086X = mean(X) if year >= 1970 & year <= 1986 \ bys fips60_06: egen mean7086X = mean(temp7086X)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp8703X = mean(X) if year >= 1987 & year <= 2003 \ bys fips60_06: egen mean8703X = mean(temp8703X)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp7087X = mean(X) if year >= 1970 & year <= 1987 \ bys fips60_06: egen mean7087X = mean(temp7087X)
	for var wtem wpre g gpwt gag gind ginvest : bys fips60_06: egen temp8803X = mean(X) if year >= 1988 & year <= 2003 \ bys fips60_06: egen mean8803X = mean(temp8803X)

	
	for var wtem wpre g gpwt gag gind ginvest : g change0050sX = mean00sX - mean50sX 
	for var wtem wpre g gpwt gag gind ginvest : g change0060sX = mean00sX - mean60sX 
	for var wtem wpre g gpwt gag gind ginvest : g change0070sX = mean00sX - mean70sX 
	for var wtem wpre g gpwt gag gind ginvest : g change0080sX = mean00sX - mean80sX 
	for var wtem wpre g gpwt gag gind ginvest : g change0090sX = mean00sX - mean90sX 
	
	for var wtem wpre g gpwt gag gind ginvest : g change9050sX = mean90sX - mean50sX 
	for var wtem wpre g gpwt gag gind ginvest : g change9060sX = mean90sX - mean60sX 
	for var wtem wpre g gpwt gag gind ginvest : g change9070sX = mean90sX - mean70sX 
	for var wtem wpre g gpwt gag gind ginvest : g change9080sX = mean90sX - mean80sX 
	
	for var wtem wpre g gpwt gag gind ginvest : g change8450sX = mean84sX - mean50sX 
	for var wtem wpre g gpwt gag gind ginvest : g change8460sX = mean84sX - mean60sX 
	for var wtem wpre g gpwt gag gind ginvest : g change8470sX = mean84sX - mean70sX 
	for var wtem wpre g gpwt gag gind ginvest : g change8480sX = mean84sX - mean80sX 
	for var wtem wpre g gpwt gag gind ginvest : g change8490sX = mean84sX - mean90sX 
	
	for var wtem wpre g gpwt gag gind ginvest : g change0064sX = mean00sX - mean64sX 
	
	for var wtem wpre g gpwt gag gind ginvest : g changeS1X = mean8600X - mean7085X 
	for var wtem wpre g gpwt gag gind ginvest : g changeS2X = mean8703X - mean7086X 	
	for var wtem wpre g gpwt gag gind ginvest : g changeS3X = mean8803X - mean7087X 	
	
	for var change*: g Xxtilegdp1 = X * initxtilegdp1
	
	for var change*wtem: label var X "Change in tem"
	for var change*wpre: label var X "Change in pre"
	for var change*wtemxtilegdp1: label var X "Change in tem * poor"
	for var change*wprextilegdp1: label var X "Change in pre * poor"
	
	
	************
	* Comparing 1986-2000 to 1970-1985 (SPLIT 1)
	************
	
	* Column 1: no Region fixed effect 

	reg changeS1g changeS1wtem changeS1wpre changeS1wtemxtilegdp1 changeS1wprextilegdp1 initxtilegdp1 if year == 2003 , robust
	lincom changeS1wtem + changeS1wtemxtilegdp1 
	local temeffectpoor_coeff = r(estimate)
	local temeffectpoor_se= r(se)
	test changeS1wtem + changeS1wtemxtilegdp1 = 0
	local temeffectpoor_p = r(p)
	
	lincom changeS1wpre + changeS1wprextilegdp1 
	local preeffectpoor_coeff = r(estimate)
	local preeffectpoor_se= r(se)
	test changeS1wpre + changeS1wprextilegdp1 = 0
	local preeffectpoor_p = r(p)
	outreg2 changeS1wtem changeS1wpre changeS1wtemxtilegdp1 changeS1wprextilegdp1 initxtilegdp1 using table7, excel less(0) nocons bdec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p',"Pre effect on poor countries",`preeffectpoor_coeff',"SE2",`preeffectpoor_se',"p2", `preeffectpoor_p') replace ctitle("7085 - 8600")

	* Column 2: add poor dummy and region FE
	reg changeS1g changeS1wtem changeS1wpre changeS1wtemxtilegdp1 changeS1wprextilegdp1 initxtilegdp1 _MENA _SSAF _LAC _EECA _SEAS if year == 2003 , robust
	lincom changeS1wtem + changeS1wtemxtilegdp1 
	local temeffectpoor_coeff = r(estimate)
	local temeffectpoor_se= r(se)
	test changeS1wtem + changeS1wtemxtilegdp1 = 0
	local temeffectpoor_p = r(p)
	
	lincom changeS1wpre + changeS1wprextilegdp1 
	local preeffectpoor_coeff = r(estimate)
	local preeffectpoor_se= r(se)
	test changeS1wpre + changeS1wprextilegdp1 = 0
	local preeffectpoor_p = r(p)
	outreg2 changeS1wtem changeS1wpre changeS1wtemxtilegdp1 changeS1wprextilegdp1 initxtilegdp1 _MENA _SSAF _LAC _EECA _SEAS using table7, excel less(0) nocons bdec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p',"Pre effect on poor countries",`preeffectpoor_coeff',"SE2",`preeffectpoor_se',"p2", `preeffectpoor_p') append ctitle("7085 - 8600")


	************
	* Comparing 1988-2003 to 1970-1987 (SPLIT 3)
	************
	* Column 3: add poor dummy and region FE
	reg changeS3g changeS3wtem changeS3wpre changeS3wtemxtilegdp1 changeS3wprextilegdp1 initxtilegdp1 _MENA _SSAF _LAC _EECA _SEAS if year == 2003 , robust
	lincom changeS3wtem + changeS3wtemxtilegdp1 
	local temeffectpoor_coeff = r(estimate)
	local temeffectpoor_se= r(se)
	test changeS3wtem + changeS3wtemxtilegdp1 = 0
	local temeffectpoor_p = r(p)
	
	lincom changeS3wpre + changeS3wprextilegdp1 
	local preeffectpoor_coeff = r(estimate)
	local preeffectpoor_se= r(se)
	test changeS3wpre + changeS3wprextilegdp1 = 0
	local preeffectpoor_p = r(p)
	outreg2 changeS3wtem changeS3wpre changeS3wtemxtilegdp1 changeS3wprextilegdp1 initxtilegdp1 _MENA _SSAF _LAC _EECA _SEAS using table7, excel less(0) nocons bdec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p',"Pre effect on poor countries",`preeffectpoor_coeff',"SE2",`preeffectpoor_se',"p2", `preeffectpoor_p') append ctitle("7087 - 8803")
	
		*60s

	reg change9060sg change9060swtem change9060swpre change9060swtemxtilegdp1 change9060swprextilegdp1 initxtilegdp1 _MENA _SSAF _LAC _EECA _SEAS if year == 2003 , robust
	lincom change9060swtem + change9060swtemxtilegdp1 
	local temeffectpoor_coeff = r(estimate)
	local temeffectpoor_se= r(se)
	test change9060swtem + change9060swtemxtilegdp1 = 0
	local temeffectpoor_p = r(p)
	
	lincom change9060swpre + change9060swprextilegdp1 
	local preeffectpoor_coeff = r(estimate)
	local preeffectpoor_se= r(se)
	test change9060swpre + change9060swprextilegdp1 = 0
	local preeffectpoor_p = r(p)
	outreg2 change9060swtem change9060swpre change9060swtemxtilegdp1 change9060swprextilegdp1 initxtilegdp1 _MENA _SSAF _LAC _EECA _SEAS using table7, excel less(0) nocons bdec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p',"Pre effect on poor countries",`preeffectpoor_coeff',"SE2",`preeffectpoor_se',"p2", `preeffectpoor_p') append ctitle("1960s - 9100")
	
	
	*70s

	reg change9070sg change9070swtem change9070swpre change9070swtemxtilegdp1 change9070swprextilegdp1 initxtilegdp1 _MENA _SSAF _LAC _EECA _SEAS if year == 2003 , robust
	lincom change9070swtem + change9070swtemxtilegdp1 
	local temeffectpoor_coeff = r(estimate)
	local temeffectpoor_se= r(se)
	test change9070swtem + change9070swtemxtilegdp1 = 0
	local temeffectpoor_p = r(p)
	
	lincom change9070swpre + change9070swprextilegdp1 
	local preeffectpoor_coeff = r(estimate)
	local preeffectpoor_se= r(se)
	test change9070swpre + change9070swprextilegdp1 = 0
	local preeffectpoor_p = r(p)
	outreg2 change9070swtem change9070swpre change9070swtemxtilegdp1 change9070swprextilegdp1 initxtilegdp1 _MENA _SSAF _LAC _EECA _SEAS using table7, excel less(0) nocons bdec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p',"Pre effect on poor countries",`preeffectpoor_coeff',"SE2",`preeffectpoor_se',"p2", `preeffectpoor_p') append ctitle("1970s - 9100")
	
	
	*80s

	reg change9080sg change9080swtem change9080swpre change9080swtemxtilegdp1 change9080swprextilegdp1 initxtilegdp1 _MENA _SSAF _LAC _EECA _SEAS if year == 2003 , robust
	lincom change9080swtem + change9080swtemxtilegdp1 
	local temeffectpoor_coeff = r(estimate)
	local temeffectpoor_se= r(se)
	test change9080swtem + change9080swtemxtilegdp1 = 0
	local temeffectpoor_p = r(p)
	
	lincom change9080swpre + change9080swprextilegdp1 
	local preeffectpoor_coeff = r(estimate)
	local preeffectpoor_se= r(se)
	test change9080swpre + change9080swprextilegdp1 = 0
	local preeffectpoor_p = r(p)
	outreg2 change9080swtem change9080swpre change9080swtemxtilegdp1 change9080swprextilegdp1 initxtilegdp1 _MENA _SSAF _LAC _EECA _SEAS using table7, excel less(0) nocons bdec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p',"Pre effect on poor countries",`preeffectpoor_coeff',"SE2",`preeffectpoor_se',"p2", `preeffectpoor_p') append ctitle("1980s - 9100")
	
*******************
	* Only Africa
*******************

	reg changeS1g changeS1wtem changeS1wpre if year == 2003 & _SSAF==1 & initxtilegdp1==1, robust
	
	outreg2 changeS1wtem changeS1wpre using table7, excel less(0) nocons bdec(3) append ctitle("7085 - 8600")

	* Not Africa
	reg changeS1g changeS1wtem changeS1wpre changeS1wtemxtilegdp1 changeS1wprextilegdp1 initxtilegdp1 _MENA _SSAF _LAC _EECA _SEAS if year == 2003 & _SSAF==0, robust
	lincom changeS1wtem + changeS1wtemxtilegdp1 
	local temeffectpoor_coeff = r(estimate)
	local temeffectpoor_se= r(se)
	test changeS1wtem + changeS1wtemxtilegdp1 = 0
	local temeffectpoor_p = r(p)
	
	lincom changeS1wpre + changeS1wprextilegdp1 
	local preeffectpoor_coeff = r(estimate)
	local preeffectpoor_se= r(se)
	test changeS1wpre + changeS1wprextilegdp1 = 0
	local preeffectpoor_p = r(p)
	outreg2 changeS1wtem changeS1wpre changeS1wtemxtilegdp1 changeS1wprextilegdp1 initxtilegdp1 using table7, excel less(0) nocons bdec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p',"Pre effect on poor countries",`preeffectpoor_coeff',"SE2",`preeffectpoor_se',"p2", `preeffectpoor_p') append ctitle("7085 - 8600")


	* Column 9: pwt data
	reg changeS1gpwt changeS1wtem changeS1wpre changeS1wtemxtilegdp1 changeS1wprextilegdp1 initxtilegdp1 _MENA _SSAF _LAC _EECA _SEAS if year == 2003 , robust
	lincom changeS1wtem + changeS1wtemxtilegdp1 
	local temeffectpoor_coeff = r(estimate)
	local temeffectpoor_se= r(se)
	test changeS1wtem + changeS1wtemxtilegdp1 = 0
	local temeffectpoor_p = r(p)
	
	lincom changeS1wpre + changeS1wprextilegdp1 
	local preeffectpoor_coeff = r(estimate)
	local preeffectpoor_se= r(se)
	test changeS1wpre + changeS1wprextilegdp1 = 0
	local preeffectpoor_p = r(p)
	outreg2 changeS1wtem changeS1wpre changeS1wtemxtilegdp1 changeS1wprextilegdp1 initxtilegdp1 _MENA _SSAF _LAC _EECA _SEAS using table7, excel less(0) nocons bdec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p',"Pre effect on poor countries",`preeffectpoor_coeff',"SE2",`preeffectpoor_se',"p2", `preeffectpoor_p') append ctitle("7085 - 8600")


