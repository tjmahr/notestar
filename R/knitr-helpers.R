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

#' @rdname set_knitr_opts
#' @export
notebook_set_markdown_hooks <- function() {
  # present plots using html figures
  hook_figure_plot <- function(x, options) {
    tags <- htmltools::tags
    cap <- options$fig.cap
    w <- options$out.width
    h <- options$out.height

    style_align <- if (options$fig.align == "center") {
      "margin-left: auto; margin-right: auto; display: block;"
    }
    style_out_width <- sprintf("width:%s;", options$out.width)

    style <- paste0(style_align, style_out_width, collapse = " ")

    as.character(tags$figure(
      tags$img(src = x, alt = cap, width = w, height = h, style = style),
      tags$figcaption(cap)
    ))
  }

  knitr::render_markdown()

  knitr::knit_hooks$set(plot = hook_figure_plot)
}
