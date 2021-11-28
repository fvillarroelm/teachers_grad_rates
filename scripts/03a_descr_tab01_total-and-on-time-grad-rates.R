#' this script generates the descriptive table 01 of the paper.
rm(list = ls()) ; gc()
if(!require("pacman")){install.packages("pacman")}

# load libraries
pacman::p_load(tidyverse, data.table, janitor, here, haven, magrittr, openxlsx, broom, fastDummies)

# load functions
source(here("scripts", "00_aux_functions.R"))

# load data
data <- fread(here("data", "proc", "working_dataset_teachers_cohorte4m_2010.csv"))

# grad rates on-time ----

# data for physical education teachers
on_time_grad_phys_ed <- data %>% filter(titulado_oportuno == 1 & teaching_area == "phys ed")

all_phys_ed <- data %>% filter(teaching_area == "phys ed")

on_time_grad_phys_ed %>% summarise(total = nrow(.))

# data for non-physical education teachers
on_time_grad_other_ed <- data %>% filter(titulado_oportuno == 1 & teaching_area == "other ed")

all_other_ed <- data %>% filter(teaching_area == "other ed")

# data for all teachers
on_time_grad_teachers <- data %>% filter(titulado_oportuno == 1)

all_teachers <- data

# final (non-formatted) table
table_grad_on_time <- 
    table_grad_rates(on_time_grad_phys_ed, all_phys_ed) %>%
    rename(phys_ed = value) %>%
    bind_cols(table_grad_rates(on_time_grad_other_ed, all_other_ed) %>%
                  rename(other_teachers = value) %>%
                  select(-name)
    ) %>%
    bind_cols(
        table_grad_rates(on_time_grad_teachers, all_teachers) %>%
            rename(total = value) %>%
            select(-name)
    )


# export on-time grad rates ----

# load existing file
excel_file <- loadWorkbook(here("tables", "03_descr-and-regs-tables.xlsx"))

# pull all data from sheet
excel_table <- read.xlsx(excel_file, sheet = "on-time_grad_rates") %>% head(-1)

# edit names
remove <- c("Sociodemográficas", 
            "Tipo de establecimiento", 
            "Quintil de Ingresos", 
            "Otras", 
            "Institucionales", 
            "Tipo de Institución", 
            "Tipo de acreditación institucional")
table_grad_on_time <- 
table_grad_on_time %>% mutate(name = excel_table %>% filter(!name %in% remove) %>% pull(name))

# join
excel_table <-
excel_table %>% select(-2:-4) %>% left_join(y = table_grad_on_time, by = "name")

# put the data back into the workbook
writeData(excel_file, sheet = "on-time_grad_rates", excel_table)

# save to disk
saveWorkbook(excel_file, 
             here("tables", "03_descr-and-regs-tables.xlsx"), 
             overwrite = TRUE)




# total grad rates ----

# data for physical education teachers
total_grad_phys_ed <- data %>% filter(titulado == 1 & teaching_area == "phys ed")

# data for non-physical education teachers
total_grad_other_ed <- data %>% filter(titulado == 1 & teaching_area == "other ed")

# data for all teachers
total_grad_teachers <- data %>% filter(titulado == 1)

# final (non-formatted) table
table_total_grad <- 
table_grad_rates(total_grad_phys_ed, all_phys_ed) %>%
    rename(phys_ed = value) %>%
    bind_cols(table_grad_rates(total_grad_other_ed, all_other_ed) %>%
                  rename(other_teachers = value) %>%
                  select(-name)
    ) %>%
    bind_cols(
        table_grad_rates(total_grad_teachers, all_teachers) %>%
            rename(total = value) %>%
            select(-name)
    )




# export total grad rates ----

# load existing file
excel_file <- loadWorkbook(here("tables", "03_descr-and-regs-tables.xlsx"))

# pull all data from sheet
excel_table <- read.xlsx(excel_file, sheet = "total_grad_rates") %>% head(-1)

# edit names
remove <- c("Sociodemográficas", 
            "Tipo de establecimiento", 
            "Quintil de Ingresos", 
            "Otras", 
            "Institucionales", 
            "Tipo de Institución", 
            "Tipo de acreditación institucional")
table_total_grad <- 
    table_total_grad %>% mutate(name = excel_table %>% filter(!name %in% remove) %>% pull(name))

# join
excel_table <-
    excel_table %>% select(-2:-4) %>% left_join(y = table_total_grad, by = "name")

# put the data back into the workbook
writeData(excel_file, sheet = "total_grad_rates", excel_table)

# save to disk
saveWorkbook(excel_file, 
             here("tables", "03_descr-and-regs-tables.xlsx"), 
             overwrite = TRUE)