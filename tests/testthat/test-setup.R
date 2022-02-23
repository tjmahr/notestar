test_that("use_notestar() defaults provide a make-able notebook", {
  create_local_project()
  was_successful <- notestar::use_notestar(open = FALSE)
  expect_true(was_successful)

  # targets::tar_make()
  targets::tar_make(reporter = "silent")
  expect_true(file.exists("notebook/book/docs/notebook.html"))

  newlines <- gsub(
    x = readLines("_targets.R"),
    "title = \"Notebook Title\",",
    "title = \"My big project\", subtitle = \"testing\","
  )
  writeLines(newlines, "_targets.R")
  readLines("_targets.R")
  targets::tar_make()

  rmarkdown::yaml_front_matter(targets::tar_read("notebook_index_rmd"))
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
  targets::tar_make(reporter = "silent")

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
  targets::tar_make(reporter = "silent")
  outdated <- targets::tar_outdated(reporter = "silent")
  expect_false("notebook" %in% outdated)

  # plot is not part of notebook
  writeLines(new_entry, "notebook/2021-01-01-plot.Rmd")
  targets::tar_make(reporter = "silent")

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


test_that("rmd collations works as expected", {
  rmds <- c("notebook/index.Rmd",  "notebook/0000-00-00-references.Rmd")
  dir_md <- "notebook/book/"
  values <- lazy_list(
    rmd_file = !! rmds,
    rmd_page_raw = basename(.data$rmd_file),
    rmd_page = paste0("entry_", .data$rmd_page_raw) %>%
      janitor::make_clean_names(),
    sym_rmd_page = rlang::syms(.data$rmd_page),
    md_page = rmd_to_md(.data$rmd_page),
    md_page_raw = rmd_to_md(.data$rmd_page_raw),
    md_file = file.path(!! dir_md, .data$md_page_raw)
  )
  expect_equal(
    values$rmd_page,
    c("entry_index_rmd", "entry_0000_00_00_references_rmd")
  )
  expect_equal(
    values$md_page,
    c("entry_index_md", "entry_0000_00_00_references_md")
  )
})
