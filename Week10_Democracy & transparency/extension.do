version 9.2
set seed 1000
set matsize 5000
capture log close
log using 090321truckinglog.log,t replace


************extension ************* 7 days interval 
***************************
	* Code basic variables we need for analysis
	***************************
	use codedkabmerged,clear
	g tripinterval = round(ztripdate / 7) 
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
	
 	eststo: xi: bencgmreg lnzpostpayment lnmeantotprovposts11 i.postdir if zprovid == "12" & zroute == "M",  cluster1("post") cluster2(trid) numrealvars(1) 
	
		
	eststo: xi: bencgmreg lnzpostpayment lnmeantotprovposts11 truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal i.postdir if zprovid == "12" & zroute == "M", cluster1("post") cluster2(trid) numrealvars(10) 
	
	

	
	
************** extension ************* 20 days interval 
***************************
	* Code basic variables we need for analysis
	***************************
	use codedkabmerged,clear
	g tripinterval = round(ztripdate / 20) 
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
	
 	eststo: xi: bencgmreg lnzpostpayment lnmeantotprovposts11 i.postdir if zprovid == "12" & zroute == "M",  cluster1("post") cluster2(trid) numrealvars(1) 
	
		
		
	eststo: xi: bencgmreg lnzpostpayment lnmeantotprovposts11 truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal i.postdir if zprovid == "12" & zroute == "M", cluster1("post") cluster2(trid) numrealvars(10) 
	
	 label variable truckage "Truck Age"

     label variable truckage2 "Truck Age2"

    label variable lnzpostpayment "Log Payment"

     label variable lnmeantotprovposts11 "Expected Posts"

     label variable zincludedCbesibekas "Steel"

    label variable zincludedCconstruction "Construction Goods"

    label variable zincludedCfood "Food"

    label variable zincludedCagprod "Agricultural"

   label variable zincludedCmanufac "Manufactured"

  label variable ztruckovertons "Over Weight"

	esttab using extension1.tex, label title(Regression table for 7 days and 20 days \label{tab1}) nonumbers mtitles("7 Days" "7 Days" "20 Days" "20 Days") replace

	
	
	
	
*************** extension ************ we use total actual post instead
	eststo:xi: bencgmreg lnzpostpayment lntotactualposts i.postdir if zprovid == "12" & zroute == "M",  cluster1("post") cluster2(trid) numrealvars(1) 
	

		
	eststo: xi: bencgmreg lnzpostpayment lntotactualposts truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal i.postdir if zprovid == "12" & zroute == "M", cluster1("post") cluster2(trid) numrealvars(10)  
	
	
	
	
	
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
	
		
	* time series Regressions with actual post 
	
	local lags = 10
	
	eststo:newey2 lntotpaid lntotactualposts if zprovid == "12"  & zroute == "M", lag(`lags') force
	
	eststo:newey2 lntotpaid lntotactualposts truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal if zprovid == "12"  & zroute == "M", lag(`lags') force
	
	label variable lntotactualposts "Total Posts"	
    esttab using extension2.tex, label title(Regression table for actual posts \label{tab1}) nonumbers mtitles("Post Level" "Post Level" "Trip level" "Trip level") replace 
	
	
*************  extension ********** bribe in aceh *************


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
*********** post level analysis 
eststo:xi: bencgmreg lnzpostpayment lntotactualposts i.postdir if zprovid == "11" & zroute == "M",  cluster1("post") cluster2(trid) numrealvars(1) 
eststo:xi: bencgmreg lnzpostpayment lntotactualposts truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal i.postdir if zprovid == "11" & zroute == "M", cluster1("post") cluster2(trid) numrealvars(10) 


************* time series 
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
	
	*****regression
	local lags=10
	eststo:newey2 lntotpaid lntotactualposts if zprovid == "11"  & zroute == "M", lag(`lags') force
	eststo:newey2 lntotpaid lntotactualposts truckage truckage2  zincludedCbesibekas zincludedCconstruction zincludedCfood zincludedCagprod zincludedCmanufac  ztruckovertons lnsal if zprovid == "11"  & zroute == "M", lag(`lags') force

	label variable truckage "Truck Age"

     label variable truckage2 "Truck Age2"


     label variable lnmeantotprovposts11 "Expected Posts"

     label variable zincludedCbesibekas "Steel"

    label variable zincludedCconstruction "Construction Goods"

    label variable zincludedCfood "Food"

    label variable zincludedCagprod "Agricultural"

   label variable zincludedCmanufac "Manufactured"

  label variable ztruckovertons "Over Weight"
	label variable lntotactualposts "Total Posts"	
    esttab using extension3.tex, label title(Regression table for Aceh \label{tab1}) nonumbers mtitles("Post Level" "Post Level" "Trip level" "Trip level") replace 
	
	
************* Extension 
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
		*************************************

		
************** Our extension
eststo:xi: areg lnpay zpostgun zpostnumppl zdriveredyears zdriveryearsexp i.trid , absorb(postdirmonth) cluster(post) 


************** Extension 
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
	
	****************************
	* Table 7 
	****************************
	drop if substr(trid,1,3) == "M03"
	/**XXXsurveyor M03 did not record ASA informationXX*/
	g lnzdrivermonthly = ln(zdrivermonthlysalary)
	


************ re-run the table 7 regression using dummy	
	gen ztruckovertons_dummy = 0 if zpostkabid == "1213" & zroutetoaceh == 1
	replace ztruckovertons_dummy = 1 if zpostkabid == "1213" & zroutetoaceh == 1 & ztruckovertons > 16 & ztruckovertons < 30 
    eststo:reg zusedasa ztruckovertons_dummy zdriveryearsexp, robust 
	
	esttab using extension4.tex, label title(Regression table for bargaining and price discrimination  \label{tab1}) nonumbers mtitles("Bargaining" "Price Discrimination") drop(_Itrid*) replace 
