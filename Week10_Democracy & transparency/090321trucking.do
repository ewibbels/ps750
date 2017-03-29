

version 9.2
set seed 1000
set matsize 5000
capture log close
log using 090321truckinglog.log,t replace


*****************
* This do file creates the tables and figures for "The Simple Economics of Extortion"
* It is designed to run on Stata 9.2 or higher 
* It uses several input files
*    codedkabmerged.dta -- this is a file at the district level that has aggregate information about the amount paid to pass through each district
*    codedperpost.dta --- this is a file at the checkpoint level that has information about the transaction at that checkpoint
*    codedtripinfo.dta ---  this is a file at the trip level with information about trip characteristics
* 
* Note that province 11 is Aceh and province 12 is North Sumatra, following Indonesian government conventions
* 
* Ben Olken and Patrick Barron
* March 23, 2009
******************



* main tables and figures
local dotable1 = 1
local dotable2 = 1
local dotable3 = 1
local dotable4 = 1
local dotable5 = 1
local dotable6 = 1
local dotable7 = 1
local dofigure3 = 1

* additional robustness analysis
local docapTanalysis = 1



**************
* Table 1: Summary stats
**************
if `dotable1' == 1 {
  *****CHECK IF WE NEED ALL THESE VARIABLES
	use codedkabmerged,clear
	
	* Note that all expense categories coded as missing are actually zeros
	for var zexp*: replace X = 0 if X == .
	
	* Calculate total expenditures
	bys trid: egen ztotexpposts = sum(ztotkabpayment)
	bys trid: egen ztotnumposts = sum(ztotkabposts)
	
	* Aggregate expenses summarized district-by-district in the data
	g provid = substr(zpostkabid,1,2)
	bys trid provid: egen tempztotexpposts = sum(ztotkabpayment)
	bys trid provid: egen tempztotnumposts = sum(ztotkabposts)
	g tempavgpaymentaceh = tempztotexpposts / tempztotnumposts if provid == "11"
	g tempavgpaymentsumatra = tempztotexpposts / tempztotnumposts if provid == "12"
	bys trid: egen avgpaymentaceh = mean(tempavgpaymentaceh)
	bys trid: egen avgpaymentsumatra = mean(tempavgpaymentsumatra )
	
	bys trid: g avgpayment = ztotexpposts / ztotnumposts 
	bys trid: egen ztotexpjemb = sum(ztotkabjembpaid)
	
	* Reduce to one observation per trip
	bys trid: keep if _n == 1
	
	* Code the expense variables that are one per trip
	g ztotexpconvoy = ztruckconvoyprice if ztruckconvoy == 1
	replace ztotexpconvoy = 0 if ztruckconvoy == 0
	g ztotexpprotection = zusedasaamt if zusedasaamt != .
	for var zusedmonth*: replace ztotexpprotection = ztotexpprotection + X / (zdrivertrips * 2) if X != . & zdrivertrips != .
	g ztotexpbribesextortionconvoy = ztotexpposts + ztotexpjemb + ztotexpconvoy + ztotexpprotection 
	g ztotexpfuel = zexpA 
	g ztotexpsalary = zdriverpertripsalary 
	replace ztotexpsalary = ztotexpsalary + zdriverasstsalary if zdriverasstsalary != .
	g ztotexpfood = zexpB 
	g ztotexploadunload = zexpC + zexpD
	g ztotexpother = zexpK 
	
	for num 1/5: replace ztotexpother = ztotexpother + zexpVX if index(ztypeexpotherVX,"BAN") != 0 | index(ztypeexpotherVX,"BENGKEL") != 0 | index(ztypeexpotherVX,"CUCI") != 0 | index(ztypeexpotherVX,"REM") != 0 | index(ztypeexpotherVX,"SIRAM") != 0 | index(ztypeexpotherVX,"BAN") != 0 | index(ztypeexpotherVX,"TARIK") != 0 | index(ztypeexpotherVX,"PERBAIKI") != 0 | index(ztypeexpotherVX,"SERVICE") != 0 | index(ztypeexpotherVX,"SERVIS") != 0 | index(ztypeexpotherVX,"TAMBAL") != 0 | index(ztypeexpotherVX,"VELG") != 0 | index(ztypeexpotherVX,"DONGKRAK") != 0 | index(ztypeexpotherVX,"KOMISI") != 0 | index(ztypeexpotherVX,"PARKIR") != 0 | index(ztypeexpotherVX,"BAN") != 0 | index(ztypeexpotherVX,"KECELAKAAN") != 0 | index(ztypeexpotherVX,"KACA") != 0 | index(ztypeexpotherVX,"OLI") != 0
	for num 1/5: replace ztotexpfood = ztotexpfood + zexpVX if index(ztypeexpotherVX,"KAMAR") != 0 | index(ztypeexpotherVX,"CASETTE") != 0 | index(ztypeexpotherVX,"PENGINAPA") != 0 | index(ztypeexpotherVX,"ROKOK UNTUK SOPIR") != 0 | index(ztypeexpotherVX,"ROKOK SOPIR") != 0 | index(ztypeexpotherVX,"BUAH") != 0 
	
	g ztotexpall = ztotexpbribesextortionconvoy + ztotexpsalary + ztotexpfuel + ztotexpfood + ztotexploadunload + ztotexpother

  * label variables
  label var ztotexpall "Total expenditure on trip"
  label var ztotexpbribesextortionconvoy "Bribes, extortion, and protection payments"
  label var ztotexpposts "Payments at checkpoints"
  label var ztotexpjemb "Payments at weigh stations"
  label var ztotexpconvoy "Convoy fees"
  label var ztotexpprotection "Coupons / protection fees"
  label var ztotexpfuel "Fuel"
  label var ztotexpsalary "Salary for truck driver and assistant"
  label var ztotexploadunload "Loading and unloading of cargo"
  label var ztotexpother "Other"
  label var ztotexpfood "Food, lodging, etc"
  label var ztotnumposts "Number of checkpoints"
  label var avgpayment "Average payment at checkpoint "
	
** create driver's residual 
 gen resi= ztruckuangjalan-ztotexpall+ztotexpprotection
 keep trid resi
 save resi,replace 

	tabstat ztotexpall ztotexpbribesextortionconvoy ztotexpposts ztotexpjemb ztotexpconvoy ztotexpprotection ztotexpfuel ztotexpsalary ztotexploadunload ztotexpother ztotexpfood ztotnumposts avgpayment if ztotexpsalary != . , s(mean sd) col(stat)
	count if ztotexpsalary != .  
	
	
	*** By route
	tabstat ztotexpall ztotexpbribesextortionconvoy ztotexpposts ztotexpjemb ztotexpconvoy ztotexpprotection ztotexpfuel ztotexpsalary ztotexploadunload ztotexpother ztotexpfood ztotnumposts avgpayment if ztotexpsalary != .  & zroute == "M", s(mean sd) col(stat)
	count if ztotexpsalary != .  & zroute == "M"
	tabstat ztotexpall ztotexpbribesextortionconvoy ztotexpposts ztotexpjemb ztotexpconvoy ztotexpprotection ztotexpfuel ztotexpsalary ztotexploadunload ztotexpother ztotexpfood ztotnumposts avgpayment if ztotexpsalary != . & zroute == "B", s(mean sd) col(stat)
	count if ztotexpsalary != .  & zroute == "B"
}	


**************
* Table 2: Impact of withdrawals
**************
if `dotable2' == 1 {	

	use codedkabmerged,clear
	
	
			
	***************************
	* Code basic variables we need for analysis
	***************************
	
	g tripinterval = round(ztripdate / 14) 
	g tripmonth = year(ztripdate)*100+ month(ztripdate)
	g BAroute = (zroute == "B") if zroute != ""
	g ztroopstnispecialbripolB = ztroopstnispecialbripol*BAroute
	g ztroopsremaintnispecialbripolB = ztroopsremaintnispecialbripol*BAroute
	
	for var ztotkabpayment ztotkabposts : g lnX = ln(X)
	for var ztroopsremaintnispecialbripol : g lX = ln(X)
	for var ztroopsremaintnispecialbripol : replace lX = 0 if substr(zpostkabid,1,2) == "12" /*since no data for sumatra this shoudl just be 0, not missing*/
	g lztroopsremaintnispecialbripolB = lztroopsremaintnispecialbripol*BAroute
	

	tempfile temppremerge
	save temppremerge,replace
		
		
	********************
	* Post level analysis
	********************
	
	* Merge in post level data
	mmerge trid zpostkabid using codedperpost, type(1:n) ukeep(zpost*)
	
	* Make variable for payment at post
	g lnzpostpayment = ln(zpostpayment)
	
	* Make post id, defined as unique of subdistrictid (zpostkecid) and which organization runs the post (zpostwhostops)
	egen postidkec = group(zpostkecid zpostwhostops )
	
	
	***************
	* Clutsering / FE vars
	***************
	capture drop postmonth
	capture drop postdirmonth
	egen postmonth = group(zpostkecid zpostwhostops tripmonth)
	egen postdirmonth = group(zpostkecid zpostwhostops tripmonth zroutetoaceh)
	egen postdir = group(zpostkecid zpostwhostops zroutetoaceh zroute)
	egen post = group(zpostkecid zpostwhostops )
	
	tempfile temp2
	save temp2,replace		
	
	** Get aggregate variables from kab dataset above
	use temppremerge,clear
	g zprovid = substr(zpostkabid,1,2)
	
	collapse (sum) ztotkabposts ztroopsremaintnispecialbripol ztroopsremaintnispecialbripolB ztroopsremaintni ztroopsremaintnispecial ztroopsremainbri ztroopsremainpol ztroopsremainbkosamapta, by(trid zprovid)
	ren ztotkabposts ztotprovposts
	reshape wide ztotprovposts ztroopsremaintnispecialbripol ztroopsremaintnispecialbripolB ztroopsremaintni ztroopsremaintnispecial ztroopsremainbri ztroopsremainpol ztroopsremainbkosamapta, i(trid) j(zprovid) string
	sort trid
	tempfile postsfile
	save postsfile,replace
		
	** Go back to checkpoint level data and merge in
	use temp2
	
	mmerge trid using postsfile
	g zprovid = substr(zpostkabid,1,2)
	egen tripintervalroute = group(tripinterval zroute)
	
	
	
	for var ztroopsremaintnispecialbripol ztroopsremaintni ztroopsremaintnispecial ztroopsremainbrimob ztroopsremainpol ztroopsremainbkosamapta : g lX11 = ln(X11)
	
	g lztroopsremain11 = ln(ztroopsremaintnispecialbripol11)	
	
	g lztroopsremainB11 = lztroopsremain11 * BA
	
	
	
	****************
	* include some control vars
	****************
	g truckage = 2006 - ztruckyear
	g truckage2 = truckage^2
	g lnsal = ln(zdrivermonthlysalary)
	g ztruckovertons = max(ztruckweight - ztruckmaxweight,0)
		
	capture drop tf* ztotkab*
	capture drop typenum* withdrawal* number*	
	local postlevelcluster = "post" /*what variable to cluster on for post level regresions*/


	* Create a posts variable by adding banda aceh posts to mean number of north sumatra posts over entire sample for each route
	bys zroute: egen meanpostsnorthsumatra12 = mean(ztotprovposts12)
	g lnztotallposts = ln(ztotprovposts11+meanpostsnorthsumatra12 )
	
	* Create expected total posts variable, where we calculate a drivers' expectation of how many posts they would face in aceh based on comparable trips
	
	preserve
		bys trid: keep if _n == 1
		bys tripinterval zroute: egen tempsumpostsaceh = sum(ztotprovposts11)
		bys tripinterval zroute: egen tempcountpostsaceh = count(ztotprovposts11)
		g temppredpostsaceh = (tempsumpostsaceh - ztotprovposts11) / (tempcountpostsaceh - 1)
		capture drop meanpostsnorthsumatra12 
		bys zroute: egen meanpostsnorthsumatra12 = mean(ztotprovposts12)
		
		g lnmeantotprovposts11  = ln(temppredpostsaceh + meanpostsnorthsumatra12 )
		tempfile tempposts11
		keep trid lnmeantotprovposts11  
		save tempposts11, replace
	restore
	mmerge trid using tempposts11, type(n:1)
	assert _merge == 3
	drop _merge

	capture drop t?
	
	* Create cubic in time
	g t1 = ztripdate-mdy(1,1,2005)
	g t2 = t1^2
	g t3 = t1^3
	
	* Create the log actual number of posts
	g lntotactualposts = ln(ztotprovposts11 + ztotprovposts12)
	
  
	***********************
	* Regressions for Table 2, Panel A
	***********************
	
 	xi: bencgmreg lnzpostpayment lnmeantotprovposts11 i.postdir if zprovid == "12" & zroute == "M",  cluster1("post") cluster2(trid) numrealvars(1) 
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 using table2a, 3aster coefastr se ctitle("OLS") replace title("price") adds("Test elas = -1",r(p),"Test elas = 0",`testp0')
		
		
	xi: bencgmreg lnzpostpayment lnmeantotprovposts11 truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal i.postdir if zprovid == "12" & zroute == "M", cluster1("post") cluster2(trid) numrealvars(1) 
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 using table2a, 3aster coefastr se ctitle("OLS") append adds("Test elas = -1",r(p),"Test elas = 0",`testp0')
	
	xi: bencgmreg lnzpostpayment lnmeantotprovposts11 truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal i.postdir if zprovid == "12" & zroute == "M" & ztripdate <= mdy(4,4,2006), cluster1("post") cluster2(trid) numrealvars(1) 
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 using table2a, 3aster coefastr se ctitle("OLS") append adds("Test elas = -1",r(p),"Test elas = 0",`testp0')
	
		
	xi: bencgmreg lnmeantotprovposts11  lztroopsremain11 truckage truckage2  zincludedC* ztruckovertons lnsal i.postdir if zprovid == "12" & zroute == "M", cluster1("post") cluster2(trid) numrealvars(1)
	testparm lztroopsremain11 
	local FirstF = r(chi2)
	
	xi: bencgmreg lnzpostpayment truckage truckage2  zincludedC* ztruckovertons lnsal i.postdir if zprovid == "12" & zroute == "M", cluster1("post") cluster2(trid) numrealvars(1) ivendogvars(lnmeantotprovposts11) ivinstruments(lztroopsremain11)
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 using table2a, 3aster coefastr se ctitle("OLS") append adds("Test elas = -1",r(p),"Test elas = 0",`testp0', "First-stage F",`FirstF')
	
	
	
	
	xi: bencgmreg lnzpostpayment lnmeantotprovposts11 t? truckage truckage2  zincludedC* ztruckovertons lnsal i.postdir  if zprovid == "12" ,  cluster1("post") cluster2(trid) numrealvars(4) 
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	local testp1 = r(p)
	outreg lnmeantotprovposts11 t? using table2a, 3aster coefastr se ctitle("Both routes with Time Cubic - D-in-D") append adds("Test elas = -1",`testp1',"Test elas = 0",`testp0')  bd(3)
	outreg lnmeantotprovposts11 t? using table2a_referee, 3aster coefastr se ctitle("Both routes with Time Cubic - D-in-D") replace adds("Test elas = -1",`testp1',"Test elas = 0",`testp0')  bd(6)
	
	
	xi: bencgmreg lnzpostpayment lnmeantotprovposts11 truckage truckage2  zincludedC* ztruckovertons lnsal i.postdir i.tripmonth if zprovid == "12" ,  cluster1("post") cluster2(trid) numrealvars(1) 
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 using table2a, 3aster coefastr se ctitle("Both routes with Month FE") append adds("Test elas = -1",r(p),"Test elas = 0",`testp0')
	
	
	xi: bencgmreg lnzpostpayment lnmeantotprovposts11 i.postdir if zprovid == "12" & zroute == "B", cluster1("post") cluster2(trid) numrealvars(1) 
	**** Note that I droop empities because it gets dropped anyway by this regression
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 using table2a_referee, 3aster coefastr se ctitle("Banda Aceh Only") append adds("Test elas = -1",r(p),"Test elas = 0",`testp0')
	
	xi: bencgmreg lnzpostpayment lnmeantotprovposts11 truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal i.postdir if zprovid == "12" & zroute == "B", cluster1("post") cluster2(trid) numrealvars(1) 
	**** Note that I droop empities because it gets dropped anyway by this regression
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 using table2a_referee, 3aster coefastr se ctitle("Banda Aceh Only") append adds("Test elas = -1",r(p),"Test elas = 0",`testp0')
	
	
	
	
	
**************
* Robustness check version of table2a 
* Uses total posts and instruments with predicted posts, rather than using predicted posts directly
***************	

	xi: bencgmreg lnzpostpayment  i.postdir if zprovid == "12" & zroute == "M",  cluster1("post") cluster2(trid) numrealvars(1) ivendogvars(lntotactualposts) ivinstruments(lnmeantotprovposts11)
	test lntotactualposts = 0
	local testp0 = r(p)
	test lntotactualposts = -1
	outreg lntotactualposts using table2a_msmtiv, 3aster coefastr se ctitle("OLS") replace title("price") adds("Test elas = -1",r(p),"Test elas = 0",`testp0')
		
		
		
	xi: bencgmreg lnzpostpayment truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal i.postdir if zprovid == "12" & zroute == "M", cluster1("post") cluster2(trid) numrealvars(1) ivendogvars(lntotactualposts) ivinstruments(lnmeantotprovposts11) 
	**** Note that I droop empities because it gets dropped anyway by this regression
	test lntotactualposts = 0
	local testp0 = r(p)
	test lntotactualposts = -1
	outreg lntotactualposts using table2a_msmtiv, 3aster coefastr se ctitle("OLS") append adds("Test elas = -1",r(p),"Test elas = 0",`testp0')
	
	xi: bencgmreg lnzpostpayment truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal i.postdir if zprovid == "12" & zroute == "M" & ztripdate <= mdy(4,4,2006), cluster1("post") cluster2(trid) numrealvars(1) ivendogvars(lntotactualposts) ivinstruments(lnmeantotprovposts11)
	**** Note that I droop empities because it gets dropped anyway by this regression
	test lntotactualposts = 0
	local testp0 = r(p)
	test lntotactualposts = -1
	outreg lntotactualposts using table2a_msmtiv, 3aster coefastr se ctitle("OLS") append adds("Test elas = -1",r(p),"Test elas = 0",`testp0')
		
	
	xi: bencgmreg lnzpostpayment truckage truckage2  zincludedC* ztruckovertons lnsal i.postdir if zprovid == "12" & zroute == "M", cluster1("post") cluster2(trid) numrealvars(1) ivendogvars(lntotactualposts) ivinstruments(lztroopsremain11)
	test lntotactualposts = 0
	local testp0 = r(p)
	test lntotactualposts = -1
	outreg lntotactualposts using table2a_msmtiv, 3aster coefastr se ctitle("OLS") append adds("Test elas = -1",r(p),"Test elas = 0",`testp0', "First-stage F",`FirstF')
	
	
	capture drop t?
	g t1 = ztripdate-mdy(1,1,2005)
	g t2 = t1^2
	g t3 = t1^3
	
	
	xi: bencgmreg lnzpostpayment  t? truckage truckage2  zincludedC* ztruckovertons lnsal i.postdir  if zprovid == "12" ,  cluster1("post") cluster2(trid) numrealvars(4) ivendogvars(lntotactualposts) ivinstruments(lnmeantotprovposts11)
	test lntotactualposts = 0
	local testp0 = r(p)
	test lntotactualposts = -1
	outreg lntotactualposts t? using table2a_msmtiv, 3aster coefastr se ctitle("Both routes with Time Cubic - D-in-D") append adds("Test elas = -1",r(p),"Test elas = 0",`testp0')  bd(6)
	
	
	xi: bencgmreg lnzpostpayment  truckage truckage2  zincludedC* ztruckovertons lnsal i.postdir i.tripmonth if zprovid == "12" ,  cluster1("post") cluster2(trid) numrealvars(1) ivendogvars(lntotactualposts) ivinstruments(lnmeantotprovposts11)
	test lntotactualposts = 0
	local testp0 = r(p)
	test lntotactualposts = -1
	outreg lntotactualposts using table2a_msmtiv, 3aster coefastr se ctitle("Both routes with Month FE") append adds("Test elas = -1",r(p),"Test elas = 0",`testp0')


**************
* Robustness check version of table2a 
* Add controls for guns and number of people at post
***************	
	
	
	xi: bencgmreg lnzpostpayment lnmeantotprovposts11 zpostgun zpostnumppl i.postdir if zprovid == "12" & zroute == "M",  cluster1("post") cluster2(trid) numrealvars(3) 
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 zpostgun zpostnumppl using table2a_gunppl, 3aster coefastr se ctitle("OLS") replace title("price") adds("Test elas = -1",r(p),"Test elas = 0",`testp0')
		
		
	xi: bencgmreg lnzpostpayment lnmeantotprovposts11 zpostgun zpostnumppl truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal i.postdir if zprovid == "12" & zroute == "M", cluster1("post") cluster2(trid) numrealvars(3) 
	**** Note that I droop empities because it gets dropped anyway by this regression
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 zpostgun zpostnumppl using table2a_gunppl, 3aster coefastr se ctitle("OLS") append adds("Test elas = -1",r(p),"Test elas = 0",`testp0')
	
	xi: bencgmreg lnzpostpayment lnmeantotprovposts11 zpostgun zpostnumppl truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal i.postdir if zprovid == "12" & zroute == "M" & ztripdate <= mdy(4,4,2006), cluster1("post") cluster2(trid) numrealvars(3) 
	**** Note that I droop empities because it gets dropped anyway by this regression
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 zpostgun zpostnumppl using table2a_gunppl, 3aster coefastr se ctitle("OLS") append adds("Test elas = -1",r(p),"Test elas = 0",`testp0')
	
		
	xi: bencgmreg lnmeantotprovposts11 zpostgun zpostnumppl  lztroopsremain11 truckage truckage2  zincludedC* ztruckovertons lnsal i.postdir if zprovid == "12" & zroute == "M", cluster1("post") cluster2(trid) numrealvars(3)
	testparm lztroopsremain11 
	local FirstF = r(chi2)
	
	xi: bencgmreg lnzpostpayment zpostgun zpostnumppl  truckage truckage2  zincludedC* ztruckovertons lnsal i.postdir if zprovid == "12" & zroute == "M", cluster1("post") cluster2(trid) numrealvars(3) ivendogvars(lnmeantotprovposts11) ivinstruments(lztroopsremain11)
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 zpostgun zpostnumppl using table2a_gunppl, 3aster coefastr se ctitle("OLS") append adds("Test elas = -1",r(p),"Test elas = 0",`testp0', "First-stage F",`FirstF')
	
		
	xi: bencgmreg lnzpostpayment lnmeantotprovposts11 zpostgun zpostnumppl t? truckage truckage2  zincludedC* ztruckovertons lnsal i.postdir  if zprovid == "12" ,  cluster1("post") cluster2(trid) numrealvars(6) 
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	local testp1 = r(p)
	outreg lnmeantotprovposts11 zpostgun zpostnumppl t? using table2a_gunppl, 3aster coefastr se ctitle("Both routes with Time Cubic - D-in-D") append adds("Test elas = -1",`testp1',"Test elas = 0",`testp0')  bd(3)
	
	
	xi: bencgmreg lnzpostpayment lnmeantotprovposts11 zpostgun zpostnumppl truckage truckage2  zincludedC* ztruckovertons lnsal i.postdir i.tripmonth if zprovid == "12" ,  cluster1("post") cluster2(trid) numrealvars(3) 
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 zpostgun zpostnumppl using table2a_gunppl, 3aster coefastr se ctitle("Both routes with Month FE") append adds("Test elas = -1",r(p),"Test elas = 0",`testp0')
	
	
	
	
	
	*****************
	* Regressions for Table 2, Panel B
	*****************
	
	* Create time series dataset
	tempfile temppostlevel
	save temppostlevel, replace
	save temp1,replace
		
	use temppostlevel,clear
	preserve
	bys trid: keep if _n == 1
	keep ztripdate lntotactualposts lnztotallposts lnmeantotprovposts11 lztroopsremain*11 truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal trid zprovid zroute zroutetoaceh tripinterval	 tripmonth
	tempfile info2
	save info2, replace
	restore
	
	use codedkabmerged,clear
	g zprovid = substr(zpostkabid,1,2)
	g totpaid = ztotkabpayment 
	replace totpaid = ztotkabpayment + ztotkabjembpaid if ztotkabjembpaid != .
	* Note that totpaid includes payments at checkpoints as well as at weigh stations
	
	* Collapse to the trip level
	collapse (sum) totpaid ztotkabposts ztotkabpayment ztotkabjembpaid, by(zprovid trid)
	fillin trid zprovid
	replace totpaid = 0 if totpaid == .
	
	mmerge trid using info2
	
	
	g lntotpaid = ln(totpaid)
	g lntotpaidcheckpoints = ln(ztotkabpayment)
	egen groupvar = group(zprovid zroute)
	
	************************
	* generate a time-series variable for newey-west errors
	************************
	sort groupvar ztripdate
	by groupvar: g tripnumber = _n
	tsset groupvar tripnumber
	
		
	* Regressions
	
	local lags = 10
	
	newey2 lntotpaid lnmeantotprovposts11 if zprovid == "12"  & zroute == "M", lag(`lags') force
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 using table2b, 3aster coefastr se ctitle("OLS") replace title("log total payments") adds("Test elas = 1",r(p),"Test elas = 0",`testp0')
	

	newey2 lntotpaid lnmeantotprovposts11 truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal if zprovid == "12"  & zroute == "M", lag(`lags') force
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 using table2b, 3aster coefastr se ctitle("OLS") append adds("Test elas = 1",r(p),"Test elas = 0",`testp0')


	newey2 lntotpaid lnmeantotprovposts11 truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal if zprovid == "12"  & zroute == "M" & ztripdate < mdy(4,4,2006), lag(`lags') force
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 using table2b, 3aster coefastr se ctitle("OLS Pre-Press") append adds("Test elas = 1",r(p),"Test elas = 0",`testp0')
	
	
	xi: newey2 lnmeantotprovposts11  lztroopsremain11 truckage truckage2  zincludedC* ztruckovertons lnsal if zprovid == "12" & zroute == "M", lag(`lags') force
	testparm lztroopsremain11 
	local FirstF = r(F)
	outreg using table2bfirststage,replace se adds("F",`FirstF') 3aster coefastr
	
	
	xi: newey2 lntotpaid (lnmeantotprovposts11 = lztroopsremain11) truckage truckage2  zincludedC* ztruckovertons lnsal if zprovid == "12" & zroute == "M", lag(`lags') force
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 using table2b, 3aster coefastr se ctitle("IV (troops)") append adds("Test elas = 1",r(p),"Test elas = 0",`testp0')

	capture drop t?
	g t1 = ztripdate-mdy(1,1,2005)
	g t2 = t1^2
	g t3 = t1^3
	
	xi: newey2 lntotpaid lnmeantotprovposts11 truckage truckage2  zincludedC* ztruckovertons lnsal t1 t2 t3 i.zroute if zprovid == "12", lag(`lags') force
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	local testp1 = r(p)
	outreg lnmeantotprovposts11 t1 t2 t3 using table2b, 3aster coefastr se ctitle("Both Routes with Time Cubic (D-in-D)") append adds("Test elas = 1",`testp1',"Test elas = 0",`testp0') bd(3)
	outreg lnmeantotprovposts11 t1 t2 t3 using table2b_referee, 3aster coefastr se ctitle("Both Routes with Time Cubic (D-in-D)") replace adds("Test elas = 1",`testp1',"Test elas = 0",`testp0') bd(6)

	
	xi: newey2 lntotpaid lnmeantotprovposts11 truckage truckage2  zincludedC* ztruckovertons lnsal i.tripmonth i.zroute if zprovid == "12", lag(`lags') force
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 using table2b, 3aster coefastr se ctitle("Both Routes with Month FE") append adds("Test elas = 1",r(p),"Test elas = 0",`testp0')
	
	newey2 lntotpaid lnmeantotprovposts11  if zprovid == "12"  & zroute == "B", lag(`lags') force
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 using table2b_referee, 3aster coefastr se ctitle("Banda Aceh") append adds("Test elas = 1",r(p),"Test elas = 0",`testp0')
	
	newey2 lntotpaid lnmeantotprovposts11 truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal if zprovid == "12"  & zroute == "B", lag(`lags') force
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 using table2b_referee, 3aster coefastr se ctitle("Banda Aceh") append adds("Test elas = 1",r(p),"Test elas = 0",`testp0')

	newey2 lntotpaidcheckpoints lnmeantotprovposts11  if zprovid == "12"  & zroute == "B", lag(`lags') force
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 using table2b_referee, 3aster coefastr se ctitle("Banda Aceh") append adds("Test elas = 1",r(p),"Test elas = 0",`testp0')
	
	newey2 lntotpaidcheckpoints lnmeantotprovposts11 truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal if zprovid == "12"  & zroute == "B", lag(`lags') force
	test lnmeantotprovposts11 = 0
	local testp0 = r(p)
	test lnmeantotprovposts11 = -1
	outreg lnmeantotprovposts11 using table2b_referee, 3aster coefastr se ctitle("Banda Aceh") append adds("Test elas = 1",r(p),"Test elas = 0",`testp0')


*****************
* Robustness version of Table 2 Panel B
* Instruments for total checkpoionts with predicted checkpoints
*****************
local lags = 10
	newey2 lntotpaid (lnztotallposts = lnmeantotprovposts11) if zprovid == "12"  & zroute == "M", lag(`lags') force
	test lnztotallposts = 0
	local testp0 = r(p)
	test lnztotallposts = -1
	outreg lnztotallposts using table2b_msmtiv, 3aster coefastr se ctitle("OLS") replace title("log total payments") adds("Test elas = 1",r(p),"Test elas = 0",`testp0')
	

	newey2 lntotpaid (lnztotallposts = lnmeantotprovposts11) truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal if zprovid == "12"  & zroute == "M", lag(`lags') force
	test lnztotallposts = 0
	local testp0 = r(p)
	test lnztotallposts = -1
	outreg lnztotallposts using table2b_msmtiv, 3aster coefastr se ctitle("OLS") append adds("Test elas = 1",r(p),"Test elas = 0",`testp0')


	newey2 lntotpaid (lnztotallposts = lnmeantotprovposts11) truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal if zprovid == "12"  & zroute == "M" & ztripdate < mdy(4,4,2006), lag(`lags') force
	test lnztotallposts = 0
	local testp0 = r(p)
	test lnztotallposts = -1
	outreg lnztotallposts using table2b_msmtiv, 3aster coefastr se ctitle("OLS Pre-Press") append adds("Test elas = 1",r(p),"Test elas = 0",`testp0')
	
	
	
	xi: newey2 lntotpaid (lnztotallposts = lztroopsremain11) truckage truckage2  zincludedC* ztruckovertons lnsal if zprovid == "12" & zroute == "M", lag(`lags') force
	test lnztotallposts = 0
	local testp0 = r(p)
	test lnztotallposts = -1
	outreg lnztotallposts using table2b_msmtiv, 3aster coefastr se ctitle("IV (troops)") append adds("Test elas = 1",r(p),"Test elas = 0",`testp0')

	capture drop t?
	g t1 = ztripdate-mdy(1,1,2005)
	g t2 = t1^2
	g t3 = t1^3
	
	xi: newey2 lntotpaid (lnztotallposts = lnmeantotprovposts11) truckage truckage2  zincludedC* ztruckovertons lnsal t1 t2 t3 i.zroute if zprovid == "12", lag(`lags') force
	test lnztotallposts = 0
	local testp0 = r(p)
	test lnztotallposts = -1
	outreg lnztotallposts t1 t2 t3 using table2b_msmtiv, 3aster coefastr se ctitle("Both Routes with Time Cubic (D-in-D)") append adds("Test elas = 1",r(p),"Test elas = 0",`testp0') bd(6)

	
	xi: newey2 lntotpaid (lnztotallposts = lnmeantotprovposts11) truckage truckage2  zincludedC* ztruckovertons lnsal i.tripmonth i.zroute if zprovid == "12", lag(`lags') force
	test lnztotallposts = 0
	local testp0 = r(p)
	test lnztotallposts = -1
	outreg lnztotallposts using table2b_msmtiv, 3aster coefastr se ctitle("Both Routes with Month FE") append adds("Test elas = 1",r(p),"Test elas = 0",`testp0')
}



**************
* Table 3: Impact of withdrawals, district by district
**************
if `dotable3' == 1 {
	
	use codedkabmerged,clear
	
	g tripinterval = round(ztripdate / 14) 
	egen postid = group(zpostkabid zroutetoaceh)
	
	
	for var ztotkabpayment ztotkabposts : g lnX = ln(X)
	for var ztroopsremaintnispecialbripol : g lX = ln(X)
	for var ztroopsremaintnispecialbripol : replace lX = 0 if substr(zpostkabid,1,2) == "12" /*since no data for sumatra this shoudl just be 0, not missing*/
		
	* Create expected posts
	preserve
	bys trid zpostkabid: keep if _n == 1
	bys tripinterval zroute zpostkabid: egen tempsumposts = sum(ztotkabposts)
	bys tripinterval zroute zpostkabid: egen tempcountpost = count(ztotkabposts)
	g meanpredpostskab = (tempsumposts - ztotkabposts) / (tempcountpost- 1)
			
	g lnmeantotkabposts  = ln(meanpredpostskab )
	tempfile tempposts11
	keep trid zpostkabid lnmeantotkabposts meanpredpostskab 
	save tempposts11, replace
  restore
  
	mmerge trid zpostkabid using tempposts11, type(n:1)
	assert _merge == 3
	drop _merge
	
	
	
	
	
	xi: bencgmreg lnztotkabpayment lnmeantotkabposts i.postid i.trid if zroute == "M", cluster1(postid)  cluster2(trid) numrealvars(1) 
	test lnmeantotkabposts = 0
	local testp0 = r(p)
	test lnmeantotkabposts= 1
	outreg lnmeantotkabposts using table3, 3aster coefastr se ctitle("OLS") replace title("ln payments") adds("Test elas = 1",r(p),"Test elas = 0",`testp0')
	
	xi: bencgmreg lnmeantotkabposts  lztroopsremaintnispecialbripol i.postid i.trid if zroute == "M", cluster1(postid)  cluster2(trid) numrealvars(2) 
	testparm lztroopsremaintnispecialbripol 
	local FirstF = r(chi2)
	xi: bencgmreg lnztotkabpayment i.postid i.trid if zroute == "M", cluster1(postid) cluster2(trid) numrealvars(1) ivendogvars(lnmeantotkabposts) ivinstruments(lztroopsremaintnispecialbripol) 
	test lnmeantotkabposts= 0
	local testp0 = r(p)
	test lnmeantotkabposts= 1
	outreg lnmeantotkabposts using table3, 3aster coefastr se ctitle("IV (troops)") append adds("First stage F",`FirstF',"Test elas = 1",r(p),"Test elas = 0",`testp0')
	
	xi: bencgmreg lnztotkabpayment lnmeantotkabposts i.postid i.trid , cluster1(postid)  cluster2(trid) numrealvars(1) 
	test lnmeantotkabposts = 0
	local testp0 = r(p)
	test lnmeantotkabposts= 1
	outreg lnmeantotkabposts using table3, 3aster coefastr se ctitle("OLS-BothRoutes") append adds("Test elas = 1",r(p),"Test elas = 0",`testp0')
	
	xi: bencgmreg lnmeantotkabposts  lztroopsremaintnispecialbripol i.postid i.trid , cluster1(postid)  cluster2(trid) numrealvars(2) 
	testparm lztroopsremaintnispecialbripol 
	local FirstF = r(chi2)
	xi: bencgmreg lnztotkabpayment i.postid i.trid , cluster1(postid) cluster2(trid) numrealvars(1) ivendogvars(lnmeantotkabposts) ivinstruments(lztroopsremaintnispecialbripol) 
	test lnmeantotkabposts= 0
	local testp0 = r(p)
	test lnmeantotkabposts= 1
	outreg lnmeantotkabposts using table3, 3aster coefastr se ctitle("IV (troops)-BothRoutes") append adds("First stage F",`FirstF',"Test elas = 1",r(p),"Test elas = 0",`testp0')

	
	
	
	
	
	
}






**************
* Table 4: Bargaining vs. fixed prices
**************
if `dotable4' == 1 {
		use codedperpost,clear
		sort trid
		merge trid using codedtripinfo, uniqusing
		drop _merge
			
		
		***********
		* These are fe / clustering vars
		***********
		g tripmy = string(year(ztripdate)) + string(month(ztripdate),"%02.0f")
		egen postdirmonth = group(zpostwhostops zpostkec zroute zroutetoaceh tripmy)
		egen post = group(zpostwhostops zpostkec)
		
		g ztruckovertons = max(ztruckweight - ztruckmaxweight,0)
		g ztruckoverweight = 1 if ztruckovertons > 0 & ztruckovertons != .
		replace ztruckoverweight = 0 if ztruckovertons  == 0
		
		g lnpayment = ln(zpostpayment) 
		g lntrips = ln(zdrivertrips) 
		g lnsal = ln(zdrivermonthlysalary)
		
		
		replace ztruckyear = 1990 if ztruckyear < 1990 /*one guy is 1977 so dont' want outlier to drive analysis*/
		
		g truckage = 2006 - ztruckyear
		g truckage2 = truckage^2
		
		g ztruckcargoweight = ztruckweight - ztruckemptyweight
		g ztruckvalperweight = ztruckcargovalue / ztruckcargoweight
		g lnztruckvalperweight = ln(ztruckvalperweight)
		
		
		* Calculate guns and people in subsequent post
		
		encode trid,g(tripnum)
		
		tsset tripnum zpostnumwithintrip 
		g gunafter = f.zpostgun
		g pplafter = f.zpostnumppl
		
		
		
		*************************************
		* Bargaining and price discrimination
		**************************************
		
		********************
		* Table 2: bargaining or posted price
		* For same truck, for given post, does price change based on bargaining power of who happens to be manning the post?
		*******************
			
		
		xi: areg lnpay zpostgun zpostnumppl i.trid , absorb(postdirmonth) cluster(post) 
		local tempdep = e(depvar)
		qui sum `tempdep' if e(sample)
		outreg zpostgun zpostnumppl using table4.out, 3aster coefastr se replace title("Bargaining") adds("Mean dep var",r(mean))

		xi: areg lnpay zpostgun zpostnumppl gunafter pplafter i.trid , absorb(postdirmonth) cluster(post) 
		local tempdep = e(depvar)
		qui sum `tempdep' if e(sample)
		outreg zpostgun zpostnumppl gunafter pplafter using table4.out, 3aster coefastr se append adds("Mean dep var",r(mean))
		
		xi: areg zpostbargain zpostgun zpostnumppl i.trid , absorb(postdirmonth) cluster(post) 
		local tempdep = e(depvar)
		qui sum `tempdep' if e(sample)
		outreg zpostgun zpostnumppl using table4.out, 3aster coefastr se append  adds("Mean dep var",r(mean))
			
		xi: areg zpostbargain zpostgun zpostnumppl gunafter pplafter i.trid , absorb(postdirmonth) cluster(post) 
		local tempdep = e(depvar)
		qui sum `tempdep' if e(sample)
		outreg zpostgun zpostnumppl gunafter pplafter using table4.out, 3aster coefastr se append  adds("Mean dep var",r(mean))

		
************** Our extension
xi: areg lnpay zpostgun zpostnumppl zdriveredyears zdriveryearsexp i.trid , absorb(postdirmonth) cluster(post) 
		
				
}


*****************
* Table 5: Sequential bargaining
* Figure 4: Sequential bargaining figure
******************

if `dotable5' == 1 {
	use codedperpost,clear
	mmerge trid using codedtripinfo
	drop _merge
	
	drop if zpostdatetime < mdy(8,1,2005) | zpostdatetime > mdy(8,1,2006)
	drop if zroutetoaceh == .
	
	bys trid: egen kecrank = rank(zpostdatetime)
	tempvar temp1
	bys trid: egen `temp1' = max(kecrank)
	g kecpctile = (kecrank - 1 ) / (`temp1' - 1)
	
	
	g tripmy = string(year(ztripdate)) + string(month(ztripdate),"%02.0f")
	g tripmonth = year(ztripdate)*100+ month(ztripdate)
	
	egen postidmonth = group(zpostkecid zpostwhostops zroute tripmy )
	egen postmonth = group(zpostkecid zpostwhostops tripmonth)
	egen post = group(zpostwhostops zpostkec)
	
	***********
	* These are current fe / clustering vars
	***********
		
	bys postidmonth zroutetoaceh : egen meankecpctile = mean(kecpctile)
	g lnpostpayment = ln(zpostpayment)
	
	**Figure 4
	xi: areg lnpostpayment i.trid , absorb(postmonth) cluster(postidmonth )
	predict resid, r
	
	fanreg resid meankecpctile if zroute == "M", cluster(trid) reps(50) xtitle("Share of trip completed") bw(3) title("Meulaboh") saving(dir-M, replace) 
	fanreg resid meankecpctile if zroute == "B", cluster(trid) reps(50) xtitle("Share of trip completed") bw(3) title("Banda Aceh") saving(dir-B, replace) 
	graph combine dir-M.gph dir-B.gph, xcommon ycommon 
	graph export figure4.eps, replace

	** Table 5
	xi: areg lnpostpayment meankecpctile i.trid if zroute == "M", absorb(postmonth) cluster(post)
	outreg meankecpctile using table5, 3aster coefastr se replace title("direction of travel")  
				
	g temptrid = trid
	replace temptrid = "" if zroute != "B"
	xi: areg lnpostpayment meankecpctile i.temptrid if zroute == "B" , absorb(postmonth) cluster(post) 
	outreg meankecpctile using table5, 3aster coefastr se append

	
	
	
}




**************
* Table 6: Price discrimination
* Figure 5: Price discrimination
**************
if `dotable6' == 1 {
	
		use codedperpost,clear
		sort trid
		merge trid using codedtripinfo, uniqusing
		drop _merge
		
		
			
		
		***********
		* These are fe / clustering vars
		***********
		g tripmy = string(year(ztripdate)) + string(month(ztripdate),"%02.0f")
		
		egen postdirmonth = group(zpostwhostops zpostkec zroute zroutetoaceh tripmy)
		egen post = group(zpostwhostops zpostkec)
		egen postidkec = group(zpostkecid zpostwhostops zroute)
		
					
		g ztruckovertons = max(ztruckweight - ztruckmaxweight,0)
		g lnpayment = ln(zpostpayment) 
		g lnsal = ln(zdrivermonthlysalary)
		g timedummy = floor(zposttime)
		
		replace ztruckyear = 1990 if ztruckyear < 1990 /*one guy is 1977 so dont' want outlier to drive analysis*/
		
		g truckage = 2006 - ztruckyear
		g truckage2 = truckage^2
		
		g ztruckcargoweight = ztruckweight - ztruckemptyweight
		g ztruckvalperweight = ztruckcargovalue / ztruckcargoweight
		g lnztruckvalperweight = ln(ztruckvalperweight)
		
		
		
	  * Variance decomposition
	  g lnzpostpayment = ln(zpostpayment)
		loneway lnzpostpayment trid
		loneway lnzpostpayment postidkec 
		xi: areg lnzpostpayment i.postidkec, absorb(trid)
		predict lnzpostpayment_nopost_notrid, r
		summ lnzpostpayment lnzpostpayment_nopost_notrid
		
		***************
		* Table 6
		***************
		xi: bencgmreg lnpayment truckage truckage2  zincludedC* ztruckovertons zdriverage zdriveredyears zdriverspeaksaceh zdriveryearsexp zdrivertrips lnsal i.time, absorb(postdirmonth) cluster1(post) cluster2(trid) numrealvars(16)
		testparm truckage truckage2  zincludedC* ztruckovertons 
		local Ftruck = r(chi2)
		local Ptruck = r(p)
		testparm zdriverage zdriveredyears zdriverspeaksaceh zdriveryearsexp zdrivertrips lnsal
		local Fdriver = r(chi2)
		local Pdriver = r(p)
		outreg truckage truckage2  zincludedC* ztruckovertons zdriverage zdriveredyears zdriverspeaksaceh  zdriveryearsexp zdrivertrips lnsal using table6, 3aster coefastr se replace title("Price discrimination") adds("F truck",`Ftruck',"P truck",`Ptruck',"F driver",`Fdriver',"P driver",`Pdriver') 
		
		
		
		xi: bencgmreg lnpayment truckage truckage2  lnztruckvalperweight  ztruckovertons zdriverage zdriveredyears zdriverspeaksaceh zdriveryearsexp zdrivertrips lnsal i.time, absorb(postdirmonth) cluster1(post) cluster2(trid) numrealvars(16)
		testparm truckage truckage2  zincludedC* ztruckovertons 
		local Ftruck = r(chi2)
		local Ptruck = r(p)
		testparm zdriverage zdriveredyears zdriverspeaksaceh zdriveryearsexp zdrivertrips lnsal
		local Fdriver = r(chi2)
		local Pdriver = r(p)
		outreg truckage truckage2  lnztruckvalperweight  ztruckovertons zdriverage zdriveredyears zdriverspeaksaceh  zdriveryearsexp zdrivertrips lnsal using table6, 3aster coefastr se append adds("F truck",`Ftruck',"P truck",`Ptruck',"F driver",`Fdriver',"P driver",`Pdriver') 
		
		**************
		* Figure 5
		**************
		fanreg zpostpayment truckage, reps(100) cluster(trid) xtitle("Truck age") saving(figuretruckage,replace) maxminon min(0) max(10000) bw(5)
		
		
		fanreg zpostpayment lnztruckvalperweight, reps(100) cluster(trid) maxminon min(0) max(10000) xtitle("Log cargo value per ton") saving(figuretruckweight,replace) bw(5)
		
		
		graph combine figuretruckage.gph figuretruckweight.gph, xsize(6) ysize(4) ycommon
		graph export figure5.eps, replace
		
		
}


**************
* Table 7: Second degree price discrimination
* Figure 6: Second degree price discrimination
* Figrue 2: Weigh station figure
**************
if `dotable7' == 1 {
	
	use codedkabmerged,clear
	
	g ztruckovertons = max(ztruckweight - ztruckmaxweight,0)
	g ztruckoverweight = 1 if ztruckovertons > 0 & ztruckovertons != .
	replace ztruckoverweight = 0 if ztruckovertons  == 0
	
	keep if ztotkabjembtotal >= 1 & ztotkabjembtotal != .
	
	* drop isolated jemb's  / coding errors -- these are locations where there should be no weigh station
	drop if zpostkabid == "1105"
	drop if zpostkabid == "1209"
	drop if zpostkabid == "1212"
	drop if zpostkabid == "1275"
	drop if zpostkabid == "1273"
	tab zpostkabid
	assert r(r) == 4 /*check only 4 weigh stations*/
	
	/*drop mel trucks that go on the aceh route, since these are also errors*/
	drop if zroute == "M" & (zpostkabid == "1114" | zpostkabid == "1213")
	
	g paidjembasa = ztotkabjembpaid + zusedasaamt
	g convoyasa = (zusedasa | ztruckconvoy) if ztruckconvoy != . & zusedasa != .
	
	*************
	* Figure 6
	*************
	lowess paidjembasa ztruckovertons if zroute == "B" & convoyasa == 1  & zroutetoaceh == 1 & zpostkabid == "1213" & ztruckovertons < 30 & substr(trid,1,3) != "M03", generate(asa1) bw(.9)
	lowess paidjembasa ztruckovertons if zroute == "B" & convoyasa == 0  & zroutetoaceh == 1 & zpostkabid == "1213" & ztruckovertons < 30 & substr(trid,1,3) != "M03", generate(asa0) bw(.9)
	/**XXXsurveyor M03 did not record ASA informationXX*/
	
	label var asa1 "Coupon"
	label var asa0 "No coupon"
	
	twoway (line asa1 ztruckovertons if ztruckovertons < 30, sort lc(red) lp(solid) lw(medium)) (line asa0 ztruckovertons if ztruckovertons < 30, sort lc(blue) lp(dash) lw(medthin)) , ylabel(0(100000)400000) xtitle("Overweight tons") ytitle("Rupiah") legend(order(1 2)) title("Gebang")
	graph export figure6.eps,replace	
	

	****************************
	* Table 7 
	****************************
	drop if substr(trid,1,3) == "M03"
	/**XXXsurveyor M03 did not record ASA informationXX*/
	g lnzdrivermonthly = ln(zdrivermonthlysalary)
	
	reg zusedasa ztruckovertons if zpostkabid == "1213" & zroutetoaceh == 1 & ztruckovertons < 30 & (lnzdrivermonthly < 18 ), robust		
	outreg using table7, se coefastr 3aster replace title("Gebang")
	reg zusedasa lnzdrivermonthly if zpostkabid == "1213" & zroutetoaceh == 1 & ztruckovertons < 30 & lnzdrivermonthly < 18 , robust		
	outreg using table7, se coefastr 3aster append
	ivreg zusedasa (ztruckovertons = lnzdrivermonthly) if zpostkabid == "1213" & zroutetoaceh == 1 & ztruckovertons < 30 & lnzdrivermonthly < 18 , robust		
	outreg using table7, se coefastr 3aster append	
*********** our extension： we think first we can add some control variable such as 
************ drivers' experience and the expense the drivers have, second salary is not a valid instrument for overweight
    
*********** re-run the first regression using residual maximazition 
    reg zexpA ztruckovertons  
	reg zusedasa zdriveryearsexp zexpA  if  zpostkabid == "1213" & zroutetoaceh == 1 & ztruckovertons < 30, robust		
	outreg using table7extension1, se coefastr 3aster replace title("Whole") /**we shows that there is still no significant**/
************ re-run the table 7 regression using dummy	
	gen ztruckovertons_dummy = 0 if zpostkabid == "1213" & zroutetoaceh == 1
	replace ztruckovertons_dummy = 1 if zpostkabid == "1213" & zroutetoaceh == 1 & ztruckovertons > 16 & ztruckovertons < 30 
    reg zusedasa ztruckovertons_dummy zdriveryearsexp, robust 		
	outreg using table7extension2, se coefastr 3aster replace title("Gebang")/**we shows that there is still no significant**/
	

	
  *****************
  * Figure 2
  *****************

	g tempztotkabjembpaid = ztotkabjembpaid / 1000
	label var tempztotkabjembpaid "Payment (Rp. thousands)"
	label var ztruckovertons "Tons overweight"
	capture label drop typenum
	
	fanreg tempztotkabjembpaid   ztruckovertons if zpostkabid == "1213", maxminon max(300) min(0) title("Banda Aceh - Gebang") saving("jemb-B-G", replace) ylabel(0(50)300) bw(3) xtitle("Tons overweight") ytitle("Payment (Rp. thousands)")
	fanreg tempztotkabjembpaid   ztruckovertons if zpostkabid == "1114", maxminon max(300) min(0) title("Banda Aceh - Seumedam") saving("jemb-B-S",replace) ylabel(0(50)300) bw(3) xtitle("Tons overweight") ytitle("Payment (Rp. thousands)")
	graph combine jemb-B-G.gph jemb-B-S.gph, ycommon xcommon  title("Banda Aceh") saving("jemb-B",replace)

	fanreg tempztotkabjembpaid   ztruckovertons if zpostkabid == "1210", maxminon max(300) min(0) title("Meulaboh - Sidikalang") saving("jemb-M-S",replace) ylabel(0(50)300) bw(3) xtitle("Tons overweight") ytitle("Payment (Rp. thousands)")
	preserve
	keep if ztruckovertons <= 23
	fanreg tempztotkabjembpaid   ztruckovertons if zpostkabid == "1211" , maxminon max(300) min(0) title("Meulaboh - Doulu") saving("jemb-M-D",replace)  ylabel(0(50)300) bw(3) xtitle("Tons overweight") ytitle("Payment (Rp. thousands)")
	restore
	graph combine jemb-M-D.gph jemb-M-S.gph, ycommon xcommon  title("Meulaboh") saving("jemb-M",replace)
	
	graph combine jemb-B-G.gph jemb-B-S.gph jemb-M-D.gph jemb-M-S.gph, xsize(7.5) ysize(7) rows(2) xcommon ycommon
	graph export figure2.eps, replace
	
	
	
	
	
}



*************
* Figure 3: Changes in checkpoints and prices
*************

if `dofigure3' == 1 {
	
		use codedkabmerged, clear
				
		preserve
	
		keep if zcompletetrip == 1
		
		drop if ztripdate < mdy(11,1,2005)
		
		drop if trid == "M02021205" /*these are problematic trips */
		drop if trid == "M04270306" /*these are problematic trips */
		g zprovid = substr(zpostkabid,1,2)
		keep if zroute == "M" & zmelcoastalroute  == 1  
		ren ztroopsremaintnispecialbripol ztroopsremall
		replace ztroopsremall = ztroopsremall * 1000
	
		g totpaid = ztotkabpayment 
		replace totpaid = ztotkabpayment + ztotkabjembpaid if ztotkabjembpaid != .
	
		drop if zprovid == "99" /*drop checkpoionts at the border*/
		
		collapse (sum) ztotkabpayment (sum) ztotkabposts (sum) ztroopsremall (sum) totpaid , by(zroute trid ztripdate zprovid)
		reshape wide ztotkabpayment ztotkabposts ztroopsremall totpaid, i(zroute trid ztripdate) j(zprovid) string
		
		g zprice11 = ztotkabpayment11 / ztotkabposts11
		g zprice12 = ztotkabpayment12 / ztotkabposts12
			
		
		g lnprice11 = ln(zprice11)
		g lnprice12 = ln(zprice12)
		g lntotpaid11 = ln(totpaid11)
		g lntotpaid12 = ln(totpaid12)
		
		egen meanposts12 = mean(ztotkabposts12)
		g posts11pred = ztotkabposts11 + meanposts12 
		g poststotal = ztotkabposts11 + ztotkabposts12
		
		sort ztripdate
		for var ztot*11 zprice*11 ln*11 tot*11: label var X "Aceh"
		for var ztot*12 zprice*12 ln*12 tot*12: label var X "N Sumatra"
		label var ztroopsremall11 "Troops"
		format %dn/Y ztripdate 
		
	
		label var ztotkabposts11 "Aceh province"
		label var ztotkabposts12 "N. Sumatra province"
		
		twoway (scatter ztotkabposts12 ztripdate, yaxis(1) msymbol(+) mcolor(gs6)) (scatter ztotkabposts11 ztripdate, yaxis(1) mcolor(navy) msymbol(circle))  (line ztroopsremall11 ztripdate, lcolor(green) yaxis(2)), ylabel(0(10)60, axis(1)) ylabel(0(1000)3000, axis(2)) saving(With-Fig1-Mel-Sep.gph,replace) title("Num checkpoints") xtitle(" ") legend(off)  ytitle("") legend(off)
		
		twoway (scatter lnprice12 ztripdate, yaxis(1) msymbol(triangle) mcolor(maroon)) (line ztroopsremall11 ztripdate, lcolor(green) yaxis(2)),  ylabel(0(1000)3000, axis(2)) saving(With-Fig3-Mel-S.gph,replace) title("Log avg. bribe in N. Sumatra") xtitle(" ") legend(off)  ytitle("")
		
		twoway  (scatter lntotpaid12 ztripdate, yaxis(1) msymbol(smsquare) mcolor(green)) (line ztroopsremall11 ztripdate, lcolor(green) yaxis(2)),   ylabel(0(1000)3000, axis(2)) saving(With-Fig4-Mel-S.gph,replace) title("Log tot. payments in N. Sumatra") xtitle(" ") legend(off)  ytitle("")
		
		graph combine "With-Fig1-Mel-Sep.gph" "With-Fig3-Mel-S.gph" "With-Fig4-Mel-S.gph" , saving(With-Fig3-Comb-M, replace) xsize(7.5) ysize(2.75) row(1) title("Meulaboh") xcommon
		
	
		restore
		
		************
		* Banda
		**************		
		
		preserve
			
		use codedkabmerged, clear
		
		*keep full trips
		keep if zcompletetrip == 1
		
		
		
		g zprovid = substr(zpostkabid,1,2)
		drop if ztripdate < mdy(11,1,2005)
		
		keep if zroute == "B" 
		ren ztroopsremaintnispecialbripol ztroopsremall
		replace ztroopsremall = ztroopsremall * 1000
		
		g totpaid = ztotkabpayment 
		replace totpaid = ztotkabpayment + ztotkabjembpaid if ztotkabjembpaid != .
	

		collapse (sum) ztotkabpayment (sum) ztotkabposts (sum) ztroopsremall (sum) totpaid, by(zroute trid ztripdate zprovid)
		reshape wide ztotkabpayment ztotkabposts ztroopsremall totpaid, i(zroute trid ztripdate) j(zprovid) string
		
		
		g zprice11 = ztotkabpayment11 / ztotkabposts11
		g zprice12 = ztotkabpayment12 / ztotkabposts12
			
		
		g lnprice11 = ln(zprice11)
		g lnprice12 = ln(zprice12)
		g lntotpaid11 = ln(totpaid11)
		g lntotpaid12 = ln(totpaid12)
		
		egen meanposts12 = mean(ztotkabposts12)
		g posts11pred = ztotkabposts11 + meanposts12 
		g poststotal = ztotkabposts11 + ztotkabposts12
					
		sort ztripdate
		for var ztot*11 zprice*11 ln*11 tot*11: label var X "Aceh"
		for var ztot*12 zprice*12 ln*12 tot*12: label var X "N Sumatra"
		label var ztroopsremall11 "Troops"
		format %dn/Y ztripdate 
		
		g lnposts11pred = ln(posts11pred)
		label var ztotkabposts11 "Aceh province"
		label var ztotkabposts12 "N. Sumatra province"
		
		twoway (scatter ztotkabposts12 ztripdate, yaxis(1) msymbol(+) mcolor(gs6)) (scatter ztotkabposts11 ztripdate, yaxis(1) msymbol(circle) mcolor(navy)) (line ztroopsremall11 ztripdate, lcolor(green) yaxis(2)) , ylabel(0(10)60, axis(1)) ylabel(0(5000)15000, axis(2)) saving(With-Fig1-BA-Sep.gph,replace) title("Num Checkpoints") xtitle(" ") legend(off)  ytitle("") legend(off)
		
		twoway (scatter lnprice12 ztripdate, yaxis(1) msymbol(triangle) mcolor(maroon)) (line ztroopsremall11 ztripdate, lcolor(green) yaxis(2)),  ylabel(0(5000)15000, axis(2)) saving(With-Fig3-BA-S.gph,replace) title("Log avg. bribe in N. Sumatra") xtitle(" ") legend(off)  ytitle("")
		
		twoway (scatter lntotpaid12 ztripdate, yaxis(1) msymbol(smsquare) mcolor(green)) (line ztroopsremall11 ztripdate, lcolor(green) yaxis(2)),  ylabel(0(5000)15000, axis(2)) saving(With-Fig4-BA-S.gph,replace) title("Log tot. payments in N. Sumatra") xtitle(" ") legend(off)  ytitle("")
		
		graph combine "With-Fig1-BA-Sep.gph" "With-Fig3-BA-S.gph" "With-Fig4-BA-S.gph" , saving(With-Fig3-Comb-BA, replace) xsize(7.5) ysize(2.75) row(1) title("Banda Aceh") xcommon
		
		restore

		**********
		* D - in - D graph
		**********
		
		graph combine With-Fig3-Comb-M.gph With-Fig3-Comb-BA.gph, xsize(6.5) ysize(4.5) row(2)
		graph export Figure3.eps,replace
		
	}	


**************
* Robustness analysis of how prices change before a post is withdrawn
**************

if `docapTanalysis' == 1 {
	

	use codedperpost,clear
	sort trid
	merge trid using codedtripinfo, uniqusing
	drop if _merge == 2
	drop _merge

	egen postidkec = group(zpostkecid zpostwhostops zroute)
	gsort +postidkec -zpostdatetime
	by postidkec: g distancefromlast = _n
	by postidkec: g numobs = _N
	g prov = substr(zpostkec,1,2)

	for num 1/5: g lastX = (distancefromlast == X)
	g templastdate = zpostdatetime if last1 == 1
	bys postidkec: egen lastdate = mean(templastdate)
	
	g lastany3 = last1 | last2 | last3
	
	g lnzpostpayment = ln(zpostpayment)
	
	egen postdir = group(zpostkecid zpostwhostops zroutetoaceh zroute)
	keep if lastdate <= mdy(6,1,2006)
	
	* restrict to checkpoints that actually close, as opposed to are just not as frequent
		
	xi: areg lnzpostpayment lastany3 i.postdir if numobs >= 10, absorb(trid) cluster(postdir)
	outreg lastany3 using table_ref_capT, 3aster coefastr se replace title("withdraw") 
	xi: areg lnzpostpayment lastany3 zpostgun zpostnumppl i.postdir if numobs >= 10, absorb(trid) cluster(postdir)
	outreg lastany3 using table_ref_capT, 3aster coefastr se append
	xi: areg lnzpostpayment lastany3 zpostgun zpostnumppl i.postdir if numobs >= 10 & prov == "11", absorb(trid) cluster(postdir)
	outreg lastany3 using table_ref_capT, 3aster coefastr se append
	
	xi: areg lnzpostpayment last? i.postdir if numobs >= 10, absorb(trid) cluster(postdir)
	outreg last? using table_ref_capT, 3aster coefastr se append
	xi: areg lnzpostpayment last? zpostgun zpostnumppl i.postdir if numobs >= 10, absorb(trid) cluster(postdir)
	outreg last? using table_ref_capT, 3aster coefastr se append
	xi: areg lnzpostpayment last? zpostgun zpostnumppl i.postdir if numobs >= 10 & prov == "11", absorb(trid) cluster(postdir)
	outreg last? using table_ref_capT, 3aster coefastr se append
	
	
	
}

log close


