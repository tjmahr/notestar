library(targets)
library(notestar)

# This is an example _targets.R file. Every
# {targets} pipeline needs one.
# Use tar_script() to create _targets.R and tar_edit()
# to open it again for editing.
# Then, run tar_make() to run the pipeline
# and tar_read(summary) to view the results.

# Define custom functions and other global objects.
# This is where you write source(\"R/functions.R\")
# if you keep your functions in external scripts.

# Set target-specific options such as packages.
tar_option_set(packages = "dplyr")

# End this file with a list of target objects.
list(
  tar_notebook_pages("notebook", "notebook/book")
)
