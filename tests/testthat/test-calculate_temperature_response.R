# Define a simple exdf object
test_exdf <- exdf(
    data.frame(
        TleafCnd = c(20, 30),
        not_used = NA
    ),
    units = data.frame(
        TleafCnd = 'degrees C',
        not_used = '',
        stringsAsFactors = FALSE
    )
)

# Choose test tolerance
TOLERANCE <- 1e-4

test_that('temperature response is calculated properly', {
    tr_res <- calculate_temperature_response(
        test_exdf,
        list(
          Kc = list(type = 'Arrhenius', c = 38.05, Ea = 79.43, units = 'micromol mol^(-1)'),
          Jmax = list(type = 'Gaussian', optimum_rate = 1, t_opt = 43, sigma = 16, units = 'micromol m^(-2) s^(-1)'),
          Tp_norm = list(type = 'Johnson', c = 21.46, Ha = 53.1, Hd = 201.8, S = 0.65, units = 'normalized to Tp at 25 degrees C'),
          theta = list(type = 'Polynomial', coef = c(0.352, 0.022, -3.4e-4), units = 'dimensionless')
        )
    )

    expect_equal(
        as.numeric(tr_res[, 'Kc']),
        c(235.5536, 690.1576),
        tolerance = TOLERANCE
    )

    expect_equal(
        as.numeric(tr_res[, 'Jmax']),
        c(0.1266401, 0.5167706),
        tolerance = TOLERANCE
    )

    expect_equal(
        as.numeric(tr_res[, 'Tp_norm']),
        c(0.7150624, 1.2863480),
        tolerance = TOLERANCE
    )

    expect_equal(
        as.numeric(tr_res[, 'theta']),
        c(0.656, 0.706),
        tolerance = TOLERANCE
    )
})

test_that('mistakes are caught', {
    expect_error(
        calculate_temperature_response(
            test_exdf,
            list(Kc = list(c = 38.05))
        ),
        'Temperature response parameter set named `Kc` does not specify a `type` value'
    )

    expect_error(
        calculate_temperature_response(
            test_exdf,
            list(Kc = list(type = 'bad_type', units = 'micromol mol^(-1)'))
        ),
        'Temperature response parameter set named `Kc` specifies an unsupported `type` value: `bad_type`. The available options are: arrhenius, gaussian, johnson, and polynomial.'
    )

    expect_error(
        calculate_temperature_response(
            test_exdf,
            list(Kc = list(type = 'Arrhenius', c = 38.05, Ea = 79.43))
        ),
        'Temperature response parameter set named `Kc` does not specify a `units` value'
    )

    expect_error(
        calculate_temperature_response(
            test_exdf,
            list(Kc = list(type = 'Arrhenius', c = 38.05, units = 'micromol mol^(-1)'))
        ),
        'Arrhenius parameter named `Kc` has the following elements: type, c, units; elements named `c`, `Ea`, and `units` are required.'
    )

    expect_error(
        calculate_temperature_response(
            test_exdf,
            list(Jmax = list(type = 'Gaussian', t_opt = 43, units = 'micromol m^(-2) s^(-1)'))
        ),
        'Gaussian parameter named `Jmax` has the following elements: type, t_opt, units; elements named `optimum_rate`, `t_opt`, `sigma`, and `units` are required.'
    )

    expect_error(
        calculate_temperature_response(
            test_exdf,
            list(Tp_norm = list(type = 'Johnson', Ha = 53.1, Hd = 201.8, S = 0.65, units = 'normalized to Tp at 25 degrees C'))
        ),
        'Johnson parameter named `Tp_norm` has the following elements: type, Ha, Hd, S, units; elements named `c`, `Ha`, `Hd`, `S`, and `units` are required.'
    )

    expect_error(
        calculate_temperature_response(
            test_exdf,
            list(theta = list(type = 'Polynomial', units = 'dimensionless'))
        ),
        'Polynomial parameter named `theta` has the following elements: type, units; elements named `coef` and `units` are required.'
    )
})
