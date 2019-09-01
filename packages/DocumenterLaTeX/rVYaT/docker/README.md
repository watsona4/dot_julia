# documenter-latex

[![Docker hub](https://img.shields.io/badge/docker-hub-blue.svg)](https://hub.docker.com/r/juliadocs/documenter-latex/)

Docker image for compiling pdf output with
[`Documenter.jl`](https://github.com/JuliaDocs/Documenter.jl) and
[`DocumenterLaTeX.jl`](https://github.com/JuliaDocs/DocumenterLaTeX.jl).

## Whats in the image?

Ubuntu + a (minimal) texlive installation, essentially only including what's
needed for compiling the output of `Documenter.jl`/`DocumenterLaTeX.jl`.
