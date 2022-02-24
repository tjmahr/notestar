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


## Recap

  - Switched to using a `config.yml` file for storing `dir_notebook`,
    `dir_md` and `notebook_helper`. This file is created and populated
    by `use_notestar()`.
    
  - `dir_notebook` and other options that live in `config.yml` are no
    longer arguments to functions.



# notestar 0.0.0.9000

  - Added a `NEWS.md` file to track changes to the package.
