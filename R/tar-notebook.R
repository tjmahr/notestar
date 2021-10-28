#' Create targets to knit notebook Rmd files
#'
#' @param dir_notebook Name of the directory containing the Rmd files. It should
#'   be a relative path from the project root. Defaults to `"notebook"`
#' @param dir_md Name of the directory to contain md files (knitted Rmd files).
#'   It should be a relative path from the project root. Defaults to
#'   `"notebook/book"`.
#' @param notebook_helper Filename for an R script to run before knitting each
#'   Rmd file and rendering the notebook with bookdown. The file must be in
#'   `dir_md`. Defaults to `"knitr-helpers.R"` so the default location is
#'   `"notebook/book/knitr_helpers.R`.
#' @return A list of targets.
#'
#' @details The list of targets produced includes:
#'
#' * `notebook_helper`, a file for the helper R script.
#' * one file target for each input Rmd file. Any targets used
#'   with `tar_read()` or `tar_load()` inside these files are detected
#'   and checked for changes.
#' * one file target for each output md file.
#' * `notebook_rmds`, a combined target for the input Rmd files.
#' * `notebook_pages`, a combined target for the output md files.
#'
#' @export
tar_notebook_pages <- function(
  dir_notebook = "notebook",
  dir_md = "notebook/book",
  notebook_helper = "notebook/book/knitr-helpers.R"
) {

  rmds <- notebook_rmd_collate(dir_notebook)

  values <- lazy_list(
    rmd_file = !! rmds,
    rmd_page = make.names(basename(.data$rmd_file), unique = TRUE),
    sym_rmd_page = rlang::syms(.data$rmd_page),
    rmd_deps = lapply(.data$rmd_file, tarchetypes::tar_knitr_deps_expr),
    md_page = rmd_to_md(.data$rmd_page),
    md_file = file.path(!! dir_md, .data$md_page)
  )

  # Give bookdown an index.Rmd file
  values$md_file[1] <- md_to_rmd(values$md_file[1])

  list(
    targets::tar_target_raw(
      "notebook_config",
      rlang::expr(
        list(
          dir_notebook = !! dir_notebook,
          dir_md = !! dir_md,
          notebook_helper = !! notebook_helper
        )
      )
    ),

    targets::tar_target_raw(
      "notebook_helper",
      quote(notebook_config$notebook_helper),
      format = "file"
    ),

    # Prepare targets for each of the notebook pages
    tarchetypes::tar_eval_raw(
      quote(
        targets::tar_target(rmd_page, rmd_file, format = "file")
      ),
      values = values
    ),

    tarchetypes::tar_eval_raw(
      quote(
        targets::tar_target(
          md_page,
          command = {
            rmd_deps
            sym_rmd_page
            notebook_knit_page(rmd_file, md_file, notebook_helper);
            md_file
          },
          format = "file"
        )
      ),
      values = values
    ),

    # Combine them together
    targets::tar_target_raw(
      "notebook_rmds",
      rlang::expr(c(!!! values$sym_rmd_page)),
      deps = values$rmd_page
    ),

    # Combine them together
    targets::tar_target_raw(
      "notebook_mds",
      rlang::expr(c(!! values$md_file)),
      deps = values$md_page,
      format = "file"
    )
  )
}

#' Assemble knitted notebook md files into a single-page bookdown document
#'
#' @param theme Theme to use for `cleanrmd::html_document_clean()`. Defaults to
#'   `"water"`.
#' @param book_filename Name to use for the final html file. Defaults to
#'   `"notebook"` which produces `"notebook.html"`.
#' @param subdir_output Subdirectory of `dir_md` which will contain final html
#'   file produced by bookdown. Defaults to `"docs"`.
#' @param extra_deps A list of extra dependencies. These should be the names of
#'   targets defined elsewhere in the dependencies graph. Defaults to `list()`.
#'   Use this argument, for example, to force a notebook to depend on a `.bib`
#'   file.
#' @return A list of targets.
#' @export
#'
#' @details The list of targets produced includes:
#'
#' * `notebook_output_yaml`, a file target for `_output.yml` (used by
#'   bookdown to set output format options).
#' * `notebook_bookdown_yaml`, a file target for `_bookdown.yml` (used by
#'   bookdown to collate pages).
#' * `notebook`, a file target for the final assembled html file used by
#'   bookdown.
#'
#' The only output format supported is an html file produced by
#' `cleanrmd::html_document_clean()`.
tar_notebook <- function(
  theme = "water",
  book_filename = "notebook",
  subdir_output = "docs",
  extra_deps = list()
) {

  # Prepare _output.yml
  target_output <- targets::tar_target_raw(
    "notebook_output_yaml",
    command = rlang::expr({
      ymlthis::yml_empty() %>%
        ymlthis::yml_output(
          bookdown::markdown_document2(
            base_format = "cleanrmd::html_document_clean",
            theme = !! theme,
            toc = TRUE,
            mathjax = "default"
          )
        ) %>%
        ymlthis::yml_chuck("output") %>%
        notebook_write_yaml(
          file.path(
            !! quote(notebook_config$dir_md),
            "_output.yml"
          )
        )
    }),
    format = "file"
  )

  # Note that
  #
  #   rlang::expr(!! rlang::sym("x"))
  #   #> x
  #
  # We use this because
  #
  # 1. The commands inside of targets expect us to refer to other targets using
  #    symbols (like `notebook_helper`).
  # 2. But R CMD check warns about undefined symbols.
  #
  # So we "wrap" the symbol inside of rlang::sym() and !! unwraps it when
  # rlang::expr() prepares the expression.

  # Prepare _bookdown.yml
  target_bookdown <- targets::tar_target_raw(
    "notebook_bookdown_yaml",
    command = rlang::expr({
      ymlthis::yml_empty() %>%
        ymlthis::yml_bookdown_opts(
          book_filename = !! book_filename,
          output_dir = !! subdir_output,
          delete_merged_file = TRUE,
          new_session = TRUE,
          before_chapter_script = basename(!! rlang::sym("notebook_helper")),
          rmd_files = basename(!! rlang::sym("notebook_mds"))
        ) %>%
        notebook_write_yaml(
          file.path(
            !! quote(notebook_config$dir_md),
            "_bookdown.yml"
          )
        )
    }),
    format = "file"
  )


  expr_extra_deps <- rlang::enexpr(extra_deps)
  target_notebook <- targets::tar_target_raw(
    "notebook",
    command = rlang::expr({
      other_deps <- list(
        !! rlang::sym("notebook_mds"),
        !! rlang::sym("notebook_bookdown_yaml"),
        !! rlang::sym("notebook_output_yaml")
      )
      extra_deps <- !! expr_extra_deps
      rmarkdown::render_site(
        !! quote(notebook_config$dir_md),
        encoding = "UTF-8"
      )
      file.path(
        !! quote(notebook_config$dir_md),
        !! subdir_output,
        paste0(!! book_filename, ".html")
      )
    }),
    format = "file"
  )

  list(target_output, target_bookdown, target_notebook)
}


#' Gather rmd entries and put them in order
#'
#' Files are sorted with index.Rmd first followed by the rest in lexicographic
#' order.
#'
#' @inheritParams tar_notebook_pages
#' @return a vector of paths to rmd files
#' @export
#' @keywords internal
notebook_rmd_collate <- function(dir_notebook = "notebook") {
  index <- file.path(dir_notebook, "index.Rmd")
  posts <- list.files(
    path = dir_notebook,
    pattern = "\\d.+.Rmd",
    full.names = TRUE
  )
  c(index, rev(posts))
}


lazy_list <- function(...) {
  q <- rlang::enexprs(..., .named = TRUE, .check_assign = TRUE)
  data <- list()
  for (x in seq_along(q)) {
    data[names(q[x])] <- list(rlang::eval_tidy(q[[x]], data = data))
  }
  data
}


rmd_to_md <- function(x) gsub("[.]Rmd$", ".md", x = x)
md_to_rmd <- function(x) gsub("[.]md$", ".Rmd", x = x)


knit_page <- function(rmd_in, md_out, helper_script) {
  requireNamespace("knitr")
  source(helper_script)

  dir_assets <- file.path(
    "assets",
    "figure",
    tools::file_path_sans_ext(basename(rmd_in)),
    "/"
  )
  knitr::opts_chunk$set(fig.path = dir_assets)
  knitr::opts_knit$set(base.dir = file.path(dirname(md_out), "/"))

  knitr::knit(rmd_in, md_out, encoding = "UTF-8")
  md_out
}


#' Knit a single notebook entry
#'
#' @keywords internal
#' @param rmd_in path to the rmd file to knit
#' @param md_out path to the md file to create
#' @param helper_script path to an R script to run beforehand
#' @export
notebook_knit_page <- function(rmd_in, md_out, helper_script) {
  callr::r(
    knit_page,
    list(rmd_in = rmd_in, md_out = md_out, helper_script = helper_script)
  )
  md_out
}


#' Write out a yaml-file and return the path
#'
#' This function is a wrapper over `yaml::write_yaml()` that works with file
#' targets.
#'
#' @param x,file,... arguments passed to `yaml::write_yaml()`.
#' @return the yaml `file` is written and the value of `file` is returned
#' @export
notebook_write_yaml <- function(x, file, ...) {
  yaml::write_yaml(x, file, ...)
  file
}

#' Open the notebook in a browser
#'
#' @param file full path to the notebook file. Defaults to `NULL` in which case
#'   it finds the path using targets.
#' @return This function is called for its side effects so it return `NULL`
#'   invisibly.
#' @export
notebook_browse <- function(file = NULL) {
  if (is.null(file)) {
    file <- targets::tar_read_raw("notebook")
  }
  utils::browseURL(file)
  invisible(NULL)
}
