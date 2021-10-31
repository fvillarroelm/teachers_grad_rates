clear all
set more off

*Directorios
global main "C:/Users/fvillarroel/Downloads/pega/udla/proyectos/teachers_grad_rates"
global tables "${main}/tables"
global graphs "${main}/graphs"
global raw "${main}/data/raw"
global proc "${main}/data/proc"

*directorio
cd $main

/*
Loop:
1) merge entre matrícula 4m con matrícula ed. sup., simce, NEM y pctil NEM, y agno titulación.
2) construcción de variables para análisis.
*/

local agno_4m = 2010
local agno_sup = 2011
local s simce2m2008 simce8b2007 simce2m2010 simce8b2009

foreach simce of local s{


	use "${proc}/matriculaIV_escolar_`agno_4m'.dta", clear


	***Merges:
		*Unión matrícula escolar y superior
		merge 1:1 mrun using "${proc}/matricula_superior_`agno_sup'_edited.dta"

		*drop merge from using
		drop if _merge==2
		
		*Variable entra_ES
		gen 	entra_ES = 0 if _merge==1 /*non-match from master*/
		replace entra_ES = 1 if _merge==3 /*match mrun escolar y ES*/
		drop	_merge


		destring cod_carrera, replace
		*se van pocas obs (<0.5%)
		drop if cod_carrera==. & entra_ES==1


		*Unión alu+cpad SIMCE
		merge 1:1 mrun using "${proc}/`simce'_alu_nse.dta", keepusing(ptje_lect* ptje_mate* educ_madre educ_padre ingreso nse_index p_nse d_nse q_nse)
		
		*keep if matches
		keep if _merge == 3
		drop 	_merge
		
		
		*Unión NEM y percentil NEM dentro del colegio
		merge 1:1 mrun rbd joven agno_4m using "${proc}/nem_pctiles_jovenesYadultos_`agno_4m'.dta"
		
		*keep if matches
		keep if _merge == 3
		drop 	_merge

		
		*Unión agno titulación ed. sup.
		forvalues x = `agno_sup'(1)2019{
				merge 1:1 mrun cod_inst cod_carrera using "${proc}/titulados_`x'_edited.dta"

				* drop not matched from using.
				drop if _merge==2

				* dummy año titulación
				gen 	titulado_`x' = . /*mv para quienes no entran a ES*/
				replace titulado_`x' = 0 if _merge==1 & entra_ES==1 /*no titulados y participantes de ES*/
				replace titulado_`x' = 1 if _merge==3 & entra_ES==1 /*titulados y participantes de ES*/
				drop 	_merge
			}
			
			
		


	***Variables construction

		*duracion_total_anios (carrera)
		gen 	duracion_total_anios=.
		replace duracion_total_anios = round(dur_total_carr/2) /*redondeo es hacia arriba. 2,5 es 3*/


		*anio_esperado_titulacion
		gen agno_esperado_titulacion = agno_ES + duracion_total_anios - 1 /*se le resta 1: si entro el 2011 a carrera de 2.5 años, debiese titularme el año 2013 (2011+3-1)*/
		
		
		*agno_titulacion: entrega el mínimo agno_titulacion para las pocas observaciones tituladas > 1 vez.
		gen agno_titulacion=.
		forvalues x = 2019(-1)`agno_sup'{
			replace agno_titulacion=`x' if titulado_`x'==1
			}

					
		*var auxiliar: dummy titulado
		egen aux_titulado = rowtotal(titulado_*) if entra_ES == 1 /*es mv si entra_ES==0*/
		*hay muy pocas personas (<100 obs) que se titularon >1 vez de la misma carrera e institución.
		table aux_titulado
		*Se considera que es un error y que realmente se titulan una vez.
		replace aux_titulado = 1 if aux_titulado > 1 & entra_ES == 1
		
		
		*dummy titulado: se considera titulado hasta 3 años post año esperado titulación
		gen 	titulado = .
		replace titulado = 0 if (entra_ES == 1) & ((agno_titulacion - agno_esperado_titulacion >3) | (aux_titulado == 0))
		replace titulado = 1 if (entra_ES == 1) & (agno_titulacion - agno_esperado_titulacion <= 3) & (aux_titulado == 1)
		
		
		*drop vars no utilizadas
		drop aux_titulado titulado_*

		
		*titulado oportuno
		gen 	titulado_oportuno = .
		replace titulado_oportuno = 0 if (agno_esperado_titulacion != agno_titulacion) & (entra_ES == 1)
		replace titulado_oportuno = 1 if ((agno_esperado_titulacion == agno_titulacion) | (agno_esperado_titulacion + 1 == agno_titulacion)) & (entra_ES == 1)
		
		
		*dummy mujer
		gen 	d_mujer_alu = .
		replace d_mujer_alu = gen_alu - 1

		
		*regiones
		gen 	cod_reg_inst = .
		replace cod_reg_inst = 1  if region_sede == "TarapacÃ¡"
		replace cod_reg_inst = 2  if region_sede == "Antofagasta"
		replace cod_reg_inst = 3  if region_sede == "Atacama"
		replace cod_reg_inst = 4  if region_sede == "Coquimbo"
		replace cod_reg_inst = 5  if region_sede == "ValparaÃ­so"
		replace cod_reg_inst = 6  if region_sede == "Lib. Gral B. O'Higgins"
		replace cod_reg_inst = 7  if region_sede == "Maule"
		replace cod_reg_inst = 8  if region_sede == "BiobÃ­o"
		replace cod_reg_inst = 9  if region_sede == "La AraucanÃ­a"
		replace cod_reg_inst = 10 if region_sede == "Los Lagos"
		replace cod_reg_inst = 11 if region_sede == "AysÃ©n"
		replace cod_reg_inst = 12 if region_sede == "Magallanes"
		replace cod_reg_inst = 13 if region_sede == "Metropolitana"
		replace cod_reg_inst = 14 if region_sede == "Los RÃ­os"
		replace cod_reg_inst = 15 if region_sede == "Arica y Parinacota"

		
		*dummy sede RM
		gen 	d_sede_RM = .
		replace d_sede_RM = 0 if cod_reg_inst != 13
		replace d_sede_RM = 1 if cod_reg_inst == 13
		
		
		*dummy estudia en región distinta a la de residencia.
		gen 	d_estudia_otra_region = .
		replace d_estudia_otra_region = 0 if cod_reg_alu == cod_reg_inst
		replace d_estudia_otra_region = 1 if cod_reg_alu != cod_reg_inst
		
		
		*rango duracion*
		replace rango_duracion = "3 o menos años de duración" if inrange(duracion_total_anios, 1, 3)
		replace rango_duracion = "4 o más años de duración"   if inrange(duracion_total_anios, 4, 12)	
		
		
		*categoría IP-CFT para tipo_inst_3
		gen 	tipo_inst_3_new = tipo_inst_3
		replace tipo_inst_3_new = "CFT-IP" if inlist(tipo_inst, "CFT", "IP")
		
		
		*rango acreditación
		replace acre_inst_anio = subinstr(acre_inst_anio, " ", "", .) /*remove spaces*/
		gen 	rango_acreditacion = ""
		replace rango_acreditacion = "0" 	if acre_inst_anio == "" 				 & acreditada_inst == "NO ACREDITADA" & entra_ES == 1
		replace rango_acreditacion = "1-3"  if inlist(acre_inst_anio, "1", "2", "3") & acreditada_inst == "ACREDITADA" 	  & entra_ES == 1
		replace rango_acreditacion = "4-5"  if inlist(acre_inst_anio, "4", "5") 	 & acreditada_inst == "ACREDITADA" 	  & entra_ES == 1
		replace rango_acreditacion = "6-7"	if inlist(acre_inst_anio, "6", "7") 	 & acreditada_inst == "ACREDITADA"	  & entra_ES == 1
		
		
		*categorical vars
		label define dependencia_cat 1 "Municipal" 2 "PS" 3 "PP" /*change labels order*/
		encode dependencia,        gen(dependencia_cat) label(dependencia_cat)
		encode rango_acreditacion, gen(rango_acreditacion_cat)
		encode tipo_inst_3_new,    gen(tipo_inst_3_cat)
		encode area_conocimiento,  gen(area_conocimiento_cat)
		
		
		*labels define		
		label drop rango_acreditacion_cat tipo_inst_3_cat /*drop already defined vals*/
		label define q_nse 				      1 "Q1 NSE" 2 "Q2 NSE" 3 "Q3 NSE" 4 "Q4 NSE" 5 "Q5 NSE"
		label define d_sede_RM 			      0 "No estudia en RM" 1 "Estudia en RM"
		label define d_estudia_otra_region    0 "Estudiante no de 'región'" 1 "Estudiante de 'región'"
		label define d_mujer_alu 	 	      0 "Hombre" 1 "Mujer"
		label define tipo_inst_3_cat	  	  1 "CFT-IP" 2 "Univ Est-CRUCH" 3 "Univ Priv" 4 "Univ Priv-CRUCH"
		label define rango_acreditacion_cat	  1 "No Acreditada" 2 "Acreditación 1-3 años" 3 "Acreditación 4-5 años" 4 "Acreditación 6-7 años"
		
		
		*label values
		label values q_nse q_nse
		label values d_sede_RM d_sede_RM
		label values d_estudia_otra_region d_estudia_otra_region
		label values d_mujer_alu d_mujer_alu
		label values tipo_inst_3_cat tipo_inst_3_cat
		label values rango_acreditacion_cat rango_acreditacion_cat
		
		
		*label vars
		label variable nem 		 "NEM"
		label variable percentil "Percentil NEM"
		
	
	*comprime y guarda dataset
	compress
	save "${proc}/working_dataset_cohorte4m_`agno_4m'.dta", replace
	
	
	
	*counters
	local ++agno_4m
	local ++agno_sup
}