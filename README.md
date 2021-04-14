
<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- say directory, not folder -->

# notestar 📓⭐

<!-- badges: start -->
<!-- badges: end -->

notestar is a notebook system built on the targets package: *notes* with
*tar*gets. I originally called this package tarnotes, but that sounded
gross.

**This README and the package are under development.**

## Installation

You can install notestar from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("tjmahr/notestar")
```

## A demo notebook

Here is an example project/notebook showing how notestar combines
various .Rmd into a single HTML file:
<https://github.com/tjmahr/notestar-demo>.

## A small example

notestar works best inside of a data analysis project and specifically,
as a part of an RStudio project. That is, we have some directory for our
project. Everything we do or create will live in that directory, and
that directory is the default working directory for all of our R code.

Let’s create a new directory inside of a temporary directory and make
that the home base for our project.

``` r
project_dir <- file.path(tempdir(), pattern = "my-project")
dir.create(project_dir)
setwd(project_dir)
```

Nothing here!

``` r
fs::dir_tree(all = TRUE)
#> .
```

`use_notestar()` will populate the project folder with some boilerplate
files.

``` r
library(notestar)
use_notestar()
#> v Creating 'R/'
#> v Writing 'R/functions.R'
#> v Creating 'notebook/'
#> v Creating 'notebook/book/'
#> v Creating 'notebook/book/assets/'
#> v Writing 'notebook/index.Rmd'
#> v Writing 'notebook/book/knitr-helpers.R'
#> v Writing 'notebook/0000-00-00-references.Rmd'
#> v Writing '_targets.R'
#> v Setting active project to '<no active project>'
```

Now, we have the basic skeleton.

``` r
fs::dir_tree(all = TRUE)
#> .
#> +-- .here
#> +-- notebook
#> |   +-- 0000-00-00-references.Rmd
#> |   +-- book
#> |   |   +-- assets
#> |   |   \-- knitr-helpers.R
#> |   \-- index.Rmd
#> +-- R
#> |   \-- functions.R
#> \-- _targets.R
```

These will be documented in detail below, but we have a folder
`notebook` where we store our notebook entries (as RMarkdown files),
`notebook/book/` where we store the knitted versions of those entries
(as markdown files), and `_targets` which orchestrates the compilation
of the notebook.

`targets::tar_make()` will then compile the notebook by:

-   knitting each Rmd file in `notebook` *if* necessary
-   collating the md files in `notebook/book/` into a single-document
    bookdown book with bookdown/RMarkdown/pandoc (*if* necessary).

I say “*if* necessary” because targets only builds targets if the target
has not been built yet or if the target is out of data. Thus, notestar
doesn’t waste time regenerating earlier entries if they have not
changed.

Here we build the notebook and see targets build each target.

``` r
targets::tar_make()
#> -- Attaching packages --------------------------------------- tidyverse 1.3.0 --
#> v ggplot2 3.3.3     v purrr   0.3.4
#> v tibble  3.1.0     v dplyr   1.0.5
#> v tidyr   1.1.3     v stringr 1.4.0
#> v readr   1.4.0     v forcats 0.5.1
#> -- Conflicts ------------------------------------------ tidyverse_conflicts() --
#> x dplyr::filter() masks stats::filter()
#> x dplyr::lag()    masks stats::lag()
#> * run target notebook_config
#> * run target 0000-00-00-references.Rmd
#> * run target index.Rmd
#> * run target spellcheck_exceptions
#> * run target notebook_output_yaml
#> * run target notebook_helper
#> * run target notebook_rmds
#> * run target 0000-00-00-references.md
#> * run target index.md
#> * run target spellcheck_notebook
#> * run target notebook_mds
#> * run target spellcheck_report_results_change
#> * run target notebook_bookdown_yaml
#> * run target spellcheck_report_results
#> No spelling errors found.
#> * run target notebook
#> 
#> 
#> processing file: index.Rmd
#>   |                                                                              |                                                                      |   0%  |                                                                              |......................................................................| 100%
#>    inline R code fragments
#> 
#> 
#> output file: index.knit.md
#> 
#> "C:/Program Files/RStudio/bin/pandoc/pandoc" +RTS -K512m -RTS notebook.utf8.md --to html5 --from markdown+autolink_bare_uris+tex_math_single_backslash --output notebook.html --lua-filter "C:\Users\Tristan\Documents\R\win-library\4.0\bookdown\rmarkdown\lua\custom-environment.lua" --lua-filter "C:\Users\Tristan\Documents\R\win-library\4.0\rmarkdown\rmarkdown\lua\pagebreak.lua" --lua-filter "C:\Users\Tristan\Documents\R\win-library\4.0\rmarkdown\rmarkdown\lua\latex-div.lua" --metadata-file "C:\Users\Tristan\AppData\Local\Temp\Rtmp6VPNB2\file15f83a5f28f8" --self-contained --variable disable-fontawesome --variable title-in-header --highlight-style pygments --table-of-contents --toc-depth 3 --mathjax --variable "mathjax-url:https://mathjax.rstudio.com/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML" --template "C:/Users/Tristan/Documents/R/win-library/4.0/cleanrmd/template/cleanrmd.html" --include-in-header "C:\Users\Tristan\AppData\Local\Temp\Rtmp6VPNB2\rmarkdown-str15f822402bc2.html" 
#> 
#> Output created: docs/notebook.html
#> * end pipeline
```

If we ask it to build the book again, it skips everything but a special
spellchecking target set to always run.

``` r
targets::tar_make()
#> -- Attaching packages --------------------------------------- tidyverse 1.3.0 --
#> v ggplot2 3.3.3     v purrr   0.3.4
#> v tibble  3.1.0     v dplyr   1.0.5
#> v tidyr   1.1.3     v stringr 1.4.0
#> v readr   1.4.0     v forcats 0.5.1
#> -- Conflicts ------------------------------------------ tidyverse_conflicts() --
#> x dplyr::filter() masks stats::filter()
#> x dplyr::lag()    masks stats::lag()
#> v skip target notebook_config
#> v skip target 0000-00-00-references.Rmd
#> v skip target index.Rmd
#> v skip target spellcheck_exceptions
#> v skip target notebook_output_yaml
#> v skip target notebook_helper
#> v skip target notebook_rmds
#> v skip target 0000-00-00-references.md
#> v skip target index.md
#> v skip target spellcheck_notebook
#> v skip target notebook_mds
#> * run target spellcheck_report_results_change
#> v skip target notebook_bookdown_yaml
#> v skip target spellcheck_report_results
#> v skip target notebook
#> * end pipeline
```

Right now, our compiled notebook (`"notebook/book/docs/notebook.html"`)
is just the title page:

<img src="man/figures/README-shot1-1.png" width="35%" />

If we look at the project tree, we see some additions.

``` r
fs::dir_tree(all = TRUE)
#> .
#> +-- .here
#> +-- notebook
#> |   +-- 0000-00-00-references.Rmd
#> |   +-- book
#> |   |   +-- 0000-00-00-references.md
#> |   |   +-- assets
#> |   |   +-- docs
#> |   |   |   +-- 0000-00-00-references.md
#> |   |   |   +-- index.md
#> |   |   |   +-- notebook.html
#> |   |   |   \-- reference-keys.txt
#> |   |   +-- index.Rmd
#> |   |   +-- knitr-helpers.R
#> |   |   +-- notebook.rds
#> |   |   +-- _bookdown.yml
#> |   |   \-- _output.yml
#> |   \-- index.Rmd
#> +-- R
#> |   \-- functions.R
#> +-- shot1.png
#> +-- _targets
#> |   +-- meta
#> |   |   +-- meta
#> |   |   +-- process
#> |   |   \-- progress
#> |   \-- objects
#> |       +-- notebook_config
#> |       +-- notebook_rmds
#> |       +-- spellcheck_exceptions
#> |       +-- spellcheck_notebook
#> |       +-- spellcheck_report_results
#> |       \-- spellcheck_report_results_change
#> \-- _targets.R
```

Briefly, there are some md files in `notebook/book/` as well as some
bookdown-related files (.yaml files, .rds file). There is also the
output of bookdown in `notebook/book/docs`. `_targets/` is a new
directory. It is the object and metadata storage for targets.

We can create a new entry from a template using `notebook_create_page()`
and regenerate the notebook. (A slug is some words we include in the
filename to help remember what the entry is about.)

``` r
notebook_create_page(slug = "hello-world")
#> v Setting active project to 'C:/Users/Tristan/AppData/Local/Temp/Rtmpyo1pfG/my-project'
#> v Writing 'notebook/2021-04-14-hello-world.Rmd'
#> * Edit 'notebook/2021-04-14-hello-world.Rmd'
#> v 'notebook/2021-04-14-hello-world.Rmd' created
```

Now targets has to rebuild the notebook because there is a new entry
that needs to be folded in.

``` r
targets::tar_make()
#> -- Attaching packages --------------------------------------- tidyverse 1.3.0 --
#> v ggplot2 3.3.3     v purrr   0.3.4
#> v tibble  3.1.0     v dplyr   1.0.5
#> v tidyr   1.1.3     v stringr 1.4.0
#> v readr   1.4.0     v forcats 0.5.1
#> -- Conflicts ------------------------------------------ tidyverse_conflicts() --
#> x dplyr::filter() masks stats::filter()
#> x dplyr::lag()    masks stats::lag()
#> v skip target notebook_config
#> v skip target 0000-00-00-references.Rmd
#> * run target 2021-04-14-hello-world.Rmd
#> v skip target index.Rmd
#> v skip target spellcheck_exceptions
#> v skip target notebook_output_yaml
#> v skip target notebook_helper
#> * run target notebook_rmds
#> v skip target 0000-00-00-references.md
#> v skip target index.md
#> * run target 2021-04-14-hello-world.md
#> * run target spellcheck_notebook
#> * run target notebook_mds
#> * run target spellcheck_report_results_change
#> * run target notebook_bookdown_yaml
#> v skip target spellcheck_report_results
#> * run target notebook
#> 
#> 
#> processing file: index.Rmd
#>   |                                                                              |                                                                      |   0%  |                                                                              |......................................................................| 100%
#>    inline R code fragments
#> 
#> 
#> output file: index.knit.md
#> 
#> "C:/Program Files/RStudio/bin/pandoc/pandoc" +RTS -K512m -RTS notebook.utf8.md --to html5 --from markdown+autolink_bare_uris+tex_math_single_backslash --output notebook.html --lua-filter "C:\Users\Tristan\Documents\R\win-library\4.0\bookdown\rmarkdown\lua\custom-environment.lua" --lua-filter "C:\Users\Tristan\Documents\R\win-library\4.0\rmarkdown\rmarkdown\lua\pagebreak.lua" --lua-filter "C:\Users\Tristan\Documents\R\win-library\4.0\rmarkdown\rmarkdown\lua\latex-div.lua" --metadata-file "C:\Users\Tristan\AppData\Local\Temp\Rtmp4W2p22\file2618647a4e69" --self-contained --variable disable-fontawesome --variable title-in-header --highlight-style pygments --table-of-contents --toc-depth 3 --mathjax --variable "mathjax-url:https://mathjax.rstudio.com/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML" --template "C:/Users/Tristan/Documents/R/win-library/4.0/cleanrmd/template/cleanrmd.html" --include-in-header "C:\Users\Tristan\AppData\Local\Temp\Rtmp4W2p22\rmarkdown-str2618b09717b.html" 
#> 
#> Output created: docs/notebook.html
#> * end pipeline
```

That entry appears in the notebook.

<img src="man/figures/README-shot2-1.png" width="35%" />

From here, we go with the flow. We use targets as we normally would,
modifying `R/functions.R` and `targets.R` to set up our data-processing
pipeline. We can now use our notebook to do reporting and exploration as
part of our data-processing pipeline. Things we make with targets can be
`tar_read()` into our notebook entries and tracked as dependencies.

## How it all works \[todo\]

targets + bookdown + some tricks

``` r
fs::dir_tree(path = project_dir, all = TRUE)
```

-   `.here` is a sentinel file for the here package. It indicates where
    the project root is located.
-   `notebook/` houses the .Rmd files that become entries in the
    notebook. By default, it includes `index.Rmd` (a bookdown title
    page) and `0000-00-00-references.Rmd` (an entry for a pandoc
    bibliography provided at the end/bottom of the notebook).
-   `notebook/book/` houses the knitted versions of the `.Rmd` entries
    and a timestamped version of the `index.Rmd`. There is a special
    file here `knitr-helpers.R` which is run before the Rmd -&gt; md and
    before the md -&gt; notebook stage. `assets/` is where knitted
    images go and where other assets to include go.
-   `_targets.R` stores the workflow for building the notebook.
-   `R/functions.R` creates
