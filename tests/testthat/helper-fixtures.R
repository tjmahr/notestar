# Copied from:
# https://www.tidyverse.org/blog/2020/04/self-cleaning-test-fixtures/
create_local_project <- function(
  # dir = fs::file_temp(),
  dir = tempfile(),
  env = parent.frame(),
  quiet = TRUE
) {
  old_options <- options(usethis.quiet = quiet)
  old_project <- getwd()

  withr::defer(
    {
      options(old_options)
      usethis::proj_set(old_project, force = TRUE)
      setwd(old_project)
      unlink(dir, recursive = TRUE)
      # fs::dir_delete(dir)
    },
    envir = env
  )

  usethis::create_project(dir, open = FALSE)

  setwd(dir)
  usethis::proj_set(dir, force = TRUE)
  invisible(dir)
}


tar_make_quietly <- function(..., reporter = "silent") {
  output <- testthat::capture_output(
    targets::tar_make(..., reporter = reporter)
  )
  invisible(output)
}
