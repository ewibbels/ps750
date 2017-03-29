program define bencgmreg, eclass

*********************************************************
* This program computes reg regressions with two simultaneous cluster variables
* The idea follows Cameron, Gelbach, and Miller (2006)
* It allows for an optional absorb variable
* Note that I also allow for lots of _I fixed effects type variables that you don't care about
* I drop them from the error matrix so we don't get lots of unpleasant matrix not semi definite errors
* If you specify the iv specicicaiton, you put the lhs and exog vars in varlist, with endovars and instruments specified late
* of indep variables, including exog ones. You are not allowd to specify BOTH exogvars and absorb
*
* Ben Olken
* September 16, 2006
*********************************************************

syntax varlist [if], cluster1(varname) cluster2(varname) [absorb(varname) NUMrealvars(int 0) ivendogvars(varlist) ivinstruments(varlist)] 

********************************
* Syntax
* bencgmareg varlist
********************************

tokenize `varlist' 

local theDepVar  `1'
mac shift
local theXVar  `*'

if "`absorb'" != "" & ("`ivinstruments'" != "" | "`ivendogvars'" != "") {
	display "You cannot specify BOTH absorb and IV variables."
	error 1	
}

quietly {
	if "`absorb'" != "" {
		areg `varlist' `if', absorb(`absorb') cluster(`cluster1')
		matrix v1 = e(V)
		areg `varlist' `if', absorb(`absorb') cluster(`cluster2')
		matrix v2 = e(V)
		
		tempvar temp1
		egen `temp1' = group(`cluster1' `cluster2')
		areg `varlist' `if', absorb(`absorb') cluster(`temp1')
		matrix v3 = e(V)
	}
	else if "`ivendogvars'" != "" | "`ivinstruments'" != "" {
		ivreg `theDepVar' (`ivendogvars' = `ivinstruments') `theXVar' `if', cluster(`cluster1')
		matrix v1 = e(V)
		ivreg `theDepVar' (`ivendogvars' = `ivinstruments') `theXVar'  `if', cluster(`cluster2')
		matrix v2 = e(V)
		
		tempvar temp1
		egen `temp1' = group(`cluster1' `cluster2')
		ivreg `theDepVar' (`ivendogvars' = `ivinstruments') `theXVar'  `if', cluster(`temp1')
		matrix v3 = e(V)
		
	}
	else {
		reg `varlist' `if', cluster(`cluster1')
		matrix v1 = e(V)
		reg `varlist' `if', cluster(`cluster2')
		matrix v2 = e(V)
		
		tempvar temp1
		egen `temp1' = group(`cluster1' `cluster2')
		reg `varlist' `if', cluster(`temp1')
		matrix v3 = e(V)
		
	}
		
		
	matrix b = e(b)
	local obs = e(N)
	tempvar sample 
	g `sample' = e(sample)
	
	matrix v4 = v1 + v2 - v3
	
	if `numrealvars' == 0 {
		matrix vnew = v4
		matrix bnew = b
	}
	else {
		matrix vnew = v4[1..`numrealvars',1..`numrealvars']
		matrix bnew = b[1,1..`numrealvars']
	}
	display "`theDepVar'"
	ereturn post bnew vnew, dep(`theDepVar') o(`obs') esample(`sample')
}
ereturn disp

display "Cluster variables: `cluster1' `cluster2'"
if "`ivendogvars'" != "" | "`ivinstruments'" != "" {
	display "Endogenous variables: `ivendogvars'"
	display "Instruments: `ivinstruments'"
	display "Exogenous variables: `theXVar'"
	}
if "`absorb'" != "" {
	display "Absorbed: `absorb'"
	}
 
end

