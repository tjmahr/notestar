test_that("setting options works", {
  knitr::opts_chunk$restore()
  expect_null(knitr::opts_chunk$get("dev"))

  applied <- notebook_set_opts_chunk()

  expect_equal(
    knitr::opts_chunk$get("dev"),
    applied[["dev"]]
  )

  knitr::opts_chunk$restore()
})
