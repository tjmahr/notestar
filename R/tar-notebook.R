utils::globalVariables("notebook_index_yml")


notebook_config <- function() {
  config <- config::get(use_parent = FALSE) |>
    getElement("notestar") |>
    lapply(getElement, "value")
}


#' Create targets to knit notebook Rmd files
#'
#' @return A list of targets.
#'
#' @details The list of targets produced includes:
#'
#' * `notebook_helper_user`, a file for the user's helper R script.
#' * `notebook_helper`, a mirrored copy of the `notebook_helper_user`
#' * one file target for each input Rmd file. Any targets used
#'   with `tar_read()` or `tar_load()` inside these files are detected
#'   and checked for changes.
#' * one file target for each output md file.
#' * `notebook_rmds`, a combined target for the input .Rmd files.
#' * `notebook_mds`, a combined target for the output .md files.
#'
#' @export
tar_notebook_pages <- function() {
  config <- notebook_config()
  dir_notebook <- config$dir_notebook
  dir_md <- config$dir_md
  notebook_helper <- config$notebook_helper

  # For every notebook entry (rmd_file)
  # - get the basename (rmd_page_raw) and derive the
  #   corresponding .md file's basename(md_page)
  # - derive legal target names from the basename for the file (rmd_page) and
  #   for the corresponding .md file (md_page_raw)
  # - create a symbol to use in the R code analyzed by targets (sym_rmd_page)
  # - identify the dependencies inside of each file (rmd_deps)
  # - derive the final path for .md file
  values <- lazy_list(
    rmd_file = notebook_rmd_collate(!! dir_notebook),
    rmd_page_raw = basename(.data$rmd_file),
    md_page_raw = rmd_to_md(.data$rmd_page_raw),
    rmd_page = paste0("entry_", .data$rmd_page_raw) |>
      janitor::make_clean_names(),
    md_page = rmd_to_md(.data$rmd_page),
    sym_rmd_page = rlang::syms(.data$rmd_page),
    rmd_deps = lapply(.data$rmd_file, tarchetypes::tar_knitr_deps_expr),
    md_file = file.path(!! dir_md, .data$md_page_raw)
  )

  # index.Rmd gets knitted when the notebook is assembled so that
  # it has a timestamp for when the whole notebook was assembled. So its .md file
  # should be a .Rmd file.
  values$md_file[1] <- md_to_rmd(values$md_file[1])

  # And index.Rmd is actually created by a different target so we need to
  # use that target name
  values$sym_rmd_page[[1]] <- rlang::sym("notebook_index_rmd")
  values$rmd_page[[1]] <- "notebook_index_rmd"

  values_no_index <- lapply(values, function(x) x[-1])

  list(
    targets::tar_target_raw(
      "notebook_helper_user",
      rlang::inject(notebook_helper),
      format = "file"
    ),

    targets::tar_target_raw(
      "notebook_helper",
      rlang::expr({
        path_out <- file.path(!! dir_md, basename(!! notebook_helper))
        file.copy(!! notebook_helper, path_out, overwrite = TRUE)
        path_out
      }),
      deps = "notebook_helper_user",
      format = "file"
    ),

    # Each Rmd file is a file target
    tarchetypes::tar_eval_raw(
      quote(
        targets::tar_target(rmd_page, rmd_file, format = "file")
      ),
      values = values_no_index
    ),

    # Prepare targets for each of the md files
    tarchetypes::tar_eval_raw(
      quote(
        targets::tar_target(
          md_page,
          command = {
            rmd_deps
            sym_rmd_page
            notebook_knit_page(rmd_file, md_file, notebook_helper)
          },
          format = "file"
        )
      ),
      values = values
    ),

    # Bundle the rmd files together (e.g., for spell-checking)
    targets::tar_target_raw(
      "notebook_rmds",
      rlang::expr(c(!!! values$sym_rmd_page)),
      deps = values$rmd_page
    ),

    # Bundle the md files together (for notebook assembly)
    targets::tar_target_raw(
      "notebook_mds",
      rlang::expr(c(!!! values$md_file)),
      deps = values$md_page,
      format = "file"
    )
  )
}


#' Create index.Rmd file
#'
#' This function creates the `index.Rmd` file for the notebook and sets YAML
#' metadata in the file. It also detects CSL and bibliography file dependencies.
#'
#' @param title Title to use for the notebook. Defaults to `"Notebook title"`.
#' @param author Author name for the notebook. Defaults to `"Author Name"`.
#'   Multiple authors, email and affiliations can used by using a list `list(name =
#'   names, email = emails)`. See [ymlthis::yml_author()].
#' @param bibliography Name of a `.bib` file in the `dir_notebook` rmd folder.
#'   This file is copied to `[dir_md]/assets/[bibliography]` and saved in the
#'   YAML metadata in index.Rmd as `"./assets/[bibliography]"`. Defaults to
#'   [ymlthis::yml_blank()]. This file is then tracked with
#'   targets and set as a dependency for `tar_notebook()`.
#' @param csl Name of a `.csl` file in the `dir_notebook` rmd folder.
#'   This file is copied to `[dir_md]/assets/[csl]` and saved in the
#'   YAML metadata in index.Rmd as `"./assets/[csl]"`. Defaults to
#'   [ymlthis::yml_blank()]. This file is then tracked with
#'   targets and set as a dependency for `tar_notebook()`.
#' @param index_rmd_body_lines optional character vector to use for body text in
#'   `index.Rmd`. Defaults to `""`.
#' @param ... Additional key-value pairs for setting fields in the yml metadata.
#'   For example, `subtitle = "Status: Project completed"` would add a subtitle
#'   to the index.Rmd file and that subtitle would appear in the notebook. These
#'   fields cannot include `"date"` or `"site"`.
#' @param .list Alternatively, these YAML fields may be set using a list. Any
#'   key-value pairs in this list will override options set by arguments. For
#'   example, an `author` entry in `.list` would override the value in the
#'   `author` parameter.
#' @return a list of targets:
#'  - `notebook_bibliography_user`, `notebook_csl_user`: file targets for
#'    the bibliography and csl files in the `dir_notebook` user folder.
#'  - `notebook_bibliography_asset`, `notebook_csl_asset`: file targets for
#'    the bibliography and csl files in the `dir_md` assets folder. These
#'    command to build these targets to copy them.
#'  - `notebook_index_rmd`: file target for the index.Rmd file.
#'
#'  If any of these file targets is not used, an empty target `list()` is passed
#'  along.
#'
#' @export
tar_notebook_index_rmd <- function(
  title = "Notebook title",
  author = "Author name",
  bibliography = ymlthis::yml_blank(),
  csl = ymlthis::yml_blank(),
  index_rmd_body_lines = "",
  ...,
  .list = rlang::list2(...)
) {
  # Retrieve the configuration
  config <- notebook_config()
  dir_notebook <- config$dir_notebook
  dir_md <- config$dir_md

  # Protect reserved yaml fields
  extra_names <- names(.list)
  if ("date" %in% extra_names) {
    d <- usethis::ui_code("date")
    usethis::ui_stop("{d} field is set when book is built.")
  }
  if ("site" %in% extra_names) {
    d <- usethis::ui_code("site")
    usethis::ui_stop("{d} field cannot be customized.")
  }

  # Resolve which arguments to use from user
  data_in_named_args <- list(
    title = title,
    author = author,
    bibliography = bibliography,
    csl = csl
  )

  # Overwrite individual arguments with the values from .list if they are
  # present, e.g. prefer "blah" in this situation
  #     `title = "default", .list = list(title = "blah")`
  data_args <- data_in_named_args |>
    utils::modifyList(.list, keep.null = TRUE)

  data_args$csl_in <- data_args$csl
  data_args$csl <- path_if_lengthy(data_args$csl, "./assets")
  data_args$bibliography_in <- data_args$bibliography
  data_args$bibliography <- path_if_lengthy(data_args$bibliography, "./assets")

  # Finally, plug in any defaults from the package template
  template <- system.file("templates/index.Rmd", package = "notestar")
  data_in_file <- rmarkdown::yaml_front_matter(template)
  data <- data_in_file |>
    utils::modifyList(data_args) |>
    utils::modifyList(list(index_rmd_body_lines = index_rmd_body_lines))

  tar_empty <- function(x) targets::tar_target_raw(x, quote(list()))
  tar_index_rmd_body <- list()
  tar_user_bibliography <- list()
  tar_user_csl <- list()
  tar_asset_csl <- tar_empty("notebook_csl_asset")
  tar_asset_bibliography <- tar_empty("notebook_bibliography_asset")

  tar_index_yaml_data <- targets::tar_target_raw(
    "notebook_index_yml",
    rlang::expr(list(!!! data))
  )

  if (length(bibliography) != 0) {
    sym_notebook_bibliography_user <- rlang::sym("notebook_bibliography_user")

    tar_user_bibliography <- targets::tar_target_raw(
      "notebook_bibliography_user",
      rlang::expr({
        file.path(
          !! dir_notebook,
          notebook_index_yml$bibliography_in
        )
      }),
      format = "file"
    )

    tar_asset_bibliography <- targets::tar_target_raw(
      "notebook_bibliography_asset",
      rlang::expr({
        path_out <- file.path(
          !! dir_md,
          "assets",
          notebook_index_yml$bibliography_in
        )
        file.copy(
          !! sym_notebook_bibliography_user,
          path_out,
          overwrite = TRUE
        )
        path_out
      }),
      format = "file"
    )
  }

  if (length(csl) != 0) {
    sym_notebook_csl_user <- rlang::sym("notebook_csl_user")

    tar_user_csl <- targets::tar_target_raw(
      "notebook_csl_user",
      rlang::expr({
        file.path(
          !! dir_notebook,
          notebook_index_yml$csl_in
        )
      }),
      format = "file"
    )

    tar_asset_csl <- targets::tar_target_raw(
      "notebook_csl_asset",
      rlang::expr({
        path_out <- file.path(
          !! dir_md,
          "assets",
          notebook_index_yml$csl_in
        )
        file.copy(
          !! sym_notebook_csl_user,
          path_out,
          overwrite = TRUE
        )
        path_out
      }),
      format = "file"
    )
  }

  tar_index_rmd <- targets::tar_target_raw(
    "notebook_index_rmd",
    command = rlang::expr({
      yml_header <- ymlthis::as_yml(notebook_index_yml) |>
        ymlthis::yml_discard(~ ymlthis::is_yml_blank(.x)) |>
        ymlthis::yml_discard("csl_in") |>
        ymlthis::yml_discard("bibliography_in") |>
        ymlthis::yml_discard("index_rmd_body_lines")

      path_index <- file.path(!! dir_notebook, "index.Rmd")

      lines <- c(
        crayon::strip_style(capture.output(print(yml_header))),
        "",
        notebook_index_yml$index_rmd_body_lines
      )
      writeLines(lines, path_index)
      path_index
    }),

    format = "file"
  )

  list(
    tar_index_yaml_data,
    tar_asset_bibliography,
    tar_user_bibliography,
    tar_asset_csl,
    tar_user_csl,
    tar_index_rmd
  )
}


path_if_lengthy <- function(file, ...) {
  if (length(file) != 0) {
    file.path(..., file)
  } else {
    file
  }
}



#' Assemble knitted notebook md files into a single-page bookdown document
#'
#' @param subdir_output Subdirectory of `dir_md` which will contain final html
#'   file produced by bookdown. Defaults to `"docs"`.
#' @param extra_deps A list of extra dependencies. These should be the names of
#'   targets defined elsewhere in the dependencies graph. Defaults to `list()`.
#'   Use this argument, for example, to force a notebook to depend on a `.css`
#'   file.
#' @param use_downlit whether to post-process the notebook with the downlit
#'   syntax highlighter. Default is `FALSE`.
#' @param markdown_document2_args arguments to pass onto
#'   [bookdown::markdown_document2()]. Defaults to `list()`.
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
  subdir_output = "docs",
  extra_deps = list(),
  use_downlit = FALSE,
  markdown_document2_args = list()
) {
  # Retrieve the configuration
  config <- notebook_config()
  dir_notebook <- config$dir_notebook
  dir_md <- config$dir_md
  theme <- config$cleanrmd_theme
  book_filename <- config$notebook_filename
  final_book_filename <- book_filename

  markdown_document2_args_defaults <- lazy_list(
    base_format = "cleanrmd::html_document_clean",
    theme = !! theme,
    toc = TRUE,
    mathjax = "default"
  )

  markdown_document2_args_defaults[names(markdown_document2_args)] <-
    markdown_document2_args
  markdown_document2_args_merged <- markdown_document2_args_defaults

  if (use_downlit) {
    css_downlit <- file.path(dir_md, "assets", "downlit.css")
    if (!file.exists(css_downlit)) {
      usethis::use_template(
        template = "downlit.css",
        package = "notestar",
        save_as = css_downlit
      )
    }
    book_filename <- paste0(".", book_filename)

    markdown_document2_args_merged$css <- c(
      markdown_document2_args_merged$css,
      "assets/downlit.css"
    )
  }


  # Prepare _output.yml
  target_output <- targets::tar_target_raw(
    "notebook_output_yaml",
    command = rlang::expr({
      ymlthis::yml_empty() |>
        ymlthis::yml_output(
          bookdown::markdown_document2(
            !!! markdown_document2_args_merged
          )
        ) |>
        ymlthis::yml_chuck("output") |>
        notebook_write_yaml(file.path(!! dir_md, "_output.yml"))
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
      ymlthis::yml_empty() |>
        ymlthis::yml_bookdown_opts(
          book_filename = !! book_filename,
          output_dir = !! subdir_output,
          delete_merged_file = TRUE,
          new_session = TRUE,
          before_chapter_script = basename(!! rlang::sym("notebook_helper")),
          rmd_files = basename(!! rlang::sym("notebook_mds"))
        ) |>
        notebook_write_yaml(
          file.path(
            !! dir_md,
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
        !! rlang::sym("notebook_output_yaml"),
        !! rlang::sym("notebook_bibliography_asset"),
        !! rlang::sym("notebook_csl_asset")
      )
      extra_deps <- !! expr_extra_deps
      rmarkdown::render_site(
        !! dir_md,
        encoding = "UTF-8"
      )

      path <- file.path(
        !! dir_md,
        !! subdir_output,
        paste0(!! book_filename, ".html")
      )

      path_final <- file.path(
        !! dir_md,
        !! subdir_output,
        paste0(!! final_book_filename, ".html")
      )

      if (!! use_downlit) {
        if (!rlang::is_installed("downlit")) {
          warning("`use_downlit` is `TRUE` but downlit is not installed.")
        } else {
          downlit::downlit_html_path(path, path_final)
        }
      }

      path_final

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

#' A list where expressions are evaluated sequentially and can
#' refer to earlier defined list entries
#' @param ... named expressions (key = value or key = expression). Tidy
#'   evaluation is supported.
#' @return the list with the expressions evaluated
#' @noRd
#' @keywords internal
#' @examples
#' value <- 0
#' lazy_list(
#'   a = 10,
#'   b = a + 1,
#'   value = 10,
#'   # rlang's data-masking rules apply
#'   value_data = value + 1,
#'   value_env = .env$value + 1
#' )
lazy_list <- function(...) {
  q <- rlang::enexprs(..., .named = TRUE, .check_assign = TRUE)
  data <- list()
  for (x in seq_along(q)) {
    data[names(q[x])] <- list(rlang::eval_tidy(q[[x]], data = data))
  }
  data
}


rmd_to_md <- function(x) {
  x <- gsub("[.]Rmd$", ".md", x = x)
  x <- gsub("[_]rmd$", "_md", x = x)
  x
}

md_to_rmd <- function(x) {
  x <- gsub("[.]md$", ".Rmd", x = x)
  x <- gsub("[_]md$", "_rmd", x = x)
  x
}


#' Knit a single notebook entry
#'
#' @export
#' @keywords internal
#' @param rmd_in path to the rmd file to knit
#' @param md_out path to the md file to create
#' @param helper_script path to an R script to run beforehand
#' @return a character vector where the first element is `md_out` and any
#'   additional elements are plots created during knitting.
#'
#' Knitting is done in a separate R process via [callr::r()].
#'
#' If the option `knitr::opts_knit$get("notestar_purge_figures")` is set to
#' `TRUE`, then the contents of the figures folder will be purged before
#' knitting the file.
notebook_knit_page <- function(rmd_in, md_out, helper_script) {
  x <- callr::r(
    knit_page,
    list(rmd_in = rmd_in, md_out = md_out, helper_script = helper_script)
  )
  x
}

knit_page <- function(rmd_in, md_out, helper_script) {
  requireNamespace("knitr")
  if (file.exists(helper_script)) {
    source(helper_script, local = TRUE)
  }

  dir_base <- dirname(md_out)
  dir_assets <- file.path(
    "assets",
    "figure",
    tools::file_path_sans_ext(basename(rmd_in)),
    "/"
  )
  dir_assets_full <- file.path(dir_base, dir_assets)

  # Clean out figures
  if (isTRUE(knitr::opts_knit$get("notestar_purge_figures"))) {
    if (dir.exists(dir_assets_full)) {
      old_files <- list.files(
        dir_assets_full,
        full.names = TRUE,
        recursive = TRUE
      )
      file.remove(old_files)
    }
  }
  knitr::opts_chunk$set(fig.path = dir_assets)
  knitr::opts_knit$set(base.dir = file.path(dir_base, "/"))
  knitr::knit(rmd_in, md_out, encoding = "UTF-8")

  # If we do not purge the figures folder beforehand, then there might a
  # leftover figure file that it is not part of the current results and
  # therefore cannot be rebuilt. That's why we have the outer condition: We only
  # track generated figures if we purge the figures folder.
  current_files <- character(0)
  if (isTRUE(knitr::opts_knit$get("notestar_purge_figures"))) {
    if (dir.exists(dir_assets_full)) {
      current_files <- list.files(
        dir_assets_full,
        full.names = TRUE,
        recursive = TRUE
      )
    }
  }


  if (isTRUE(knitr::opts_knit$get("notestar_clean_entry_yaml"))) {
    if (basename(rmd_in) != "index.Rmd") {
      front_matter <- rmarkdown::yaml_front_matter(md_out)
      if (utils::hasName(front_matter, "bibliography")) {
        warning(
          "`bibliography` yaml entry found in notebook entry: ", rmd_in,
          "\nPlease declare bibliography files in index.Rmd."
        )
        filename <- tempfile()
        front_matter$bibliography <- NULL
        yaml::write_yaml(front_matter, filename)
        new_yaml <- c("---", readLines(filename), "---")

        lines <- readLines(md_out)

        yaml_starts <- grep("^---$", lines)
        yaml_ends <- grep("^(---)|([.][.][.])$", lines)

        lines[yaml_starts[1]:yaml_ends[2]] <- ""

        lines[seq(yaml_starts[1], length.out = length(new_yaml))] <- new_yaml

        writeLines(lines, md_out)
      }
    }
  }

  c(md_out, current_files)
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
