capture program drop fan_reg	
program def fan_reg	
	* Fan Locally-weighted nonparametric regression, quartic kernel */
	* Refer to URL: www.worldbank.org/LSMS/tools/deaton, or the Deaton book */
	* fan_reg performs the locally-weighted nonparametric regression:
	*argument 1 is the dependent variable   (input)
	*argument 2 is the explanatory variable (input)
	*argument 3 is the estimated regression function (output)
	*argument 4 is the derivative of the regression function (output)
	*argument 5 is the bandwidth (input)
	*argument 6 is the grid over the explanatory variable for evaluation */
	*argument 7 is the number of points to calculate
	
	* ic is the loop counter 
	local ic = 1	
	* Generate the estimated function (3) and its derivative (4) */
	gen `3' = .	
	gen `4' = .	
	local gsize = `7' + 1
	* Loop until reaching the last cell of the grid */
	while `ic' <= `gsize' {	
		* Display the counter 
		*dis `ic'	
		quietly {	
			* Get the ic entry in the grid *
			local xx = `6'[`ic']	
			* Absolute value of x - x(i), divided by the bandwidth 
			gen z = abs((`2' - `xx')/`5')	
			* Observation i gets the following quartic kernel weight 
			gen kz = (15/16)*(1 - z^2)^2 if z<=1	
			* Perform the regression weighted by the kernel (analogous to GLS) 
			capture reg  `1' `2' [aw=kz] if kz~=.	,robust 
			* The estimated regression is the value at x 
			capture replace `3' = _b[_cons]+_b[`2']*`xx' in `ic' 	
			* The estimated slope is the coefficient estimate at x 
			capture replace `4' = _b[`2'] in `ic'	
			drop z kz	
		}	
	local ic = `ic' + 1	
	}	
end	




program define fanreg
syntax varlist [if] [,reps(integer 50) cluster(varlist) bw(real 5) np(integer 50) maxminon max(real 0) min(real 0) title(passthru) xtitle(passthru) ytitle(passthru) saving(passthru) ygen(string) xgen(string) graph(string) ylabel(passthru) yline(passthru) xline(passthru)] 

*************** Explation of this program and method
*This uses a fan locally weighted nonparametric regression 
*( standard errors are recovemaroon through bootstrapping with replacement.
*****CODE FROM REBECCA THORNTON!
set seed 1000

tokenize `varlist' 

local theDepVar = "`1'"
mac shift
local theXVar = "`*'"


* Range of independent variable 
qui summ `theXVar' if `theDepVar' != .

local xmin = r(min)
local xmax = r(max)
* Number of points at which to calculate, 50 to 100 are typically fine 
local gsize = `np' + 1
* Size of each step 
local st = (`xmax' - `xmin')/(`gsize'-1)	
* Bandwidth - equal to 1-Nth of total distance 
local h = (`xmax' - `xmin') / `bw'
* name y variable for output
local yvar = "`ygen'"
local xvar = "`xgen'"
* turn graph on or off (on is default); set to "off" to supress graphs
local graph = "`graph'"
*display "`yvar'"
*Num bootstrap reps
local numreps = `reps'
pause
preserve

* reduce observations according to [if]
if "`if'" != "" {
	qui keep `if'
}

tempfile testfile lw_boot

qui save `testfile'

qui use `testfile', clear 

qui gen replic = 0	
qui gen ESTFCT= .	
qui gen xgrid = .	
qui gen ESTDER= .
qui keep in 1/1	

qui save `lw_boot', replace	

if "`cluster'" != "" {
	local clusterstring = ", cluster(`cluster')"	
	
}
else {
	local clusterstring = ""	
}
* Perform the bootstrap 
local jc = 1	
while `jc' <= `numreps' {	
	if mod(`jc',10) == 0 {
		display `jc' _continue
	}
	else {
		display "." _continue
	}
	
		
	drop _all	
	qui use `testfile',clear
	bsample `clusterstring'
	* This takes a sample of size _N (sample size), with replacement 
	qui gen xgrid = `xmin' + (_n-1)*`st' in 1/`gsize'	
	qui fan_reg `theDepVar' `theXVar' ESTFCT ESTDER `h' xgrid `np'
	drop `theDepVar' `theXVar'
	* Only keep the regression results 
	qui keep in 1/`gsize'	
	qui gen replic = `jc'	
	* "Stack" simulated regression results 
	append using `lw_boot'	
	qui save `lw_boot', replace	
	local jc = `jc' + 1	
	}	



* Recover the standard errors 
qui use `lw_boot',clear	
* Drop the "useless" initial values 
qui drop if replic == 0	
/* Compute the variation at each grid point */  
qui egen sdESTFCT = sd(ESTFCT), by(xgrid)
qui egen sdESTDER = sd(ESTDER), by(xgrid) 
/* Only keep the standard errors */  
sort xgrid 
/* Only keep the first observation at each grid point */  
quietly by xgrid: drop if _n ~= 1
qui keep xgrid sdESTFCT sdESTDER
sort xgrid
qui save `lw_boot',replace
clear 

/* Perform the Fan regression */ 
qui use `testfile'
qui gen xgrid = `xmin' + (_n-1)*`st' in 1/`gsize' 
qui fan_reg  `theDepVar' `theXVar' ESTFCT ESTDER `h' xgrid `np'
qui keep EST* xgrid 
sort xgrid 
/* Keep only the regression output */ 
qui keep in 1/`gsize' 

/* Merge the bootstrap standard error results */ 
qui merge xgrid using `lw_boot'
qui tab _me
qui drop _me
qui save `lw_boot', replace 

/* Compute 95 percent confidence bands */ 
/* Regression */ 
qui use `lw_boot', clear 
qui gen ESTFCT_u = ESTFCT + 1.96*sdESTFCT 
qui gen ESTFCT_l = ESTFCT - 1.96*sdESTFCT 
/* Derivative */ 
qui gen ESTDER_u = ESTDER + 1.96*sdESTDER 
qui gen ESTDER_l = ESTDER - 1.96*sdESTDER 
sort xgrid  


sort xgrid

pause
if "`maxminon'" == "maxminon" & "`max'" != "" & (`max' != 0 | `min' != 0) {
	qui replace ESTFCT = . if ESTFCT > `max' & ESTFCT != .
	qui replace ESTFCT_l = . if ESTFCT_l > `max' & ESTFCT_l != .
	qui replace ESTFCT_u = . if ESTFCT_u > `max' & ESTFCT_u != .
	pause	
}

if "`maxminon'" == "maxminon" & "`min'" != "" & (`max' != 0 | `min' != 0) {
	qui replace ESTFCT = . if ESTFCT < `min' & ESTFCT != .
	qui replace ESTFCT_l = . if ESTFCT_l < `min' & ESTFCT_l != .
	qui replace ESTFCT_u = . if ESTFCT_u < `min' & ESTFCT_u != .
	pause
}
pause

if "`graph'" != "off" {
	/* Graph the function and bounds */ 
	if "`maxminon'" == "maxminon"  {
		twoway (line ESTFCT xgrid, sort) (line ESTFCT_u xgrid, sort clpat(shortdash) cmissing(n)) (line ESTFCT_l xgrid, sort clpat(shortdash) cmissing(n)),  legend(off) `title' `xtitle' `ytitle' `saving' `ylabel' `yline' `xline' yscale(range(`min' `max'))
	} 
	else {
		twoway (line ESTFCT xgrid, sort) (line ESTFCT_u xgrid, sort clpat(shortdash) cmissing(n)) (line ESTFCT_l xgrid, sort clpat(shortdash) cmissing(n)),  legend(off) `title' `xtitle' `ytitle' `saving' `ylabel' `yline' `xline'
	}
}

*** Save y and x variables if they have been asked for (must ask for both)
if "`yvar'" != "" & "`xvar'" != "" {
	tempname file sortvar
	qui keep ESTFCT* xgrid
	*disp "HERE2a `yvar' `xvar'"
	ren ESTFCT `yvar'
	ren ESTFCT_u `yvar'_u
	ren ESTFCT_l `yvar'_l
	ren xgrid `xvar'
	qui keep `yvar' `yvar'_u `yvar'_l `xvar'
	sort `xvar'
	qui g `sortvar' = _n
	sort `sortvar'
	tempname file
	qui save `file', replace
}


/* Graph the derivative and bounds */ 
*twoway (line ESTDER xgrid, sort) (line ESTDER_u xgrid, sort clpat(dash)) (line ESTDER_l xgrid, sort clpat(dash)  xtitle("`theXVar'") ytitle("`theDepVar' ") )

restore

*** Bring generated variables back in
if "`yvar'" != "" & "`xvar'" != "" {
	g `sortvar' = _n
	sort `sortvar'
	merge `sortvar' using `file'
	drop _merge
	drop `sortvar'
}

end
