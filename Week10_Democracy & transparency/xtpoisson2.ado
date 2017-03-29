
***********************************
* reverse-engineered XTGLS (adapted from Wes Yin's code, and optimized for large groups)
***********************************
program define xtpoisson2
	version 7.0, missing
	if replay() {
		if _by() { error 190 }
                if `"`e(cmd)'"'~=`"xtpoisson2"' {
                        error 301
                }
		syntax [, Level(int $S_level)]
                if `"`level'"' != "" {
                        if `level' < 10 | `level' > 99 {
                                local level = 95
                        }
                }
		else local level $S_level
		DispRes `level'
		exit
	}
	if _by() {
		local by "by `_byvars'`_byrc0':"
	}
	capture noi `by' Estimate `0'
	nobreak { mac drop X_* }
	exit _rc
end


program define Estimate, eclass byable(recall)
	mac drop X_*
	syntax varlist [if] [in] [aw] [, i(varname) ]

preserve

matrix drop _all


*global var1 etcfull
*global var2 etcadopt
*global var3 znumdusun
*global var4 zmeanadulteducation
*global var5 elevation 
*global var6 zdistancekabnear 
*global var7 ztimekabnear 
*global var8 zpercentpoorpra
*global var9 cons




di "testing ..."

	gettoken depvar varlist: varlist

	
	
	di "dropping collinear columns ..."
	_rmcoll `varlist' [`weight'`exp'] `if' `in', cons
	di "done dropping."
	_rmcoll `varlist' `if' `in'
	local varlist `r(varlist)'
	global X_indv1 `varlist' 
	local kk : word count `varlist'
	global X_rhok "k(`kk')"

*	if "`constant'" == "" {
*		local varname `varlist' _cons
*	}
*	else {
*		local varname `varlist'
*	}

di "dropping ..."
drop if `depvar' == .

*di "X_rhok: $X_rhok"
*di "varlist: `varlist'"
*di "X_indv1 $X_indv"


display "dep var is `depvar'"

local varlist `depvar' `varlist'
global X_depv1 "`depvar'"



di "weights: `weight' `exp' ..."

	global X_if `"`if'"'
	global X_in `"`in'"'


	tokenize `varlist'
	global X_depv `"`1'"'
	mac shift
	global X_indv `"`*'"'

di "----------"
di "X_depv: $X_depv"
di "X_indv: $X_indv"
di "----------"

tokenize "$X_indv"
local j 1
while `"``j''"' != `""' {
  global var`j' = "``j''"
  local j = `j' + 1
}

local numvars = `j' - 1
forvalues j = 1/`numvars' {
  di "var`j' ... ${var`j'} ... "
}



local cluster = "`i'"
xtpoisson $X_depv $X_indv, fe i(`cluster')

quietly {
*xtpoisson $X_depv $X_indv$depvar numchannelskec lnzadultpop znumdusun zmeanadulteducation elevation zdistancekabnear ztimekabnear zpercentpoorpra if numchannelskecdemeanedpctile > .025 & numchannelskecdemeanedpctile < .975, fe i(kabnum)	
*areg zsocdesanumgroupsneighbALL numchannelskec lnzadultpop znumdusun zmeanadulteducation elevation zdistancekabnear ztimekabnear zpercentpoorpra if numchannelskecdemeanedpctile > .025 & numchannelskecdemeanedpctile < .975,  absorb(kabnum)	
keep if e(sample)									/* keeps only those */
*drop id2 id n_i *hat* *_it**/
*args depvar var1 var2 var3 var4 var5 var6 var7 var8 var9 var10 var11 var12 var13 var14 var15 var16 var17	/* Program for variables with three regressors (help to imbed?) */
*save robust_temp, replace							/* to avoid saving over panel_skel.dta */


di "generating time-series variable ..."
local ivar = "`cluster'"
sort `ivar'
by `ivar': gen __year__ = _n - _N
*g __year__ = 1
di "done."


******* Creating Variables to be Inputted into Matrices ********/

di "creating matrices ..."
sort `ivar' __year__

matrix VC=e(V)									/* defines initial V-C matrix (includes poisson alpha coefficient) */
matrix b = e(b)	
matrix betas = e(b)	

di "creating n_hi, mu_hat_i, etc. ..."
bysort `ivar': egen n_i = sum($X_depv)
predict xb_hat_it if e(sample), xb
gen mu_hat_it = exp( xb_hat_it) 	/* predicted mu for each disease, every t; also numerator for p_it */ 
bysort `ivar': egen mu_hat_i = sum( mu_hat_it)   /* i-specific denominator for p_it */
gen p_it =  mu_hat_it / mu_hat_i
gen u_it = $X_depv - p_it*n_i	/* this is u_hat_it, which forms Tx1 vector u_hat_i; needs to be made a matrix */

/* Variables for Del_p_it */	/* in Stata's editor, this will form the TxP matrix; will need ot be transposed */

global i = 1
global colsb = colsof(b)

di "number of dependent variables"
di $colsb
di "====="

sort `ivar' __year__

while $i <= $colsb {
	di "number ... $i"
	gen mu_hat_it_var$i = (${var$i}) * mu_hat_it
	bysort `ivar':  egen mu_hat_i_var$i = sum(mu_hat_it_var$i)
	di "got here!"
	gen del_p_it_var$i = ( ${var$i} * (mu_hat_it * mu_hat_i) - mu_hat_it * (mu_hat_i_var$i)) / ((mu_hat_i)^2)
	global i = $i + 1
}

sort `ivar' __year__
bysort `ivar': gen id = 1 if _n==1
sort id `ivar'
egen id2 = fill(1 2)
replace id2 = . if id == .
sort `ivar' __year__
replace id = id2
drop id2
bysort `ivar': gen id2 = sum(id)
replace id = id2
drop id2			/* id is new disease specific count variable */

*ereturn list
global n = e(N_g)						/* $n counts the total number of diseases included in the e(sample)*/

di "total number of ivar clusters ... $n"

sort `ivar' __year__


/***** Inputting into Matrices ******/

global i =1
global p = 1
global t = 1
*global colsb = colsof(b)*/
*global T = e(g_max)
*di "max T ... $T"

matrix B_i = J($colsb, $colsb, 0)
matrix B = J($colsb, $colsb, 0)
matrix A_i = J($colsb, $colsb, 0)
matrix A = J($colsb, $colsb, 0)

matrix invDiagP_i = J($colsb, $colsb, 0)



gen id2 = id
sort id2 __year__

while $i <= $n {
	qui summ id if id == $i
	global T = r(N)
	di "trial $i ... T: $T ..."        

	matrix D_i = J($T, $colsb, 0)	
	matrix P_i = J($T, 1, 0)	
	matrix U_i = J($T, 1, 0)	
	matrix U_i = J($T, 1, 0)	

	while $p <= $colsb {
		qui global t = 1
		while $t <= $T {							/* fill in for all t's first */
                    matrix D_i[$t,$p] = del_p_it_var$p[$t]			/* value for disease i, __year__ t (1981), variable p */
                    matrix P_i[$t,1] = p_it[$t]				/* value for disease i, __year__ t (1981) of P matrix */
                    matrix U_i[$t,1] = u_it[$t]				/* value for disease i, __year__ t (1981) of U matrix */
		    qui global t = $t + 1
		}
		qui global p = $p + 1
		sort id2 __year__
	}

	global p = 1

	matrix invDiagP_i = syminv(diag(P_i))

	matrix S_i = D_i' * invDiagP_i * U_i
	matrix B_i = S_i*S_i'
	matrix B = B + B_i
	
	global ni = n_i	
	matrix A_i = $ni*D_i'* invDiagP_i * D_i
	matrix A = A + A_i

*	matrix list A
*	matrix list B

*	matrix Rtemp = syminv(A) * B * syminv(A)
*	matrix list Rtemp
	qui replace id2 = id2 + e(N_g) if id == $i  /* this sequence moves the ith disease that was just done to the bottom */
	sort id2 __year__

	global i = $i + 1

/*	di "done"*/

}




/***** Compare SE's ******/
matrix Vmle = vecdiag(VC)
global p = 1
while $p <= $colsb {
	global v = Vmle[1,$p]
	matrix SEmle = [nullmat(SEmle), sqrt($v)]
	global p = $p + 1
}



*matrix list A
matrix Ai = syminv(A)
matrix R = Ai*B*Ai
matrix robustV = R
matrix Rmle = vecdiag(R)
global p = 1
while $p <= $colsb {
	global v = Rmle[1,$p]
	matrix RSEmle = [nullmat(RSEmle), sqrt($v)]
	global p = $p + 1
}

*matrix list b

di "done."

}
*end quietly

di "displaying matrix results ..."
matrix list SEmle
matrix list RSEmle

matrix robustV = vecdiag(robustV)
matrix robustV = diag(robustV)

gen tempSample = e(sample)
local depvar2 = e(depvar)
local obs = e(N)
di "obs `obs' ..." 
	
di "xtpoisson with ROBUST standard errors ..."
di "updating ..."

*est clear
*est post betas robustV, depname(`depvar2') o(`obs') esample(tempSample)
est repost b = betas V = robustV
est display

restore 
di "DONE!!!!"
est repost

end



