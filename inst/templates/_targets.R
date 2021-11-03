library(targets)
library(tarchetypes)
library(notestar)
# options(tidyverse.quiet = TRUE)
# library(tidyverse)

source("R/functions.R")

tar_option_set(
  packages = c(
    # "tidyverse",
    "notestar"
  ),
  imports = c("notestar")
)


# Develop your main targets here
targets_main <- list(

)



targets_notebook <- list(
  tar_notebook_index_rmd(
    title = "Notebook Title",
    author = "Author Name",
    # bibliography = "refs.bib",
    # csl = "apa.csl",
    dir_notebook = "{{dir_notebook}}"
  ),

  tar_notebook_pages(
    dir_notebook = "{{dir_notebook}}",
    dir_md = "{{dir_md}}",
    notebook_helper = "{{notebook_helper}}"
  ),
  tar_notebook(
    ## we can tell notestar to make the notebook depend on any extra targets by
    ## creating the targets and passing them through here:
    # extra_deps = list(...)
  ),

  # Remove the following three targets to disable spellchecking
  # or add new exceptions here
  tar_target(
    spellcheck_exceptions,
    c(
      # need a placeholder word so that tests work
      "tibble"
      # add new exceptions here
    )
  ),

  tar_target(
    spellcheck_notebook,
    spelling::spell_check_files(notebook_rmds, ignore = spellcheck_exceptions)
  ),

  # Prints out spelling mistakes when any are found
  tar_force(
    spellcheck_report_results,
    print(spellcheck_notebook),
    nrow(spellcheck_notebook) > 0
  )
)

list(
  targets_main,
  targets_notebook
)

