replace authoritarian=0 if authoritarian==.
encode cabb, g(new_cabb)
xtset new_cabb period

xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   authoritarian, corr(psar1) /* Column 2*/
outreg using Binary, replace
xtpcse logCMRwdi logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1  authoritarian  IDdum*, corr(psar1) /* Column 3*/
outreg using Binary, merge


/* Looking within authoritarian countries */
replace military_new5=0 if military_new5==.
gen military_auth=authoritarian*military_new5
xtpcse logCMRwdi  logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1 authoritarian military_new5 IDdum*, corr(psar1)
replace opposition 

xtpcse logCMRwdi  logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1 authoritarian IDdum*, corr(psar1)


