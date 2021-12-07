#' this script generates the descriptive table 02 of the paper.
rm(list = ls()) ; gc()
if(!require("pacman")){install.packages("pacman")}

# load libraries
pacman::p_load(tidyverse, data.table, janitor, here, haven, magrittr, openxlsx, broom, fastDummies)

# load functions
source(here("scripts", "00_aux_functions.R"))

# load data
data <- fread(here("data", "proc", "working_dataset_teachers_cohorte4m_2010.csv")) %>%
    mutate(d_mujer_alu = ifelse(d_mujer_alu == "Mujer", 1, 0),
           d_estudia_otra_region = ifelse(d_estudia_otra_region == "Estudiante de 'regiÃ³n'", 1, 0),
           d_sede_RM = ifelse(d_sede_RM == "Estudia en RM", 1, 0)) %>%
    filter(teaching_area == "phys ed")

# table
# graduation rates (outcomes) ----

graduation_rates <-
data %>% select(starts_with("titulado")) %>%
    pivot_longer(everything()) %>%
    group_by(name) %>%
    summarise_all(.funs = list(mean = mean, sum = ~sum(!is.na(.))), na.rm = T) %>%
    mutate(mean = round(mean, 3)) %>%
    rbind(NA, NA)


# demographic ----
n_obs <- data %>% nrow(.)

# set value labels as values
data <- data %>% mutate(dependencia_cat = factor(dependencia_cat, levels = c("Municipal", "PS", "PP")),
                            q_nse = factor(q_nse))

demographic_section <- 
data %>% group_by(dependencia_cat) %>% 
    summarise(mean = n() / n_obs,
              sum = n_obs) %>% 
    ungroup() %>%
    rename(name = dependencia_cat) %>%
    rbind(NA) %>%
    bind_rows(
                data %>% group_by(q_nse) %>%
                    summarise(mean = n() / n_obs,
                              sum = n_obs) %>%
                    ungroup() %>%
                    rename(name = q_nse)) %>%
                    rbind(NA) %>%
    bind_rows(
                data %>% select(d_mujer_alu, d_estudia_otra_region) %>%
                    pivot_longer(everything()) %>%
                    group_by(name) %>%
                    summarise_all(.funs = list(mean = mean, sum = ~sum(!is.na(.))), na.rm = T) %>%
                    rbind(NA, NA)
                ) %>%
    mutate(mean = round(mean, 3))

# institutional ----

# set value labels as values
data <- data %>% mutate(rango_acreditacion_cat = factor(rango_acreditacion_cat))


institutional_section <- 
data %>% group_by(tipo_inst_3) %>% 
    summarise(mean = n() / n_obs,
              sum = n_obs) %>%
    rename(name = tipo_inst_3) %>%
    ungroup() %>%
    bind_rows(
                data %>% select(d_sede_RM) %>%
                    pivot_longer(everything()) %>%
                    group_by(name) %>%
                    summarise_all(.funs = list(mean = mean, sum = ~sum(!is.na(.))), na.rm = T) %>%
                    rbind(NA)
                ) %>%
    bind_rows(
                data %>% group_by(rango_acreditacion_cat) %>% 
                    summarise(mean = n() / n_obs,
                              sum = n_obs) %>%
                    ungroup() %>%
                    rename(name = rango_acreditacion_cat) %>%
                    rbind(NA)
                ) %>%
    mutate(mean = round(mean, 3))

# academic ----

academic_section <- 
data %>% select(starts_with("ptje"), nem) %>%
    pivot_longer(everything()) %>%
    group_by(name) %>%
    summarise_all(.funs = list(mean = mean, sum = ~sum(!is.na(.))), na.rm = T) %>%
    mutate(mean = round(mean,1))



# join all sections ----
table <- 
graduation_rates %>% bind_rows(demographic_section) %>%
                     bind_rows(institutional_section) %>%
                     bind_rows(academic_section)


# overwrite results over existing table

## Load existing file
excel_file <- loadWorkbook(here("tables", "03_descr-and-regs-tables.xlsx"))

## Pull data
excel_table <- read.xlsx(excel_file, sheet = "vars_tabulation_phys_ed") %>% head(-1)

## join data
table <- table %>% add_row(name = NA, .before = 1) # to match with "Results" subtitle.
excel_table <- excel_table %>% mutate("Valor.(%)" = table %>% pull(mean),
                                        "N" = table %>% pull(sum))

## Put the data back into the workbook
writeData(excel_file, sheet = "vars_tabulation_phys_ed", excel_table)

## Save to disk
saveWorkbook(excel_file, 
             here("tables", "03_descr-and-regs-tables.xlsx"),
             overwrite = TRUE)
