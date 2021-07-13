#' Set default knitr options for notebook knitting
#'
#' These options are used in the `knitr-helpers.R` file.
#'
#' @rdname set_knitr_opts
#' @return a list containing the default options used
#' @export
notebook_set_opts_knit <- function() {
  defaults <- list(root.dir = here::here())
  knitr::opts_knit$set(
    defaults
  )
  defaults
}

#' @rdname set_knitr_opts
#' @export
notebook_set_opts_chunk <- function() {
  defaults <- list(
    echo = FALSE,
    collapse = TRUE,
    comment = "#>",
    fig.align = "center",
    fig.retina = 1,
    fig.width = 6,
    fig.height = 4,
    dpi = 300,
    dev = "ragg_png"
  )
  knitr::opts_chunk$set(defaults)
  defaults
}
