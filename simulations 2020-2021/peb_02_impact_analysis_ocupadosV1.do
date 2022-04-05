/*==============================================================================
project:       PAN Simulations COVID19 -  Datasets 2018			
Author:        Javier Romero
Last modification: Angela Lopez 
----------------------------------------------------
==============================================================================*/


 global path "C:\Users\WB585318\WBG\Javier Romero - Panama"
		


/*==================================================
			6: Impact and Poverty - A
* All Population
* program recipients
==================================================*/


preserve

tempname pname
tempfile pfile
postfile `pname' year str30(sample) pline str30(desagregacion) str30(income_type) str30(inc_reduc) value population using `pfile', replace
local samples all  

*----------6.1: Deflactation
local lost 100_20 100_21 100_22
 
foreach l of local lost {
	
    if "`l'"=="100_20" local ano_p = "20"
	if "`l'"=="100_21" local ano_p = "21"
	if "`l'"=="100_22" local ano_p = "22"
	
	local income  ipcf ipcf_`l' ipcf_PS20_`l' ipcf_PS1_1_`l'_1 ipcf_PS1_1_`l'_2 ipcf_PS1_1_`l'_3
	
	foreach var in `income' {
		noi di in red "Income: `var'"
		*cap drop `var'_ppp
		cap gen double `var'_ppp = (`var' * (ipc11/ipc_sedlac) * (1/ppp11))
	}

*---------5.2: Poverty Lines

	cap drop lp_190usd_ppp lp_320usd_ppp lp_550usd_ppp lp_1300usd_ppp 
	cap drop lp_1000usd_ppp 
	
	
	local days = 365/12		// Ave days in a month
	*local pls 550 785
	local pls 190 200 320 342 550 560 1300 1310 7000 7010

	
	foreach pl of local pls {
		local pl1 = `pl'/100
		cap gen double lp_`pl'_ppp = `pl1'*(`days')
		
	}
	
*----------5.3: Poverty impact 


	local incomes  ipcf_ppp ipcf_ppp11_20_sin_covid ipcf_`l'_ppp ipcf_PS20_`l'_ppp ipcf_PS1_1_`l'_1_ppp  ipcf_PS1_1_`l'_2_ppp ipcf_PS1_1_`l'_3_ppp		// <------------- 	INCOMES POVERTY CALCUL!
	local bono = 0 
	local caracteristicas total urbano_ rural_ 
	*comarcas provincias indig Cocle Colon Chiriqui Darien Herrera Los_Santos Panama Veraguas Comarca_Kuna_Yala Comarca_Embera Comarca_Ngobe_Bugle Panama_Oeste Bocas_del_Toro 
	
	foreach inc of local incomes{
		
		foreach carac of local caracteristicas{
			
			foreach pl of local pls {	
				
				*set trace on
				noi di in red "LOST `l'"
				
				display in red "Count `bono'"
				
				cap drop poor_`l'_`pl'_`bono'
				gen poor_`l'_`pl'_`bono' = .
				replace poor_`l'_`pl'_`bono' = 1 if `inc' < lp_`pl'_ppp
				label var poor_`l'_`pl'_`bono' "Poor with income `inc' and line `pl'"
		

		
				*------- poblaciones de interés
							
				*headcount 
				
				di in red "`carac'"
				apoverty `inc' [w=pondera_`ano_p'] if `carac'==1, varpl(lp_`pl'_ppp) 
				local value = `r(head_1)' 
							
				*--			
				cap sum poor_`l'_`pl'_`bono' [iw=pondera_`ano_p'] if `carac'==1
				local poor = `r(sum_w)'
				
				post `pname' (2019) ("poverty") (`pl') ("`carac'") ("`inc'") ("`l'") (`value') (`poor')

		} // close lp
		
				* GINI
				
				ineqdeco `inc' [iw=pondera_`ano_p'] if `carac'==1
				local value= `r(gini)'
				local poor= `r(sumw)'
				
				post `pname' (2019) ("gini") (.) ("`carac'") ("`inc'") ("`l'") (`value') (`poor')
							
						
		}	// Close characteristica
	}	// close incomes
}	// Close lost


postclose `pname'
use `pfile', clear
format value %15.2fc

export excel using "C:\Users\WB585318\WBG\Javier Romero - Panama\Covid\output\impact_no_psV2.xlsx", sh("Results_22_V1", replace)  firstrow(var)


cap restore
	

save "${path}\interdata\peb_202107_impact_ramas_22calibrado.dta", replace

exit 