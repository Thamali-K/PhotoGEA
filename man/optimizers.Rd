\name{optimizers}

\alias{optimizers}
\alias{optimizer_deoptim}
\alias{optimizer_hjkb}
\alias{optimizer_nlminb}
\alias{optimizer_nmkb}
\alias{optimizer_null}

\title{Optimizers}

\description{
  These functions return optimizers that meet requirements for the
  \code{optim_fun} input argument of \code{\link{fit_c3_aci}},
  \code{\link{fit_c3_variable_j}}, \code{\link{fit_c4_aci}}, and
  \code{\link{fit_c4_aci_hyperbola}}. Essentially, they are wrappers for
  optimizers from other libraries that serve to standardize their inputs and
  outputs.
}

\usage{
  optimizer_deoptim(itermax, VTR = -Inf)

  optimizer_hjkb(tol, maxfeval = Inf, target = Inf)

  optimizer_nlminb(rel.tol, eval.max = 200, iter.max = 200, abs.tol = 0)

  optimizer_nmkb(tol, maxfeval = 2000, restarts.max = 10)

  optimizer_null()
}

\arguments{
  \item{tol}{
    A convergence tolerance value; to be passed to \code{\link[dfoptim]{nmkb}}
    or \code{\link[dfoptim]{hjkb}} via their \code{control} input arguments. A
    typical value is \code{1e-7}.
  }

  \item{maxfeval}{
    A maximum value for the number of function evaluations to allow during
    optimization; to be passed to \code{\link[dfoptim]{nmkb}} or
    \code{\link[dfoptim]{hjkb}} via their \code{control} input arguments.
  }

  \item{target}{
    A real number restricting the absolute function value; to be passed to
    \code{\link[dfoptim]{hjkb}} via its \code{control} input argument.
  }

  \item{rel.tol}{
    A relative convergence tolerance value; to be passed to
    \code{\link[stats]{nlminb}} via its \code{control} input argument. A typical
    value is \code{1e-10}.
  }

  \item{eval.max}{
    A maximum value for the number of function evaluations; to be passed to
    \code{\link[stats]{nlminb}} via its \code{control} input argument.
  }

  \item{iter.max}{
    A maximum value for the number of iterations; to be passed to
    \code{\link[stats]{nlminb}} via its \code{control} input argument.
  }

  \item{abs.tol}{
    An absolute convergence tolerance value; to be passed to
    \code{\link[stats]{nlminb}} via its \code{control} input argument.
  }

  \item{restarts.max}{
    A maximum value for the number of restarts allowed during optimization;
    to be passed to \code{\link[dfoptim]{nmkb}} via its \code{control} input
    argument.
  }

  \item{itermax}{
    The maximum number of generations to be used; to be passed to
    \code{\link[DEoptim]{DEoptim}} via its \code{control} input argument. Note
    that when \code{VTR} is \code{-Inf}, the optimizer will always use the
    maximum number of generations. A typical value is \code{200}.
  }

  \item{VTR}{
    The value to be reached; to be passed to \code{\link[DEoptim]{DEoptim}} via
    its \code{control} input argument.
  }
}

\details{
  \code{optimizer_deoptim} is a wrapper for \code{\link[DEoptim]{DEoptim}}.

  \code{optimizer_hjkb} is a wrapper for \code{\link[dfoptim]{hjkb}}.

  \code{optimizer_nlminb} is a wrapper for \code{\link[stats]{nlminb}}.

  \code{optimizer_nmkb} is a wrapper for \code{\link[dfoptim]{nmkb}}.

  \code{optimizer_null} simply returns the initial guess without doing any
  optimization; it can be useful for viewing initial guesses.

  See the documentation for those functions for more information about how the
  optimizers work.
}

\value{
  Each of these functions returns an optimizer function \code{optim_fun}. The
  returned \code{optim_fun} function has four input arguments: an initial guess
  (\code{guess}), an error function (\code{fun}), lower bounds (\code{lower}),
  and upper bounds (\code{upper}). It returns a list with four named elements:
  \code{par}, \code{convergence}, \code{feval}, and \code{convergence_msg}.
}

\examples{
# Here we just show examples of the optim_fun results. Other examples using the
# optimizers can be found throughout PhotoGEA, such as in the user guides and
# the documentation for fit_c3_aci, fit_c4_aci, etc.

optimizer_deoptim(200)

optimizer_hjkb(1e-7)

optimizer_nlminb(1e-7)

optimizer_nmkb(1e-7)

optimizer_null()
}
