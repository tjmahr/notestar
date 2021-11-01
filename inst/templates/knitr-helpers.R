# This script is run before knitting each chapter. It sets the knitting root
# directory so that it can see the `_targets` folder, and it sets the chunk
# default settings.
notestar::notebook_set_opts_knit()

notestar::notebook_set_opts_chunk()

notestar::notebook_set_markdown_hooks()

knitr::opts_knit$set(notestar_purge_figures = TRUE)
