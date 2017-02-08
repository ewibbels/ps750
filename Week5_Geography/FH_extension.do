set matsize 800
set mem 200m
capture log close

cd "/Users/deandulay/Desktop"

use climate_panel, clear

keep if year <= 2003


/*g tempnonmis = 1 if g != .
	replace tempnonmis = 0 if g == .
	bys fips60_06: egen tempsumnonmis = sum(tempnonmis)
	drop if tempsumnonmis  < 20*/
	
/*generate cc_ variable - country dummies */
encode fips60_06, g(cc_num)
sort country_code year
tsset cc_num year

/* generate temperature interactions */
/* first generate a poor dummy */
gen poor_country=1 if lnrgdpl_t0 <=7.831997
replace poor_country=0 if poor_country==.

/* now creat interactions*/
gen temp_poor=wtem*poor
gen pre_poor= wpre*poor

/* generate poor-year FE */
gen poor_year_FE=year*poor

/* generate region-year FE */
foreach a in _MENA _SSAF _LAC _WEOFF _EECA _SEAS {
gen year_region_`a'= `a'*year

}

merge country_code year using religion

/* cleaning by removing missing data for key variables */

drop if sumreligpct==.
drop if wtem==.


xi: reg nonreligpct wtem temp_poor wpre pre_poor year_region_* i.cc_num poor_year_FE, cluster(parent)
estimates store m1
outreg using Table1, replace

xi: reg chrstgenpct wtem pre_poor year_region_* i.cc_num poor_year_FE, cluster(parent)
estimates store m2
outreg using Table1, merge

xi: reg islmgenpct wtem pre_poor year_region_* i.cc_num poor_year_FE, cluster(parent)
estimates store m3
outreg using Table1, merge

/* create a Herfindahl Index */
foreach b in chrstgenpct judgenpct islmgenpct budgenpct othrgenpct nonreligpct {
gen `b'_sq=`b'^2
}

gen hhi_1=chrstgenpct_sq + judgenpct_sq + islmgenpct_sq + budgenpct_sq + othrgenpct_sq + nonreligpct_sq


xi: reg hhi_1 wtem temp_poor wpre pre_poor year_region_* i.cc_num poor_year_FE, cluster(parent)
estimates store m4
outreg using Table1, merge

estout m1 m2 m3 m4 using "Table1.tex", cells(b(star fmt(3)) se(par fmt(2))) legend label varlabels(_cons Constant) stats(r2 N, fmt(3) label(R-squared Observations))  indicate("RegionxYear FE =year_region_*"  "Country FE=_Icc*"  "FE=poor_year_FE"  ) style(tex) replace

/* stylized facts - are the poor more religious? */

foreach b in _MENA _SSAF _LAC _WEOFF _EECA _SEAS {
gen temp_region_`b'= `b'*temperature
}



/*Using outreg*/
xi: reg nonreligpct temperature temp_poor precipitation pre_poor year_region_* i.cc_num poor_year_FE, cluster(parent)
outreg using Table1, replace

xi: reg chrstgenpct temperature temp_poor precipitation pre_poor year_region_* i.cc_num poor_year_FE, cluster(parent)
outreg using Table1, merge

xi: reg islmgenpct temperature temp_poor precipitation pre_poor year_region_* i.cc_num poor_year_FE, cluster(parent)
outreg using Table1, merge

xi: reg hhi_1 temperature temp_poor precipitation pre_poor year_region_* i.cc_num poor_year_FE, cluster(parent)
outreg using Table1, merge

xi: reg hhi_1 temperature temp_poor precipitation pre_poor temp_region_* year_region_* i.cc_num poor_year_FE, cluster(parent)





