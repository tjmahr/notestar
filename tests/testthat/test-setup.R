test_that("use_notestar() defaults provide a make-able notebook", {
  create_local_project()
  was_successful <- notestar::use_notestar(open = FALSE)
  expect_true(was_successful)

  targets::tar_make(reporter = "silent")
  expect_true(file.exists("notebook/book/docs/notebook.html"))
})



test_that("use_notestar() paths are customizable", {
  create_local_project()
  was_successful <- notestar::use_notestar(
    dir_notebook = "pages",
    dir_md = "book",
    notebook_helper = "knitr-helpers.R",
    open = FALSE
  )
  expect_true(was_successful)

  targets::tar_make("notebook_config", reporter = "silent")
  config <- targets::tar_read("notebook_config")
  expect_equal(config$dir_notebook, "pages")
  expect_equal(config$dir_md, "book")
  expect_equal(config$notebook_helper, "book/knitr-helpers.R")

  targets::tar_make(reporter = "silent")
  expect_true(file.exists("book/docs/notebook.html"))
})



