test_that("use_notestar() defaults provide a make-able notebook", {
  create_local_project()
  was_successful <- notestar::use_notestar(open = FALSE)
  expect_true(was_successful)

  expect_false(file.exists("notebook/book/docs/notebook.html"))
  capture_output(targets::tar_make(reporter = "silent"))
  expect_true(file.exists("notebook/book/docs/notebook.html"))
})


test_that("use_notestar() paths are customizable", {
  create_local_project()
  was_successful <- notestar::use_notestar(
    dir_notebook = "pages",
    dir_md = "book",
    notebook_helper = "knitr-helpers.R",
    notebook_filename = "notes",
    open = FALSE
  )
  expect_true(was_successful)

  config <- notebook_config()
  expect_equal(config$dir_notebook, "pages")
  expect_equal(config$dir_md, "book")
  expect_equal(config$notebook_helper, "pages/knitr-helpers.R")

  capture_output(targets::tar_make(reporter = "silent"))
  expect_true(file.exists("book/docs/notes.html"))
})


test_that("can track/purge generated figures", {
  skip_if_not_installed("ragg")

  entry <- "
<!--- Timestamp to trigger book rebuilds: `r Sys.time()` --->

## Demo entry

<small>Source: <code>`r knitr::current_input()`</code></small>

```{r faithful}
plot(faithful)
```
"
  new_entry <- "
<!--- Timestamp to trigger book rebuilds: `r Sys.time()` --->

## Demo entry

<small>Source: <code>`r knitr::current_input()`</code></small>

```{r faithful}
# plot(faithful)
```
"

  create_local_project()
  was_successful <- notestar::use_notestar(open = FALSE)

  # create a notebook with the plot
  writeLines(entry, "notebook/2021-01-01-plot.Rmd")
  capture_output(targets::tar_make(reporter = "silent"))

  # notebook is current
  outdated <- targets::tar_outdated(reporter = "silent")
  expect_false("entry_2021_01_01_plot_md" %in% outdated)

  # plot landed where it was expected
  expect_true(
    file.exists("notebook/book/assets/figure/2021-01-01-plot/faithful-1.png")
  )

  # plot is being tracked
  expect_equal(
    targets::tar_read("entry_2021_01_01_plot_md"),
    c(
      "notebook/book/2021-01-01-plot.md",
      "notebook/book/assets/figure/2021-01-01-plot/faithful-1.png"
    )
  )

  # notebook depends on plot file
  file.remove("notebook/book/assets/figure/2021-01-01-plot/faithful-1.png")
  outdated <- targets::tar_outdated(reporter = "silent")
  expect_true("entry_2021_01_01_plot_md" %in% outdated)
  expect_true("notebook" %in% outdated)

  # notebook is current again
  capture_output(targets::tar_make(reporter = "silent"))
  outdated <- targets::tar_outdated(reporter = "silent")
  expect_false("notebook" %in% outdated)

  # plot is not part of notebook
  writeLines(new_entry, "notebook/2021-01-01-plot.Rmd")
  capture_output(targets::tar_make(reporter = "silent"))

  outdated <- targets::tar_outdated(reporter = "silent")
  expect_false("notebook" %in% outdated)

  # plot purged
  expect_false(
    file.exists("notebook/book/assets/figure/2021-01-01-plot/faithful-1.png")
  )

  # plot is not being tracked
  expect_equal(
    targets::tar_read("entry_2021_01_01_plot_md"),
    "notebook/book/2021-01-01-plot.md"
  )
})


test_that("index.Rmd can be customized", {
  skip("to do")
})

test_that("index.Rmd can be customized (bib file)", {
  skip("to do")
})

test_that("index.Rmd can be customized (csl file)", {
  skip("to do")
})

