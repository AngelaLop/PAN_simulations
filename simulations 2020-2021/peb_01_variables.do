
/* 	=======================================================================================
	Project:            PANAMA 2022 Simulations 
	Author:             Angela Lopez with inputs of Javier Romero and Kiyomi Cadena
	Organization:       The World Bank-ELCPV
	---------------------------------------------------------------------------------------
	Creation Date:       March 10, 2021
	Note:				 Starts from 2019 EML data
	======================================================================================= */

	
	global path "C:\Users\WB585318\WBG\Javier Romero - Panama"	
	global input "$path\Covid\microsimulations\inputs"
	global output "$path\Covid\microsimulations\results"
	global data_m "$path\Covid\microsimulations\inputs\excel"


/*===============================================================================================
                                  0. Program set up
===============================================================================================*/

clear all
drop _all	
	

tempfile g_pop g_pcons 

/*===============================================================================================
							A. Add  macro projections 
===============================================================================================*/

	*-------------1.1 Population WDI --------------------
    import excel using "${input}/Excel/pop_MPO.xlsx", firstrow clear
	replace country=lower(country)
	
		* Compute total population
		foreach y in 2019 2020 2021 2022 2023 2024 { 
			replace y`y'=y`y'*1000000
		}
	
	keep  country y2019 y2020 y2021 y2022 
	save `g_pop', replace 
	
	*-------------1.2 Baseline/Downside Private Consumption per-capita--------------------
	import excel using "${input}/Excel/baseline_pc.xlsx", firstrow clear         // private consum per-capita
	replace country=lower(country)

	destring y*, replace 
	replace country=lower(country)
	keep country y2019 y2020 y2021 y2022 
	save `g_pcons', replace 


/*===============================================================================================
							B. Using SEDLAC Dataset and adjusting pondera
===============================================================================================*/	
	

	
	use  "${path}\data\datalibweb\pan_2019_eh_v01_m_v01_a_sedlac-03_all", clear
	duplicates report id com /*is id*/
	
	
	gen country="pan"
	cap keep if hogarsec ==0
	cap drop _merge factor_aj 
	
		*----------------Population INEC projections
	merge m:1 country using `g_pop'
	drop if _merge!=3                                                
	drop _merge
	
	*----------------Private Consumption Per-capita
	merge m:1 country using `g_pcons', 
	drop if _merge!=3
	drop _merge
	
	* adjust pondera
	bysort country: egen pop_pondera=total(pondera) // total de poblacion en 2019
	
	gen pondera_19=pondera
	
	*Just for looping reasons create replicates of pondera_2020
	gen pondera_20=pondera_19*(y2020/pop_pondera) 
	gen pondera_21=pondera_19*(y2021/pop_pondera)
	gen pondera_22=pondera_19*(y2022/pop_pondera)
	gen pondera_23=pondera_19*(y2023/pop_pondera)
	gen pondera_24=pondera_19*(y2024/pop_pondera)
	gen pondera_25=pondera_19*(y2025/pop_pondera)

	save "${input}/mdat/temp.dta", replace 
	
	
*-----------------------2 Define Controls and variables  ----------------------------------	
	
	
	
	*Ind and hh counter
	g total =1
	
	*gen hhhead_count = 1 if relacion == 1
	gen mujer = (hombre==0)
	
	* PET >18 calificada 
	g calificado = inlist(nivel,3,4,5,6) & edad>=18
	g no_calificado  = inlist(nivel,0,1,2) & edad>=18
	
	* nivel educativo 
	g e_primaria = inlist(nivel,0,1,2,3)  
	g e_secundaria  = inlist(nivel,4,5) 
	g e_terciaria  = inlist(nivel,6)  
	
	* nivel educativo jefe hogar
	g nivel_e = 1 if e_primaria ==1 & jefe==1
	replace nivel_e = 2 if e_secundaria ==1 & jefe==1
	replace nivel_e = 3 if e_terciaria ==1 & jefe==1
 
	* nivel educativo jefe_h
	egen jh_nivel_e = max(nivel_e) , by(id) 
	g jh_e_primaria   = jh_nivel_e==1
	g jh_e_secundaria = jh_nivel_e==2
	g jh_e_terciaria  = jh_nivel_e==3 
		
	*informalidad
	g formal = (categ_lab==1)
	g informal = (categ_lab==2)

	*rama agregada
	cap gen rama_a =1 if inlist(rama,1)  // Agricultura
	replace rama_a =2 if inlist(rama,3) // industria  	
	replace rama_a =3 if inlist(rama,2,4,5) // otras 	
	replace rama_a =4 if inlist(rama,6) // Construcción
	replace rama_a =5 if inlist(rama,7) // Comercio
	replace rama_a =6 if inlist(rama,8) // Transporte
	replace rama_a =7 if inlist(rama,9) // hotles restaur
	replace rama_a =8 if inlist(rama,13,14,16,17,19,18,21,20) // Servicios comunales, sociales y personales
	replace rama_a =9 if inlist(rama,15) //Adm. Pública y Defensa
	replace rama_a =10 if inlist(rama,10,11,12) //financieras, inmobiliarias y de comunicacion
	
	*rama agregada sectores
	cap gen rama_sec =1 if inlist(rama,1)  // Agricultura
	replace rama_sec =2 if inlist(rama,2,3,4,5,6) // industria  	
	replace rama_sec =3 if rama > 6 // servicios  	
	
	cap gen rama_s =1 if inlist(rama,1)  // Agricultura
	replace rama_s =2 if inlist(rama,2,3,4,5,6) // industria  		
	replace rama_s =3 if inlist(rama,7) // comercio
	replace rama_s =4 if rama>7 // servicios
	
	gen agricultura = (rama_s==1)
	gen industria = (rama_s==2)
	gen comercio  = (rama_s==3)
	gen servicios = (rama_s==4)
	* posicion ocupacional 
	
	gen posicion=p33
	replace posicion = 2 if inlist(posicion,2,3,4,9)
		label var posicion "Posicion ocupacional"
		label define grupos_p ///
		1 "Empleado(a) del Gobierno" ///
		2 "Empleado(a) empersa priv" ///
		5 "Empleado(a) servicio domestico"  ///
		7 "Indep. Por cuenta propia" ///
		8 "Indep. Patrono(a) dueño(a)" ///
		9 "Miembro de una cooperativa de producción"  ///
		10 "Trabajador(a) familiar" , replace 
		label values posicion grupos_p	
	
	*ocupaciones 
	
* ocupacion 
	destring  p28reco, g(ocupacion)
	
	gen independiente = 0 if ocupado==1
	replace independiente = 1 if inlist(posicion,7,8) & ocupado==1
	
	gen asalariado_nogob = 0 if ocupado==1
	replace asalariado_nogob = 1 if inlist(posicion,2,5,9) & ocupado==1
	
	gen directores 		= (ocupacion==1) & ocupado==1 //Directores y gerentes de los sectores público, privado y de organizaciones de interés social
	gen profecionales 	= (ocupacion==2) & ocupado==1 //Profesionales, científicos e intelectuales
	gen tecnicos 		= (ocupacion==3) & ocupado==1 //Técnicos y profesionales de nivel medio
	gen empleados_of 	= (ocupacion==4) & ocupado==1 //Empleados de oficina
	gen trabajadores_serv = (ocupacion==5) & ocupado==1 //Trabajadores de los servicios y vendedores de comercios y mercados
	gen agricultores 	= (ocupacion==6) & ocupado==1 //Agricultores y trabajadores agropecuarios, forestales, de la pesca y caza
	gen artesanos		= (ocupacion==7) & ocupado==1 // Artesanos y trabajadores de la minería, la construcción, la industria manufacturera, la mecánica y ocupaciones afines
	gen operadores 		= (ocupacion==8) & ocupado==1 // Operadores de instalaciones fijas y máquinas; ensambladores, conductores y operadores de maquinarias móviles
	gen trabajadores_no_calif = (ocupacion==9) & ocupado==1 //Trabajadores no calificados de los servicios, la minería, construcción, industria manufacturera, transporte y otras ocupaciones elementales
	
	g cuenta_propia = (posicion==7) if ocupado==1
	g cuenta_propia_micro = cuenta_propia if empresa==2
	
	* ocupados exuyendo ocupaciones agricultura, profecionales y tecnicos cuenta propia o patronos
	g ocupados_no_prof = ocupado ==1
	replace ocupados_no_prof = 0 if inlist(posicion,7,8) & (directores==1 | profecionales==1)	
	
	* informalidad
	g informal2 =0 if ocupado ==1
	replace informal2 =1 if p4==6 & ocupado ==1	
	replace informal2 =1 if inlist(p35,1,2,4) | inlist(p36,2,3) | p38 ==1	
	
	*area 
	g urbano_ =  (urbano==1)
	g rural_=	(urbano==0)
	
	* regiones
	encode region_est2, g(region)
	
	g Bocas_del_Toro 	= (region==1)
	g Cocle 			= (region==2)
	g Colon 			= (region==3)
	g Chiriqui 			= (region==4)
	g Darien 			= (region==5)
	g Herrera 			= (region==6)
	g Los_Santos		= (region==7)
	g Panama 			= (region==8)
	g Veraguas 			= (region==9)
	g Comarca_Kuna_Yala = (region==10)
	g Comarca_Embera 	= (region==11)
	g Comarca_Ngobe_Bugle = (region==12)
	g Panama_Oeste 		= (region==13)
	
	g comarcas = inlist(region,10,11,12)
	g provincias = (comarcas==0)
	
	
	*Bottom 40 and income distribution
	xtile  ipcf_Q5 = ipcf [fw=pondera] ,  nquantiles(5)
	tab ipcf_Q5, miss
	gen bottom40 = (ipcf_Q5 == 1 | ipcf_Q5 == 2)
	tab ipcf_Q5, gen(ipcf_Q5_q)
	replace bottom40 = . if missing(ipcf_Q5)
	
	pctile ipcf_Q5_cuts = ipcf [fw=pondera] , nquantiles(5)
	
	tab ipcf_Q5	[w=pondera], miss
	

		
	*Age:
		
	tab edad, miss
	gen edad_grp_65plus = (edad>=65)
		

// Indigenous
	tab p4d_indige [w=pondera]
	tab indi_rec [w=pondera]

	tab p4d_indige indi_rec [w=pondera]
	destring p4d_indige, gen(p4d_indige_n)

	gen indig = (p4d_indige_n!=11)
	replace indig = . if p4d_indige_n==.
	

// Afro-decendants
	tab p4f_afrod [w=pondera]

	destring p4f_afrod, gen(p4f_afrod_n)

	gen afrod = (p4f_afrod_n!=8)
	replace afrod = . if p4f_afrod_n==.

*Red Oportunidades / 120 a los 65 
*	gen red_12065=0
*	replace red_12065 = 1 if p56_g1>0 & p56_g1!=.  // Red Oportunidades
*	replace red_12065 = 1 if p56_g5>0 & p56_g5!=.

	
	gen red = 0
	replace red = 1 if p56_g1 > 0 & !missing(p56_g1)
	gen pen12065 = 0
	replace pen12065 = 1 if p56_g5 > 0 & !missing(p56_g5)
	gen angel = 0
	replace angel = 1 if p56_g6 > 0 & !missing(p56_g6)
	
	gen ben_main_cct = 0
	replace ben_main_cct = 1 if red == 1 | pen12065 == 1 | angel == 1
	tab ben_main_cct [w=pondera]
	
	egen hh_main_cct = max(ben_main_cct), by(id) /*household benefits from main cash transfers*/
	
*Labor HHs
	
	gen agro = (sector1d==1) 
	replace agro = . if missing(sector1d)
	
	egen hh_agro = max(agro), by(id)
	
* 	Lugar de trabajo 
	clonevar lugar_tr = p29
	
* 	display length(p28)
	gen ocup_2d_str = substr(p28, 1, 2)

	destring ocup_2d_str, gen(ocup_2d)

	
	
*-----------------------1 Affected population  ----------------------------------
* 2020 based on 2019	
* Afectación de la ocupacion de acuerdo con EML2019-2020
* Variacion de la ocupacion 2019 - 2020: 329 mil ocupados (17.7%)

	cap drop shock_3
	g shock_3=1 if ocupado==1
	*excluding 
	*by sector and ocupation 
	replace shock_3= 0 if rama==1 & ocupado ==1 & inlist(ocupacion,2,3,4)	// agriculture professionals 
	replace shock_3= 0 if rama==15 & ocupado ==1 // Administración pública y defensa sale by definition
	replace shock_3= 0 if rama==7 & inlist(ocupacion,1,2,3) & ocupado ==1 // Trade - professionals 
	replace shock_3= 0 if inlist(rama,13,14,16,17,19,18,21,20) & inlist(ocupacion,2) & ocupado ==1
	replace shock_3= 0 if rama==8 & inlist(ocupacion,2,3) & ocupado ==1 // transportantion - professionals technitians
	replace shock_3= 0 if inlist(rama,10,11,12) & inlist(ocupacion,5) & ocupado ==1 // actividades financieras - trabajadores de los serviciso 				
	replace shock_3= 0 if rama==3 & inlist(ocupacion,1,4,5,7) & ocupado ==1 // industry 
	replace shock_3= 0 if inlist(rama,2,4,5) & ocupado ==1	// other sectors 
	* by work place 
	replace shock_3=0 if inlist(lugar_tr,2,3) // en casa 
	

	label var shock_3 "Affected sectors and occupations"
	label define shock_3_en 0 "Not affected" 1 "Affected", replace
	label values shock_3 shock_3_en


*----------------------------------------------------------------------------------------------------------------
*-----------------------2 Probit model for ocupation ---------------------------------

*controls

gen nro_hijos_nomiss = nro_hijos
replace nro_hijos_nomiss = 0 if missing(nro_hijos)

gen ocup_2d_nomiss = ocup_2d
replace ocup_2d_nomiss = 0 if missing(ocup_2d)

display length( p30)
gen sect_2d_str = substr(p30, 1, 2)

destring sect_2d_str, gen(sect_2d)
tab sect_2d pea, miss

gen p29_nomiss = p29
replace p29_nomiss = 0 if missing(p29)

gen sect_2d_nomiss = sect_2d
replace sect_2d_nomiss = 0 if  missing(sect_2d)

* probit -----------------------------------------------------------------------------------------


global controlsi "i.edad i.relacion i.hombre i.nro_hijos_nomiss i.urbano i.aedu i.p29_nomiss  i.ocup_2d_nomiss i.sect_2d_nomiss"
probit ocupado $controlsi [fw=pondera_19] if pea== 1
predict ocupa_Fx if pea ==1,  asif

		
*save "${path}\Covid\interdata\Nov2021\variables_conagri.dta", replace		



*-----------------------3 Income simulations ---------------------------------

*use "${path}\Covid\interdata\Nov2021\variables_conagri.dta", clear




*proyecting 2020 without covid

		global privconsum_20 = 3.0 /*private consumption growth average 2017-2019*/
		gen ipcf_ppp11_20_sin_covid = ipcf_ppp11*(1 + ${privconsum_20}/100)
	
			
			
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
		local sexs hombre mujer 
		local ramas agricultura industria comercio servicios 
		
		gen employed20_aux = sum(people_active_) if hombre==1 & rama_s ==1 & pea==1 // Agricultura
		
		foreach sex of global sexs {
			foreach rama of local ramas {
				replace employed20_aux = sum(people_active_) if `sex'==1 & `rama' ==1 & pea==1 
			}
		}
		
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
			
				
		
			*2021 // EML 2021 publicada INEC 
			
			
		*hombres 
				gen employed21 = (employed20_aux<=212002) if hombre==1 & rama_s ==1 & pea==1 // Agricultura	
			replace employed21 = (employed20_aux<=226578) if hombre==1 & rama_s ==2 & pea==1 // Industria
			replace employed21 = (employed20_aux<=169120) if hombre==1 & rama_s ==3 & pea==1 // Comercio
			replace employed21 = (employed20_aux<=431385) if hombre==1 & rama_s ==4 & pea==1 // Servicios		
			
		*mujeres 
			replace employed21 = (employed20_aux<=61137)  if hombre==0 & rama_s ==1 & pea==1 // Agricultura	
			replace employed21 = (employed20_aux<=67112)  if hombre==0 & rama_s ==2 & pea==1 // Industria
			replace employed21 = (employed20_aux<=144248) if hombre==0 & rama_s ==3 & pea==1 // Comercio
			replace employed21 = (employed20_aux<=432805) if hombre==0 & rama_s ==4 & pea==1 // Servicios
			
	
			
*-----------------------2 Mitigation measures  ----------------------------------	


	di in red "PANAMA SOLIDARIO: PERSONAS 2020 condiciones antes de shock (PS2020)"

	*------5.4.1: generate variable 

	gen ben_pan_solid20 = 0
	replace ben_pan_solid20 = (edad >=18)

	// Exclusions:

	replace ben_pan_solid20 = 0 if ben_pan_solid20 == 1 & ila>917 & ila!=. // Ingreso laboral anual superior $11.000 / Mensual superior a $917
	replace ben_pan_solid20 = 0 if ben_pan_solid20 == 1 & asalariado_nogob==1 & formal==1 & urbano==1
	replace ben_pan_solid20 = 0 if ben_pan_solid20 == 1 & ijubi>0 & ijubi!=.  // Recibe jubilación o pensión
	replace ben_pan_solid20 = 0 if ben_pan_solid20 == 1 & posicion==1 & ocupado==1 // Empleados del gobierno (0 real changes made)
	egen hh_ben_pan_solid20 = max(ben_pan_solid20), by(id)
	replace ben_pan_solid20 = 1 if hh_ben_pan_solid20 ==1 & urbano==0 & jefe==1 & ben_pan_solid20 ==0 // un beneficiario por hogares rurales 
	replace ben_pan_solid20 = 0 if hh_ben_pan_solid20 ==1 & urbano==0 & jefe==0 & ben_pan_solid20 ==1

			
	di in red "PANAMA SOLIDARIO: PERSONAS 2020 condiciones luego de shock (PS2020)"
		
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
	
	replace ben_pan_solid211 = 0 if employed20_1==0 & employed21 ==1 & ben_pan_solid211 == 1 & urbano==1
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




