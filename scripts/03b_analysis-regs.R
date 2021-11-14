#' this script generates the descriptive table 02 of the paper.
rm(list = ls())
if(!require("pacman")){install.packages("pacman")}

# load libraries
pacman::p_load(tidyverse, data.table, janitor, here, magrittr, openxlsx, broom, margins)

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
reg_expr <- "dependencia_cat|q_nse|rango_acreditacion_cat|teaching_area|tipo_inst_3_cat|d_mujer_alu|d_estudia_otra_region"

margins_table_grad_on_time <- 
    sum_margins_grad_on_time %>% select(term, estimate, p.value) %>% 
                          mutate(term = term %>% str_remove(reg_expr) %>% 
                                                     recode("nem" = "NEM",
                                                            "ptje_lect2m_alu" = "Ptje. SIMCE Lect.",
                                                            "ptje_mate2m_alu" = "Ptje. SIMCE Mat.",
                                                            "d_sede_RM" = "Universidad de RM",
                                                            "d_phys_ed" = "Educ. Física"),
                                 estimate = estimate %>% round(4) %>% 
                                        format(., scientific = F) %>% 
                                        as.character() %>% 
                                        {case_when(p.value > 0.05 & p.value <= 0.1 ~ paste0(., "*"),
                                                  p.value > 0.01 & p.value <= 0.05 ~ paste0(., "**"),
                                                  p.value <= 0.01 ~ paste0(., "***"),
                                                  TRUE ~ paste0(.))})

margins_table_grad_total <- 
    sum_margins_grad_total %>% select(term, estimate, p.value) %>% 
    mutate(term = term %>% str_remove(reg_expr) %>% 
               recode("nem" = "NEM",
                      "ptje_lect2m_alu" = "Ptje. SIMCE Lect.",
                      "ptje_mate2m_alu" = "Ptje. SIMCE Mat.",
                      "d_sede_RM" = "Universidad de RM",
                      "d_phys_ed" = "Educ. Física"),
           estimate = estimate %>% round(4) %>% 
               format(., scientific = F) %>% 
               as.character() %>% 
               {case_when(p.value > 0.05 & p.value <= 0.1 ~ paste0(., "*"),
                          p.value > 0.01 & p.value <= 0.05 ~ paste0(., "**"),
                          p.value <= 0.01 ~ paste0(., "***"),
                          TRUE ~ paste0(.))})


# export on-time grad rates ----

# load existing file
excel_file <- loadWorkbook(here("tables", "03_descr-and-regs-tables.xlsx"))

# pull all data from sheet
excel_table <- read.xlsx(excel_file, sheet = "logit_reg") %>% select(-1)

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
             here("tables", "03_descr_tab01_total-and-on-time-grad-rates.xlsx"), 
             overwrite = TRUE)