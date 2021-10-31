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
*               NEM y Percentil 4m  2010-2013      	         *
**************************************************************

**JOVENES
*cargo data
import delimited "${raw}/nem_pctiles_jovenes_1990-2017.csv", clear

*mantengo vars relevantes
keep if inrange(agno_egreso, 2010, 2013)
drop cod_depe puesto_*
rename agno_egreso agno_4m

*no hay dups
duplicates report mrun
*nem dentro de rangos esperados
sum nem

*creo var joven
gen joven = 1

*guardo data por agnos
forvalues x = 2010(1)2013{
	preserve
	keep if agno_4m == `x'
	compress
	save "${proc}/nem_pctiles_jovenesYadultos_`x'.dta", replace
	restore
}

**ADULTOS
*cargo data
import delimited "${raw}/nem_pctiles_adultos_1990-2017.csv", clear

*mantengo vars relevantes
keep if inrange(agno_egreso, 2010, 2013)
drop cod_depe puesto_*
rename agno_egreso agno_4m

*no hay dups
duplicates report mrun
*nem dentro de rangos esperados
sum nem

*creo var joven
gen joven = 0

*guardo data por agnos: estos van en append con el archivo de jóvenes para que sea un archivo por año.
forvalues x = 2010(1)2013{
	preserve
	keep if agno_4m == `x'
	compress
	append using "${proc}/nem_pctiles_jovenesYadultos_`x'.dta"
	restore
}