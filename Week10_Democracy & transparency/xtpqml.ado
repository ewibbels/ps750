program define xtpqml, eclass 	 

tempvar n_i xb_hat_it mu_hat_it sum_mu_i p_it u_it v_inv_u_hat

syntax [varlist] [if], I(varname) T(varname) [irr] 	 
xtpois `varlist' `if', fe i(`i') `irr' 	 
display "Calculating Robust Standard Errors..." 	 
quietly { 	 
	local varlist : colnames e(b) 	 
	/******* Creating Matrices for Outer Product ********/ 	 
	matrix A_hat = e(V) 	/* defines initial V-C matrix */ 	 
	matrix b = e(b) 	 
	global K = colsof(b) 	 
	bysort `i' (`t'): egen `n_i' = sum(`e(depvar)') if e(sample) 	 
	predict `xb_hat_it', xb 	 
	gen `mu_hat_it' = exp(`xb_hat_it') if e(sample) 	 
	by `i': egen `sum_mu_i' = sum(`mu_hat_it') if e(sample) 	 
	/* i-specific denominator for p_it */ 	 
	gen `p_it' = `mu_hat_it' / `sum_mu_i' if e(sample) 	 
	gen `u_it' = `e(depvar)' - `p_it'*`n_i' if e(sample) 	 
	/* Generate Derivates of m_hat_it */ 	 
	foreach v of var `varlist' { 	 
		by `i': egen wt_sum_`v' = sum(`v'*`mu_hat_it') if e(sample) 	 
		gen del_m_`v' = `n_i'*`p_it'*(`v' - (wt_sum_`v'/`sum_mu_i')) if e(sample) 	 
		drop wt_sum_`v' 	 
		} 	 
	gen `v_inv_u_hat' = `u_it'/(`n_i'*`p_it') if e(sample) 	 
	matrix opaccum B_hat = del_m_* if e(sample), op(`v_inv_u_hat') group(`i') nocons 	 
	drop del_m_* 	 
	mat coef = e(b) 	 
	mat Vnew = A_hat*B_hat*A_hat 	 
	ereturn post coef Vnew 	 
} 		 
if "`irr'" == "irr" { 	 
ereturn display, eform(IRR) 	 
} 	 
if "`irr'" != "irr" { 	 
 ereturn display 	 
} 	 
end 	 
