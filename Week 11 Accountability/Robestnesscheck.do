capture clear
capture log close
set mem 128m
set more off
set matsize 1000

log using robestnesscheck.log,name(robestnesscheck) text replace


use "/Users/Eason/Downloads/Survey_AJPS_3.dta", clear

generate h0m1=0
replace h0m1=1 if responsibleschools=="2"
generate h0m2=0
replace h0m2=1 if responsibleclinics=="2"
generate h0m3=0
replace h0m3=1 if responsibletaxes=="2"
generate h0m4=0
replace h0m4=1 if responsiblewater=="2"
generate h0m5=0
replace h0m5=1 if responsibleconflict=="2"
generate h0m6=.
replace h0m6=1 if budget==2
replace h0m6=0 if budget==1
generate h0m7=.
replace h0m7=1 if budgetbig==1
replace h0m7=0 if budgetbig==2
destring notsecret, generate(h0m8)
replace h0m8=. if h0m8==88 | h0m8==0
replace h0m8=-h0m8
generate h0m9=.
replace h0m9=1 if retrovoting==1
replace h0m9=0 if retrovoting==2
generate h0m10=nprojectsfuture
generate h0m20=0
replace h0m20=1 if paybirthcert=="0"
destring   agreemultiparty  agreerespectauth  agreestrongopposition agreestrongchief  agreegenderequal, replace
generate h0m21=agreemultiparty
generate h0m22=7-agreerespectauth
generate h0m23=7-agreestrongchief
generate h0m24=agreegenderequal
generate h0m25=7-agreestrongopposition
generate h0m26=infoperform

foreach var of varlist h0m20 h0m21 h0m22 h0m23 h0m24 h0m25 h0m26{
macro drop _mean _sd
su `var' if t==0
local mean = r(mean)
local sd = r(sd)
replace `var'=(`var'-`mean')/`sd'
}

egen indexexpectnew = rowmean(h0m1 h0m2 h0m3 h0m4 h0m5 h0m6 h0m7 h0m8 h0m9 h0m10 h0m20 h0m21 h0m22 h0m23 h0m24 h0m25)

generate t2hi=0
generate t2low=0
su indexi
replace t2hi=1 if t==2 & indexi>=`r(mean)'
replace t2low=1 if t==2 & indexi<`r(mean)'

bsample round(0.6*_N), strata(vid)

xtmixed indexexpectnew t1 t2 i.enumerator i.block, ||cid: ||village:

outreg2 using "/Users/Eason/Desktop/robestnesscheck.docx", replace keep(t1 t2 t2hi t2low)

xtmixed indexexpectnew t1 t2hi t2low i.enumerator i.block, ||cid: ||village:

outreg2 using "/Users/Eason/Desktop/robestnesscheck.docx", append keep(t1 t2 t2hi t2low) 

clear

log close robestnesscheck
exit, clear
