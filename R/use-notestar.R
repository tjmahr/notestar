# usethis-like facilities

#' Create a brand new notebook with default settings
#'
#' @param dir_project file-path to the base/root folder of the project. Defaults to
#'   `"."` which is the current working directory.
#' @param dir_notebook Name of the directory containing the Rmd files. It should
#'   be a relative path from the project root. Defaults to `"notebook"`
#' @param dir_md Name of the directory to contain md files (knitted Rmd files).
#'   It should be a relative path from the project root. Defaults to
#'   `"notebook/book"`.
#' @param notebook_helper Filename for an R script to run before knitting each
#'   Rmd file and rendering the notebook with bookdown. The file must be in
#'   `dir_md`. Defaults to `"knitr-helpers.R"` so the default location is
#'   `"notebook/knitr_helpers.R`.
#' @param cleanrmd_theme Theme to use for `cleanrmd::html_document_clean()`. Defaults to
#'   `"water"`.
#' @param notebook_filename Name to use for the final html file. Defaults to
#'   `"notebook"` which produces `"notebook.html"`.
#' @param open whether to open `_targets.R`, `notebook/index.Rmd`, and
#'   `R/functions.R` when they are created. Defaults to `interactive()` (whether
#'   the code is being called interactively).
#' @return
#'
#' `use_notestar_makefile()` creates a Makefile that will build or clean a
#' targets-based workflow.
#'
#' `use_notestar_references()` adds the files `"refs.bib"` and `"apa.csl"` to
#' `dir_notebook`.
#'
#' @export
#' @rdname use-notestar
use_notestar <- function(
  dir_project = ".",
  dir_notebook = "notebook",
  dir_md = "notebook/book",
  notebook_helper = "knitr-helpers.R",
  cleanrmd_theme = "water",
  notebook_filename = "notebook",
  open = interactive()
) {

  # set up a project folder
  here::set_here(dir_project, verbose = FALSE)
  usethis::local_project(path = dir_project, quiet = TRUE)
  notebook_file <- function(x) file.path(dir_notebook, x)
  md_file <- function(x) file.path(dir_md, x)

  usethis::use_template(
    "config.yml",
    save_as = "config.yml",
    data = list(
      dir_notebook = dir_notebook,
      dir_md = dir_md,
      notebook_helper = notebook_file(notebook_helper),
      cleanrmd_theme = cleanrmd_theme,
      notebook_filename = notebook_filename
    ),
    package = "notestar",
    open = FALSE
  )

  # R/functions.R
  usethis::use_directory("R")
  usethis::use_template(
    template = "functions.R",
    save_as = "R/functions.R",
    package = "notestar",
    open = FALSE
  )

  usethis::use_directory(dir_notebook)
  usethis::use_directory(dir_md)
  usethis::use_directory(file.path(dir_md, "assets"))

  usethis::use_template(
    template = "index.Rmd",
    save_as = notebook_file("index.Rmd"),
    package = "notestar",
    open = FALSE
  )

  usethis::use_template(
    "knitr-helpers.R",
    save_as = notebook_file(notebook_helper),
    package = "notestar",
    open = FALSE
  )

  usethis::use_template(
    "0000-00-00-references.Rmd",
    save_as = notebook_file("0000-00-00-references.Rmd"),
    package = "notestar",
    open = FALSE
  )

  usethis::use_template(
    "_targets.R",
    save_as = "_targets.R",
    package = "notestar",
    open = open
  )

  invisible(TRUE)
}


#' @export
#' @rdname use-notestar
use_notestar_makefile <- function(dir_project = ".") {
  usethis::local_project(path = dir_project, quiet = FALSE)
  usethis::use_template("Makefile", package = "notestar")

  usethis::ui_todo(
    paste(
      "Set",
      usethis::ui_field("Project Options > Build Tools"),
      "to use a Makefile"
    )
  )
}


#' @export
#' @rdname use-notestar
use_notestar_references <- function(dir_project = ".") {
  usethis::local_project(path = dir_project, quiet = FALSE)
  config <- notebook_config()

  usethis::use_template(
    "refs.bib",
    file.path(config$dir_notebook, "refs.bib"),
    package = "notestar"
  )

  usethis::use_template(
    "apa.csl",
    file.path(config$dir_notebook, "apa.csl"),
    package = "notestar"
  )

  usethis::ui_todo(
    paste(
      "In", usethis::ui_path("_targets.R"),
      "add these lines to the",
      usethis::ui_code("tar_notebook_index_rmd()"),
      "call:"
    )
  )

  usethis::ui_code_block(c(
    "bibliography = \"refs.bib\",",
    "    csl = \"apa.csl\""
  ))
}


#' Create a new notebook page
#'
#' Creates a file with pattern `[notebook_dir]/[date][-slug].Rmd`.
#'
#' @param slug Optional "slug" (label) for the post. Defaults to `""`.
#' @param date Optional data to use. This date should have the format
#'   `YYYY-MM-DD`. Defaults to the current date.
#' @param open Whether to open the new file for editing. Defaults to
#'   `rlang::is_interactive()`.
#' @return Invisible returns the relative path to the created file.
#' @export
notebook_create_page <- function(
  slug = NULL,
  date = NULL,
  open = TRUE
) {
  config <- notebook_config()
  notebook_dir <- config[["dir_notebook"]]

  if (is.null(date)) {
    date_data <- Sys.Date()
    date <- format(date_data, "%Y-%m-%d")
  } else {
    date_data <- as.Date(date, "%Y-%m-%d")
  }

  data_title_month <- format.Date(date_data, "%b. ")
  data_title_day <- as.integer(format.Date(date_data, "%d"))
  data_title_year <- format.Date(date_data, ", %Y")
  date_title <- paste0(data_title_month, data_title_day, data_title_year)

  if (is.null(slug)) {
    slug <- ""
    sep <- ""
  } else {
    sep <- "-"
  }
  filename <- paste0(date, sep, slug, ".Rmd")

  to_create <- file.path(notebook_dir, filename)

  usethis::use_template(
    template = "0000-00-00-demo-post.Rmd",
    save_as = to_create,
    package = "notestar",
    data = list(date = date_title),
    open = open
  )

  usethis::ui_done("{usethis::ui_path(to_create)} created")
  invisible(to_create)
}
