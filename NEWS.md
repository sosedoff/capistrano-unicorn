# Capistrano Unicorn NEWS

## 0.2.0

Significant changes since 0.1.10 are as follows.  Backwards-incompatible changes are **in bold**.

*   Ensured `RAILS_ENV` is set correctly.
*   Embedded multistage docs directly within the [README](README.md) (the wiki page was version-specific and misleading).
*   Significantly tidied up the usage and documentation of configuration variables:
    *   **In most cases, it should now be sufficient to simply set `rails_env` correctly,
        and other variables should assume the correct value by default.**
    *   **Make `unicorn_env` default to `rails_env` or `'production'`.**
    *   **Rename `app_env` to `unicorn_rack_env` and fix default value.**
    *   Add `unicorn_options` variable which allows passing of arbitrary options to unicorn.
    *   Added `app_subdir` to support app running in a subdirectory.
    *   Updated documentation in [README](README.md) to fix inaccuracies and ambiguities.
    *   `unicorn_pid` defaults to attempting to auto-detect from unicorn config file.
        This avoids having to keep two paths in sync.
        https://github.com/sosedoff/capistrano-unicorn/issues/7
    *   Also added the `unicorn:show_vars` task to make it easier to debug
        config variable values client-side.
*   Defer calculation of `unicorn-roles`.

It was noticed that there are a
[huge number of unmerged forks on github](https://github.com/sosedoff/capistrano-unicorn/issues/45),
so we also updated the [README](README.md) asking the community to
contribute back any useful changes they make.
