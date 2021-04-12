# Copied from:
# https://www.tidyverse.org/blog/2020/04/self-cleaning-test-fixtures/
create_local_project <- function(
  dir = fs::file_temp(),
  env = parent.frame()
) {
  old_project <- usethis::proj_get()

  withr::defer(
    {
      usethis::proj_set(old_project, force = TRUE)
      setwd(old_project)
      fs::dir_delete(dir)
    },
    envir = env
  )

  usethis::create_project(dir, open = FALSE)

  setwd(dir)
  usethis::proj_set(dir)
  invisible(dir)
}


test_that("use_notestar() runs without error", {
  create_local_project()

  was_successful <- notestar::use_notestar()
  expect_true(was_successful)

  targets::tar_make()
  expect_true(file.exists("notebook/book/docs/notebook.html"))
})


test_that("use_notestar() defaults provide a make-able notebook", {
  create_local_project()
  use_notestar()
  targets::tar_make(reporter = "silent")
  expect_true(file.exists("notebook/book/docs/notebook.html"))
})

