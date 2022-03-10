/*==================================================
project:       
Author:        Angela Lopez 
E-email:       alopezsanchez@worldbank.org
url:           
Dependencies:  
----------------------------------------------------
Creation Date:     6 Jan 2022 - 11:19:54
Modification Date:   
Do-file version:    01
References:          
Output:             
==================================================*/

/*==================================================
              0: Program set up
==================================================*/
version 17
drop _all


/*==================================================
              1: routes
==================================================*/
global path "C:\Users\WB585318\WBG\Javier Romero - Panama\Pre-SCD"
global input "$path\02 data\simulations"
global output "$path\04 results"
/*==================================================
              2: 
==================================================*/


tempname pname
tempfile pfile
postfile `pname' str30(country) year str30(indicators pline zone income_type) value obs using `pfile', replace
local samples all  


use "$input\variables_conagri.dta"
*----------2.1: Deflactation


local lost 100_20 100_21
	
foreach l of local lost {
    
	local income  ipcf ipcf_`l' ipcf_PS20_`l' ipcf_PS1_1_`l' ipcf_PS1_1_`l'_1 ipcf_PS1_1_`l'_2 
	
	foreach var in `income' {
		noi di in red "Income: `var'"
		*cap drop `var'_ppp
		cap gen double `var'_ppp = (`var' * (ipc11/ipc_sedlac) * (1/ppp11))
	}

*---------2.2: Poverty Lines

	cap drop lp_190usd_ppp lp_320usd_ppp lp_550usd_ppp lp_1300usd_ppp lp_7000usd_ppp
	cap drop lp_1000usd_ppp 
	
	
	local days = 365/12		// Ave days in a month
	*local pls 550 785
	local pls 190 320 550 1300 7000
	
	foreach pl of local pls {
		
		
		local pl1 = `pl'/100
		cap gen double lp_`pl'_ppp = `pl1'*(`days')
		
	}	
*----------2.3: Poverty impact 
	

	local incomes ipcf_ppp ipcf_`l'_ppp ipcf_PS1_1_`l'_2_ppp 		// <------------- 	INCOMES POVERTY CALCUL!
	local bono = 0 
	local caracteristicas total urbano_ rural_ comarcas provincias Cocle Colon Chiriqui Darien Herrera Los_Santos Panama Veraguas Comarca_Kuna_Yala Comarca_Embera Comarca_Ngobe_Bugle Panama_Oeste Bocas_del_Toro 
	
	foreach inc of local incomes{
		
		foreach carac of local caracteristicas{
			
			local pls 190 320 550 1300 7000
			
			foreach pl of local pls {	
				
				
				if "`l'"  =="100_20"   local ano 2020
				if "`l'"  =="100_21"   local ano 2021
				if "`inc'"=="ipcf_ppp" local ano 2019
				
				*set trace on
				noi di in red "LOST `l'"
				
				display in red "Count `bono'"
				
				cap drop poor_`l'_`pl'_`bono'
				gen poor_`l'_`pl'_`bono' = .
				replace poor_`l'_`pl'_`bono' = 1 if `inc' < lp_`pl'_ppp
				replace poor_`l'_`pl'_`bono' = . if `inc' ==.
			
				label var poor_`l'_`pl'_`bono' "Poor with income `inc' and line `pl'"
		

				*------- poblaciones de interés
							
				*headcount 
				
				di in red "`carac'"
				apoverty `inc' [w=pondera] if `carac'==1, varpl(lp_`pl'_ppp) 
				local value = `r(head_1)' 

				cap sum poor_`l'_`pl'_`bono' [w=pondera] if `carac'==1
				local poor = `r(sum_w)'
				
				
				post `pname' ("pan") (`ano') ("poverty") ("`pl'") ("`carac'") ("`inc'") (`value') (`poor')

				
				

				
		} // close lp
				
				cap gen poor_`l'_1300_`bono' = . 
				cap replace poor_`l'_1300_`bono' = 1 if (`inc' >= lp_550_ppp & `inc'<lp_1300_ppp)
				cap replace poor_`l'_1300_`bono' = . if `inc' ==.
				
				cap gen poor_`l'_7000_`bono' = . 
				cap replace poor_`l'_7000_`bono' = 1 if (`inc' >= lp_1300_ppp & `inc'<lp_7000_ppp) 
				cap replace poor_`l'_7000_`bono' = . if `inc' ==.
				
				cap gen poor_`l'_7000_`bono'_plus =. 
				replace poor_`l'_7000_`bono'_plus =1 if `inc'>lp_7000_ppp
				cap replace poor_`l'_7000_`bono'_plus = . if `inc' ==. 
				
				cap sum poor_`l'_1300_`bono' [w=pondera] if `carac'==1 & if (`inc' >= lp_550_ppp & `inc'<lp_1300_ppp)
				
				if `r(N)' >  0 {
						
				local poor = `r(sum_w)'
				sum `carac' [w=pondera]
				local denom = `r(sum_w)'
				local value = `poor'/`denom' *100
				
				post `pname' ("pan") (`ano') ("poverty") ("Vulnerable") ("`carac'") ("`inc'") (`value') (`poor')
				}
		
		
				cap sum poor_`l'_7000_`bono' [w=pondera] if `carac'==1 & (`inc' >= lp_1300_ppp & `inc'<lp_7000_ppp) 
				
				if `r(N)' >  0 {
						
				local poor = `r(sum_w)'
				sum `carac' [w=pondera]
				local denom = `r(sum_w)'
				local value = `poor'/`denom' *100
				
				post `pname' ("pan") (`ano') ("poverty") ("Middle") ("`carac'") ("`inc'") (`value') (`poor')
				}
		
		
				cap sum poor_`l'_7000_`bono'_plus [w=pondera] if `carac'==1 
				
				if `r(N)' >  0 {
						
				local poor = `r(sum_w)'
				sum `carac' [w=pondera]
				local denom = `r(sum_w)'
				local value = `poor'/`denom' *100
				
				post `pname' ("pan") (`ano') ("poverty") ("Rich") ("`carac'") ("`inc'") (`value') (`poor')
				}
				
				if `r(N)' ==  0 {
				post `pname' ("pan") (`ano') ("poverty") ("Rich") ("`carac'") ("`inc'") (.) (.)
				}
		
				* GINI
				
				ineqdeco `inc' [w=pondera] if `carac'==1
				
				local value= `r(gini)'
				local poor= `r(sumw)'
				
				post `pname' ("pan") (`ano') ("gini") (".") ("`carac'") ("`inc'")  (`value') (`poor')
			
						
		}	// Close characteristica
	}	// close incomes
}	// Close lost


postclose `pname'
use `pfile', clear
format value %15.2fc

*drop if year ==2019

export excel using "${output}\Poverty_Indicators_PAN_simulaciones.xlsx", sh("Poverty_GINI", replace)  firstrow(var)




exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:


