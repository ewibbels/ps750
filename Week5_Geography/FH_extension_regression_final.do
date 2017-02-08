set matsize 800
set mem 200m
capture log close

cd "/Users/deandulay/Desktop"

use climate_religion_merged.dta

rename wtem temperature
rename wpre precipitation


xi: reg nonreligpct temperature temp_poor precipitation pre_poor year_region_* i.cc_num poor_year_FE, cluster(parent)
estimates store m1

xi: reg chrstgenpct temperature precipitation pre_poor year_region_* i.cc_num poor_year_FE, cluster(parent)
estimates store m2

xi: reg islmgenpct temperature precipitation pre_poor year_region_* i.cc_num poor_year_FE, cluster(parent)
estimates store m3

/* create a Herfindahl Index */
foreach b in chrstgenpct judgenpct islmgenpct budgenpct othrgenpct nonreligpct {
gen `b'_sq=`b'^2
}

gen hhi_1=chrstgenpct_sq + judgenpct_sq + islmgenpct_sq + budgenpct_sq + othrgenpct_sq + nonreligpct_sq


xi: reg hhi_1 temperature temp_poor precipitation pre_poor year_region_* i.cc_num poor_year_FE, cluster(parent)
estimates store m4

estout m1 m2 m3 m4 using "Table1.tex", cells(b(star fmt(3)) se(par fmt(2))) legend label varlabels(_cons Constant) stats(r2 N, fmt(3) label(R-squared Observations))  indicate("RegionxYear FE =year_region_*"  "Country FE=_Icc*"  "FE=poor_year_FE"  ) style(tex) replace
