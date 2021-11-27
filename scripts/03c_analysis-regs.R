#' this script generates the probit margins summary table.
rm(list = ls())
if(!require("pacman")){install.packages("pacman")}

# load libraries
pacman::p_load(tidyverse, data.table, janitor, here, magrittr, openxlsx, broom, margins)

# load function
source(here("scripts", "00_aux_functions.R"))

# load data
teachers_data <- fread(here("data", "proc", "working_dataset_teachers_cohorte4m_2010.csv"))

# there are 6 students enrolled in "Pedagogia en Ingles plan comun", a 2-year program.
# I will include them in the regression in the meantime.
#teachers_data %>% count(duracion_total_anios)

# there are 68 students in a non-accredited program.
#teachers_data %>% count(rango_acreditacion_cat)

# polish variables
teachers_data <- teachers_data %>% mutate(
                                d_sede_RM = ifelse(d_sede_RM == "Estudia en RM", 1, 0),
                                d_phys_ed = ifelse(teaching_area == "phys ed", 1, 0 ),
                                d_estudia_otra_region = d_estudia_otra_region %>% str_replace("Ã³", "ó") %>%
                                                                            as.factor() %>% 
                                                                            relevel("Estudiante no de 'región'"),
                                rango_acreditacion_cat = rango_acreditacion_cat %>% str_replace("Ã³", "ó") %>%
                                                                            str_replace("Ã±", "ñ") %>%
                                                                            as.factor() %>% 
                                                                            relevel("No Acreditada")
                                ) 

# variables for regression
df_logit <- teachers_data %>% select(titulado,
                                     titulado_oportuno,
                                     d_phys_ed,
                                     d_mujer_alu, 
                                     d_sede_RM, 
                                     d_estudia_otra_region, 
                                     dependencia_cat,
                                     q_nse,
                                     rango_acreditacion_cat,
                                     tipo_inst_3_cat,
                                     matches("ptje_lect"),
                                     matches("ptje_mat"),
                                     nem)



# logit
logit_grad_on_time <- glm(titulado_oportuno ~ ., data = df_logit %>% select(-titulado), family = binomial(link = "logit"))

logit_grad_total <- glm(titulado ~ ., data = df_logit %>% select(-titulado_oportuno), family = binomial(link = "logit"))

# margins summary table
sum_margins_grad_on_time <- tidy(margins(logit_grad_on_time))

sum_margins_grad_total <- tidy(margins(logit_grad_total))

# format table
margins_table_grad_on_time <- f_format_margins_table(sum_margins_grad_on_time)

margins_table_grad_total <- f_format_margins_table(sum_margins_grad_total)

# bind tables
final_table <- margins_table_grad_on_time %>% bind_cols(margins_table_grad_total %>% select(-1)) %>%
    rename("on_time" = "estimate...2",
           "total" = "estimate...3") %>%
    bind_rows(data.frame(term = "Observaciones", 
                         on_time = nrow(df_logit) %>% as.character(), 
                         total = nrow(df_logit) %>% as.character())
              )

# export table ----

# load existing file
excel_file <- loadWorkbook(here("tables", "03_descr-and-regs-tables.xlsx"))

# pull all data from sheet
excel_table <- read.xlsx(excel_file, sheet = "logit_reg") %>% select(-1) %>% drop_na()

# set col names
final_table <- 
final_table %>% set_colnames(names(excel_table))

# join
excel_table <-
    excel_table %>% select(-2:-3) %>% left_join(y = final_table, by = "term")

# put the data back into the workbook
writeData(excel_file, sheet = "logit_reg", excel_table, startCol = 2)

# save to disk
saveWorkbook(excel_file, 
             here("tables", "03_descr-and-regs-tables.xlsx"), 
             overwrite = TRUE)