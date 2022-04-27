.PHONY: targets clean

targets:
	Rscript --vanilla -e "                                              \
	  options(cli.num_colors = 256, renv.config.startup.quiet = FALSE); \
	  cli::cli_inform(R.version.string);                                \
	  if (file.exists('renv.lock')) renv::load();                       \
	  targets::tar_make(reporter = 'verbose', callr_function = NULL);   \
	  Sys.sleep(.25);                                                   \
	  cli::cat_rule('Makefile finished')                                \
	"

clean:
	Rscript --vanilla -e "                                              \
	  options(cli.num_colors = 256, renv.config.startup.quiet = FALSE); \
	  cli::cli_inform(R.version.string);                                \
	  if (file.exists('renv.lock')) renv::load();                       \
	  targets::tar_prune(callr_function = NULL);                        \
	  Sys.sleep(.25);                                                   \
	  cli::cat_rule('Makefile finished')                                \
	 "
