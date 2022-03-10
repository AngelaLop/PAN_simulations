/*==============================================================================
project:       PAN Simulations COVID19 -  Datasets 2018
				

							
				
Author:        Javier Romero
Last modification: Angela Lopez 
----------------------------------------------------
==============================================================================*/

clear 

 global path "C:\Users\WB585318\WBG\Javier Romero - Panama"
		

/*******************************************************************************
		4: Income simulations
*******************************************************************************/

use "${path}\Covid\interdata\Nov2021\variables_conagri.dta", clear

*proyecting 2020 without covid

		global privconsum_20 = 1.3 /*private consumption growth*/
		gen ipcf_ppp11_20_sin_covid = ipcf_ppp11*(1 + ${privconsum_20}/100)
	
	
*proyecting with COVID-19

		*100% loss for 18% unemployed
		gen people_active_ = pondera if pea == 1
		sum pondera if pea == 1
		local  people_pea = r(sum)
		di `people_pea'
		gen people_active_shock = pondera if pea == 1 & shock_3 ==1 
		gsort -shock_3 -desocupa_Fx
		gen people_desocupa = sum(people_active_shock)
		gen desocupa_prct = people_desocupa/`people_pea'


			*2020
			*unemployment 
			gen unemployed20 = (desocupa_prct<=0.185)
			tab unemployed20 [fw=pondera] if pea == 1, miss
			tab unemployed20 shock_3 /*only those shocked*/
			
			*sexo
			gen unemployed20_1 = (desocupa_prct<=0.136) if hombre==1
			replace unemployed20_1 = (desocupa_prct<=0.247) if hombre==0
			tab unemployed20_1 [fw=pondera] if pea == 1, miss
			tab unemployed20_1 shock_3 /*only those shocked*/
			
			
			*2021
			gen unemployed21 = (desocupa_prct<=0.173) // from HFS 2021
			tab unemployed21 [fw=pondera] if pea == 1, miss
			tab unemployed21 shock_3 /*only those shocked*/
			
			
		*100% loss for  employment 
		cap gen people_active_ = pondera if pea == 1
		sum pondera if pea == 1
		local  people_pea = r(sum)
		di `people_pea'
		cap gen people_active_shock = pondera if pea == 1 & shock_3 ==1 
		gsort shock_3 -ocupa_Fx 
		gen people_ocupa = sum(people_active_shock)
		gen ocupa_prct = people_ocupa/`people_pea'
	
	br people_active_shock shock_3 ocupa_Fx ocupa_prct people_active_

			*2020
			
			* tasas de ocupacion por rama y sexo (ocupados/pea)
			*sexo y rama
		
		*hombres			
				gen employed20_aux = sum(people_active_) if hombre==1 & rama_s ==1 & pea==1 // Agricultura			
			replace employed20_aux = sum(people_active_) if hombre==1 & rama_s ==2 & pea==1 // Industria
			replace employed20_aux = sum(people_active_) if hombre==1 & rama_s ==3 & pea==1 // Comercio
			replace employed20_aux = sum(people_active_) if hombre==1 & rama_s ==4 & pea==1 // Servicios
						
		*mujeres
			replace employed20_aux = sum(people_active_) if hombre==0 & rama_s ==1 & pea==1 // Agricultura
			replace employed20_aux = sum(people_active_) if hombre==0 & rama_s ==2 & pea==1 // Industria
			replace employed20_aux = sum(people_active_) if hombre==0 & rama_s ==3 & pea==1 // Comercio
			replace employed20_aux = sum(people_active_) if hombre==0 & rama_s ==4 & pea==1 // Servicios
*-------					
		*hombres 
				gen employed20_1 = (employed20_aux<=179016) if hombre==1 & rama_s ==1 & pea==1 // Agricultura	
			replace employed20_1 = (employed20_aux<=224322) if hombre==1 & rama_s ==2 & pea==1 // Industria
			replace employed20_1 = (employed20_aux<=146005) if hombre==1 & rama_s ==3 & pea==1 // Comercio
			replace employed20_1 = (employed20_aux<=413723) if hombre==1 & rama_s ==4 & pea==1 // Servicios		
			
		*mujeres 
			replace employed20_1 = (employed20_aux<=55228) if hombre==0 & rama_s ==1 & pea==1 // Agricultura	
			replace employed20_1 = (employed20_aux<=78183) if hombre==0 & rama_s ==2 & pea==1 // Industria
			replace employed20_1 = (employed20_aux<=131463) if hombre==0 & rama_s ==3 & pea==1 // Comercio
			replace employed20_1 = (employed20_aux<=413151) if hombre==0 & rama_s ==4 & pea==1 // Servicios
			
				
		
			*2021 // aumento de la TO 5.5pp (HFS2021) representa aumento de los ocupados en 10.7%  
			
			*gen employed21 = (ocupa_prct>=0.8265) if pea==1
			*gen employed21 = (unemployed21==0) if pea == 1
			
			
		*hombres 
				gen employed21 = (employed20_aux<=193617) if hombre==1 & rama_s ==1 & pea==1 // Agricultura	
			replace employed21 = (employed20_aux<=247444) if hombre==1 & rama_s ==2 & pea==1 // Industria
			replace employed21 = (employed20_aux<=160791) if hombre==1 & rama_s ==3 & pea==1 // Comercio
			replace employed21 = (employed20_aux<=456908) if hombre==1 & rama_s ==4 & pea==1 // Servicios		
			
		*mujeres 
			replace employed21 = (employed20_aux<=60547)  if hombre==0 & rama_s ==1 & pea==1 // Agricultura	
			replace employed21 = (employed20_aux<=86086)  if hombre==0 & rama_s ==2 & pea==1 // Industria
			replace employed21 = (employed20_aux<=144902) if hombre==0 & rama_s ==3 & pea==1 // Comercio
			replace employed21 = (employed20_aux<=456928) if hombre==0 & rama_s ==4 & pea==1 // Servicios
			
			
			
			* alternative scenario - 154000 reactivated jobs acording to MEP  (https://www.laestrella.com.pa/opinion/columnistas/210706/panama-panorama-laboral-2021)
			
		*hombres 
				gen employed21_1 = (employed20_aux<=195814) if hombre==1 & rama_s ==1 & pea==1 // Agricultura	
			replace employed21_1 = (employed20_aux<=245372) if hombre==1 & rama_s ==2 & pea==1 // Industria
			replace employed21_1 = (employed20_aux<=159706) if hombre==1 & rama_s ==3 & pea==1 // Comercio
			replace employed21_1 = (employed20_aux<=452546) if hombre==1 & rama_s ==4 & pea==1 // Servicios		
			
		*mujeres 
			replace employed21_1 = (employed20_aux<=60410)  if hombre==0 & rama_s ==1 & pea==1 // Agricultura	
			replace employed21_1 = (employed20_aux<=85519)  if hombre==0 & rama_s ==2 & pea==1 // Industria
			replace employed21_1 = (employed20_aux<=143799) if hombre==0 & rama_s ==3 & pea==1 // Comercio
			replace employed21_1 = (employed20_aux<=451921) if hombre==0 & rama_s ==4 & pea==1 // Servicios		
			
		
			
	di in red "PANAMA SOLIDARIO: PERSONAS 2020 condiciones luego de shock (PS2020)"
		tab total [w=pondera] if ben_pan_solid20 == 1 & asalariado_nogob==1 & employed20_1==1 & urbano==1
		replace ben_pan_solid20 = 0 if ben_pan_solid20 == 1 & asalariado_nogob==1 & employed20_1==1 & urbano==1 // asalariados activos
		
		
		* mejorando el targeting por localizacion geografica 
		* zonas urbanas -  Vale digital
		
		gen benef_aux = pondera if ben_pan_solid20 ==0 & (ila<917 | ila==.)

		set seed 1234 
    
    * Assign random numbers to the observations and rank them from the smallest to the largest
    gen random_benef = uniform() if ben_pan_solid20 ==0 & (ila<917 | ila==.)  // [GENERATES A RANDOM NUMBER BETWEEN 0 AND 1] 
	sort region urbano random_benef
	
	    gen random_benef_aux = sum(benef_aux) if Panama==1 & urbano==1
	replace random_benef_aux = sum(benef_aux) if Panama_Oeste==1 & urbano==1
	replace random_benef_aux = sum(benef_aux) if Colon==1 & urbano==1
	replace random_benef_aux = sum(benef_aux) if Chiriqui==1 & urbano==1
	replace random_benef_aux = sum(benef_aux) if Comarca_Ngobe_Bugle==1 & urbano==1
	replace random_benef_aux = sum(benef_aux) if Panama_Oeste==1 & urbano==0
	replace random_benef_aux = sum(benef_aux) if Panama==1 & urbano==0
	replace random_benef_aux = sum(benef_aux) if Comarca_Embera==1 & urbano==0

	* urban areas
	    gen random_benefiario = random_benef_aux <=35147   if Panama ==1 & urbano==1
	replace random_benefiario = random_benef_aux <=31249   if Panama_Oeste==1 & urbano==1	
	replace random_benefiario = random_benef_aux <=47324   if Colon==1 & urbano==1
	replace random_benefiario = random_benef_aux <=12534   if Chiriqui==1 & urbano==1
	replace random_benefiario = random_benef_aux <=3499    if Comarca_Ngobe_Bugle==1 
	
	* rural areas 
	replace random_benefiario = random_benef_aux <=17239    if Panama_Oeste==1 & urbano==0  
	replace random_benefiario = random_benef_aux <=13866    if Panama==1 & urbano==0
	replace random_benefiario = random_benef_aux <=1055     if Comarca_Embera ==1 & urbano==0
	
	
	* randomly exclude beneficiaries 
	gen benef_excl_aux = pondera if ben_pan_solid20 ==1

	set seed 1235 
    
    * Assign random numbers to the observations and rank them from the smallest to the largest
    gen random_excluded = uniform() if ben_pan_solid20 ==1  // [GENERATES A RANDOM NUMBER BETWEEN 0 AND 1] 
	sort random_excluded
	gen random_excluded_aux = sum(benef_excl_aux) if Panama==1 & urbano==1
	replace random_excluded_aux = sum(benef_excl_aux) if Cocle==1 & urbano==1
	replace random_excluded_aux = sum(benef_excl_aux) if Los_Santos==1 & urbano==1
	replace random_excluded_aux = sum(benef_excl_aux) if Bocas_del_Toro==1 & urbano==1
	replace random_excluded_aux = sum(benef_excl_aux) if Veraguas==1 & urbano==1
	replace random_excluded_aux = sum(benef_excl_aux) if Herrera==1 & urbano==1
	replace random_excluded_aux = sum(benef_excl_aux) if Darien==1 & urbano==1
	
	replace random_excluded_aux = sum(benef_excl_aux) if Chiriqui==1 & urbano==0
	replace random_excluded_aux = sum(benef_excl_aux) if Veraguas==1 & urbano==0
	replace random_excluded_aux = sum(benef_excl_aux) if Cocle==1 & urbano==0
	replace random_excluded_aux = sum(benef_excl_aux) if Comarca_Ngobe_Bugle==1 & urbano==0
	replace random_excluded_aux = sum(benef_excl_aux) if Colon==1 & urbano==0
	replace random_excluded_aux = sum(benef_excl_aux) if Bocas_del_Toro==1 & urbano==0
	replace random_excluded_aux = sum(benef_excl_aux) if Los_Santos==1 & urbano==0
	replace random_excluded_aux = sum(benef_excl_aux) if Herrera==1 & urbano==0
	replace random_excluded_aux = sum(benef_excl_aux) if Darien==1 & urbano==0
	replace random_excluded_aux = sum(benef_excl_aux) if Comarca_Kuna_Yala==1 & urbano==0
	
	* urbano
		  g randomly_excluded = random_excluded_aux <=14148   if Veraguas==1 & urbano==1
	replace randomly_excluded = random_excluded_aux <=13689   if Cocle==1 & urbano==1
	replace randomly_excluded = random_excluded_aux <=7200    if Los_Santos==1 & urbano==1
	replace randomly_excluded = random_excluded_aux <=16289   if Bocas_del_Toro==1 & urbano==1
	replace randomly_excluded = random_excluded_aux <=13916   if Herrera==1 & urbano==1
	replace randomly_excluded = random_excluded_aux <=717     if Darien==1 & urbano==1

	* rural 
	replace randomly_excluded = random_excluded_aux <=12929   if Chiriqui==1 & urbano==0
	replace randomly_excluded = random_excluded_aux <=16583   if Veraguas==1 & urbano==0
	replace randomly_excluded = random_excluded_aux <=17394   if Cocle==1 & urbano==0
	replace randomly_excluded = random_excluded_aux <=11995   if Comarca_Ngobe_Bugle==1 & urbano==0
	replace randomly_excluded = random_excluded_aux <=4416    if Colon==1 & urbano==0
	replace randomly_excluded = random_excluded_aux <=3986    if Bocas_del_Toro==1 & urbano==0
	replace randomly_excluded = random_excluded_aux <=7429    if Los_Santos==1 & urbano==0
	replace randomly_excluded = random_excluded_aux <=1844    if Herrera==1 & urbano==0
	replace randomly_excluded = random_excluded_aux <=2234    if Darien==1 & urbano==0
	replace randomly_excluded = random_excluded_aux <=993     if Comarca_Kuna_Yala==1 & urbano==0
 
	replace ben_pan_solid20 = 1 if ben_pan_solid20 ==0 & random_benefiario ==1
	replace ben_pan_solid20 = 0 if ben_pan_solid20 ==1 & randomly_excluded ==1
	
	egen hh_ben_pan_solid20_1 = max(ben_pan_solid20), by(id)

	di in red "PANAMA SOLIDARIO: HOGARES 2021-S1 condiciones luego de shock (P20211)"
	
		
	*------5.4.2: generate variable 
	*drop  ben_pan_solid211 random_number_aux hh_empleado_gob hh_empleado_gob_ random_number hh_empleado_gob_out
	
	gen ben_pan_solid211 = ben_pan_solid20 
	
	replace ben_pan_solid211 = 0 if employed20_1==0 & employed21_1 ==1 & ben_pan_solid211 == 1 & urbano==1
	*replace ben_pan_solid211 =0 if ben_pan_solid211 == 1 & red_12065==1 & urbano==1 // Recibe Red Opor, 120 a los 65
	
	****************************************************************************
	egen hh_ben_pan_solid211 = max(ben_pan_solid211), by(id) 
	****************************************************************************
	
	/*
	
	
	replace hh_empleado_gob = 0 if empleado_gob ==1	
	gen hh_empleado_gob_ = pondera if hh_empleado_gob == 1 & ben_pan_solid211 ==1  

    set seed 12345  
    
    * Assign random numbers to the observations and rank them from the smallest to the largest
    gen random_number = uniform() if hh_empleado_gob==1 & ben_pan_solid211 ==1 & urbano==1 // [GENERATES A RANDOM NUMBER BETWEEN 0 AND 1] 
	sort random_number
	gen random_number_aux = sum(hh_empleado_gob_)
	gen hh_empleado_gob_out = random_number_aux <=23000
	

	replace ben_pan_solid211 = 0 if hh_empleado_gob_out ==1
	
	*/
	
	
	gen empleado_gob = (posicion ==1) & ocupado==1 
	egen hh_empleado_gob = max(empleado_gob), by(id)
	
	gen ben_pan_solid212 = ben_pan_solid211
	replace ben_pan_solid212 = 0 if hh_empleado_gob ==1 
	****************************************************************************
	egen hh_ben_pan_solid212 = max(ben_pan_solid212), by(id) // hogares beneficiarios/por hogar version 2 todos los hogares con servidores publicos
    ****************************************************************************
	
		*---------- LABOR INCOME SCENARIOS			<-------------------------------


		*Income in 2020
		gen double ila_100_20 = ila
		replace ila_100_20 = 0 if shock_3 ==1 & employed20_1 == 0
		replace ila_100_20 = ila*0.814 if shock_3 ==1 & employed20_1 == 1 /*income losses for all others according EML2020 -18.6 mediana ingreso*/
		label var ila_100_20 "2020 Monthly labor - 100% lost for unemployed and 20% lower income"

		*Income in 2021
		gen double ila_100_21 = ila
		replace ila_100_21 = 0 if shock_3 ==1 & employed21 == 0
		replace ila_100_21 = ila*0.814 if shock_3 ==1 & employed21 == 1 & employed21 == 1 /*income losses for all others* that were unemployed before*/
		replace ila_100_21 = ila*0.814 if shock_3 ==1 & employed21 == 1 & employed21 == 0 /*income losses for all others* that were never unemployed but shocked*/

		label var ila_100_21 "2020 Monthly labor - 100% lost for unemployed and 10% lower income"

		*-------------4.2.1: INGRESOS INDIVIDUALES TOTALES ANUALES - SHOCK

		local lost 100_20 100_21

		foreach l of local lost {

					* Monetario
					egen ii_`l' = rsum( ila_`l'  inla ), missing	
					
					* Identifica perceptores de ingresos 
					gen       perii_`l' = 0
					replace   perii_`l' = 1		if  ii_`l'>0 & ii_`l'!=.
					
		*-------------4.2.2: INGRESOS FAMILIARES TOTALES	
		
					* Ingreso familiar total (antes de renta imputada)
					egen itf_sin_ri_`l' = sum(ii_`l')	if  hogarsec==0, by(id)
					
					* Ingreso familiar total - total
					egen    itf_`l' = rsum(itf_sin_ri_`l' renta_imp) 
					replace itf_`l' = .		if  itf_sin_ri_`l'==.
						
					* Ingreso familiar per capita 
					gen ipcf_`l'    = itf_`l'        / miembros
					
					label var ipcf_`l'  "IPCF - Lost:`l'%"

		}	// close lost

/*==================================================
			7: Incomes with PANAMA SOLIDARIO 
==================================================*/


			*------5.2.2: Assigment
			// NOTE -> receive transfer if they meet the conditions 

			cap gen pan_solid100_20 = 0
			replace pan_solid100_20 = 93 if ben_pan_solid20 ==1 
			replace pan_solid100_20 = 42.4 if ben_pan_solid20 ==1 & (urbano ==0 | comarcas==1) //precio de la bolsa marzo - agosto 15, septiembre - dic 25. dos bolsas al mes en areas rurales

			cap gen pan_solid100_21 = 0
			replace pan_solid100_21 = 120 if ben_pan_solid211 ==1 
			replace pan_solid100_21 = 61.5  if ben_pan_solid211 ==1 & (urbano ==0 | comarcas==1) //precio de la bolsa marzo - agosto 15, septiembre - dic 25. dos bolsas al mes en areas rurales
			

			

			local lost 100_20 100_21
			
					*----------5.1.1: NEW ANNUAL INCOME + PAN Solidario
					
			foreach l of local lost {

		*-------	-5.1.1.1: INGRESOS INDIVIDUALES TOTALES
					* Monetario
					egen ii_PS20_`l' = rsum( ila_`l' inla pan_solid`l'), missing
					
					* Identifica perceptores de ingresos 
					gen       perii_PS20_`l' = 0
					replace   perii_PS20_`l' = 1		if  ii_PS20_`l'>0 & ii_PS20_`l'!=.
					
						*panama solidario 
							gen       perii_pan_solid`l' = 0
							replace   perii_pan_solid`l' = 1		if  pan_solid`l'>0 & pan_solid`l'!=.
				
				
		*-------	-5.1.1.2: INGRESOS FAMILIARES TOTALES			
					* Ingreso familiar total (antes de renta imputada)
					egen itf_sin_ri_PS20_`l' = sum(ii_PS20_`l')	if  hogarsec==0, by(id)
					*panama solidario 
					egen itf_pan_solid`l' = sum(pan_solid`l')	if  hogarsec==0, by(id)
					
					* Ingreso familiar total - total
					egen    itf_PS20_`l' = rsum(itf_sin_ri_PS20_`l' renta_imp) 
					replace itf_PS20_`l' = .		if  itf_sin_ri_PS20_`l'==.
						
					* Ingreso familiar per capita 
					gen ipcf_PS20_`l'    = itf_PS20_`l'        / miembros
					
					label var ipcf_PS20_`l'  "IPCF + PAN Solidario condiciones - Lost:`l' "
					
					* panama solidario
					gen ipcf_pan_solid`l'    = itf_pan_solid`l'        / miembros
			
			
			}	// Close lost



			*------5.2.2: Alternative Assigment 1
			
			// NOTE -> receive transfer if they meet the conditions 

			cap gen pan_solid100_20_1 = 0
			replace pan_solid100_20_1 = 93 if ben_pan_solid20 ==1 
			replace pan_solid100_20_1 = 42.4  if ben_pan_solid20 ==1 & (urbano ==0 | comarcas==1) //precio de la bolsa marzo - agosto 15, septiembre - dic 25. dos bolsas al mes en areas rurales
			
			
			* solo cambiando programas sociales en 2021-1
			cap gen pan_solid100_21_1 = 0
			replace pan_solid100_21_1 = 120 if ben_pan_solid211 ==1 
			replace pan_solid100_21_1 = 61.5  if ben_pan_solid211 ==1 & (urbano ==0 | comarcas==1) //precio de la bolsa marzo - agosto 15, septiembre - dic 25. dos bolsas al mes en areas rurales
			
			
			

			local lost 100_20 100_21
			
					*----------5.1.1: NEW ANNUAL INCOME + PAN Solidario
					
			foreach l of local lost {

		*-------	-5.1.1.1: INGRESOS INDIVIDUALES TOTALES
					* Monetario
					egen ii_PS20_`l'_1 = rsum( ila_`l' inla pan_solid`l'_1), missing
					
					* Identifica perceptores de ingresos 
					gen       perii_PS20_`l'_1 = 0
					replace   perii_PS20_`l'_1 = 1		if  ii_PS20_`l'_1 >0 & ii_PS20_`l'_1 !=.
					
						*panama solidario 
							gen       perii_pan_solid`l'_1 = 0
							replace   perii_pan_solid`l'_1 = 1		if  pan_solid`l'_1 >0 & pan_solid`l'_1 !=.
				
				
		*-------	-5.1.1.2: INGRESOS FAMILIARES TOTALES			
					* Ingreso familiar total (antes de renta imputada)
					egen itf_sin_ri_PS20_`l'_1 = sum(ii_PS20_`l'_1)	if  hogarsec==0, by(id)
					*panama solidario 
					egen itf_pan_solid`l'_1 = sum(pan_solid`l'_1)	if  hogarsec==0, by(id)
					
					* Ingreso familiar total - total
					egen    itf_PS20_`l'_1 = rsum(itf_sin_ri_PS20_`l'_1 renta_imp) 
					replace itf_PS20_`l'_1 = .		if  itf_sin_ri_PS20_`l'_1 ==.
						
					* Ingreso familiar per capita 
					gen ipcf_PS20_`l'_1    = itf_PS20_`l'_1        / miembros
					
					label var ipcf_PS20_`l'_1  "IPCF + PAN Solidario condiciones - Lost:`l' "
					
					* panama solidario
					gen ipcf_pan_solid`l'_1    = itf_pan_solid`l'_1        / miembros
			
			
			}	// Close lost



		*------5.2.2: ALTERNATIVE Assigment 2
		// NOTE -> receive transfer if they meet the conditions in urban / and only if they are the HH head in Rural
		 
		 
		cap gen pan_solid_1_100_20 = 0
		replace pan_solid_1_100_20 = 93 if ben_pan_solid20 ==1 & urbano ==1 
		replace pan_solid_1_100_20 = 42.4  if ben_pan_solid20 ==1 & (urbano ==0 | comarcas==1) & com == 1 //*Only 1 transfer in rural households  //precio de la bolsa marzo - agosto 15, septiembre - dic 25. dos bolsas al mes en areas rurales */ 

		cap gen pan_solid_1_100_21 = 0
		replace pan_solid_1_100_21 = 120 if ben_pan_solid211 ==1 & urbano ==1 
		replace pan_solid_1_100_21 = 61.5  if ben_pan_solid211 ==1 & (urbano ==0 | comarcas==1) & com == 1 //precio de la bolsa marzo - agosto 15, septiembre - dic 25. dos bolsas al mes en areas rurales 
		 
		local lost 100_20 100_21
		foreach l of local lost {

*----------5.1.1: NEW ANNUAL INCOME + PAN Solidario


*-------	-5.1.1.1: INGRESOS INDIVIDUALES TOTALES
			* Monetario
			egen ii_PS1_1_`l' = rsum( ila_`l' inla pan_solid_1_`l'), missing
			
			
			* Identifica perceptores de ingresos 
				*totales 
				gen       perii_PS1_1_`l' = 0
				replace   perii_PS1_1_`l' = 1		if  ii_PS1_1_`l'>0 & ii_PS1_1_`l'!=.
				* panama solidario
				gen       perii_pan_solid_1_`l' = 0
				replace   perii_pan_solid_1_`l' = 1		if  pan_solid_1_`l'>0 & pan_solid_1_`l'!=.
		
		
*-------	-5.1.1.2: INGRESOS FAMILIARES TOTALES			
			* Ingreso familiar total (antes de renta imputada)
				egen itf_sin_ri_PS1_1_`l' = sum(ii_PS1_1_`l')	if  hogarsec==0, by(id)
				
			* ingreso familiar panama solidario
				egen itf_pan_solid_1_`l' = sum(pan_solid_1_`l')	if  hogarsec==0, by(id)
			
			
			* Ingreso familiar total - total
				egen    itf_PS1_1_`l' = rsum(itf_sin_ri_PS1_1_`l' renta_imp) 
				replace itf_PS1_1_`l' = .		if  itf_sin_ri_PS1_1_`l'==.
				
				
			* Ingreso familiar per capita 
				gen ipcf_PS1_1_`l'    = itf_PS1_1_`l'        / miembros
				
				label var ipcf_PS1_1_`l'  "zonas rurales hogarizadas - Lost:`l' "
				* panama solidario
				gen ipcf_pan_solid_1_`l'    = itf_pan_solid_1_`l'        / miembros
				
				
}	// Close lost



		*------5.2.2: ALTERNATIVE Assigment 3
		// NOTE -> receive transfer if they meet the conditions in urban / and only if they are the HH head in Rural
		 * just counting those who were excluded form the program for being beneficieries of other social programs
		tab ben_pan_solid20 [w=pondera] if urbano==0
		
		
		cap gen pan_solid_1_100_20_1 = 0
		replace pan_solid_1_100_20_1 = 93    if ben_pan_solid20 ==1 & urbano ==1 
		replace pan_solid_1_100_20_1 = 42.4  if hh_ben_pan_solid20_1 ==1 & (urbano ==0 | comarcas==1) & com == 1 //*Only 1 transfer in rural households  //precio de la bolsa marzo - agosto 15, septiembre - dic 25. dos bolsas al mes en areas rurales */ 
		 
		 
		cap gen pan_solid_1_100_21_1 = 0
		replace pan_solid_1_100_21_1 = 120  if ben_pan_solid211 ==1 & urbano ==1 
		replace pan_solid_1_100_21_1 = 61.5 if ben_pan_solid211 ==1 & (urbano ==0 | comarcas==1) & com == 1 //precio de la bolsa marzo - agosto 15, septiembre - dic 25. dos bolsas al mes en areas rurales 
		 
		local lost 100_20 100_21
		foreach l of local lost {

*----------5.1.1: NEW ANNUAL INCOME + PAN Solidario


*-------	-5.1.1.1: INGRESOS INDIVIDUALES TOTALES
			* Monetario
			egen ii_PS1_1_`l'_1 = rsum( ila_`l' inla pan_solid_1_`l'_1), missing
			
			
			* Identifica perceptores de ingresos 
				*totales 
				gen       perii_PS1_1_`l'_1 = 0
				replace   perii_PS1_1_`l'_1 = 1		if  ii_PS1_1_`l'_1 >0 & ii_PS1_1_`l'_1 !=.
				* panama solidario
				gen       perii_pan_solid_1_`l'_1 = 0
				replace   perii_pan_solid_1_`l'_1 = 1		if  pan_solid_1_`l'_1 >0 & pan_solid_1_`l'_1 !=.
		
		
*-------	-5.1.1.2: INGRESOS FAMILIARES TOTALES			
			* Ingreso familiar total (antes de renta imputada)
				egen itf_sin_ri_PS1_1_`l'_1 = sum(ii_PS1_1_`l'_1)	if  hogarsec==0, by(id)
				
			* ingreso familiar panama solidario
				egen itf_pan_solid_1_`l'_1 = sum(pan_solid_1_`l'_1)	if  hogarsec==0, by(id)
			
			
			* Ingreso familiar total - total
				egen    itf_PS1_1_`l'_1 = rsum(itf_sin_ri_PS1_1_`l'_1 renta_imp) 
				replace itf_PS1_1_`l'_1 = .		if  itf_sin_ri_PS1_1_`l'_1 ==.
				
				
			* Ingreso familiar per capita 
				gen ipcf_PS1_1_`l'_1    = itf_PS1_1_`l'_1        / miembros
				
				label var ipcf_PS1_1_`l'_1  "zonas rurales hogarizadas - Lost:`l' "
				* panama solidario
				gen ipcf_pan_solid_1_`l'_1    = itf_pan_solid_1_`l'_1      / miembros
				
				
}	// Close lost

		*------5.2.2: ALTERNATIVE Assigment 4
		// NOTE -> receive transfer if they meet the conditions in urban / and only if they are the HH head in Rural
		 * just counting those who were excluded form the program for being beneficieries of other social programs
		 * excluding beneficiaries who live with a public servent 				
		
		cap gen pan_solid_1_100_20_2 = 0
		replace pan_solid_1_100_20_2 = 93    if ben_pan_solid20 ==1 & urbano ==1 
		replace pan_solid_1_100_20_2 = 42.4  if hh_ben_pan_solid20_1 ==1 & (urbano ==0 | comarcas==1) & com == 1 //*Only 1 transfer in rural households  //precio de la bolsa marzo - agosto 15, septiembre - dic 25. dos bolsas al mes en areas rurales */ 
		 
		 
		cap gen pan_solid_1_100_21_2 = 0
		replace pan_solid_1_100_21_2 = 120   if ben_pan_solid212 ==1 & urbano ==1 
		replace pan_solid_1_100_21_2 = 61.5  if hh_ben_pan_solid212 ==1 & (urbano ==0 | comarcas==1) & com == 1 //precio de la bolsa marzo - agosto 15, septiembre - dic 25. dos bolsas al mes en areas rurales 
		 
		local lost 100_20 100_21
		foreach l of local lost {

*----------5.1.1: NEW ANNUAL INCOME + PAN Solidario


*-------	-5.1.1.1: INGRESOS INDIVIDUALES TOTALES
			* Monetario
			egen ii_PS1_1_`l'_2 = rsum( ila_`l' inla pan_solid_1_`l'_2), missing
			
			
			* Identifica perceptores de ingresos 
				*totales 
				gen       perii_PS1_1_`l'_2 = 0
				replace   perii_PS1_1_`l'_2 = 1		if  ii_PS1_1_`l'_2 >0 & ii_PS1_1_`l'_2 !=.
				* panama solidario
				gen       perii_pan_solid_1_`l'_2 = 0
				replace   perii_pan_solid_1_`l'_2 = 1		if  pan_solid_1_`l'_2 >0 & pan_solid_1_`l'_2 !=.
		
		
*-------	-5.1.1.2: INGRESOS FAMILIARES TOTALES			
			* Ingreso familiar total (antes de renta imputada)
				egen itf_sin_ri_PS1_1_`l'_2 = sum(ii_PS1_1_`l'_2)	if  hogarsec==0, by(id)
				
			* ingreso familiar panama solidario
				egen itf_pan_solid_1_`l'_2 = sum(pan_solid_1_`l'_2)	if  hogarsec==0, by(id)
			
			
			* Ingreso familiar total - total
				egen    itf_PS1_1_`l'_2 = rsum(itf_sin_ri_PS1_1_`l'_2 renta_imp) 
				replace itf_PS1_1_`l'_2 = .		if  itf_sin_ri_PS1_1_`l'_2 ==.
				
				
			* Ingreso familiar per capita 
				gen ipcf_PS1_1_`l'_2    = itf_PS1_1_`l'_2        / miembros
				
				label var ipcf_PS1_1_`l'_2  "zonas rurales hogarizadas sin hogares de funcionarios - Lost:`l' "
				* panama solidario
				gen ipcf_pan_solid_1_`l'_2    = itf_pan_solid_1_`l'_2      / miembros
				
				
}	// Close lost
*tab rama_a hombre [w=pondera] if pea==1 & ocupado ==1 & edad>=15,m



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
local lost 100_20 100_21
	
foreach l of local lost {
    
	local income  ipcf ipcf_`l' ipcf_PS20_`l' ipcf_PS1_1_`l' ipcf_PS1_1_`l'_1 ipcf_PS1_1_`l'_2
	
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
	local pls 190 320 550 1300 7000
	
	foreach pl of local pls {
		local pl1 = `pl'/100
		cap gen double lp_`pl'_ppp = `pl1'*(`days')
		
	}
	
*----------5.3: Poverty impact 


	local incomes  ipcf_ppp ipcf_ppp11_20_sin_covid ipcf_`l'_ppp ipcf_PS20_`l'_ppp ipcf_PS1_1_`l'_ppp ipcf_PS1_1_`l'_1_ppp  ipcf_PS1_1_`l'_2_ppp 		// <------------- 	INCOMES POVERTY CALCUL!
	local bono = 0 
	local caracteristicas total urbano_ rural_ comarcas provincias indig Cocle Colon Chiriqui Darien Herrera Los_Santos Panama Veraguas Comarca_Kuna_Yala Comarca_Embera Comarca_Ngobe_Bugle Panama_Oeste Bocas_del_Toro 
	
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
				apoverty `inc' [w=pondera] if `carac'==1, varpl(lp_`pl'_ppp) 
				local value = `r(head_1)' 
							
				*--			
				cap sum poor_`l'_`pl'_`bono' [w=pondera] if `carac'==1
				local poor = `r(sum_w)'
				
				post `pname' (2019) ("poverty") (`pl') ("`carac'") ("`inc'") ("`l'") (`value') (`poor')

		} // close lp
		
				* GINI
				
				ineqdeco `inc' [w=pondera] if `carac'==1
				local value= `r(gini)'
				local poor= `r(sumw)'
				
				post `pname' (2019) ("gini") (.) ("`carac'") ("`inc'") ("`l'") (`value') (`poor')
							
						
		}	// Close characteristica
	}	// close incomes
}	// Close lost


postclose `pname'
use `pfile', clear
format value %15.2fc

export excel using "C:\Users\WB585318\OneDrive - Universidad de los Andes\WB\Panama\output\impact_no_ps.xlsx", sh("Results_conRamas_21calibrado2", replace)  firstrow(var)


cap restore
	

save "${path}/interdata/peb_202107_impact_ramas_21calibrado.dta", replace

exit 