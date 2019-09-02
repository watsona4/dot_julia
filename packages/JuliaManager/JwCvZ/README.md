# JuliaManager.jl / `jlm`: System image manager for Julia

[![Stable documentation][docs-stable-img]][docs-stable-url]
[![Latest documentation][docs-dev-img]][docs-dev-url]
[![Travis Status][travis-img]][travis-url]


`jlm` is a command line interface to configure Julia's system image to
be used for each project.


It also automatically create a system image with the change proposed
in
[RFC: a "workaround" for the multi-project precompilation cache problem without long-term code debt - Development / Internals - JuliaLang](https://discourse.julialang.org/t/22233).
Note that the default system image used by standard `julia` usage is
not modified by `jlm`.


## Quick usage

```julia
(v1.2) pkg> add JuliaManager
...

julia> using JuliaManager

julia> JuliaManager.install_cli()
...
```

You need to add `~/.julia/bin` to `$PATH` as would be indicated if it
not.  Then, you can use `jlm`:

```console
$ cd PATH/TO/YOUR/PROJECT

$ jlm init
...

$ jlm run
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.1.0 (2019-01-21)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

julia>
```

See `jlm --help` or the [documentation][docs-dev-url] for more
information.


[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://jlm.readthedocs.io/en/stable/
[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://jlm.readthedocs.io/en/latest/
[travis-img]: https://travis-ci.com/tkf/JuliaManager.jl.svg?branch=master
[travis-url]: https://travis-ci.com/tkf/JuliaManager.jl
