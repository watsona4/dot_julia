# ApplicationBuilderAppUtils

A small package providing utilities for applications built with
[`ApplicationBuilder.jl`](https://github.com/NHDaly/ApplicationBuilder.jl).

This is split out into a separate package so that users' application code does not need to
have a dependency on the `ApplicationBuilder` module itself.

Users should `Pkg.add("ApplicationBuilderAppUtils")` for their application's Project if they
want to use these utilities.
