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


**************************************************************
* 				Matrícula Superior 2011-2014 				 *
**************************************************************

*mini-reporte: N y % obs perdidas post-limpieza.
matrix mat_sup = J(2014-2011+1, 3, 0)
local j = 1
local sup_rownames


forvalues x = 2011(1)2014{
	import delimited "${raw}/matricula_superior_`x'.csv", clear


	
	*agno_ES
	rename ïcat_periodo agno_ES
	
	*Mantengo variables relevantes
	keep agno_ES mrun tipo_inst_1 tipo_inst_2 tipo_inst_3 cod_inst ///
	cod_carrera nomb_carrera modalidad jornada dur_total_carr ///
	region_sede provincia_sede comuna_sede nivel_global /// 
	valor_arancel valor_matricula area_conocimiento /// 
	acreditada_carr acreditada_inst acre_inst_anio
	
	**variables relevantes
	*area de conocimiento
	*Nota: hay personas sin area de conocimiento
	replace area_conocimiento="Sin Área definida" if area_conocimiento=="Sin Ã¡rea definida"
	replace area_conocimiento="Administración y Comercio" if area_conocimiento=="AdministraciÃ³n y Comercio"
	replace area_conocimiento="Ciencias Básicas" if area_conocimiento=="Ciencias BÃ¡sicas"
	replace area_conocimiento="Educación" if area_conocimiento=="EducaciÃ³n"
	replace area_conocimiento="Tecnología" if area_conocimiento=="TecnologÃ­a"

	*duración en años:
	destring dur_total_carr,replace
	drop if dur_total_carr==1 | dur_total_carr==. 


	*rango duración
	gen rango_duracion="."
	replace rango_duracion="1-3 años" if inrange(dur_total_carr,2,7)
	replace rango_duracion="4-5 años" if inrange(dur_total_carr,8,11)
	replace rango_duracion="6 o más años" if inrange(dur_total_carr,12,24)
	*Nota: carreras llegan hasta 9 años máximo aprox.

	*tipo de institución ES.
	gen tipo_inst=tipo_inst_1
	replace tipo_inst="CFT" if tipo_inst=="Centros de FormaciÃ³n TÃ©cnica"
	replace tipo_inst="IP" if tipo_inst=="Institutos Profesionales"
	replace tipo_inst="Univ" if tipo_inst=="Universidades"
	
	*para merges
	destring mrun, replace

	*computo N inicial
	qui sum mrun
	local N_i = r(N)
	scalar N_inicial = `N_i'
	
	**mrun
	*hay mv
	drop if mrun==.
	*reporte duplicados
	qui duplicates report mrun
	*elimino duplicados
	duplicates drop mrun, force


	*computo N final
	qui sum mrun
	local N_f = r(N)
	scalar N_final = `N_f'

	*calculo porcentaje limpiado
	scalar perc_cleaned = (abs(N_final - N_inicial) / N_inicial)*100
	*asigno valores a matriz
	matrix mat_sup[`j',1] = N_inicial
	matrix mat_sup[`j',2] = N_final
	matrix mat_sup[`j',3] = perc_cleaned
	
	*asigno nombre a fila de la matriz
	local sup_rownames `sup_rownames' sup_`=`x''
	*contador
	local ++j

	*comprime tamaño dataset 
	compress
	
save "${proc}/matricula_superior_`x'_edited.dta", replace
}


*asigno nombre a matriz
matrix rownames mat_sup = `sup_rownames'
*asigno nombre columna
matrix colnames mat_sup = "N_inicial" "N_final" "perc_cleaned"
*output:
matrix list mat_sup
/*
             N_inicial       N_final  perc_cleaned
sup_2011       1065700       1056530     -.8604673
sup_2012       1123203       1112569    -.94675673
sup_2013       1181544       1168163    -1.1325012
sup_2014       1213782       1200183    -1.1203824

*/
