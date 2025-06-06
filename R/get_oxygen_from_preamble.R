get_oxygen_from_preamble <- function(licor_exdf) {
    # Check the input
    if (!is.exdf(licor_exdf)) {
        stop('licor_exdf must be an exdf object')
    }

    # Make sure the preamble is included in the exdf object
    if (!'preamble' %in% names(licor_exdf)) {
        stop('exdf_obj$preamble must be defined; see read_gasex_file for more info')
    }

    # Add a new column to the Licor file in preparation for adding the
    # oxygen information
    licor_exdf <- document_variables(
        licor_exdf,
        c('in', 'oxygen', 'percent')
    )

    # Try to get the oxygen information from the Licor file's preamble
    preamble <- licor_exdf[['preamble']]

    oxygen <- if ('Oxygen' %in% colnames(preamble)) {
        try_as_numeric(preamble[['Oxygen']])
    } else if ('SysConst:Oxygen' %in% colnames(preamble)) {
        try_as_numeric(preamble[['SysConst:Oxygen']])
    } else {
        msg <- paste0(
            "Could not automatically get oxygen information from file:\n'",
            licor_exdf[['file_name']],
            "'\nConsider adding oxygen values with the `set_variable` function ",
            "rather than using `get_oxygen_from_preamble`"
        )
        warning(msg)
        NA
    }

    # Remove any duplicated or NA values
    oxygen <- unique(oxygen)
    oxygen <- oxygen[!is.na(oxygen)]

    # Check for issues with multiple values
    if (length(unique(oxygen)) > 1) {
        msg <- paste0(
            "Found multiple oxygen values in file:\n'",
            licor_exdf[['file_name']],
            "'\nConsider adding oxygen values with the `set_variable` function ",
            "rather than using `get_oxygen_from_preamble`"
        )
        warning(msg)
        oxygen <- NA
    }

    # Store it in the Licor file and return the updated file
    licor_exdf[, 'oxygen'] <- oxygen

    return(licor_exdf)
}
