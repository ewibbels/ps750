************************
*** REPLICATION FILE
************************

* Harunobu Saijo, Jan Vogler

clear
cd "C:\Users\Jan\OneDrive\Documents\GitHub\ps750\W2_Growth"



************************
*** REPLICATION OF TABLE 1
************************

use gjv, clear

xi: reg urbrate mfgserv_gdp2010 nrx2_mean [pw=pop] if year == 2010, robust