#' this script generates the descriptive table 03 of the paper.
if(!require("pacman")){install.packages("pacman")}

# load libraries
pacman::p_load(tidyverse, data.table, janitor, here, haven, magrittr, openxlsx, broom)

# load data
data_raw <- read_dta(here("data", "proc", "working_dataset_cohorte4m_2010.dta"))

data_2 <-
    data_raw %>% filter(entra_ES == 1 & 
                        area_conocimiento_cat != 10 & 
                        is.na(ptje_lect2m_alu) == 0 &
                        is.na(ptje_mate2m_alu) == 0
    ) %>%
            mutate(area_conocimiento_cat = as_factor(area_conocimiento_cat) %>% droplevels(),
                   dependencia_cat = as_factor(dependencia_cat))

data_3y <-
data_2 %>% filter(duracion_total_anios <= 3)

data_4y <-
data_2 %>% filter(duracion_total_anios >= 4)

# table function ----

table <- function(data){
    
    # row names
    row_names <-
        data %>% tabyl(area_conocimiento_cat, dependencia_cat) %>%
        adorn_totals(c("row", "col")) %>%
        pull(area_conocimiento_cat)
    
    
    # denominator: graduates + non-graduates
    grads_and_nongrads <-
        data %>% tabyl(area_conocimiento_cat, dependencia_cat) %>%
        adorn_totals(c("row", "col")) %>%
        select(-area_conocimiento_cat)
    
    # numerator: graduates
    grads <- 
        data %>% filter(titulado_oportuno == 1) %>%
        tabyl(area_conocimiento_cat, dependencia_cat) %>%
        adorn_totals(c("row", "col")) %>% 
        select(-area_conocimiento_cat)
    
    # numerator/denominator (graduation rate by knowledge area)
    table_grads <- round(grads / grads_and_nongrads, 3) %>% 
        mutate(area_conocimiento_cat = row_names) %>%
        relocate(area_conocimiento_cat) %>%
        pivot_longer(2:5, names_to = "school_type", values_to = "value") # to "long" data
    
    # diff pp and ps with mun for each program.
    diff_pp_and_ps_with_mun <-
        map_df(.x = data %$% levels(area_conocimiento_cat),
               .f = ~{data %>% filter(area_conocimiento_cat == .x) %>%
                       lm (titulado_oportuno ~ dependencia_cat, .) %>% 
                       tidy() %>%
                       mutate(p.value = round(p.value, 3),
                              #diff = round(estimate, 3),
                              area_conocimiento_cat = .x,
                              school_type = term %>% str_remove("dependencia_cat")) %>%
                       filter(!str_detect(school_type, "Intercept")) %>%
                       select(area_conocimiento_cat, school_type, p.value) # excluded diff
               }
        ) %>%
        
        bind_rows(
            # total row!
            data %>% lm (titulado_oportuno ~ dependencia_cat, .) %>% 
                tidy() %>%
                mutate(p.value = round(p.value, 3),
                       #diff = round(estimate, 3),
                       area_conocimiento_cat = "Total",
                       school_type = term %>% str_remove("dependencia_cat")) %>%
                filter(!str_detect(school_type, "Intercept")) %>%
                select(area_conocimiento_cat, school_type, p.value) #excluded diff
        )
    
    
    # final table
    final_table <- table_grads %>% left_join(diff_pp_and_ps_with_mun, 
                                             by = c("area_conocimiento_cat", "school_type")) %>%
        mutate(value = as.character(value*100) %>% str_replace_all(., "\\.", ",")) %>%
        mutate(value = case_when(p.value > 0.05 & p.value <= 0.1 ~ paste0(value, "% *"),
                                 p.value > 0.01 & p.value <= 0.05 ~ paste0(value, "% **"),
                                 p.value <= 0.01 ~ paste0(value, "% ***"),
                                 TRUE ~ paste0(value, "%"))) %>%
        select(-p.value) %>%
        pivot_wider(names_from = "school_type", values_from = "value")
    
    return(final_table)
    
}


# tables ----

table_3y <- table(data_3y)

table_4y <- table(data_4y) %>% select(-area_conocimiento_cat)

final_table <- table_3y %>% bind_cols(table_4y)

# export ----

# load existing file
excel_file <- loadWorkbook(here("results", "tables", "descriptive","03_descriptive_table03_in-time-grad-rates.xlsx"))

# pull all data from sheet 1
excel_table <- read.xlsx(excel_file, sheet=1)

# set colnames to final_table (which has the same structure as excel_file, except for the colnames)
col_names <- excel_table %>% names()
excel_table <- final_table %>% set_colnames(col_names)

# put the data back into the workbook
writeData(excel_file, sheet=1, excel_table)

# save to disk
saveWorkbook(excel_file, 
             here("results", "tables", "descriptive","03_descriptive_table03_in-time-grad-rates.xlsx"), 
             overwrite = TRUE)
