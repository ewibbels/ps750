*Authors: Mitch Watkins and Zeren Li
*PS750 


clear all

set more off

cd "/Users/rogerli/Dropbox/course/Duke 206-2017 Spring/Development/adverse_effect of sunhine/Original Replication Files/"

use "electionresults_replication_public.dta"
*This is the main dataset used for the replication. Additional data files are also included in replication. 
*Clarify.dta is used for Figure 1 and balance.dta is used for summary stats. 
*The version we use is Stata14. 


/* We focus on the replication of the MST's primary results on the effect of transparency on legistlative participiation (speeches and questions). 
The main replication results are found in Table 3 (DIRECT EFFECTS) and Table 5 (INTENSITY OF TREATMENT). 
*/


/***************************************************Index**************************************************

Table3: Panels A, B, and D (Direct Effects) 
Table5: Use internet penetration as a measure of treatment intensity


Extensions: 
E1. Interaction analysis: Distribution of Internet Penetration; See R code. 
E2. Outlier Analysis-Cooks D and bfbeta
E3. Pre-treatments differences in internet penetration and DV Participation variables 


Additional Notable Tables:
Table1: Treatment Control Summary stats
Table 2: Summary of participation in different sessions 



****************************************************************************************************************/



*Creation of varible for use in R code extension. 

g dquestion_count = d.question_count
g dcriticize_total_per = d.criticize_total_per
saveold "/Users/rogerli/Dropbox/course/Duke 206-2017 Spring/Development/adverse_effect of sunhine/Original Replication Files/electionresults_replication_public2.dta",v(12) replace



/******************Table 3 --- Panel A (Page 174)********Diff Between 5 and 6th Sessions - Regressed on Treatment (Diff-in-Diff)*/

/*Diff-in-Diff*/


generate time=0 if session==5
replace time=1 if session==6

xi: reg  question_count i.t2*time if  politburo==0, robust cluster(pci_id)
xi: reg  criticize_total_per  i.t2*time if  politburo==0, robust cluster(pci_id)


xi: reg  d.question_count t2 if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using diff_table3_a, e(all) bdec(3) tdec(3) replace

xi: reg  d.question_count t2 fulltime centralnom retirement if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using diff_table3_a, e(all) bdec(3) tdec(3)

xi: reg  d.question_count t2 interview fulltime centralnom retirement  if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using diff_table3_a, e(all) bdec(3) tdec(3)

xi: reg  d.criticize_total_per t2 if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using diff_table3_a, e(all) bdec(3) tdec(3)

xi: reg  d.criticize_total_per t2 fulltime centralnom retirement if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using diff_table3_a, e(all) bdec(3) tdec(3)

xi: reg  d.criticize_total_per t2 interview fulltime centralnom retirement  if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using diff_table3_a, e(all) bdec(3) tdec(3) excel

/********************************************************************************************************************************/



/*Table 3 --- Panel B (Page 174)********Diff Between Average and 6th Sessions - Regressed on Treatment (Diff-in-Diff)*/

by delegate_id, sort:  egen avg_speech=mean(speaknum_count) if session <5.9
by delegate_id, sort:  egen avg_speechpost=mean(speaknum_count) if session >5.9
generate diff_speech=speaknum_count-l.avg_speech if session==6
lab var diff_speech "Speeches - Difference Between 6th and Delegate Average in Previous Sessions (#)"

 
by delegate_id, sort:  egen avg_quest=mean(question_count) if session <5.9
by delegate_id, sort:  egen avg_questpost=mean(question_count) if session >5.9
generate diff_quest= question_count-l.avg_quest if session==6
lab var diff_quest "Questions - Difference Between 6th and Delegate Average in Previous Sessions (#)"


by delegate_id, sort:  egen avg_crit=mean(criticize_total_per) if session <5.9
by delegate_id, sort:  egen avg_critpost=mean(criticize_total_per) if session >5.9
generate diff_crit=criticize_total_per-l.avg_crit if session==6
lab var diff_quest "Difference Between 6th and Delegate Average in Previous Sessions (% Critical)"



xi: reg  diff_quest t2 if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using diff1_table3_b, e(all) bdec(3) tdec(3) replace

xi: reg  diff_quest t2 fulltime centralnom retirement if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using diff1_table3_b, e(all) bdec(3) tdec(3)

xi: reg  diff_quest t2 interview fulltime centralnom retirement  if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using diff1_table3_b, e(all) bdec(3) tdec(3)

xi: reg diff_crit t2 if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using diff1_table3_b, e(all) bdec(3) tdec(3)

xi: reg  diff_crit t2 fulltime centralnom retirement if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using diff1_table3_b, e(all) bdec(3) tdec(3)

xi: reg  diff_crit t2 interview fulltime centralnom retirement  if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using diff1_table3_b, e(all) bdec(3) tdec(3) excel

/********************************************************************************************************************************/



/*****************************TABLE 3 --- Panel D (Page 174)*********************  Average Treatment Effect*/

sort delegate_id session

xi: reg  question_count t2 if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using ate, e(all) bdec(3) tdec(3) replace

xi: reg  criticize_total_per t2 if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using ate, e(all) bdec(3) tdec(3)

xi: reg  question_count t2 fulltime centralnom retirement if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using ate, e(all) bdec(3) tdec(3)

xi: reg  criticize_total_per t2 fulltime centralnom retirement  if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using ate, e(all) bdec(3) tdec(3)

xi: reg  question_count t2 fulltime centralnom retirement interview if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using ate, e(all) bdec(3) tdec(3)

xi: reg  criticize_total_per t2 fulltime centralnom retirement interview  if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using ate, e(all) bdec(3) tdec(3) excel

/********************************************************************************************************************************/




/*****************************************TABLE 5: Dose Treatment Effect Internet (Panels A&B)*************************************************/  

/*Panel A - Questions*/

xi: reg  d.question_count i.t2 if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Table5, e(all) bdec(3) tdec(3) replace

xi: reg  d.question_count i.t2*internet_users100 if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Table5, e(all) bdec(3) tdec(3)

xi: reg  d.question_count i.t2*internet_users100 centralnom fulltime retirement  if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Table5, e(all) bdec(3) tdec(3)

xi: reg  d.question_count i.t2*internet_users100 centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Table5, e(all) bdec(3) tdec(3)



/*Panel A - Criticism*/

xi: reg  d.criticize_total_per i.t2 if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Table5, e(all) bdec(3) tdec(3)

xi: reg  d.criticize_total_per i.t2*internet_users100 if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Table5, e(all) bdec(3) tdec(3)

xi: reg  d.criticize_total_per i.t2*internet_users100 centralnom fulltime retirement  if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Table5, e(all) bdec(3) tdec(3)

xi: reg  d.criticize_total_per i.t2*internet_users100 centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Table5, e(all) bdec(3) tdec(3)


/*Panel B - Avg. v. 6th*/

xi: reg  diff_quest i.t2*internet_users100 centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Table5, e(all) bdec(3) tdec(3)


xi: reg  diff_crit  i.t2*internet_users100 centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Table5, e(all) bdec(3) tdec(3) excel







/********************************************* EXTENSION 2:*****************************************************************/



*Pretreatment Differencdes in Internet penetration 

*Questions DV
xi: reg  question_count internet_users100 if session==5 & t2==0 & politburo==0, robust cluster(pci_id)
outreg2 using PretreatDiff, e(all) bdec(3) tdec(3)
predict predictq_control


xi: reg  question_count internet_users100 if session==5 & t2==1 & politburo==0, robust cluster(pci_id)
outreg2 using PretreatDiff, e(all) bdec(3) tdec(3)
predict predictq_treated

xi: reg  question_count internet_users100 if session==5 & politburo==0,robust cluster(pci_id)
outreg2 using PretreatDiff, e(all) bdec(3) tdec(3)
predict predictq_all 


label variable predictq_control Control
label variable predictq_treated Treated
label variable predictq_all All


twoway (scatter predictq_control internet_users100, ytitle("Change in Questions")) (scatter predictq_treated internet_users100)  (scatter predictq_all internet_users100)  
	   
graph save Graph "Pretreat_Questions_Internet.gph", replace
	  
	  
	  
*Criticisms DV
xi: reg  criticize_total_per internet_users100 if session==5 & t2==0 & politburo==0, robust cluster(pci_id)
outreg2 using PretreatDiff, e(all) bdec(3) tdec(3)
predict predictc_control


xi: reg  criticize_total_per internet_users100 if session==5 & t2==1 & politburo==0, robust cluster(pci_id)
outreg2 using PretreatDiff, e(all) bdec(3) tdec(3)
predict predictc_treated

xi: reg  criticize_total_per internet_users100 if session==5 & politburo==0,robust cluster(pci_id)
outreg2 using PretreatDiff, e(all) bdec(3) tdec(3) excel
predict predictc_all

label variable predictc_control Control
label variable predictc_treated Treated
label variable predictc_all All

twoway (scatter predictc_control internet_users100, ytitle("Change in Criticism")) (scatter predictc_treated internet_users100)  (scatter predictc_all internet_users100)  
	   

graph save Graph "Pretreat_Criticisms_Internet.gph", replace
	 

	  
	   
*Posttreatment differences 

*Questions DV
xi: reg  question_count internet_users100 if session==6 & t2==0 & politburo==0, robust cluster(pci_id)
outreg2 using PosttreatDiff, e(all) bdec(3) tdec(3)
predict postq_control


xi: reg  question_count internet_users100 if session==6 & t2==1 & politburo==0, robust cluster(pci_id)
outreg2 using PosttreatDiff, e(all) bdec(3) tdec(3)
predict postq_treated

xi: reg  question_count internet_users100 if session==6 & politburo==0 & t2<=1 ,robust cluster(pci_id)
outreg2 using PosttreatDiff, e(all) bdec(3) tdec(3)
predict postq_all 

label variable postq_control Control
label variable postq_treated Treated
label variable postq_all All

	   
twoway (scatter postq_control internet_users100, ytitle("Change in Questions")) (scatter postq_treated internet_users100)  (scatter postq_all internet_users100)  
graph save Graph "Posttreat_Questions_Internet.gph", replace
	 
	   

	  
	  
*Criticisms DV
xi: reg  criticize_total_per internet_users100 if session==6 & t2==0 & politburo==0, robust cluster(pci_id)
outreg2 using PosttreatDiff, e(all) bdec(3) tdec(3)
predict postc_control


xi: reg  criticize_total_per internet_users100 if session==6 & t2==1 & politburo==0, robust cluster(pci_id)
outreg2 using PosttreatDiff, e(all) bdec(3) tdec(3)
predict postc_treated

xi: reg  criticize_total_per internet_users100 if session==6 & politburo==0,robust cluster(pci_id)
outreg2 using PosttreatDiff, e(all) bdec(3) tdec(3) excel
predict postc_all

label variable postc_control Control
label variable postc_treated Treated
label variable postc_all All

twoway (scatter postc_control internet_users100,ytitle("Change in Criticism")) (scatter postc_treated internet_users100)  (scatter postc_all internet_users100)  
graph save Graph "Posttreat_Criticisms_Internet.gph", replace
	   


graph combine Pretreat_Questions_Internet.gph Pretreat_Criticisms_Internet.gph, cols(2) xcommon title("Pre-treatmnet relationship between Participation and Internet", size(small))
graph save pretreat_relationship.gph, replace


graph combine Posttreat_Questions_Internet.gph Posttreat_Criticisms_Internet.gph, cols(2) xcommon title("Post-treatmnet relationship between Participation and Internet", size(small))
graph save posttreat_reatlionship.gph, replace


graph combine pretreat_relationship.gph posttreat_reatlionship.gph, rows(2) xcommon
graph save prepost.gph, replace


	   
	   
	   

/****************************** Extension 1B: Outlier Analysis  **************************************************************************************************/


*Questions DV
xi: reg  d.question_count i.t2*internet_users100 centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0


predict D, cooksd
graph twoway scatter D (delegate_id), msymbol(o)  title("Cook's Distance by Delegate")
graph save Graph "CooksD1.gph", replace

hilo D delegate_id pci_id internet_users100, show(5)


dfbeta
hilo  _dfbeta_2 internet_users100 question_count criticize_total_per t2 delegate_id pci_id, show(5)



*Results disappear by dropping one province (province 1) which has outlier delegates 20 and 21
xi: reg  d.question_count i.t2*internet_users100 centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0 & pci_id!=1


xi: reg  d.question_count i.t2*internet_users100 centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0 & internet_users100<8





*Criticism DV

xi: reg  d.criticize_total_per i.t2*internet_users100 centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0

predict D2, cooksd
graph twoway scatter D2 (delegate_id) , msymbol(o)
graph save Graph "CooksD2.gph", replace

hilo D2 delegate_id pci_id internet_users100, show(20)  ///findit hilo and install the package


dfbeta
hilo  _dfbeta_14 internet_users100 question_count criticize_total_per t2 delegate_id pci_id, show(10)


graph combine CooksD1.gph CooksD2.gph, cols(2) xcommon title("Cooks D for full specifications (Questions and Criticism DVs) in Table 5", size(small))
graph save cooksD.gph, replace




*Again Results disappear by dropping one province (province 1) which has outlier delegates 20 and 21
xi: reg  d.criticize_total_per i.t2*internet_users100 centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0 & pci_id !=1


*Histograms

histogram  internet_users100
histogram  thanh_thi_per
histogram  state_labor_per
histogram  student_per




/****************************** Extension 1C: Drop the outliers and re-run the regression **************************************************************************************************/

#delimit;
xi: reg  d.question_count i.t2*internet_users100 centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id);
outreg2 using extention.xls, e(all) bdec(3) tdec(3) replace;
xi: reg  d.criticize_total_per i.t2*internet_users100 centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id);
outreg2 using extention.xls, e(all) bdec(3) tdec(3) append;
xi: reg  diff_quest i.t2*internet_users100 centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id);
outreg2 using extention.xls, e(all) bdec(3) tdec(3)append ;
xi: reg  diff_crit  i.t2*internet_users100 centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id);
outreg2 using extention.xls, e(all) bdec(3) tdec(3) excel append;

xi: reg  d.question_count i.t2*internet_users100 centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0 & internet_users100<4 , robust cluster(pci_id);
outreg2 using extention.xls, e(all) bdec(3) tdec(3) append;
xi: reg d.criticize_total_per i.t2*internet_users100 centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0 & internet_users100<4 , robust cluster(pci_id);
outreg2 using extention.xls, e(all) bdec(3) tdec(3) append;
xi: reg  diff_quest i.t2*internet_users100 centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0 & internet_users100<4 , robust cluster(pci_id);
outreg2 using extention.xls, e(all) bdec(3) tdec(3)append;
xi: reg  diff_crit  i.t2*internet_users100 centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0 & internet_users100<4 , robust cluster(pci_id);
outreg2 using extention.xls, e(all) bdec(3) tdec(3) append;







**ADDITIONAL TABLE REPLICATIONS-NOT IMPORTANT



/**********************************************Appendix 11 Robust to other Intensity of Treatment Effects*******************************************/


xtset delegate_id session
lab var thanh_thi_per "Urban Population %"
lab var state_labor_per "State Labor Share %"
lab var student_per "College Students %"



/*Panel A - Questions*/

xi: reg  d.question_count i.t2*thanh_thi_per centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Appendix11b, e(all) bdec(3) tdec(3) replace

xi: reg  d.question_count i.t2*state_labor_per centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Appendix11b, e(all) bdec(3) tdec(3)

xi: reg  d.question_count i.t2*student_per centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Appendix11b, e(all) bdec(3) tdec(3)



/*Panel B - Criticism*/

xi: reg  d.criticize_total_per  i.t2*thanh_thi_per  centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Appendix11b, e(all) bdec(3) tdec(3)

xi: reg  d.criticize_total_per  i.t2*state_labor_per centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Appendix11b, e(all) bdec(3) tdec(3)

xi: reg  d.criticize_total_per  i.t2*student_per centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Appendix11b, e(all) bdec(3) tdec(3)



/*Panel B - Questions*/

xi: reg  diff_quest i.t2*thanh_thi_per centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Appendix11b, e(all) bdec(3) tdec(3)

xi: reg  diff_quest i.t2*state_labor_per centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Appendix11b, e(all) bdec(3) tdec(3)

xi: reg  diff_quest i.t2*student_per centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Appendix11b, e(all) bdec(3) tdec(3)



/*Panel B - Criticsm*/

xi: reg  diff_crit  i.t2*thanh_thi_per  centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Appendix11b, e(all) bdec(3) tdec(3)

xi: reg  diff_crit  i.t2*state_labor_per centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Appendix11b, e(all) bdec(3) tdec(3)

xi: reg  diff_crit  i.t2*student_per centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Appendix11b, e(all) bdec(3) tdec(3) excel

/********************************************************************************************************************************/






/*ADDITIONAL TABLES */


/*FIGURE 1: Clarify data created from predictive simulations 90% CI levels */


use clarify.dta, clear



twoway (rcap  low hi internet if type==3)   
(scatter  mean internet if type==3, msymbol(triangle) mcolor(maroon)),
yline(0, lcolor(red) lpattern(dash))
ytitle("Change in Questions Asked", size(medium) margin(medsmall))
xtitle("Internet Subscribers per 100 Citizens", size(medium) margin(medsmall)) 
title("6th Session vs. Average", size(large))
legend(off)

graph save interact_diffquest2.gph, replace



twoway (rcap  low hi internet if type==1)   
(scatter  mean internet if type==1, msymbol(triangle) mcolor(maroon)),
yline(0, lcolor(red) lpattern(dash))
ytitle("Change in Questions Asked", size(medium) margin(medsmall))
xtitle("Internet Subscribers per 100 Citizens", size(medium) margin(medsmall)) 
title("6th vs. 5th Session", size(large))
legend(off)

graph save interact_diffquest1.gph, replace




twoway (rcap  low hi internet if type==4)   
(scatter  mean internet if type==4, msymbol(triangle) mcolor(maroon)),
yline(0, lcolor(red) lpattern(dash))
ytitle("Change in Critical Questions (%)", size(medium) margin(medsmall))
xtitle("Internet Subscribers per 100 Citizens", size(medium) margin(medsmall)) 
title("6th Session vs. Average", size(large))
legend(off)

graph save interact_diffcrit2.gph, replace


twoway (rcap  low hi internet if type==2)   
(scatter  mean internet if type==2, msymbol(triangle) mcolor(maroon)),
yline(0, lcolor(red) lpattern(dash))
ytitle("Change in Critical Questions (%)", size(medium) margin(medsmall))
xtitle("Internet Subscribers per 100 Citizens", size(medium) margin(medsmall)) 
title("6th vs. 5th Session", size(large))
legend(off)


graph save interact_diffcrit1.gph, replace



graph combine interact_diffquest1.gph interact_diffquest2.gph, cols(2) xcommon ycommon title("Change in Questions Asked", size(large))
graph save interact_questions_total.gph, replace


graph combine interact_diffcrit1.gph interact_diffcrit2.gph, cols(2) xcommon ycommon title("Change in Criticism", size(large))
graph save interact_criticism_total.gph, replace


graph combine interact_questions_total.gph interact_criticism_total.gph, rows(2) xcommon
graph save APSR_FIGURE1.gph, replace






/************************************TABLE 1: Summary Statistics for Treatment and Control- Balance Check - Page 772********************************************************/
clear all
set more off 

use balance.dta

preserve

order politburo t2 age male minority party percentage  avg_speech avg_crit gdp pop_stacked internet thanh_thi_per  south transfer student_per centralnominated fulltime avg_quest retirement
mat T= J(18,2,1000)
mat rownames T=age male minority party percentage  avg_speech avg_crit gdp pop_stacked internet thanh_thi_per  south transfer student_per centralnominated fulltime avg_quest retirement
mat colnames T=T2_P T2_T  

	local counter=0
	
	foreach v of varlist age-retirement{
		local counter = `counter'+1
		tabstat `v' if t2==1 & politburo==0, stat(mean sd min max)
		tabstat `v' if t2==0 & politburo==0, stat(mean sd min max)
		ttest `v' if polit==0, by(t2) unequal
		mat T[`counter',1]=r(p)
		mat T[`counter',2]=r(t)	
	}

mat list T

restore







/**********************TABLE 2******************************/

tabstat speaknum_count question_count criticize_total_per local_total_per cutri_total_per if session<7, by(session) stat(mean)
tabstat speaknum_count question_count criticize_total_per local_total_per cutri_total_per if session<7 & question_count>1 & question_count !=., by(session)





/**********************************************Table 6: Debate Speeches*********************Difference in Levels*/



xi: reg  debate_speeches i.t2 if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Table6, e(all) bdec(3) tdec(3) replace

xi: reg  debate_speeches i.t2*internet if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Table6, e(all) bdec(3) tdec(3)

xi: reg  debate_speeches i.t2*internet centralnom fulltime retirement  if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Table6, e(all) bdec(3) tdec(3)

xi: reg  debate_speeches i.t2*internet centralnom fulltime retirement  city ln_gdpcap ln_pop transfer south unweighted if session==6 & politburo==0, robust cluster(pci_id)
outreg2 using Table6, e(all) bdec(3) tdec(3) excel

/***********************************************************************************************************************/






/***************************************Table 3: Panel C - Difference Between Ministers********************/

use minister_replication2.dta, replace



/*Replication of Analysis by Minister************************************************************************************************/


xi: reg  diff3_quest i.t2 if  politburo==0, robust cluster(pci_id)
outreg2 using Table3_C, e(all) bdec(3) tdec(3) replace

xi: reg  diff3_quest i.t2 fulltime centralnom retirement  if  politburo==0, robust cluster(pci_id)
outreg2 using Table3_C, e(all) bdec(3) tdec(3)

xi: reg  diff3_quest i.t2 interview fulltime centralnom retirement  if  politburo==0, robust cluster(pci_id)
outreg2 using Table3_C, e(all) bdec(3) tdec(3)

xi: reg  diff3_crit i.t2 if politburo==0, robust cluster(pci_id)
outreg2 using Table3_C, e(all) bdec(3) tdec(3)

xi: reg  diff3_crit i.t2 fulltime centralnom retirement  if  politburo==0, robust cluster(pci_id)
outreg2 using Table3_C, e(all) bdec(3) tdec(3)

xi: reg  diff3_crit i.t2 interview fulltime centralnom retirement  if  politburo==0, robust cluster(pci_id)
outreg2 using Table3_C, e(all) bdec(3) tdec(3) excel

/********************************************************************************************************************************/





/*Interaction Difference 2*/

xi: reg  diff3_quest i.t2*fulltime centralnom retirement  if politburo==0, robust cluster(pci_id)
outreg2 using Appendix9, e(all) bdec(3) tdec(3) replace

xi: reg  diff3_quest i.t2*centralnom fulltime  retirement  if politburo==0, robust cluster(pci_id)
outreg2 using Appendix9, e(all) bdec(3) tdec(3)

xi: reg  diff3_quest i.t2*retirement centralnom fulltime  if politburo==0, robust cluster(pci_id)
outreg2 using Appendix9, e(all) bdec(3) tdec(3)

xi: reg diff3_quest i.t2*percentage retirement centralnom fulltime   if politburo==0, robust cluster(pci_id)
outreg2 using Appendix9, e(all) bdec(3) tdec(3)

/********************************************************************************************************************************/




xi: reg  diff3_crit i.t2*fulltime centralnom retirement  if politburo==0, robust cluster(pci_id)
outreg2 using Appendix9, e(all) bdec(3) tdec(3)

xi: reg  diff3_crit i.t2*centralnom fulltime  retirement  if politburo==0, robust cluster(pci_id)
outreg2 using Appendix9, e(all) bdec(3) tdec(3)

xi: reg  diff3_crit i.t2*retirement centralnom fulltime  if politburo==0, robust cluster(pci_id)
outreg2 using Appendix9, e(all) bdec(3) tdec(3)

xi: reg  diff3_crit i.t2*percentage retirement centralnom fulltime  if politburo==0, robust cluster(pci_id)
outreg2 using Appendix9, e(all) bdec(3) tdec(3) excel

/********************************************************************************************************************************/


