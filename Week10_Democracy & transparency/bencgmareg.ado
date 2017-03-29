program define bencgmareg, eclass

*********************************************************
* This program computes areg regressions with two simultaneous cluster variables
* The idea follows Cameron, Gelbach, and Miller (2006)
* Note that I also allow for lots of _I fixed effects type variables that you don't care about
* I drop them from the error matrix so we don't get lots of unpleasant matrix not semi definite errors
*
* Ben Olken
* September 16, 2006
*********************************************************

syntax varlist [if], absorb(varname) cluster1(varname) cluster2(varname) [numrealvars(int 0)] 

********************************
* Syntax
* bencgmareg varlist
********************************

tokenize `varlist' 

local theDepVar = "`1'"
mac shift
local theXVar = "`*'"

quietly {
	areg `varlist' `if', absorb(`absorb') cluster(`cluster1')
	matrix v1 = e(V)
	areg `varlist' `if', absorb(`absorb') cluster(`cluster2')
	matrix v2 = e(V)
	
	tempvar temp1
	egen `temp1' = group(`cluster1' `cluster2')
	areg `varlist' `if', absorb(`absorb') cluster(`temp1')
	matrix v3 = e(V)
	
	matrix b = e(b)
	local obs = r(N)
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
	
	ereturn post bnew vnew, depvar(`theDepVar') obs(`obs') esample(`sample')
}
ereturn disp
 
end

