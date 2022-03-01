
# Trying to get the package check to pass.
# These packages are used in the targets but not in the package.
zzz_force_dependencies <- function() {
  cleanrmd::cleanrmd_themes()
  withr::with_options(NULL, NULL)
  spelling::get_wordlist()
}
