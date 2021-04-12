# This script is run before knitting each chapter. It sets the knitting root
# directory so that it can see the `_targets` folder, and it sets the chunk
# default settings.
knitr::opts_knit$set(
  root.dir = here::here()
)

knitr::opts_chunk$set(
  echo = FALSE,
  collapse = TRUE,
  comment = "#>",
  fig.align = "center",
  fig.retina = 1,
  fig.width = 6,
  fig.height = 4,
  dpi = 144,
  dev = "ragg_png"
)
