# StrEntities

| **Info** | **Windows** | **Linux & MacOS** | **Package Evaluator** | **CodeCov** | **Coveralls** |
|:------------------:|:------------------:|:---------------------:|:-----------------:|:---------------------:|:-----------------:|
| [![][license-img]][license-url] | [![][app-s-img]][app-s-url] | [![][travis-s-img]][travis-url] | [![][pkg-s-img]][pkg-s-url] | [![][codecov-img]][codecov-url] | [![][coverall-s-img]][coverall-s-url]
| [![][gitter-img]][gitter-url] | [![][app-m-img]][app-m-url] | [![][travis-m-img]][travis-url] | [![][pkg-m-img]][pkg-m-url] | [![][codecov-img]][codecov-url] | [![][coverall-m-img]][coverall-m-url]

[license-img]:  http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat
[license-url]:  LICENSE.md

[gitter-img]:   https://badges.gitter.im/Join%20Chat.svg
[gitter-url]:   https://gitter.im/JuliaString/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge

[travis-url]:   https://travis-ci.org/JuliaString/StrEntities.jl
[travis-s-img]: https://travis-ci.org/JuliaString/StrEntities.jl.svg
[travis-m-img]: https://travis-ci.org/JuliaString/StrEntities.jl.svg?branch=master

[app-s-url]:    https://ci.appveyor.com/project/ScottPJones/strentities-jl
[app-m-url]:    https://ci.appveyor.com/project/ScottPJones/strentities-jl/branch/master
[app-s-img]:    https://ci.appveyor.com/api/projects/status/5pj0ubfrai4dsp0r?svg=true
[app-m-img]:    https://ci.appveyor.com/api/projects/status/5pj0ubfrai4dsp0r/branch/master?svg=true

[pkg-s-url]:    http://pkg.julialang.org/?pkg=StrEntities?ver=0.7
[pkg-m-url]:    http://pkg.julialang.org/?pkg=StrEntities?ver=0.7
[pkg-s-img]:    http://pkg.julialang.org/badges/StrEntities_0.6.svg
[pkg-m-img]:    http://pkg.julialang.org/badges/StrEntities_0.7.svg

[codecov-url]:  https://codecov.io/gh/JuliaString/StrEntities.jl
[codecov-img]:  https://codecov.io/gh/JuliaString/StrEntities.jl/branch/master/graph/badge.svg

[coverall-s-url]: https://coveralls.io/github/JuliaString/StrEntities.jl?branch=master?ver=0.6
[coverall-m-url]: https://coveralls.io/github/JuliaString/StrEntities.jl?branch=master?ver=0.7
[coverall-s-img]: https://coveralls.io/repos/github/JuliaString/StrEntities.jl/badge.svg?branch=master?ver=0.6
[coverall-m-img]: https://coveralls.io/repos/github/JuliaString/StrEntities.jl/badge.svg?branch=master?ver=0.7

StrEntities extends the string literals provided by the [StrLiterals](https://github.com/JuliaString/StrLiterals.jl) package.
It adds support for HTML, LaTeX, Unicode and Emoji entities, provided by the packages:
* [HTML_Entities](https://github.com/JuliaString/HTML_Entities.jl)
* [LaTeX_Entities](https://github.com/JuliaString/LaTeX_Entities.jl)
* [Emoji_Entities](https://github.com/JuliaString/Emoji_Entities.jl)
* [Unicode_Entities](https://github.com/JuliaString/Unicode_Entities.jl)

This adds four ways of representing characters in the literal string,
`\:emojiname:`, `\<latexname>`, `\&htmlname;` and `\N{UnicodeName}`.
This makes life a lot easier when you want to keep the text of a program in ASCII, and
also to be able to write programs using those characters that might not even display
correctly in their editor.

* `\<` followed by a LaTeX entity name followed by `>` outputs that character or sequence if the name is valid.
* `\:` followed by an Emoji name followed by `:` outputs that character or sequence (if a valid name)
* `\&` followed by an HTML entity name followed by `;` outputs that character or sequence (if a valid name)
* `\N{` followed by a Unicode entity name (case-insensitive!) followed by a `}` outputs that Unicode character (if a valid name)
