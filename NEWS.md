# notestar (development version)

## Switch to config.yml for storing options

The backend of notestar has changed to rely on a `config.yml` file for
storing options like `dir_notebook`, `dir_md`, `notebook_helper`.

Previously, these were passed to `tar_notebook_pages()` and they were
added as targets. The upside of this approach was that
`tar_read("notebook_config")` could read in these configuration options,
and other targets could depend on these values. The downside of this
approach is that these configuration options could not read by other
functions, like `notebook_create_page()`, could not be used unless
`tar_make()` had been run.

Now, these are options are set and stored in a `config.yml` file that is
created when `use_notestar()` is run. Additionally, the configuration
options stored in this file are no longer set-able by other functions.
For example, `tar_notebook(..., dir_md)` would let a user set and
override the location for `dir_md`. This `dir_md` argument has been
removed.

## Other changes

There is now a `tar_notebook_index_rmd()` function that creates the
`index.Rmd` file programmatically. In the built-in `_targets.R`
template, it has the placeholders:

```
tar_notebook_index_rmd(
  title = "Notebook Title",
  author = "Author Name",
  # bibliography = "refs.bib",
  # csl = "apa.csl"
)
```

The bibliography and csl files should files inside of the notebook
folder (alongside the .Rmd files). When these files are used in this
way, they are tracked as dependencies for the whole notebook. They are
copied to the `assets/` subdirectory of the knitted notebook folder
(where the .md files live). `use_notestar_references()` will provide
starter files for `refs.bib` (which you have to edit) and `apa.csl`
(which you should not edit).


## Bullet-point summary

  - Switched to using a `config.yml` file for storing `dir_notebook`,
    `dir_md`, `notebook_helper`, `cleanrmd_theme`, and
    `notebook_filename`. This file is created and populated by
    `use_notestar()`.
    
  - `dir_notebook` and other options that live in `config.yml` are no
    longer arguments to functions.
    
  - `tar_notebook_index_rmd()` add to create a index.Rmd
    programmatically.
  
  - The notebook helper now lives in the notebook folder (alongside the
    .Rmd files). This file gets copied to the knitted notebook folder.
    
  - `use_notestar_references()` provides `refs.bib` and `apa.csl`
    starter files.




# notestar 0.0.0.9000

  - Added a `NEWS.md` file to track changes to the package.
