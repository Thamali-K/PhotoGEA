\name{plot_ball_berry_fit}

\alias{plot_ball_berry_fit}

\title{Plot the results of a C3 CO2 response curve fit}

\description{
  Plots the output from \code{\link{fit_c3_aci}} or
  \code{\link{fit_c3_variable_j}}.
}

\usage{
  plot_ball_berry_fit(
    fit_results,
    identifier_column_name,
    bb_index_column_name = 'bb_index',
    gsw_column_name = 'gsw',
    \dots
  )
}

\arguments{
  \item{fit_results}{
    A list of three \code{exdf} objects names \code{fits}, \code{parameters},
    and \code{fits_interpolated}, as calculated by \code{\link{fit_c3_aci}}.
  }

  \item{identifier_column_name}{
    The name of a column in each element of \code{fit_results} whose value can
    be used to identify each response curve within the data set; often, this is
    \code{'curve_identifier'}.
  }

  \item{bb_index_column_name}{
    The name of the column in \code{fit_results$fits} that contains the
    Ball-Berry index in \code{mol m^(-2) s^(-1)}; should be the same value that
    was passed to \code{fit_ball_berry}.
  }

  \item{gsw_column_name}{
    The name of the column in \code{fit_results$fits} that contains the stomatal
    conductance to water vapor in \code{mol m^(-2) s^(-1)}; should be the same
    value that was passed to \code{fit_ball_berry}.
  }

  \item{\dots}{
    Additional arguments to be passed to \code{\link[lattice]{xyplot}}.
  }
}

\details{
  This is a convenience function for plotting the results of a Ball-Berry curve
  fit. It is typically used for displaying several fits at once, in which case
  \code{fit_results} is actually the output from calling
  \code{\link{consolidate}} on a list created by calling \code{\link{by.exdf}}
  with \code{FUN = fit_ball_berry}.

  The resulting plot will show curves for the fitted \code{gsw}, along with
  points for the measured values of \code{gsw}.

  Internally, this function uses \code{\link[lattice]{xyplot}} to perform the
  plotting. Optionally, additional arguments can be passed to \code{xyplot}.
  These should typically be limited to things like \code{xlim}, \code{ylim},
  \code{main}, and \code{grid}, since many other \code{xyplot} arguments will be
  set internally (such as \code{xlab}, \code{ylab}, \code{auto}, and others).

  See the help file for \code{\link{fit_ball_berry}} for an example using this
  function.
}


\value{
  A \code{trellis} object created by \code{lattice::xyplot}.
}

\examples{
# Read an example Licor file included in the PhotoGEA package, calculate
# additional gas properties, calculate the Ball-Berry index, define a new column
# that uniquely identifies each curve, and then perform a fit to extract the
# Ball-Berry parameters from each curve.
licor_file <- read_gasex_file(
  PhotoGEA_example_file_path('ball_berry_1.xlsx')
)

licor_file <- calculate_total_pressure(licor_file)

licor_file <- calculate_gas_properties(licor_file)

licor_file[,'species_plot'] <-
  paste(licor_file[,'species'], '-', licor_file[,'plot'])

licor_file <- calculate_ball_berry_index(licor_file)

# Fit all curves in the data set
bb_results <- consolidate(by(
  licor_file,
  licor_file[, 'species_plot'],
  fit_ball_berry
))

# View the fits for each species / plot
plot_ball_berry_fit(bb_results, 'species_plot')
}

\concept{exdf}
