test_that("use_notestar() defaults provide a make-able notebook", {
  create_local_project()
  was_successful <- use_notestar(open = FALSE)
  expect_true(was_successful)

  expect_false(file.exists("notebook/book/docs/notebook.html"))
  tar_make_quietly()
  expect_true(file.exists("notebook/book/docs/notebook.html"))
})


test_that("use_notestar() paths are customizable", {
  create_local_project()
  was_successful <- use_notestar(
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

  tar_make_quietly()
  expect_true(file.exists("pages/knitr-helpers.R"))
  expect_true(file.exists("book/docs/notes.html"))
})


test_that("changing config.yml theme should outdate notebook", {
  create_local_project()
  was_successful <- use_notestar(open = FALSE)
  tar_make_quietly()

  yaml_in <- yaml::read_yaml("config.yml")
  yaml_in$default$notestar$cleanrmd_theme$value <- "sakura-vader"
  yaml::write_yaml(yaml_in, "config.yml")

  outdated <- targets::tar_outdated()
  expect_true("notebook" %in% outdated)
})


test_that("notesstar can track/purge generated figures", {
  skip_if_not_installed("ragg")

  entry <- "
  <!--- Timestamp to trigger book rebuilds: `r Sys.time()` --->

  ## Demo entry

  <small>Source: <code>`r knitr::current_input()`</code></small>

  ```{r faithful}
  plot(faithful)
  ```
  "
  entry <- gsub("\\n  ", "\n", entry)

  new_entry <- "
  <!--- Timestamp to trigger book rebuilds: `r Sys.time()` --->

  ## Demo entry

  <small>Source: <code>`r knitr::current_input()`</code></small>

  ```{r faithful}
  # plotting code removed
  ```
  "
  new_entry <- gsub("\\n  ", "\n", new_entry)

  create_local_project()
  was_successful <- use_notestar(open = FALSE)

  # Create a notebook with the plot
  writeLines(entry, "notebook/2021-01-01-plot.Rmd")
  tar_make_quietly()

  # Notebook is current
  outdated <- targets::tar_outdated(reporter = "silent")
  expect_false("entry_2021_01_01_plot_md" %in% outdated)

  # Plot landed where it was expected
  expect_true(
    file.exists("notebook/book/assets/figure/2021-01-01-plot/faithful-1.png")
  )

  # Plot is being tracked
  expect_equal(
    targets::tar_read("entry_2021_01_01_plot_md"),
    c(
      "notebook/book/2021-01-01-plot.md",
      "notebook/book/assets/figure/2021-01-01-plot/faithful-1.png"
    )
  )

  # Notebook depends on plot file
  file.remove("notebook/book/assets/figure/2021-01-01-plot/faithful-1.png")
  outdated <- targets::tar_outdated(reporter = "silent")
  expect_true("entry_2021_01_01_plot_md" %in% outdated)
  expect_true("notebook" %in% outdated)

  # Restore the notebook and plot
  tar_make_quietly()

  # Update entry to remove the plot
  writeLines(new_entry, "notebook/2021-01-01-plot.Rmd")
  capture_output(targets::tar_make(reporter = "silent"))

  # Plot has been removed
  expect_false(
    file.exists("notebook/book/assets/figure/2021-01-01-plot/faithful-1.png")
  )

  # Plot is not being tracked
  expect_equal(
    targets::tar_read("entry_2021_01_01_plot_md"),
    "notebook/book/2021-01-01-plot.md"
  )
})


test_that("index.Rmd can be customized", {
  create_local_project()
  was_successful <- use_notestar(open = FALSE)
  expect_true(was_successful)

  tar_make_quietly()
  old_yaml <- rmarkdown::yaml_front_matter("notebook/index.Rmd")

  writeLines(
    gsub(
      "title = .*,",
      "title = \"Test title\", subtitle = \"another test\",",
      readLines("_targets.R")
    ),
    "_targets.R"
  )

  expect_true(
    all(c("notebook_index_rmd", "notebook") %in% targets::tar_outdated())
  )

  tar_make_quietly()
  new_yaml <- rmarkdown::yaml_front_matter("notebook/index.Rmd")

  expect_equal(new_yaml$subtitle, "another test")
  expect_false(old_yaml$title == new_yaml$subtitle)
})


test_that("index.Rmd can be customized (bib file)", {
  create_local_project()
  was_successful <- use_notestar(open = FALSE)
  expect_true(was_successful)

  tar_make_quietly()
  old_yaml <- rmarkdown::yaml_front_matter("notebook/index.Rmd")

  writeLines(
    gsub(
      "title = .*,",
      "title = \"Test title\", subtitle = \"another test\",",
      readLines("_targets.R")
    ),
    "_targets.R"
  )
})

test_that("index.Rmd can be customized (csl file)", {
  skip("to do")
})

