# Here we implement equations defined in: Warren et al. "Transfer conductance in
# second growth Douglas-fir (Pseudotsuga menziesii (Mirb.)Franco) canopies."
# Plant, Cell & Environment 26, 1215–1227 (2003).

calculate_c3_limitations_warren <- function(
    exdf_obj,
    Wj_coef_C = 4.0,
    Wj_coef_Gamma_star = 8.0,
    ca_column_name = 'Ca',
    cc_column_name = 'Cc',
    ci_column_name = 'Ci',
    gamma_star_norm_column_name = 'Gamma_star_norm',
    j_norm_column_name = 'J_norm',
    kc_norm_column_name = 'Kc_norm',
    ko_norm_column_name = 'Ko_norm',
    oxygen_column_name = 'oxygen',
    rl_norm_column_name = 'RL_norm',
    total_pressure_column_name = 'total_pressure',
    tp_norm_column_name = 'Tp_norm',
    vcmax_norm_column_name = 'Vcmax_norm',
    hard_constraints = 0,
    ...
)
{
    # Check inputs
    if (!is.exdf(exdf_obj)) {
        stop('calculate_c3_limitations_warren requires an exdf object')
    }

    # Make sure the required variables are defined and have the correct units.
    required_variables <- list()
    required_variables[['alpha_g']]                   <- unit_dictionary('alpha_g')
    required_variables[['alpha_old']]                 <- unit_dictionary('alpha_old')
    required_variables[['alpha_s']]                   <- unit_dictionary('alpha_s')
    required_variables[['alpha_t']]                   <- unit_dictionary('alpha_t')
    required_variables[['Gamma_star_at_25']]          <- unit_dictionary('Gamma_star_at_25')
    required_variables[['J_at_25']]                   <- unit_dictionary('J_at_25')
    required_variables[['Kc_at_25']]                  <- unit_dictionary('Kc_at_25')
    required_variables[['Ko_at_25']]                  <- unit_dictionary('Ko_at_25')
    required_variables[['RL_at_25']]                  <- unit_dictionary('RL_at_25')
    required_variables[['Tp_at_25']]                  <- unit_dictionary('Tp_at_25')
    required_variables[['Vcmax_at_25']]               <- unit_dictionary('Vcmax_at_25')
    required_variables[[ca_column_name]]              <- unit_dictionary('Ca')
    required_variables[[cc_column_name]]              <- unit_dictionary('Cc')
    required_variables[[ci_column_name]]              <- unit_dictionary('Ci')
    required_variables[[gamma_star_norm_column_name]] <- unit_dictionary('Gamma_star_norm')
    required_variables[[j_norm_column_name]]          <- unit_dictionary('J_norm')
    required_variables[[kc_norm_column_name]]         <- unit_dictionary('Kc_norm')
    required_variables[[ko_norm_column_name]]         <- unit_dictionary('Ko_norm')
    required_variables[[oxygen_column_name]]          <- unit_dictionary('oxygen')
    required_variables[[rl_norm_column_name]]         <- unit_dictionary('RL_norm')
    required_variables[[total_pressure_column_name]]  <- unit_dictionary('total_pressure')
    required_variables[[tp_norm_column_name]]         <- unit_dictionary('Tp_norm')
    required_variables[[vcmax_norm_column_name]]      <- unit_dictionary('Vcmax_norm')

    # Don't throw an error if some columns are all NA
    check_required_variables(exdf_obj, required_variables, check_NA = FALSE)

    # Extract key variables to make the following equations simpler
    Ca <- exdf_obj[, ca_column_name]    # micromol / mol
    Cc <- exdf_obj[, cc_column_name]    # micromol / mol
    Ci <- exdf_obj[, ci_column_name]    # micromol / mol

    # If gsc is as measured and gmc is infinite, we have the measured drawdown
    # across the stomata, but no drawdown across the mesophyll:
    #  Cc_inf_gmc = Ca - (Ca - Ci) - 0 = Ci
    exdf_obj[, 'Cc_inf_gmc'] <- Ci # micromol / mol

    # If gsc is infinite and gmc is as measured, we have no drawdown across the
    # stomata, but the measured drawdown across the mesophyll:
    #  Cc_inf_gsc = Ca - 0 - (Ci - Cc) = Ca - Ci + Cc
    exdf_obj[, 'Cc_inf_gsc'] <- Ca - Ci + Cc # micromol / mol

    # Document the columns that were just added
    exdf_obj <- document_variables(
        exdf_obj,
        c('calculate_c3_limitations_warren', 'Cc_inf_gmc', 'micromol mol^(-1)'),
        c('calculate_c3_limitations_warren', 'Cc_inf_gsc', 'micromol mol^(-1)')
    )

    # Make a helping function for calculating assimilation rates for different
    # Cc column names
    an_from_cc <- function(cc_name) {
        calculate_c3_assimilation(
            exdf_obj,
            '', # alpha_g
            '', # alpha_old
            '', # alpha_s
            '', # alpha_t
            '', # Gamma_star_at_25
            '', # J_at_25
            '', # Kc_at_25
            '', # Ko_at_25
            '', # RL_at_25
            '', # Tp_at_25
            '', # Vcmax_at_25
            Wj_coef_C = Wj_coef_C,
            Wj_coef_Gamma_star = Wj_coef_Gamma_star,
            cc_column_name = cc_name,
            gamma_star_norm_column_name = gamma_star_norm_column_name,
            j_norm_column_name = j_norm_column_name,
            kc_norm_column_name = kc_norm_column_name,
            ko_norm_column_name = ko_norm_column_name,
            oxygen_column_name = oxygen_column_name,
            rl_norm_column_name = rl_norm_column_name,
            total_pressure_column_name = total_pressure_column_name,
            tp_norm_column_name = tp_norm_column_name,
            vcmax_norm_column_name = vcmax_norm_column_name,
            hard_constraints = hard_constraints,
            perform_checks = FALSE,
            return_table = TRUE,
            ...
        )[, 'An']
    }

    # Calculate the net assimilation rate assuming gmc and gsc are as measured
    An <- an_from_cc(cc_column_name) # micromol / m^2 / s

    # Calculate the net assimilation rate assuming gmc is infinite and gsc is as
    # measured
    exdf_obj[, 'An_inf_gmc'] <- an_from_cc('Cc_inf_gmc') # micromol / m^2 / s

    # Calculate the net assimilation rate assuming gmc is as measured and gsc is
    # infinite
    exdf_obj[, 'An_inf_gsc'] <- an_from_cc('Cc_inf_gsc') # micromol / m^2 / s

    # Calculate the limitations using Equations 10 and 11
    exdf_obj[, 'lm_warren'] <- c3_limitation_warren(exdf_obj[, 'An_inf_gmc'], An) # dimensionless
    exdf_obj[, 'ls_warren'] <- c3_limitation_warren(exdf_obj[, 'An_inf_gsc'], An) # dimensionless

    # Document the columns that were just added and return the exdf
    document_variables(
        exdf_obj,
        c('calculate_c3_limitations_warren', 'An_inf_gmc', 'micromol m^(-2) s^(-1)'),
        c('calculate_c3_limitations_warren', 'An_inf_gsc', 'micromol m^(-2) s^(-1)'),
        c('calculate_c3_limitations_warren', 'lm_warren',  'dimensionless'),
        c('calculate_c3_limitations_warren', 'ls_warren',  'dimensionless')
    )
}

# Compares assimilation rates assuming an infinite conductance against a base
# assimilation rate
c3_limitation_warren <- function(An_inf, An_base) {
    (An_inf - An_base) / An_inf
}
