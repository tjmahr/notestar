.PHONY: targets clean

targets:
	Rscript --vanilla -e "                                            \
	  options(cli.num_colors = 256);                                  \
	  cli::cli_inform(R.version.string);                              \
	  targets::tar_make(reporter = 'verbose', callr_function = NULL); \
	  Sys.sleep(.25);                                                 \
	  cli::cat_rule('Makefile finished')                              \
	"

clean:
	Rscript --vanilla -e "                                            \
	  options(cli.num_colors = 256);                                  \
	  cli::cli_inform(R.version.string);                              \
	  targets::tar_prune(callr_function = NULL);                      \
	  Sys.sleep(.25);                                                 \
	  cli::cat_rule('Makefile finished')                              \
	"
