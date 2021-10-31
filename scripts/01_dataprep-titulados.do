clear all
set more off

*Directorios
global main "C:/Users/fvillarroel/Downloads/pega/udla/proyectos/titulacion_educacion_superior"
global tables "${main}/results/tables"
global graphs "${main}/results/graphs"
global raw "${main}/data/raw"
global proc "${main}/data/proc"

*directorio
cd $main



**************************************************************
*				  Titulados 2011-2019						 *
**************************************************************

matrix titulados = J(2019-2011+1, 3, 0)
local j = 1
local tit_rownames

forvalues x = 2011(1)2019{

	import delimited "${raw}/titulados_`x'.csv", clear

	*variables relevantes: mrun, cod_inst, cod_carrera
	keep mrun cod_inst cod_carrera

	*computo N inicial
	qui sum cod_inst
	local N_i = r(N)
	scalar N_inicial = `N_i'

	*destring mrun.
	destring mrun, replace

	*drop mv mrun.
	drop if mrun==.
	
	*destring cod_carrera
	destring cod_carrera, replace
	
	*drop mv cod_carrera
	drop if cod_carrera==.

	*chequeo duplicados
	qui duplicates report mrun
	*elimino duplicados
	duplicates drop mrun, force
	

	*computo N final
	qui sum cod_inst
	local N_f = r(N)
	scalar N_final = `N_f'

	*calculo porcentaje
	scalar perc_cleaned = (abs(N_final - N_inicial) / N_inicial)*100
	*asigno valores a matriz
	matrix titulados[`j',1] = N_inicial
	matrix titulados[`j',2] = N_final
	matrix titulados[`j',3] = perc_cleaned
	
	*asigno nombre a fila de la matriz
	local tit_rownames `tit_rownames' tit_`=`x''
	*contador
	local ++j

	*guardo dataset final
	save "${proc}/titulados_`x'_edited.dta", replace

}

*asigno nombre a matriz
matrix rownames titulados = `tit_rownames'
*asigno nombre columna
matrix colnames titulados = "N_inicial" "N_final" "perc_cleaned"
*output
matrix list titulados