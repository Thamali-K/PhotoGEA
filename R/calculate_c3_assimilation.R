calculate_c3_assimilation <- function(
    data_table,
    alpha_g,          # dimensionless      (this value is sometimes being fitted)
    alpha_old,        # dimensionless      (typically this value is being fitted)
    alpha_s,          # dimensionless      (this value is sometimes being fitted)
    alpha_t,          # dimensionless      (this value is sometimes being fitted)
    Gamma_star_at_25, # micromol / mol     (at 25 degrees C; this value is sometimes being fitted)
    J_at_25,          # micromol / m^2 / s (at 25 degrees C; typically this value is being fitted)
    Kc_at_25,         # micromol / mol     (at 25 degrees C; this value is sometimes being fitted)
    Ko_at_25,         # mmol / mol         (at 25 degrees C; this value is sometimes being fitted)
    RL_at_25,         # micromol / m^2 / s (at 25 degrees C; typically this value is being fitted)
    Tp_at_25,         # micromol / m^2 / s (at 25 degrees C; typically this value is being fitted)
    Vcmax_at_25,      # micromol / m^2 / s (at 25 degrees C; typically this value is being fitted)
    Wj_coef_C = 4.0,
    Wj_coef_Gamma_star = 8.0,
    cc_column_name = 'Cc',
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
    perform_checks = TRUE,
    return_table = TRUE,
    ...
)
{
    optional_args <- list(...)

    potential_optional_args <- c(
        'consider_depletion',
        'TPU_threshold',
        'use_FRL',
        'use_min_A'
    )

    check_optional_arguments(optional_args, potential_optional_args)

    consider_depletion <- get_optional_argument(optional_args, 'consider_depletion', FALSE)
    TPU_threshold      <- get_optional_argument(optional_args, 'TPU_threshold',      NULL)
    use_FRL            <- get_optional_argument(optional_args, 'use_FRL',            FALSE)
    use_min_A          <- get_optional_argument(optional_args, 'use_min_A',          FALSE)

    if (perform_checks) {
        # Make sure the required variables are defined and have the correct units
        required_variables <- list()
        required_variables[[cc_column_name]]              <- unit_dictionary('Cc')
        required_variables[[gamma_star_norm_column_name]] <- unit_dictionary('Gamma_star_norm')
        required_variables[[j_norm_column_name]]          <- unit_dictionary('J_norm')
        required_variables[[kc_norm_column_name]]         <- unit_dictionary('Kc_norm')
        required_variables[[ko_norm_column_name]]         <- unit_dictionary('Ko_norm')
        required_variables[[oxygen_column_name]]          <- unit_dictionary('oxygen')
        required_variables[[rl_norm_column_name]]         <- unit_dictionary('RL_norm')
        required_variables[[total_pressure_column_name]]  <- unit_dictionary('total_pressure')
        required_variables[[tp_norm_column_name]]         <- unit_dictionary('Tp_norm')
        required_variables[[vcmax_norm_column_name]]      <- unit_dictionary('Vcmax_norm')

        flexible_param <- list(
            alpha_g = alpha_g,
            alpha_old = alpha_old,
            alpha_s = alpha_s,
            alpha_t = alpha_t,
            Gamma_star_at_25 = Gamma_star_at_25,
            J_at_25 = J_at_25,
            Kc_at_25 = Kc_at_25,
            Ko_at_25 = Ko_at_25,
            RL_at_25 = RL_at_25,
            Tp_at_25 = Tp_at_25,
            Vcmax_at_25 = Vcmax_at_25
        )

        required_variables <-
            require_flexible_param(required_variables, flexible_param)

        check_required_variables(data_table, required_variables)
    }

    # Retrieve values of flexible parameters as necessary
    if (!value_set(alpha_g))          {alpha_g          <- data_table[, 'alpha_g']}
    if (!value_set(alpha_old))        {alpha_old        <- data_table[, 'alpha_old']}
    if (!value_set(alpha_s))          {alpha_s          <- data_table[, 'alpha_s']}
    if (!value_set(alpha_t))          {alpha_t          <- data_table[, 'alpha_t']}
    if (!value_set(Gamma_star_at_25)) {Gamma_star_at_25 <- data_table[, 'Gamma_star_at_25']}
    if (!value_set(J_at_25))          {J_at_25          <- data_table[, 'J_at_25']}
    if (!value_set(Kc_at_25))         {Kc_at_25         <- data_table[, 'Kc_at_25']}
    if (!value_set(Ko_at_25))         {Ko_at_25         <- data_table[, 'Ko_at_25']}
    if (!value_set(RL_at_25))         {RL_at_25         <- data_table[, 'RL_at_25']}
    if (!value_set(Tp_at_25))         {Tp_at_25         <- data_table[, 'Tp_at_25']}
    if (!value_set(Vcmax_at_25))      {Vcmax_at_25      <- data_table[, 'Vcmax_at_25']}

    # Extract a few columns from the exdf object to make the equations easier to
    # read, converting units as necessary
    pressure <- data_table[, total_pressure_column_name] # bar

    oxygen <- data_table[, oxygen_column_name] # percent
    POc <- oxygen * pressure * 1e4             # microbar

    Cc <- data_table[, cc_column_name] # micromol / mol
    PCc <- Cc * pressure               # microbar

    Gamma_star_tl <- Gamma_star_at_25 * data_table[, gamma_star_norm_column_name]   # micromol / mol
    J_tl          <- J_at_25 * data_table[, j_norm_column_name]                     # micromol / m^2 / s
    Kc_tl         <- Kc_at_25 * data_table[, kc_norm_column_name] * pressure        # microbar
    Ko_tl         <- Ko_at_25 * data_table[, ko_norm_column_name] * pressure * 1000 # microbar
    RL_tl         <- RL_at_25 * data_table[, rl_norm_column_name]                   # micromol / m^2 / s
    Tp_tl         <- Tp_at_25 * data_table[, tp_norm_column_name]                   # micromol / m^2 / s
    Vcmax_tl      <- Vcmax_at_25 * data_table[, vcmax_norm_column_name]             # micromol / m^2 / s

    # Make sure key inputs have reasonable values
    msg <- character()

    # Always check parameters that cannot be fit, and make sure we are not
    # mixing models
    mixed_alpha <- any(alpha_old > 0, na.rm = TRUE) &&
        (any(alpha_g > 0, na.rm = TRUE) || any(alpha_s > 0, na.rm = TRUE) || any(alpha_t > 0, na.rm = TRUE))

    mixed_j_coeff <- (abs(Wj_coef_C - 4) > 1e-10 || abs(Wj_coef_Gamma_star - 8) > 1e-10) &&
        (any(alpha_g > 0, na.rm = TRUE) || any(alpha_s > 0, na.rm = TRUE) || any(alpha_t > 0, na.rm = TRUE))

    if (any(oxygen < 0, na.rm = TRUE))   {msg <- append(msg, 'oxygen must be >= 0')}
    if (any(pressure < 0, na.rm = TRUE)) {msg <- append(msg, 'pressure must be >= 0')}
    if (mixed_alpha)                     {msg <- append(msg, 'Cannot specify nonzero alpha_old and nonzero alpha_g / alpha_s / alpha_t')}
    if (mixed_j_coeff)                   {msg <- append(msg, 'Wj_coef_C must be 4 and Wj_coef_Gamma_star must be 8 when alpha_g / alpha_s / alpha_t are nonzero')}

    # Optionally check whether Cc is reasonable
    if (hard_constraints >= 1) {
        if (any(Cc < 0, na.rm = TRUE)) {msg <- append(msg, 'Cc must be >= 0')}
    }

    # Optionally check reasonableness of parameters that can be fit
    if (hard_constraints >= 2) {
        if (any(alpha_g < 0 | alpha_g > 1, na.rm = TRUE))                   {msg <- append(msg, 'alpha_g must be >= 0 and <= 1')}
        if (any(alpha_old < 0 | alpha_old > 1, na.rm = TRUE))               {msg <- append(msg, 'alpha_old must be >= 0 and <= 1')}
        if (any(alpha_s < 0 | alpha_s > 1, na.rm = TRUE))                   {msg <- append(msg, 'alpha_s must be >= 0 and <= 1')}
        if (any(alpha_t < 0 | alpha_t > 1, na.rm = TRUE))                   {msg <- append(msg, 'alpha_t must be >= 0 and <= 1')}
        if (any(alpha_g + 2 * alpha_t + 4 * alpha_s / 3 > 1, na.rm = TRUE)) {msg <- append(msg, 'alpha_g + 2 * alpha_t + 4 * alpha_s / 3 must be <= 1')}
        if (any(Gamma_star_at_25 < 0, na.rm = TRUE))                        {msg <- append(msg, 'Gamma_star_at_25 must be >= 0')}
        if (any(J_at_25 < 0, na.rm = TRUE))                                 {msg <- append(msg, 'J_at_25 must be >= 0')}
        if (any(Kc_at_25 < 0, na.rm = TRUE))                                {msg <- append(msg, 'Kc_at_25 must be >= 0')}
        if (any(Ko_at_25 < 0, na.rm = TRUE))                                {msg <- append(msg, 'Ko_at_25 must be >= 0')}
        if (any(RL_at_25 < 0, na.rm = TRUE))                                {msg <- append(msg, 'RL_at_25 must be >= 0')}
        if (any(Tp_at_25 < 0, na.rm = TRUE))                                {msg <- append(msg, 'Tp_at_25 must be >= 0')}
        if (any(Vcmax_at_25 < 0, na.rm = TRUE))                             {msg <- append(msg, 'Vcmax_at_25 must be >= 0')}
    }

    msg <- paste(msg, collapse = '. ')

    # We only bypass these checks if !perform_checks && return_table
    if (perform_checks || !return_table) {
        if (msg != '') {
            stop(msg)
        }
    }

    # Get the effective value of Gamma_star
    Gamma_star_agt <- (1 - alpha_g + 2 * alpha_t) * Gamma_star_tl * pressure # microbar

    # Rubisco-limited carboxylation (micromol / m^2 / s)
    Wc <- PCc * Vcmax_tl / (PCc + Kc_tl * (1.0 + POc / Ko_tl))

    # RuBP-regeneration-limited carboxylation (micromol / m^2 / s)
    Wj <- PCc * J_tl / (PCc * Wj_coef_C + Gamma_star_agt * (Wj_coef_Gamma_star + 16 * alpha_g - 8 * alpha_t + 8 * alpha_s))

    # TPU-limited carboxylation (micromol / m^2 / s)
    Wp <- PCc * 3 * Tp_tl / (PCc - Gamma_star_agt * (1 + 3 * alpha_old + 3 * alpha_g + 6 * alpha_t + 4 * alpha_s))

    # Apply a TPU threshold
    if (is.null(TPU_threshold)) {
        # Use the threshold determined from biochemistry
        Wp[PCc <= Gamma_star_agt * (1 + 3 * alpha_old + 3 * alpha_g + 6 * alpha_t + 4 * alpha_s)] <- Inf
    } else {
        # Use an arbitrary threshold
        Wp[PCc <= TPU_threshold] <- Inf
    }

    # Carboxylation rate limited by Rubisco deactivation or RuBP depletion
    # (micromol / m^2 / s).
    Wd <- rep_len(0, length(PCc))
    Wd[PCc > Gamma_star_agt] <- Inf

    # Overall carboxylation rate
    Vc <- if (consider_depletion) {
        pmin(Wc, Wj, Wp, Wd, na.rm = TRUE)
    } else {
        pmin(Wc, Wj, Wp, na.rm = TRUE)
    }

    # Calculate corresponding net CO2 assimilations by accounting for
    # photorespiration and non-photorespiratory CO2 release
    photo_resp_factor <- 1.0 - Gamma_star_agt / PCc # dimensionless
    Ac <- photo_resp_factor * Wc - RL_tl
    Aj <- photo_resp_factor * Wj - RL_tl
    Ap <- photo_resp_factor * Wp - RL_tl
    Ad <- photo_resp_factor * Wd - RL_tl
    An <- photo_resp_factor * Vc - RL_tl

    # Possibly use the pseudo-FvCB model or one of its variants
    if (use_min_A) {
        # Recalculate Ap (micromol / m^2 / s)
        Ap <- (PCc - Gamma_star_agt) * 3 * Tp_tl /
            (PCc - Gamma_star_agt * (1 + 3 * alpha_old + 3 * alpha_g + 6 * alpha_t + 4 * alpha_s)) - RL_tl

        # Apply a TPU threshold
        if (is.null(TPU_threshold)) {
            # Use the threshold determined from biochemistry
            Ap[PCc <= Gamma_star_agt * (1 + 3 * alpha_old + 3 * alpha_g + 6 * alpha_t + 4 * alpha_s)] <- Inf
        } else {
            # Use an arbitrary threshold
            Ap[PCc <= TPU_threshold] <- Inf
        }

        # Possibly force Rubisco limitations below Gamma_star
        if (use_FRL) {
            Aj[PCc < Gamma_star_agt] <- Inf
            Ap[PCc < Gamma_star_agt] <- Inf
        }

        # Get the minimum assimilation rate (micromol / m^2 / s)
        An <- pmin(Ac, Aj, Ap, na.rm = TRUE)

        # Recalculate the carboxylation rate (micromol / m^2 / s)
        Vc <- (An + RL_tl) / photo_resp_factor
    }

    if (return_table) {
        # Add the new columns to the input table and make sure units are
        # included

        optional_arg_string <-
            paste(paste(names(optional_args), optional_args, sep = ' = '), collapse = ', ')

        output <- data.frame(
            alpha_g = alpha_g,
            alpha_old = alpha_old,
            alpha_s = alpha_s,
            alpha_t = alpha_t,
            Gamma_star_at_25 = Gamma_star_at_25,
            J_at_25 = J_at_25,
            Kc_at_25 = Kc_at_25,
            Ko_at_25 = Ko_at_25,
            RL_at_25 = RL_at_25,
            Tp_at_25 = Tp_at_25,
            Vcmax_at_25 = Vcmax_at_25,
            Gamma_star_agt = Gamma_star_agt,
            Gamma_star_tl = Gamma_star_tl,
            J_tl = J_tl,
            Kc_tl = Kc_tl,
            Ko_tl = Ko_tl,
            RL_tl = RL_tl,
            Tp_tl = Tp_tl,
            Vcmax_tl = Vcmax_tl,
            Ac = Ac,
            Aj = Aj,
            Ap = Ap,
            Ad = Ad,
            An = An,
            Wc = Wc,
            Wj = Wj,
            Wp = Wp,
            Wd = Wd,
            Vc = Vc,
            Wj_coef_C = Wj_coef_C,
            Wj_coef_Gamma_star = Wj_coef_Gamma_star,
            c3_assimilation_msg = msg,
            c3_optional_arguments = optional_arg_string,
            stringsAsFactors = FALSE
        )

        if (is.exdf(data_table)) {
            output <- exdf(output)
        }

        document_variables(
            output,
            c('calculate_c3_assimilation', 'alpha_g',               'dimensionless'),
            c('calculate_c3_assimilation', 'alpha_old',             'dimensionless'),
            c('calculate_c3_assimilation', 'alpha_s',               'dimensionless'),
            c('calculate_c3_assimilation', 'alpha_t',               'dimensionless'),
            c('calculate_c3_assimilation', 'Gamma_star_at_25',      'micromol mol^(-1)'),
            c('calculate_c3_assimilation', 'J_at_25',               'micromol m^(-2) s^(-1)'),
            c('calculate_c3_assimilation', 'Kc_at_25',              'micromol mol^(-1)'),
            c('calculate_c3_assimilation', 'Ko_at_25',              'mmol mol^(-1)'),
            c('calculate_c3_assimilation', 'RL_at_25',              'micromol m^(-2) s^(-1)'),
            c('calculate_c3_assimilation', 'Tp_at_25',              'micromol m^(-2) s^(-1)'),
            c('calculate_c3_assimilation', 'Vcmax_at_25',           'micromol m^(-2) s^(-1)'),
            c('calculate_c3_assimilation', 'Gamma_star_agt',        'microbar'),
            c('calculate_c3_assimilation', 'Gamma_star_tl',         'micromol mol^(-1)'),
            c('calculate_c3_assimilation', 'J_tl',                  'micromol m^(-2) s^(-1)'),
            c('calculate_c3_assimilation', 'Kc_tl',                 'micromol mol^(-1)'),
            c('calculate_c3_assimilation', 'Ko_tl',                 'mmol mol^(-1)'),
            c('calculate_c3_assimilation', 'RL_tl',                 'micromol m^(-2) s^(-1)'),
            c('calculate_c3_assimilation', 'Tp_tl',                 'micromol m^(-2) s^(-1)'),
            c('calculate_c3_assimilation', 'Vcmax_tl',              'micromol m^(-2) s^(-1)'),
            c('calculate_c3_assimilation', 'Ac',                    'micromol m^(-2) s^(-1)'),
            c('calculate_c3_assimilation', 'Aj',                    'micromol m^(-2) s^(-1)'),
            c('calculate_c3_assimilation', 'Ap',                    'micromol m^(-2) s^(-1)'),
            c('calculate_c3_assimilation', 'Ad',                    'micromol m^(-2) s^(-1)'),
            c('calculate_c3_assimilation', 'An',                    'micromol m^(-2) s^(-1)'),
            c('calculate_c3_assimilation', 'Wc',                    'micromol m^(-2) s^(-1)'),
            c('calculate_c3_assimilation', 'Wj',                    'micromol m^(-2) s^(-1)'),
            c('calculate_c3_assimilation', 'Wp',                    'micromol m^(-2) s^(-1)'),
            c('calculate_c3_assimilation', 'Wd',                    'micromol m^(-2) s^(-1)'),
            c('calculate_c3_assimilation', 'Vc',                    'micromol m^(-2) s^(-1)'),
            c('calculate_c3_assimilation', 'Wj_coef_C',             'dimensionless'),
            c('calculate_c3_assimilation', 'Wj_coef_Gamma_star',    'dimensionless'),
            c('calculate_c3_assimilation', 'c3_optional_arguments', ''),
            c('calculate_c3_assimilation', 'c3_assimilation_msg',   '')
        )
    } else {
        return(list(An = An, Ac = Ac, Aj = Aj, Ap = Ap, Wc = Wc, Wj = Wj, J_tl = J_tl))
    }
}
