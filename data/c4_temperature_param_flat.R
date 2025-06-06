c4_temperature_param_flat <- list(
    Vcmax_norm = list(type = 'Arrhenius', c = 0,               Ea = 0, units = 'normalized to Vcmax at 25 degrees C'),
    Vpmax_norm = list(type = 'Arrhenius', c = 0,               Ea = 0, units = 'normalized to Vpmax at 25 degrees C'),
    RL_norm =    list(type = 'Arrhenius', c = 0,               Ea = 0, units = 'normalized to RL at 25 degrees C'),
    Kc =         list(type = 'Arrhenius', c = log(1210),       Ea = 0, units = 'microbar'),
    Ko =         list(type = 'Arrhenius', c = log(292),        Ea = 0, units = 'mbar'),
    Kp =         list(type = 'Arrhenius', c = log(82),         Ea = 0, units = 'microbar'),
    gamma_star = list(type = 'Arrhenius', c = log(0.5 / 1310), Ea = 0, units = 'dimensionless'),
    ao =         list(type = 'Arrhenius', c = log(0.047),      Ea = 0, units = 'dimensionless'),
    gmc_norm =   list(type = 'Arrhenius', c = 0,               Ea = 0, units = 'normalized to gmc at 25 degrees C'),
    J_norm =     list(type = 'Arrhenius', c = 0,               Ea = 0, units = 'normalized to J at 25 degrees C')
)
