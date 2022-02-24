
tar_notebook_config <- function(
  dir_notebook = "notebook",
  dir_md = "notebook/book",
  notebook_helper = "notebook/book/knitr-helpers.R"
) {
  targets::tar_target_raw(
    "notebook_config",
    rlang::expr(
      list(
        dir_notebook = !! dir_notebook,
        dir_md = !! dir_md,
        notebook_helper = !! notebook_helper
      )
    )
  )
}


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
#' * `notebook_helper`, a file for the helper R script.
#' * one file target for each input Rmd file. Any targets used
#'   with `tar_read()` or `tar_load()` inside these files are detected
#'   and checked for changes.
#' * one file target for each output md file.
#' * `notebook_rmds`, a combined target for the input Rmd files.
#' * `notebook_pages`, a combined target for the output md files.
#'
#' @export
#' @importFrom rlang `%||%`
tar_notebook_pages <- function() {
  config <- notebook_config()
  dir_notebook <- config$dir_notebook
  dir_md <- config$dir_md
  notebook_helper <- config$notebook_helper

  # f_notebook_helper <- function() notebook_helper

  rmds <- notebook_rmd_collate(dir_notebook)
  values <- lazy_list(
    rmd_file = !! rmds,
    rmd_page_raw = basename(.data$rmd_file),
    rmd_page = paste0("entry_", .data$rmd_page_raw) %>%
      janitor::make_clean_names(),
    sym_rmd_page = rlang::syms(.data$rmd_page),
    rmd_deps = lapply(.data$rmd_file, tarchetypes::tar_knitr_deps_expr),
    md_page = rmd_to_md(.data$rmd_page),
    md_page_raw = rmd_to_md(.data$rmd_page_raw),
    md_file = file.path(!! dir_md, .data$md_page_raw)
  )
  # Give bookdown an index.Rmd file
  values$md_file[1] <- md_to_rmd(values$md_file[1])

  # Need to figure out how to make this happen.
  # # Link index_rmd to target created by tar_notebook_index_rmd
  values$sym_rmd_page[[1]] <- rlang::sym("notebook_index_rmd")
  values$rmd_page[[1]] <- "notebook_index_rmd"

  values_no_index <- lapply(values, function(x) x[-1])

  list(
    # targets::tar_target(notebook_helper, !! f_notebook_helper(), format = "file"),
    targets::tar_target_raw(
      "notebook_helper",
      rlang::inject(notebook_helper),
      format = "file"
    ),
    # Prepare targets for each of the notebook pages
    tarchetypes::tar_eval_raw(
      quote(
        targets::tar_target(rmd_page, rmd_file, format = "file")
      ),
      values = values_no_index
    ),

    tarchetypes::tar_eval_raw(
      quote(
        targets::tar_target(
          md_page,
          command = {
            rmd_deps
            sym_rmd_page
            notebook_knit_page(rmd_file, md_file, notebook_helper)
            # md_file
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
#' @param bibliography,csl Name of a `.bib` file in the `dir_notebook` rmd folder.
#'   This file is copied to `[dir_md]/assets/[bibliography]` and saved in the
#'   YAML metadata in index.Rmd as "./assets/[bibliography]". Defaults to
#'   [ymlthis::yml_blank()]. This file is then tracked with
#'   targets and set as a dependency for `tar_notebook()`.
#' @param csl Name of a `.csl` file in the `dir_notebook` rmd folder.
#'   This file is copied to `[dir_md]/assets/[csl]` and saved in the
#'   YAML metadata in index.Rmd as "./assets/[csl]". Defaults to
#'   [ymlthis::yml_blank()]. This file is then tracked with
#'   targets and set as a dependency for `tar_notebook()`.
#' @param ... Additional key-value pairs for setting fields in the yml metadata.
#'   For example, `subtitle = "Status: Project completed"` would add a subtitle
#'   to the index.Rmd file and that subtitle would appear in the notebook. These
#'   fields cannot include `"date"` or `"site"`.
#' @param .list Alternatively, these YAML fields may be set using a list. Any
#'   key-value pairs in this list will override options set by arguments. For
#'   example, an `author` entry in `.list` would override the value in the
#'   `author` parameter.
#' @param dir_notebook The notebook directory. Defaults to `"notebook"`.
#' @return a list of targets:
#'  - `notebook_bibliography_user`, `notebook_csl_user`: file targets for
#'    the bibliography and csl files in the `dir_notebook` user folder.
#'  - `notebook_bibliography_asset`, `notebook_csl_asset`: file targets for
#'    the bibliography and csl files in the `dir_md` assets folder. These
#'    command to build these targets to copy them.
#'  - `notebook_deps_in_index_yml`: a list with the names of asset
#'    bibliography and asset csl targets if they are present. Can be an
#'    empty list.
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

  # Determine the template to use
  template_expected <- file.path(dir_notebook, "index.Rmd")
  template <- if (file.exists(template_expected)) {
    template_expected
  } else {
    usethis::use_template(
      template = "index.Rmd",
      save_as = template_expected,
      package = "notestar"
    )
  }

  # Resolve which arguments to use from user
  data_in_named_args <- list(
    title = title,
    author = author,
    bibliography = bibliography,
    csl = csl
  )

  data_args <- data_in_named_args %>%
    utils::modifyList(.list, keep.null = TRUE)

  data_args$csl_in <- data_args$csl
  data_args$csl <- path_if_lengthy(data_args$csl, "./assets")
  data_args$bibliography_in <- data_args$bibliography
  data_args$bibliography <- path_if_lengthy(data_args$bibliography, "./assets")

  data_in_file <- rmarkdown::yaml_front_matter(template)

  data <- data_in_file %>%
    utils::modifyList(data_args)

  tar_user_bibliography <- list()
  tar_asset_bibliography <- list()
  tar_user_csl <- list()
  tar_asset_csl <- list()
  notebook_deps <- list()

  if (length(bibliography) != 0) {
    tar_user_bibliography <- targets::tar_target_raw(
      "notebook_bibliography_user",
      rlang::expr({
        file.path(
          !! dir_notebook,
          !! data$bibliography_in
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
          !! data$bibliography_in
        )
        file.copy(notebook_bibliography_user, path_out)
        path_out
      }),
      format = "file"
    )

    notebook_deps <- append(notebook_deps, quote(notebook_bibliography_asset))
  }

  if (length(csl) != 0) {
    tar_user_csl <- targets::tar_target_raw(
      "notebook_csl_user",
      rlang::expr({
        file.path(
          !! dir_notebook,
          !! data$csl_in
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
          !! data$csl_in
        )
        file.copy(notebook_csl_user, path_out)
        path_out
      }),
      format = "file"
    )
    notebook_deps <- append(notebook_deps, quote(notebook_csl_asset))
  }

  tar_yml_deps <- targets::tar_target_raw(
    "notebook_deps_in_index_yml",
    command = rlang::expr({ !!! notebook_deps })
  )


  yml_header <- ymlthis::as_yml(data) %>%
    ymlthis::yml_discard(~ ymlthis::is_yml_blank(.x)) %>%
    ymlthis::yml_discard("csl_in") %>%
    ymlthis::yml_discard("bibliography_in")

  tar_index_rmd <- targets::tar_target_raw(
    "notebook_index_rmd",
    command = rlang::expr({
      path_index <- file.path(
        !! dir_notebook,
        "index.Rmd"
      )
      withr::local_options(list(usethis.overwrite = TRUE))
      create_file <- ymlthis::use_index_rmd(
        ymlthis::as_yml(list(!!! yml_header)),
        template = path_index,
        path = !! dir_notebook,
        quiet = TRUE,
        open_doc = FALSE,
        include_yaml = FALSE
      )

      path_index
    }),

    format = "file"
  )

  list(
    tar_asset_bibliography,
    tar_user_bibliography,
    tar_asset_csl,
    tar_user_csl,
    tar_yml_deps,
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
#' @param theme Theme to use for `cleanrmd::html_document_clean()`. Defaults to
#'   `"water"`.
#' @param book_filename Name to use for the final html file. Defaults to
#'   `"notebook"` which produces `"notebook.html"`.
#' @param subdir_output Subdirectory of `dir_md` which will contain final html
#'   file produced by bookdown. Defaults to `"docs"`.
#' @param extra_deps A list of extra dependencies. These should be the names of
#'   targets defined elsewhere in the dependencies graph. Defaults to `list()`.
#'   Use this argument, for example, to force a notebook to depend on a `.css`
#'   file.
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
  theme = "water",
  book_filename = "notebook",
  subdir_output = "docs",
  extra_deps = list(),
  markdown_document2_args = list()
) {
  # Retrieve the configuration
  config <- notebook_config()
  dir_notebook <- config$dir_notebook
  dir_md <- config$dir_md

  markdown_document2_args_defaults <- lazy_list(
    base_format = "cleanrmd::html_document_clean",
    theme = !! theme,
    toc = TRUE,
    mathjax = "default"
  )

  markdown_document2_args_defaults[names(markdown_document2_args)] <-
    markdown_document2_args
  markdown_document2_args_merged <- markdown_document2_args_defaults

  # Prepare _output.yml
  target_output <- targets::tar_target_raw(
    "notebook_output_yaml",
    command = rlang::expr({
      ymlthis::yml_empty() %>%
        ymlthis::yml_output(
          bookdown::markdown_document2(
            !!! markdown_document2_args_merged
          )
        ) %>%
        ymlthis::yml_chuck("output") %>%
        notebook_write_yaml(
          file.path(
            !! dir_md,
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
        !! rlang::sym("notebook_deps_in_index_yml")
      )
      extra_deps <- !! expr_extra_deps
      rmarkdown::render_site(
        !! dir_md,
        encoding = "UTF-8"
      )
      file.path(
        !! dir_md,
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
