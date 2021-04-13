# Copied from:
# https://www.tidyverse.org/blog/2020/04/self-cleaning-test-fixtures/
create_local_project <- function(
  dir = fs::file_temp(),
  env = parent.frame()
) {
  old_options <- options(usethis.quiet = TRUE)
  old_project <- usethis::proj_get()

  withr::defer(
    {
      options(old_options)
      usethis::proj_set(old_project, force = TRUE)
      setwd(old_project)
      fs::dir_delete(dir)
    },
    envir = env
  )

  usethis::create_project(dir, open = FALSE)

  # fs::dir_create(dir)
  setwd(dir)
  usethis::proj_set(dir)
  invisible(dir)
}

