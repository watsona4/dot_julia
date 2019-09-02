# KaTeX

[![Build Status](https://travis-ci.org/piever/KaTeX.jl.svg?branch=master)](https://travis-ci.org/piever/KaTeX.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/github/piever/KaTeX.jl?branch=master&svg=true)](https://ci.appveyor.com/project/piever/katex-jl)

This is a package to download KaTeX and make it available from Julia.

The files `"auto-render.min.js", "katex.min.css", "katex.min.js"` are in the folder `KaTeX.assetsdir`, whereas KaTeX fonts are in `KaTeX.fontsdir = joinpath(KaTeX.assetsdir, "fonts")`.
