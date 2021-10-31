clear all
set more off

*Directorios
global main "C:/Users/fvillarroel/Downloads/pega/udla/proyectos/graduation_rates"
global tables "${main}/results/tables"
global graphs "${main}/results/graphs"
global raw "${main}/data/raw"
global proc "${main}/data/proc"

*directorio
cd $main



**************************************************************
*  	     SIMCE 2M 2008 (match matricula 4m 2010)	         *
**************************************************************

**Alumnos
use "${raw}/simce2m2008_alu.dta", clear
*alu N=270.897

*keep variables relevantes
keep  mrun idalumno ptje_lect2m_alu ptje_mate2m_alu
*label ptje simce
label variable ptje_lect2m_alu "Ptje. SIMCE Lect."
label variable ptje_mate2m_alu "Ptje. SIMCE Mat."


*hay duplicados (~12k)
duplicates report mrun
*borro duplicados (5.924)
duplicates drop mrun, force



**Cuestionario padres.
*Debe unirse con base_alu antes. Sólo base_alu tiene mrun.
merge 1:1 idalumno using "${raw}/simce2m2008_cpad.dta", keepusing(cpad_p05* cpad_p06* cpad_p07*)
*cpad_p05... (edu_padre) cpad_p06... (edu_madre) cpad_p07... (ingreso_hogar)

*matched: 200.810
*not matched (from master): 64.163
*not matched (from using): 1.440
keep if _merge==3 /*only matches*/
*N=200.810
drop _merge

**Variables NSE: son múltiples dummies de nivel alcanzado. hay que pasarla a variable única numérica (años de escolaridad).
*educ_padre
gen educ_padre=.
replace educ_padre=. if cpad_p05_01==1

forvalues x=2(1)9{
replace educ_padre=`x'-2 if cpad_p05_0`x'==1
}
forvalues x=10(1)14{
replace educ_padre=`x'-2 if cpad_p05_`x'==1
}
replace educ_padre=12 if cpad_p05_15==1
replace educ_padre=13 if cpad_p05_16==1
replace educ_padre=14 if cpad_p05_17==1
replace educ_padre=14.5 if cpad_p05_18==1
replace educ_padre=17 if cpad_p05_19==1
replace educ_padre=19 if cpad_p05_20==1
replace educ_padre=24 if cpad_p05_21==1

*educ_madre
gen educ_madre=.
replace educ_madre=. if cpad_p06_01==1
forvalues x=2(1)9{
replace educ_madre=`x'-2 if cpad_p06_0`x'==1
}
forvalues x=10(1)14{
replace educ_madre=`x'-2 if cpad_p06_`x'==1
}
replace educ_madre=12 if cpad_p06_15==1
replace educ_madre=13 if cpad_p06_16==1
replace educ_madre=14 if cpad_p06_17==1
replace educ_madre=14.5 if cpad_p06_18==1
replace educ_madre=17 if cpad_p06_19==1
replace educ_madre=19 if cpad_p06_20==1
replace educ_madre=24 if cpad_p06_21==1

*ingreso_hogar
gen ingreso_hogar=.
replace ingreso_hogar=50000 if cpad_p07_01==1
replace ingreso_hogar=150000 if cpad_p07_02==1
replace ingreso_hogar=250000 if cpad_p07_03==1
replace ingreso_hogar=350000 if cpad_p07_04==1
replace ingreso_hogar=450000 if cpad_p07_05==1
replace ingreso_hogar=550000 if cpad_p07_06==1
replace ingreso_hogar=700000 if cpad_p07_07==1
replace ingreso_hogar=900000 if cpad_p07_08==1
replace ingreso_hogar=1100000 if cpad_p07_09==1
replace ingreso_hogar=1300000 if cpad_p07_10==1
replace ingreso_hogar=1500000 if cpad_p07_11==1
replace ingreso_hogar=1700000 if cpad_p07_12==1
replace ingreso_hogar=2300000 if cpad_p07_13==1


*drop full missing values: se van 993 obs.
drop if ingreso_hogar==. & educ_padre==. & educ_madre==.


*drop variables no usadas
drop cpad_p05* cpad_p06* cpad_p07*


****Imputación.

**NSE vars
replace educ_madre=educ_padre if educ_madre==. /*1043 cambios*/
replace educ_padre=educ_madre if educ_padre==. 
/*9160 cambios*/

*drop missing values (mv): 2187 obs menos.
drop if ingreso_hogar==. | (educ_madre==. & educ_padre==.)
*Nota: se van personas con ingreso mv y educación de ambos padres no-mv, y personas con educación de ambos padres mv e ingreso no-mv.


**Ptje SIMCE vars
*hay un ~3,3% de missing values en ptjes
mdesc ptje_lect2m_alu
mdesc ptje_mate2m_alu

*imputación
replace ptje_lect2m_alu = ptje_mate2m_alu if ptje_lect2m_alu == .
replace ptje_mate2m_alu = ptje_lect2m_alu if ptje_mate2m_alu == .

*con imputación queda en 2,8%
mdesc ptje_lect2m_alu
mdesc ptje_mate2m_alu


*nse_index: principal component factor analysis
factor educ_madre educ_padre ingreso_hogar, pcf
rotate, oblimin
predict nse_index
sum nse_index /*media=0, sd=1*/
*percentiles NSE
xtile p_nse=nse_index,n(100)
*deciles NSE
xtile d_nse=nse_index,n(10)
*quintiles NSE
xtile q_nse=nse_index,n(5)


*comprime tamaño dataset
compress

save "${proc}/simce2m2008_alu_nse.dta", replace











**************************************************************
* 		   SIMCE 8B 2007 (match matrícula 4m 2011) 	   	     *
**************************************************************

**Alumnos
use "${raw}/simce8b2007_alu.dta", clear
*alu N=282.086

*keep variables relevantes
keep mrun idalumno ptje_lect8b_alu ptje_mate8b_alu
*label ptje simce
label variable ptje_lect8b_alu "Ptje. SIMCE Lect."
label variable ptje_mate8b_alu "Ptje. SIMCE Mat."


*hay duplicados (~12k)
duplicates report mrun
*borro duplicados (6.174)
duplicates drop mrun, force


**Cuestionario padres.
*Debe unirse con base_alu antes. Sólo base_alu tiene mrun.
merge 1:1 idalumno using "${raw}/simce8b2007_cpad.dta", keepusing(cpad_p05 cpad_p06 cpad_p09)
*cpad_p05 (edu_padre) cpad_p06 (edu_madre) cpad_p09 (ingreso_hogar)

*matched: 232.949
*not matched (from master): 42.963
*not matched (from using): 2.175
keep if _merge==3 /*only matches*/
*N=232.949
drop _merge

**Variables NSE: variables categóricas
*educ_padre
gen educ_padre=.
replace educ_padre=. if cpad_p05==1 | cpad_p05==99

forvalues x=2(1)14{
replace educ_padre=`x'-2 if cpad_p05==`x'
}
replace educ_padre=12 if cpad_p05==15
replace educ_padre=13 if cpad_p05==16
replace educ_padre=14 if cpad_p05==17
replace educ_padre=14.5 if cpad_p05==18
replace educ_padre=17 if cpad_p05==19
replace educ_padre=19 if cpad_p05==20
replace educ_padre=24 if cpad_p05==21

*educ_madre
gen educ_madre=.
replace educ_madre=. if cpad_p06==1 | cpad_p06==99

forvalues x=2(1)14{
replace educ_madre=`x'-2 if cpad_p06==`x'
}
replace educ_madre=12 if cpad_p06==15
replace educ_madre=13 if cpad_p06==16
replace educ_madre=14 if cpad_p06==17
replace educ_madre=14.5 if cpad_p06==18
replace educ_madre=17 if cpad_p06==19
replace educ_madre=19 if cpad_p06==20
replace educ_madre=24 if cpad_p06==21

*ingreso_hogar
gen ingreso_hogar=.
replace ingreso_hogar=. if cpad_p09==00 | cpad_p09==99
replace ingreso_hogar=50000 if cpad_p09==1
replace ingreso_hogar=150000 if cpad_p09==2
replace ingreso_hogar=250000 if cpad_p09==3
replace ingreso_hogar=350000 if cpad_p09==4
replace ingreso_hogar=450000 if cpad_p09==5
replace ingreso_hogar=550000 if cpad_p09==6
replace ingreso_hogar=700000 if cpad_p09==7
replace ingreso_hogar=900000 if cpad_p09==8
replace ingreso_hogar=1100000 if cpad_p09==9
replace ingreso_hogar=1300000 if cpad_p09==10
replace ingreso_hogar=1500000 if cpad_p09==11
replace ingreso_hogar=1700000 if cpad_p09==12
replace ingreso_hogar=2300000 if cpad_p09==13

*se van 1.753 obs.
drop if ingreso_hogar==. & educ_padre==. & educ_madre==.

*drop vars no usadas
drop cpad_p05 cpad_p06 cpad_p09

****Imputación
**NSE vars
replace educ_madre=educ_padre if educ_madre==. /*1.305 cambios*/
replace educ_padre=educ_madre if educ_padre==. 
/*10.238 cambios*/

*drop missing values (mv): 11.608 obs menos.
drop if ingreso_hogar==. | (educ_madre==. & educ_padre==.)
*Nota: se van personas con ingreso mv y educación de ambos padres no-mv, y personas con educación de ambos padres mv e ingreso no-mv.


**Ptje SIMCE vars
*hay 1,5-2% de missing values en ptjes
mdesc ptje_lect8b_alu
mdesc ptje_mate8b_alu

*imputación
replace ptje_lect8b_alu = ptje_mate8b_alu if ptje_lect8b_alu == .
replace ptje_mate8b_alu = ptje_lect8b_alu if ptje_mate8b_alu == .

*con imputación queda en 1,3%
mdesc ptje_lect8b_alu
mdesc ptje_mate8b_alu

*nse_index: principal component factor analysis
factor educ_madre educ_padre ingreso, pcf
rotate, oblimin
predict nse_index
sum nse_index /*media=0, sd=1*/

*percentiles
xtile p_nse=nse_index,n(100)
*deciles
xtile d_nse=nse_index,n(10)
*quintiles
xtile q_nse=nse_index,n(5)


*compress and save
compress
save "${proc}/simce8b2007_alu_nse.dta", replace










**************************************************************
*		   SIMCE 2M 2010 (match matrícula 4m 2012)		     *
**************************************************************

**Alumnos
use "${raw}/simce2m2010_alu.dta", clear
*alu N=282.086

*keep vars relevantes
keep mrun idalumno ptje_lect2m_alu ptje_mate2m_alu
*label ptje simce
label variable ptje_lect2m_alu "Ptje. SIMCE Lect."
label variable ptje_mate2m_alu "Ptje. SIMCE Mat."

*hay duplicados (~12k)
qui duplicates report mrun
*borro duplicados (6.174)
duplicates drop mrun, force


**Cuestionario padres.
*Debe unirse con base_alu antes. Sólo base_alu tiene mrun.
merge 1:1 idalumno using "${raw}/simce2m2010_cpad.dta", keepusing(cpad_p09_* cpad_p10_* cpad_p11_*)
keep if _merge==3 /*only matches*/
drop _merge

*EDU PADRE
gen educ_padre = .
forvalues x=1(1)9{
replace educ_padre=`x'-1 if cpad_p09_0`x'==1
}

forvalues x=10(1)13{
replace educ_padre=`x'-1 if cpad_p09_`x'==1
}

replace educ_padre = 12   if cpad_p09_14 == 1
replace educ_padre = 13   if cpad_p09_15 == 1
replace educ_padre = 14   if cpad_p09_16 == 1
replace educ_padre = 14.5 if cpad_p09_17 == 1
replace educ_padre = 17   if cpad_p09_18 == 1
replace educ_padre = 19   if cpad_p09_19 == 1
replace educ_padre = 24   if cpad_p09_20 == 1
replace educ_padre = .    if cpad_p09_21 == 1


*EDU MADRE
gen educ_madre = .
forvalues x=1(1)9{
replace educ_madre=`x'-1 if cpad_p10_0`x'==1
}

forvalues x=10(1)13{
replace educ_madre=`x'-1 if cpad_p10_`x'==1
}

replace educ_madre = 12   if cpad_p10_14 == 1
replace educ_madre = 13   if cpad_p10_15 == 1
replace educ_madre = 14   if cpad_p10_16 == 1
replace educ_madre = 14.5 if cpad_p10_17 == 1
replace educ_madre = 17   if cpad_p10_18 == 1
replace educ_madre = 19   if cpad_p10_19 == 1
replace educ_madre = 24   if cpad_p10_20 == 1
replace educ_madre = .    if cpad_p10_21 == 1

*INGRESOS
gen ingreso_hogar = .
replace ingreso_hogar = 50000   if cpad_p11_01 == 1
replace ingreso_hogar = 150000  if cpad_p11_02 == 1
replace ingreso_hogar = 250000  if cpad_p11_03 == 1
replace ingreso_hogar = 350000  if cpad_p11_04 == 1
replace ingreso_hogar = 450000  if cpad_p11_05 == 1
replace ingreso_hogar = 550000  if cpad_p11_06 == 1
replace ingreso_hogar = 700000  if cpad_p11_07 == 1
replace ingreso_hogar = 900000  if cpad_p11_08 == 1
replace ingreso_hogar = 1100000 if cpad_p11_09 == 1
replace ingreso_hogar = 1300000 if cpad_p11_10 == 1
replace ingreso_hogar = 1500000 if cpad_p11_11 == 1
replace ingreso_hogar = 1700000 if cpad_p11_12 == 1
replace ingreso_hogar = 1900000 if cpad_p11_13 == 1
replace ingreso_hogar = 2100000 if cpad_p11_14 == 1
replace ingreso_hogar = 2500000 if cpad_p11_15 == 1

*drop todos con mv
drop if ingreso_hogar==. & educ_padre==. & educ_madre==.

*drop vars no usadas
drop cpad_p09_* cpad_p10_* cpad_p11_*

****Imputación.
**NSE vars
replace educ_madre=educ_padre if educ_madre==. 
replace educ_padre=educ_madre if educ_padre==. 

*drop missing values (mv)
drop if ingreso_hogar==. | (educ_madre==. & educ_padre==.)
*Nota: se van personas con ingreso mv y educación de ambos padres no-mv, y personas con educación de ambos padres mv e ingreso no-mv.


**Ptje SIMCE vars
*hay ~2,7% de missing values en ptjes
mdesc ptje_lect2m_alu
mdesc ptje_mate2m_alu

*imputación
replace ptje_lect2m_alu = ptje_mate2m_alu if ptje_lect2m_alu == .
replace ptje_mate2m_alu = ptje_lect2m_alu if ptje_mate2m_alu == .

*con imputación queda en 2,3%
mdesc ptje_lect2m_alu
mdesc ptje_mate2m_alu


*nse_index: principal component factor analysis
factor educ_madre educ_padre ingreso, pcf
rotate, oblimin
predict nse_index
sum nse_index /*media=0, sd=1*/

*percentiles
xtile p_nse=nse_index,n(100)
*deciles
xtile d_nse=nse_index,n(10)
*quintiles
xtile q_nse=nse_index,n(5)

*compress and save
compress
save "${proc}/simce2m2010_alu_nse.dta", replace











**************************************************************
*		   SIMCE 8B 2009 (match matrícula 4m 2013)		     *
**************************************************************

**Alumnos
use "${raw}/simce8b2009_alu.dta", clear
*alu N=282.086

*keep vars relevantes
keep mrun idalumno ptje_lect8b_alu ptje_mate8b_alu
*label ptje simce
label variable ptje_lect8b_alu "Ptje. SIMCE Lect."
label variable ptje_mate8b_alu "Ptje. SIMCE Mat."


*hay duplicados (~12k)
qui duplicates report mrun
*borro duplicados (6.174)
duplicates drop mrun, force



**Cuestionario padres.
*Debe unirse con base_alu antes. Sólo base_alu tiene mrun.
merge 1:1 idalumno using "${raw}/simce8b2009_cpad.dta", keepusing(cpad_p09_* cpad_p10_*)
keep if _merge==3 /*only matches*/
drop _merge

*EDU PADRE
gen educ_padre = .
forvalues x=1(1)9{
replace educ_padre=`x'-1 if cpad_p09_01_0`x'==1
}

forvalues x=10(1)13{
replace educ_padre=`x'-1 if cpad_p09_01_`x'==1
}

replace educ_padre = 12   if cpad_p09_01_14 == 1
replace educ_padre = 13   if cpad_p09_01_15 == 1
replace educ_padre = 14   if cpad_p09_01_16 == 1
replace educ_padre = 14.5 if cpad_p09_01_17 == 1
replace educ_padre = 17   if cpad_p09_01_18 == 1
replace educ_padre = 19   if cpad_p09_01_19 == 1
replace educ_padre = 24   if cpad_p09_01_20 == 1
replace educ_padre = .    if cpad_p09_01_21 == 1


*EDU MADRE
gen educ_madre = .
forvalues x=1(1)9{
replace educ_madre=`x'-1 if cpad_p09_02_0`x'==1
}

forvalues x=10(1)13{
replace educ_madre=`x'-1 if cpad_p09_02_`x'==1
}

replace educ_madre = 12   if cpad_p09_02_14 == 1
replace educ_madre = 13   if cpad_p09_02_15 == 1
replace educ_madre = 14   if cpad_p09_02_16 == 1
replace educ_madre = 14.5 if cpad_p09_02_17 == 1
replace educ_madre = 17   if cpad_p09_02_18 == 1
replace educ_madre = 19   if cpad_p09_02_19 == 1
replace educ_madre = 24   if cpad_p09_02_20 == 1
replace educ_madre = .    if cpad_p09_02_21 == 1

*INGRESOS
gen ingreso_hogar = .
replace ingreso_hogar = 50000   if cpad_p10_01 == 1
replace ingreso_hogar = 150000  if cpad_p10_02 == 1
replace ingreso_hogar = 250000  if cpad_p10_03 == 1
replace ingreso_hogar = 350000  if cpad_p10_04 == 1
replace ingreso_hogar = 450000  if cpad_p10_05 == 1
replace ingreso_hogar = 550000  if cpad_p10_06 == 1
replace ingreso_hogar = 700000  if cpad_p10_07 == 1
replace ingreso_hogar = 900000  if cpad_p10_08 == 1
replace ingreso_hogar = 1100000 if cpad_p10_09 == 1
replace ingreso_hogar = 1300000 if cpad_p10_10 == 1
replace ingreso_hogar = 1500000 if cpad_p10_11 == 1
replace ingreso_hogar = 1700000 if cpad_p10_12 == 1
replace ingreso_hogar = 1900000 if cpad_p10_13 == 1
replace ingreso_hogar = 2100000 if cpad_p10_14 == 1
replace ingreso_hogar = 2500000 if cpad_p10_15 == 1


*drop todos con mv
drop if ingreso_hogar==. & educ_padre==. & educ_madre==.

*drop vars no usadas
drop cpad_p09_* cpad_p10_*

****Imputación.
**NSE vars
replace educ_madre=educ_padre if educ_madre==. 
replace educ_padre=educ_madre if educ_padre==. 

*drop missing values (mv)
drop if ingreso_hogar==. | (educ_madre==. & educ_padre==.)
*Nota: se van personas con ingreso mv y educación de ambos padres no-mv, y personas con educación de ambos padres mv e ingreso no-mv.


**Ptje SIMCE vars
*hay 2,2-2,9% de missing values en ptjes
mdesc ptje_lect8b_alu
mdesc ptje_mate8b_alu

*imputación
replace ptje_lect8b_alu = ptje_mate8b_alu if ptje_lect8b_alu == .
replace ptje_mate8b_alu = ptje_lect8b_alu if ptje_mate8b_alu == .

*con imputación queda en 1,5%
mdesc ptje_lect8b_alu
mdesc ptje_mate8b_alu


*nse_index: principal component factor analysis
factor educ_madre educ_padre ingreso, pcf
rotate, oblimin
predict nse_index
sum nse_index /*media=0, sd=1*/

*percentiles
xtile p_nse=nse_index,n(100)
*deciles
xtile d_nse=nse_index,n(10)
*quintiles
xtile q_nse=nse_index,n(5)

*comprime tamaño dataset
compress

save "${proc}/simce8b2009_alu_nse.dta", replace