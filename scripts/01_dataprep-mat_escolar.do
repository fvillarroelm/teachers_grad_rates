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
*           	  Matrícula 4m  2010-2013    	  	         *
**************************************************************

*mini-reporte: N y % obs perdidas post-limpieza.
matrix mat_esc = J(2013-2010+1, 3, 0)
local j = 1
local esc_rownames

forvalues x = 2010(1)2013{
	*importo .csv
	import delimited "${raw}/matricula_escolar_`x'.csv", clear

	
	*rename agno_4m
	rename agno agno_4m
	
	*mantengo variables relevantes
	keep agno_4m mrun rbd dgv_rbd cod_reg_rbd cod_com_rbd ///
	nom_com_rbd cod_depe2 rural_rbd cod_ense cod_grado ///
	cod_jor gen_alu fec_nac_alu repite_alu cod_reg_alu ///
	cod_com_alu nom_com_alu
	
	**Creación variables
	
	*Dummy de enseñanza media
	gen EM=0
	replace EM=1 if cod_ense>=310

	*Dummy para diferenciar estudios de jóvenes y adultos
	gen joven=0
	replace joven=1 if (cod_ense==310 | cod_ense==410 | cod_ense==510 | cod_ense==610 | cod_ense==710 | cod_ense==810 | cod_ense==910)

	*Dummy para diferenciar colegios científico-humanistas y técnicos
	gen H_C=0
	replace H_C=1 if (cod_ense==310 | cod_ense==360 | cod_ense==361 | cod_ense==363)

	*1ero Medio
	gen grado=0
	replace grado=1 if cod_ense==310 & cod_grado==1
	replace grado=1 if cod_ense==360 & cod_grado==1
	replace grado=1 if cod_ense==310 & cod_grado==1
	replace grado=1 if cod_ense==410 & cod_grado==1
	replace grado=1 if cod_ense==510 & cod_grado==1
	replace grado=1 if cod_ense==610 & cod_grado==1
	replace grado=1 if cod_ense==710 & cod_grado==1
	replace grado=1 if cod_ense==810 & cod_grado==1
	replace grado=1 if cod_ense==910 & cod_grado==1

	*2do Medio
	replace grado=2 if cod_ense==310 & cod_grado==2
	replace grado=2 if cod_ense==363 & cod_grado==1
	replace grado=2 if cod_ense==410 & cod_grado==2
	replace grado=2 if cod_ense==463 & cod_grado==1
	replace grado=2 if cod_ense==510 & cod_grado==2
	replace grado=2 if cod_ense==563 & cod_grado==1
	replace grado=2 if cod_ense==610 & cod_grado==2
	replace grado=2 if cod_ense==663 & cod_grado==1
	replace grado=2 if cod_ense==710 & cod_grado==2
	replace grado=2 if cod_ense==763 & cod_grado==1
	replace grado=2 if cod_ense==810 & cod_grado==2
	replace grado=2 if cod_ense==863 & cod_grado==1
	replace grado=2 if cod_ense==910 & cod_grado==2
	replace grado=2 if cod_ense==963 & cod_grado==1

	*3ro Medio
	replace grado=3 if cod_ense==310 & cod_grado==3
	replace grado=3 if cod_ense==410 & cod_grado==3
	replace grado=3 if cod_ense==463 & cod_grado==3
	replace grado=3 if cod_ense==510 & cod_grado==3
	replace grado=3 if cod_ense==563 & cod_grado==3
	replace grado=3 if cod_ense==610 & cod_grado==3
	replace grado=3 if cod_ense==663 & cod_grado==3
	replace grado=3 if cod_ense==710 & cod_grado==3
	replace grado=3 if cod_ense==763 & cod_grado==3
	replace grado=3 if cod_ense==810 & cod_grado==3
	replace grado=3 if cod_ense==863 & cod_grado==3
	replace grado=3 if cod_ense==910 & cod_grado==3
	replace grado=3 if cod_ense==963 & cod_grado==3

	*4to Medio
	replace grado=4 if cod_ense==310 & cod_grado==4
	replace grado=4 if cod_ense==360 & cod_grado==4
	replace grado=4 if cod_ense==363 & cod_grado==3
	replace grado=4 if cod_ense==410 & cod_grado==4
	replace grado=4 if cod_ense==463 & cod_grado==4
	replace grado=4 if cod_ense==510 & cod_grado==4
	replace grado=4 if cod_ense==561 & cod_grado==4
	replace grado=4 if cod_ense==563 & cod_grado==4
	replace grado=4 if cod_ense==610 & cod_grado==4
	replace grado=4 if cod_ense==661 & cod_grado==4
	replace grado=4 if cod_ense==663 & cod_grado==4
	replace grado=4 if cod_ense==710 & cod_grado==4
	replace grado=4 if cod_ense==763 & cod_grado==4
	replace grado=4 if cod_ense==810 & cod_grado==4
	replace grado=4 if cod_ense==863 & cod_grado==4
	replace grado=4 if cod_ense==910 & cod_grado==4
	replace grado=4 if cod_ense==963 & cod_grado==4
	
	*Para dejar sólo alumnos de 4to Medio
	keep if grado==4
	
	*computo N inicial
	qui sum mrun
	local N_i = r(N)
	scalar N_inicial = `N_i'
	
	*Para ver si hay duplicados
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
	matrix mat_esc[`j',1] = N_inicial
	matrix mat_esc[`j',2] = N_final
	matrix mat_esc[`j',3] = perc_cleaned
	
	*asigno nombre a fila de la matriz
	local esc_rownames `esc_rownames' esc_`=`x''
	*contador
	local ++j

	*tipo de dependencia.
	*se añade a la categoría municipal a los de administración delegada (70 establecimientos T-P de propiedad del Estado).
	gen dependencia="."
	replace dependencia= "PS" if cod_depe2==2
	replace dependencia="PP" if cod_depe2==3
	replace dependencia="Municipal" if cod_depe2==1 | cod_depe2==4

	*comprime tamaño dataset
	compress
	
	save "${proc}/matriculaIV_escolar_`x'.dta",replace
}

*asigno nombre a matriz
matrix rownames mat_esc = `esc_rownames'
*asigno nombre columna
matrix colnames mat_esc = "N_inicial" "N_final" "perc_cleaned"
*% obs que se pierden post-limpieza entre 2010-2013:
matrix list mat_esc
/*
			N_inicial       N_final  perc_cleaned
esc_2010     3647607        274455    -92.475752
esc_2011     3603002        274420    -92.383573
esc_2012     3549148        262685    -92.598646
esc_2013     3537087        258472    -92.692518
*/