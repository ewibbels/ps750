* Table 1 - High observation and low observation authoritarian states

sum  GDPcap2000_exp  U5MRwdi1970 U5MRwdi2000 if numvalid<75 & polity<0 & fmr_sov==0 & fmr_yug==0 & GDPcap2000!=.
sum  GDPcap2000_exp  U5MRwdi1970 U5MRwdi2000 if numvalid>75 & polity<0 & fmr_sov==0 & fmr_yug==0 & GDPcap2000!=.

* Table 2 - Nonmissing observations in democracies and nondemocracies

reg numvalid under log70_tst ACLP_demyrs, robust
reg numvalid under log70_tst if ACLP_demyrs>15, robust
reg numvalid under log70_tst if ACLP_demyrs<=15, robust
reg numvalid under log70_tst fmr_sov fmr_yug if ACLP_demyrs<=15, robust

* Table 6 - Democracy and public health inequalities in 45 states

reg deliveries Polity99, robust
reg deliveries Polity99 GDPppp99, robust
reg ari Polity99, robust
reg ari Polity99 GDPppp99, robust
reg diarrhea Polity99, robust
reg diarrhea Polity99 GDPppp99, robust

* Figure 2 - Missing observations and regime type
twoway (scatter numvalid polity if fmr_sov==0 & fmr_yug==0 & id!="CZE" & id!="DEU", msymbol(D)), ///
 title("Figure 2: Missing Observations and Regime Type") ///
ytitle("Number of Observations, 1970-2000") xtitle("Mean POLITY Score, 1970-2000") ///
legend(off)  

* Figure 3 - Child health treatments and democracy in 42 developing countries
scatter  Polity99 deliveries, title("Figure 3: Child health treatments and democracy in 42 developing countries", size(medium)) ///
ytitle("Polity Score") xtitle("Diarrhea treatment in public facilities, ratio of richest to poorest quintile") 
