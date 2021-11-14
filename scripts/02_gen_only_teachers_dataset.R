#' this script generates the descriptive table 02 of the paper.
rm(list = ls())
if(!require("pacman")){install.packages("pacman")}

# load libraries
pacman::p_load(tidyverse, data.table, here, haven)

# load data
data_raw <- fread(here("data", "proc", "working_dataset_cohorte4m_2010.csv"))

data_2 <-
    data_raw %>% filter(entra_ES == 1 & 
                            tipo_inst_1 == "Universidades" &
                            str_detect(nomb_carrera, "(PEDAGOGIA|EDUCACION|PROFESOR|PARVULO|PARVULARIA|DIFERENCIAL)") &
                            nomb_carrera != "PSICOPEDAGOGIA" &
                            is.na(ptje_lect2m_alu) == 0 &
                            is.na(ptje_mate2m_alu) == 0
    ) %>%
    filter(!str_detect(nomb_carrera, "(TECNICO|BACHILLERATO)")) %>%
    mutate(area_conocimiento_cat = as_factor(area_conocimiento_cat) %>% droplevels(),
           dependencia_cat = as_factor(dependencia_cat),
           rango_acreditacion_cat = as_factor(rango_acreditacion_cat),
           teaching_area = ifelse(str_detect(nomb_carrera, "EDUCACION FISICA"), "phys ed", "other ed") %>% as_factor()
    )

# export new dataset
fwrite(data_2, here("data", "proc", "working_dataset_teachers_cohorte4m_2010.csv"))