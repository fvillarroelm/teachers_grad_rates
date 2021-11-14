table_grad_rates <- function(grad_data, all_data){
    
    grads <- # had to convert categorical to dummies to count easily.
        grad_data %>% summarise(titulacion_oportuna = n()) %>%
        bind_cols(
                grad_data %>% dummy_cols(select_columns = c("q_nse", 
                                                            "dependencia_cat", 
                                                            "rango_acreditacion_cat", 
                                                            "tipo_inst_3",
                                                            "d_mujer_alu",
                                                            "d_estudia_otra_region",
                                                            "d_sede_RM")) %>% 
                select(matches("dependencia_cat.+"),
                       matches("q_nse.+"),
                       matches("d_estudia_otra_region_Estudiante de.*"),
                       matches("d_mujer_alu_M.+"),
                       matches("tipo_inst_3_U.+"),
                       matches("d_sede_RM_Est.+"),
                       matches("rango_acreditacion_cat.+")) %>%
                summarise_all(~sum(.)) 
        ) %>%
        clean_names()
    
    
    all <- # had to convert categorical to dummies to count easily.
        all_data %>% summarise(titulacion_oportuna = n()) %>%
        bind_cols(
                all_data %>% dummy_cols(select_columns = c("q_nse", 
                                                           "dependencia_cat", 
                                                           "rango_acreditacion_cat", 
                                                           "tipo_inst_3",
                                                           "d_mujer_alu",
                                                           "d_estudia_otra_region",
                                                           "d_sede_RM")) %>% 
                select(matches("dependencia_cat.+"),
                       matches("q_nse.+"),
                       matches("d_estudia_otra_region_Estudiante de.*"),
                       matches("d_mujer_alu_M.+"),
                       matches("tipo_inst_3_U.+"),
                       matches("d_sede_RM_Est.+"),
                       matches("rango_acreditacion_cat.+")) %>%
                summarise_all(~sum(.))
        ) %>%
        clean_names()
    
    # patch: for "rango_acreditacion == "No acreditada", there are no grads sometimes.
    # this causes that df's length are different, which causes an error.
    # the solution is to add the column (= 0) "manually" when the var does not exist.
    # it is not really a "0", it is a boolean (FALSE), which is arithmetically equal to 0 .
    if (length(setdiff(names(all), names(grads))) > 0){
        grads <- grads %>% add_column(!all[setdiff(names(all), names(.))])
    } else{grads <- grads}
    
    #column_total_grad_rates <- 
    
    final_table <-
        grads %>% divide_by(all) %>%
        round(3) %>%
        pivot_longer(everything())
    return(final_table)
}


f_format_margins_table <- function(input){
    
    reg_expr <- "dependencia_cat|q_nse|rango_acreditacion_cat|teaching_area|tipo_inst_3_cat|d_mujer_alu|d_estudia_otra_region"
    
    input %>% select(term, estimate, p.value) %>% 
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
                              TRUE ~ paste0(.))}) %>%
        select(-p.value)
}