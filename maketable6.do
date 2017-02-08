clear
clear matrix
clear mata
set more off
set matsize 800
set mem 200m
capture log close

global rfe = 1 /*1 for region*year, 2 for year only*/
global maineffectsonly = 0 /*1 to drop all interactions*/

capture program drop createsamplefirstyear20yrs
program define createsamplefirstyear20yrs
	* This sample is the sample of all countries 
	* Init GDP is defined based on your first year in the data
	* Must have at least 20 years of GDP data
	use climate_panel, clear
	
	  
	
	* restrict to 2003
	keep if year <= 2003
	
	encode parent, g(parent_num)
	
	gen lgdp=ln(gdpLCU)
	
	encode fips60_06, g(cc_num)
	sort country_code year
	tsset cc_num year
	
	*calculate GDP growth
	gen temp1 = l.lgdp
	gen g=lgdp-temp1
	replace g = g * 100 
	drop temp1
	summarize g
	
	g lnag = ln(gdpWDIGDPAGR) 
	g lnind = ln(gdpWDIGDPIND) 
		g lninvest = ln(rgdpl*ki/100)
	
	g lngdpwdi = ln(gdpLCU)
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
	
end

capture program drop maketable6
program define maketable6
	syntax anything(name=filename)
	
	****************************************************************
	* Make the political variables, and then merge into the main dataset
	****************************************************************
	
	tempfile initialdata temppolity tempfips temparchigos tempconflict 
	drop _merge
	sort fips60_06 year
	save `initialdata', replace
	
	
	*******************
	* Code polity
	******************
	
	use polity, clear

	gen politychange=.
	replace politychange=1 if polity!=lpolity & polity != . & lpolity != .
	recode politychange .=0
	label var politychange "dummy for politychange in polity score between t and t-1"
	
	rename inter polityinter
	
	save `temppolity', replace

	*********************
	* Code Archigos data
	*********************
	
	clear
	insheet using fips_to_cow.csv
	sort ccode
	save `tempfips', replace
	
	use Archigos.dta, clear

	*--create some variables--*
	replace startdate="09/11/1942" if startdate=="9/11/1942"
	replace startdate="01/01/2001" if startdate=="1/1/2001"
	replace startdate="01/01/2002" if startdate=="1/1/2002"
	replace startdate="14/09/1923" if startdate=="14/9/1923"
	keep ccode startdate entry
	gen year=substr(startdate,7,4)
	destring year, replace
	drop if year<1950
	tab year
	recode entry 2=1 /*transition imposed by other country coded as irregular*/
	tab entry
	sort ccode
	
	replace ccode=679 if ccode==680 /*combining Yemen pre and post 1990*/
	replace ccode=255 if (ccode==260 & year==1998) /*separating post-unification
		Germany from West Germany*/
	sort ccode
	merge ccode using `tempfips', uniqusing
	tab _merge
	keep if _merge==3 /*_merge==1s are places like Bavaria that no longer exist
		and East/West Germany, South Vietnam, which we are dropping and thus
		were excluded from the code conversion list without leader data*/
		/*merge==2s are places in the code list without transition data, like
		Monaco, Kiribat, and the Federal States of Micronesia*/
	drop _merge
			
	*---code countries whose borders have changed---*
	
	*aggregate to country*year observations
	rename fips_code fips
	gen fips60_06=fips
	replace fips60_06=	"PBD"	if (fips==	"PK"	& year <	1971	)
	replace fips60_06=	"ETR"	if (fips==	"ET"	& year <	1993	)
	replace fips60_06=	"NSA"	if (fips==	"SF"	& year <	1990	)
	replace fips60_06=	"SVT"	if (fips==	"RS"	& year <	1992	)
	/*codebook takes care of Yugoslavia and Czechoslovakia, because these
		have COW codes*/
	sort fips60_06
		
	*---create some variables---*
	collapse (sum)entry, by (year fips60_06)
	
	recode entry 2/7=1 /*some countries have more than one transition in a given
		year. If any of the transitions were irregular, I code that year as 
		experiencing an irregular transition*/
	sort fips60_06 
	save `temparchigos', replace
	

	********************************
	* Code conflict
	********************************
	

	
	clear
  insheet using fips_to_cow.csv
  sort ccode
  save temp, replace
	
	clear
	insheet using prio.csv
	
	rename gwnoa countrya 
	rename gwnob countryb
	gen countryc=.
	gen countryd=.
	gen countrye=.
	gen countryf=.
	replace countryc=666 if countrya=="220, 666, 200"
	replace countryc=645 if countryb=="651, 645, 663, 660, 652"
	replace countryc=200 if countryb=="900, 200, 2"
	replace countryd=200 if countrya=="220, 666, 200"
	replace countryd=663 if countryb=="651, 645, 663, 660, 652"
	replace countryd=2 if countryb=="900, 200, 2"
	replace countrye=660 if countryb=="651, 645, 663, 660, 652"
	replace countryf=652 if countryb=="651, 645, 663, 660, 652"
	replace countrya="220" if countrya=="220, 666, 200"
	replace countryb="651" if countryb=="651, 645, 663, 660, 652"
	replace countryb="900" if countryb=="900, 200, 2"
	
	destring countrya, replace
	destring countryb, replace
	replace countrya=. if countrya==-99
	g intensitycivil = intensity
	replace intensitycivil = 0 if type != 3 & type != 4 & intensitycivil != .
	
	gen obs=_n
	reshape long country, i(obs) j(temp) str
	
	
	
	keep  year intensity country intensitycivil
	drop if country==.
	drop if year<1950
	
	rename country ccode
	replace ccode=679 if ccode==680 /*combining Yemen pre and post 1990*/
	sort ccode
	merge ccode using temp, uniqusing
	tab _merge
	/*the _merge==1s are Yemen (pre-1950, before climate data) and South Vietnam*/
	/*the _merge==2s are countries not in the conflict table*/
	keep if _merge==3
	drop _merge
	
	
	*---code countries whose borders have changed---*
	
	*aggregate to country*year observations
	rename fips_code fips
	gen fips60_06=fips
	replace fips60_06=	"PBD"	if (fips==	"PK"	& year <	1971	)
	replace fips60_06=	"ETR"	if (fips==	"ET"	& year <	1993	)
	replace fips60_06=	"NSA"	if (fips==	"SF"	& year <	1990	)
	replace fips60_06=	"SVT"	if (fips==	"RS"	& year <	1992	)
	/*codebook takes care of Yugoslavia and Czechoslovakia, because these
		have COW codes*/

	
	
	***************
	* Merge datasets
	****************

	*****************
	* Merge conflict and create vars
	*****************
	collapse intensity intensitycivil, by (fips60_06 year)
    sort fips60_06 year
    merge fips60_06 year using `initialdata', unique
  tab _merge
  /*the _merge==1s are Georgia, Croatia, and Bosnia. They are in the conflicts
  	data before I code them as a state (i.e. conflict in Yugoslavia ->
  	split categorized as conflict in Croatia and Bosnia)*/
  drop if _merge==1
  drop _merge
  
 replace intensity=0 if intensity==.
 tab intensity

  
  collapse (max) intensity, by (fips60_06 year)
  sort fips60_06 year
    merge fips60_06 year using `initialdata', unique
  tab _merge
  /*the _merge==1s are Georgia, Croatia, and Bosnia. They are in the conflicts
  	data before I code them as a state (i.e. conflict in Yugoslavia ->
  	split categorized as conflict in Croatia and Bosnia)*/
  drop if _merge==1
  drop _merge
  
  *-------code the dependent variables-------*
  /*Varaiable defintions:
  
  I define seven conflict variables:
  
  *---Overall---*
  	
  change: any change in conflict status
  
  *---Conditional on the conflict being in process---*
  	
  mod2n: conflict change -> no war | in a moderate conflict
  int2n: conflict change -> no war | in an intense conflict
  war2n: conflict change -> no war | in an intense or moderate conflict
  
  *---Conditional on conflict not being in process---*
  	
  n2mod: conflict change -> moderate | not at war
  n2int:conflict change -> intense | not at war
  n2war: conflict change -> (moderate or intense) | not at war
  */
  
  sort cc_num year
  tsset cc_num year
  
  gen lintensity=l.intensity
  drop if year==1950 
  gen change=.
  replace change=1 if lintensity!=intensity
  recode change .=0
  gen mod2n=.
  replace mod2n=1 if (intensity==0 & lintensity==1)
  replace mod2n=0 if (intensity!=0 & lintensity==1)
  replace mod2n=. if (lintensity==0 | lintensity==2)
  gen int2n=.
  replace int2n=1 if (intensity==0 & lintensity==2)
  replace int2n=0 if (intensity!=0 & lintensity==2)
  replace int2n=. if (lintensity==0 | lintensity==1)
  gen war2n=.
  replace war2n=1 if (intensity==0 & (lintensity==1 | lintensity==2))
  replace war2n=0 if (intensity!=0 & (lintensity==1 | lintensity==2))
  replace war2n=. if lintensity==0
  gen n2mod=.
  replace n2mod=1 if (intensity==1 & lintensity==0)
  replace n2mod=0 if (intensity!=1 & lintensity==0)
  replace n2mod=. if lintensity!=0
  gen n2int=.
  replace n2int=1 if (intensity==2 & lintensity==0)
  replace n2int=0 if (intensity!=2 & lintensity==0)
  replace n2int=. if lintensity!=0
  gen n2war=.
  replace n2war=1 if (intensity==1 & lintensity==0)
  replace n2war=1 if (intensity==2 & lintensity==0)
  replace n2war=0 if (intensity==0 & lintensity==0)
  replace n2war=. if lintensity!=0
  
  tab change
  tab mod2n
  tab int2n
  tab war2n
  tab n2mod
  tab n2int
  tab n2war
  drop lintensity* intensity*
  foreach X in change mod2n int2n war2n n2mod n2int n2war {
  	tab `X'
  }
  	
	*-----------------------gen a parent country var for clustering------------------------------------*
	capture{
		gen parentconflict=fips
		replace parentconflict=	"PBD"	if (fips==	"PK"	)
		replace parentconflict=	"PBD"	if (fips==	"BG"	)
		replace parentconflict=	"CZK"	if (fips==	"LO"	)
		replace parentconflict=	"CZK"	if (fips==	"EZ"	)
		replace parentconflict=	"ETR"	if (fips==	"ET"	)
		replace parentconflict=	"ETR"	if (fips==	"ER"	)
		replace parentconflict=	"YGL"	if (fips==	"BK"	)
		replace parentconflict=	"YGL"	if (fips==	"HR"	)
		replace parentconflict=	"YGL"	if (fips==	"MK"	)
		replace parentconflict=	"YGL"	if (fips==	"SI"	)
		replace parentconflict=	"YGL"	if (fips==	"YI"	)
		replace parentconflict=	"NSA"	if (fips==	"SF"	)
		replace parentconflict=	"NSA"	if (fips==	"WA"	)
		replace parentconflict=	"SVT"	if (fips==	"AM"	)
		replace parentconflict=	"SVT"	if (fips==	"AJ"	)
		replace parentconflict=	"SVT"	if (fips==	"BO"	)
		replace parentconflict=	"SVT"	if (fips==	"EN"	)
		replace parentconflict=	"SVT"	if (fips==	"GG"	)
		replace parentconflict=	"SVT"	if (fips==	"KZ"	)
		replace parentconflict=	"SVT"	if (fips==	"KG"	)
		replace parentconflict=	"SVT"	if (fips==	"LG"	)
		replace parentconflict=	"SVT"	if (fips==	"LH"	)
		replace parentconflict=	"SVT"	if (fips==	"MD"	)
		replace parentconflict=	"SVT"	if (fips==	"RS"	)
		replace parentconflict=	"SVT"	if (fips==	"TI"	)
		replace parentconflict=	"SVT"	if (fips==	"TX"	)
		replace parentconflict=	"SVT"	if (fips==	"UP"	)
		replace parentconflict=	"SVT"	if (fips==	"UZ"	)
		}
		
	
	***************
	* Merge polity
	**************
	
	drop if fips60_06 == "" | year == .
	mmerge fips60_06 year using `temppolity', type(1:1)
	tab _merge
	drop if _merge == 2
	* This means that we keep only observations that were in our original sample

	
	
	
	
	****************
	* Merge archigos
	****************
	
	
	mmerge fips60_06 year using `temparchigos', type(1:1)
	tab _merge
	
	drop if _merge==2 
	
	gen lt=.
	replace lt=0 if _merge==1
	replace lt=1 if _merge==3
	tab lt
	count
	
	gen regtr=.
	replace regtr=1 if entry==0
	recode regtr .=0
	
	gen irregtr=.
	replace irregtr=1 if entry==1
	recode irregtr .=0


	
	drop _merge
	
	*--Create a region x year variable for clustering
	
	g region=""
	foreach X in _MENA   _SSAF   _LAC    _WEOFF  _EECA   _SEAS {
		replace region="`X'" if `X'==1
	}
	
	g regionyear=region+string(year)
	encode regionyear, g(rynum)	
	
	************************************
	* Make tables
	***********************************	
	if $maineffectsonly != 1 {
	
	* Polity - change

	cgmreg politychange  wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
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
		
	outreg wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  using `filename', 3aster coefastr se  replace title("Political variables") adec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p',"Pre effect on poor countries",`preeffectpoor_coeff',"SE2",`preeffectpoor_se',"p2", `preeffectpoor_p')
	
	
	
	* Polity - interregnum
	cgmreg polityinter wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
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
		
		
	outreg wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  using `filename', 3aster coefastr se  append adec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p',"Pre effect on poor countries",`preeffectpoor_coeff',"SE2",`preeffectpoor_se',"p2", `preeffectpoor_p')

	
	* Archigos - leader transition
	cgmreg lt wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
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
		
		
	outreg wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  using `filename', 3aster coefastr se  append adec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p',"Pre effect on poor countries",`preeffectpoor_coeff',"SE2",`preeffectpoor_se',"p2", `preeffectpoor_p')
	
	* Archigos - regular transition
	cgmreg regtr wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
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
		
		
	outreg wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  using `filename', 3aster coefastr se  append adec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p',"Pre effect on poor countries",`preeffectpoor_coeff',"SE2",`preeffectpoor_se',"p2", `preeffectpoor_p')
		
	* Archigos - irregular transition
	cgmreg irregtr wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  RY* i.cc_num, cluster(parent_num rynum)
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
		
		
	outreg wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  using `filename', 3aster coefastr se  append adec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p',"Pre effect on poor countries",`preeffectpoor_coeff',"SE2",`preeffectpoor_se',"p2", `preeffectpoor_p')
	
	
	* Conflict - no war to war
	cgmreg n2war wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  yr* i.cc_num, cluster(parent_num rynum)
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
		
		
	outreg wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  using `filename', 3aster coefastr se  append adec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p',"Pre effect on poor countries",`preeffectpoor_coeff',"SE2",`preeffectpoor_se',"p2", `preeffectpoor_p')
	
	* Conflict - war to no war
	cgmreg war2n wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  yr* i.cc_num, cluster(parent_num rynum)
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
		
		
	outreg wtem wtem_initxtilegdp1 wpre wpre_initxtilegdp1  using `filename', 3aster coefastr se  append adec(3) adds("Tem effect on poor countries",`temeffectpoor_coeff',"SE1",`temeffectpoor_se',"p1", `temeffectpoor_p',"Pre effect on poor countries",`preeffectpoor_coeff',"SE2",`preeffectpoor_se',"p2", `preeffectpoor_p')

	}
	else {
		if $maineffectsonly == 1 {
		
		* Polity - change
		cgmreg politychange  wtem wpre RY* i.cc_num, cluster(parent_num rynum)
			
		outreg wtem wpre using `filename', 3aster coefastr se  replace title("Political variables") 
		
		
		
		* Polity - interregnum
		cgmreg polityinter wtem wpre RY* i.cc_num, cluster(parent_num rynum)
				
		outreg wtem wpre using `filename', 3aster coefastr se  append 
		
		* Archigos - leader transition
		cgmreg lt wtem wpre RY* i.cc_num, cluster(parent_num rynum)
				
		outreg wtem wpre using `filename', 3aster coefastr se  append 
		
		* Archigos - regular transition
		cgmreg regtr wtem wpre RY* i.cc_num, cluster(parent_num rynum)
				
		outreg wtem wpre using `filename', 3aster coefastr se  append 
		
		* Archigos - irregular transition
		cgmreg irregtr wtem wpre RY* i.cc_num, cluster(parent_num rynum)
				
		outreg wtem wpre using `filename', 3aster coefastr se  append 
		

		
		* Conflict - no war to war
		cgmreg n2war wtem wpre RY* i.cc_num, cluster(parent_num rynum)
				
		outreg wtem wpre using `filename', 3aster coefastr se  append 
		
		
		* Conflict - war to no war
		cgmreg war2n wtem wpre RY* i.cc_num, cluster(parent_num rynum)
				
		outreg wtem wpre using `filename', 3aster coefastr se  append 

		}
	}
end

createsamplefirstyear20yrs

tempfile tempsamplefirstyear20yrs
save `tempsamplefirstyear20yrs',replace

use `tempsamplefirstyear20yrs',clear
maketable6 071004_20yrs_firstyear_table6 
