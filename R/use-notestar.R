# usethis-like facilities




#' Create a new notebook page
#'
#' Creates a file with pattern `[notebook_dir]/[date][-slug].Rmd`.
#'
#' @param slug Optional "slug" (label) for the post. Defaults to `""`.
#' @param date Optional data to use. This date should have the format
#'   `YYYY-MM-DD`. Defaults to the current date.
#' @param notebook_dir Optional path to the folder with .Rmd files. Defaults to
#'   the `notebook_dir` stored in `tar_read(notebook_config)`.
#' @param open Whether to open the new file for editing. Defaults to
#'   `rlang::is_interactive()`.
#' @return Invisible returns the relative path to the created file.
#' @export
notebook_create_page <- function(
  slug = NULL,
  date = NULL,
  notebook_dir = NULL,
  open = TRUE
) {

  if (is.null(notebook_dir)) {
    config <- targets::tar_read_raw("notebook_config")
    notebook_dir <- config[["dir_notebook"]]
  }

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
