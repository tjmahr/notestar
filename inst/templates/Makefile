.PHONY: targets clean

targets:
	Rscript --vanilla -e "targets::tar_make(reporter = 'verbose'); cli::cat_rule('Makefile finished')"

clean:
	Rscript --vanilla -e "targets::tar_prune(); cli::cat_rule('Makefile finished')"
