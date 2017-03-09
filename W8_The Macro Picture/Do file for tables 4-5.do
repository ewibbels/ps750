* Table 4 - regression with filled-in data set
miest mr1 xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1  , corr(psar1)
miest mr1 xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   PolityB_1 , corr(psar1)
miest mr1 xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   PolityB_1 dperiod*, corr(psar1)
miest mr1 xtpcse logCMRwdi  logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   PolityB_1 dperiod* IDdum*, corr(psar1)
miest mr1 xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   logDEMYRS_1 , corr(psar1)
miest mr1 xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   logDEMYRS_1 dperiod*, corr(psar1)
miest mr1 xtpcse logCMRwdi  logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   logDEMYRS_1 dperiod* IDdum*, corr(psar1)

/*This works */
xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1  , corr(psar1)
xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   PolityB_1 , corr(psar1)
xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   PolityB_1 dperiod*, corr(psar1)
xtpcse logCMRwdi  logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   PolityB_1 dperiod* IDdum*, corr(psar1)
xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   logDEMYRS_1 , corr(psar1)
xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   logDEMYRS_1 dperiod*, corr(psar1)
xtpcse logCMRwdi  logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   logDEMYRS_1 dperiod* IDdum*, corr(psar1)



*Table 5 - Summary of results with alternative measures of infant and child mortality, using filled-in data
miest mr1 xtpcse logIMRwdi  logIMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1  PolityB_1 , corr(psar1)
miest mr1 xtpcse logIMRwdi  logIMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1  PolityB_1 dperiod*, corr(psar1)
miest mr1 xtpcse logIMRwdi  logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1  PolityB_1 dperiod* IDdum*, corr(psar1)
miest mr1 xtpcse logIMRunicef logIMRunicef_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1  PolityB_1 , corr(psar1)
miest mr1 xtpcse logIMRunicef  logIMRunicef_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1  PolityB_1 dperiod*, corr(psar1)
miest mr1 xtpcse logIMRunicef  logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1  PolityB_1 dperiod* IDdum*, corr(psar1)
miest mr1 xtpcse logCMRunicef  logCMRunicef_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1  PolityB_1 , corr(psar1)
miest mr1 xtpcse logCMRunicef  logCMRunicef_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1  PolityB_1 dperiod*, corr(psar1)
miest mr1 xtpcse logCMRunicef  logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1  PolityB_1 dperiod* IDdum*, corr(psar1)
miest mr1 xtpcse logCMRwho  logCMRwho_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1  PolityB_1 , corr(psar1)
miest mr1 xtpcse logCMRwho  logCMRwho_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1  PolityB_1 dperiod*, corr(psar1)
miest mr1 xtpcse logCMRwho  logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1  PolityB_1 dperiod* IDdum*, corr(psar1)


