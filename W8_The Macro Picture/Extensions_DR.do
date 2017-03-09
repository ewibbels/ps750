***** EXTENSIONS for Ross (BASE: Table 3)

********************************************************************************
***              Extensions: Ideology and Fractionalization                  ***
***                                                                          ***
***    Merging Ross' data with:                                              ***
***    Database of Political Institutions 2012. Philip Keefer, World Bank    ***
********************************************************************************
clear

* Merging datases 

use "/Users/DRomero/Desktop/Econ 750/Replication Ex2/replication data - 5 year panels.dta"

merge 1:1 id period using "/Users/DRomero/Desktop/Econ 750/Replication Ex2/DPI_3.dta"

save "/Users/DRomero/Desktop/Econ 750/Replication Ex2/Ext_Data.dta"

********************************************************************************
***                    New Models                                            ***
********************************************************************************
clear
use "/Users/DRomero/Desktop/Econ 750/Replication Ex2/Ext_Data.dta"
drop year
drop notanymore
*-----> Column 2, Table 3: POLITY
tsset period country
prais logCMRwdi Polity_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1 transition_1 dperiod* IDdum*, robust

*-----> domide: ideology of dominant governing party for the 5 year period
replace domide=. if domide==-999
replace domide=. if domide==0
gen left=.
replace left=1 if domide==3
replace left=0 if domide==2
replace left=0 if domide==1
tsset
prais logCMRwdi left logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1 transition_1 dperiod* IDdum*, robust 

*-----> ruralsup: 1 if governing party has support from rural areas 5 year period
replace ruralsup=. if ruralsup==-999
tsset
prais logCMRwdi ruralsup logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1 transition_1 dperiod* IDdum*, robust 

*-----> herfgov5: herfindahl index for parties in government
tsset
prais logCMRwdi herfgov5 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1 transition_1 dperiod* IDdum*, robust 

*-----> oppfrac: The probability that two deputies picked at random from among the opposition parties will be of different  parties
tsset
prais logCMRwdi oppfrac logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1 transition_1 dperiod* IDdum*, robust 

** NOTE: ruralsup was significat. Use ruralsup and POLITY
tsset
prais logCMRwdi ruralsup Polity_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1 transition_1 dperiod* IDdum*, robust 

** ruralsup interacted with democracy
gen ruralsup_polity = ruralsup*Polity_1
tsset
prais logCMRwdi Polity_1 ruralsup_polity logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1 transition_1 dperiod* IDdum*, robust 

gen ruralsup_polity = ruralsup*Polity_1
tsset
prais logCMRwdi ruralsup ruralsup_polity logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1 transition_1 dperiod* IDdum*, robust 

