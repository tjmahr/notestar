test_that("setting options works", {
  knitr::opts_chunk$restore()
  expect_equal(knitr::opts_chunk$get("comment"), "##")

  applied <- notebook_set_opts_chunk()

  expect_equal(
    knitr::opts_chunk$get("comment"),
    applied[["comment"]]
  )

  knitr::opts_chunk$restore()
})
