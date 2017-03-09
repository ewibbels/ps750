* Replication for Ross Table 3
 
*with 'transition' variable
prais logCMRwdi  logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1 transition_1 dperiod* IDdum*, robust 
xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1 transition_1 Polity_1 , corr(psar1) 
xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1 transition_1 Polity_1  dperiod*, corr(psar1) 
prais logCMRwdi  logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1 transition_1 Polity_1 dperiod* IDdum*, robust 
xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1 transition_1 logDEMYRS_1, corr(psar1) 
xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1 transition_1 logDEMYRS_1 dperiod*, corr(psar1) 
prais logCMRwdi  logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1 transition_1 logDEMYRS_1 dperiod* IDdum*, robust 

* without 'transition' variable
xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1, corr(psar1)  /*Column 1*/
xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   Polity_1 , corr(psar1) /* Column 2*/
xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   Polity_1  dperiod*, corr(psar1) /* Column 3*/
prais logCMRwdi  logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   Polity_1 dperiod* IDdum*, robust /*Column 4 */
xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   logDEMYRS_1, corr(psar1) /* Column 5 */
xtpcse logCMRwdi  logCMRwdi_1 logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   logDEMYRS_1 dperiod*, corr(psar1)  /*Column 6 */
prais logCMRwdi  logGDPcap_1  logHIV_1 logDen_1 GDPgrowth_1   logDEMYRS_1 dperiod* IDdum*, robust /* Column 7 */

