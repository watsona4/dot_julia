# StrLiterals

| **Info** | **Windows** | **Linux & MacOS** | **Package Evaluator** | **CodeCov** | **Coveralls** |
|:------------------:|:------------------:|:---------------------:|:-----------------:|:---------------------:|:-----------------:|
| [![][license-img]][license-url] | [![][app-s-img]][app-s-url] | [![][travis-s-img]][travis-url] | [![][pkg-s-img]][pkg-s-url] | [![][codecov-img]][codecov-url] | [![][coverall-s-img]][coverall-s-url]
| [![][gitter-img]][gitter-url] | [![][app-m-img]][app-m-url] | [![][travis-m-img]][travis-url] | [![][pkg-m-img]][pkg-m-url] | [![][codecov-img]][codecov-url] | [![][coverall-m-img]][coverall-m-url]

[license-img]:  http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat
[license-url]:  LICENSE.md

[gitter-img]:   https://badges.gitter.im/Join%20Chat.svg
[gitter-url]:   https://gitter.im/JuliaString/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge

[travis-url]:   https://travis-ci.org/JuliaString/StrLiterals.jl
[travis-s-img]: https://travis-ci.org/JuliaString/StrLiterals.jl.svg
[travis-m-img]: https://travis-ci.org/JuliaString/StrLiterals.jl.svg?branch=master

[app-s-url]:    https://ci.appveyor.com/project/ScottPJones/strliterals-jl
[app-m-url]:    https://ci.appveyor.com/project/ScottPJones/strliterals-jl/branch/master
[app-s-img]:    https://ci.appveyor.com/api/projects/status/8462oq09ek07knos?svg=true
[app-m-img]:    https://ci.appveyor.com/api/projects/status/8462oq09ek07knos/branch/master?svg=true

[pkg-s-url]:    http://pkg.julialang.org/detail/StrLiterals
[pkg-m-url]:    http://pkg.julialang.org/detail/StrLiterals
[pkg-s-img]:    http://pkg.julialang.org/badges/StrLiterals_0.6.svg
[pkg-m-img]:    http://pkg.julialang.org/badges/StrLiterals_0.7.svg

[codecov-url]:  https://codecov.io/gh/JuliaString/StrLiterals.jl
[codecov-img]:  https://codecov.io/gh/JuliaString/StrLiterals.jl/branch/master/graph/badge.svg

[coverall-s-url]: https://coveralls.io/github/JuliaString/StrLiterals.jl
[coverall-m-url]: https://coveralls.io/github/JuliaString/StrLiterals.jl?branch=master
[coverall-s-img]: https://coveralls.io/repos/github/JuliaString/StrLiterals.jl/badge.svg
[coverall-m-img]: https://coveralls.io/repos/github/JuliaString/StrLiterals.jl/badge.svg?branch=master

The StrLiterals package is an attempt to bring a cleaner string literal syntax to Julia, as well as having an easier way of producing formatted strings, borrowing from both Python and C formatted printing syntax.  It also adds support for using LaTex, Emoji, HTML, or Unicode entity names that are looked up at compile-time.
This builds on the previous work in StringUtils and StringLiterals, but is based on the new Strs.jl package

Currently, it adds a Swift style string macro, `f"..."`, which uses the Swift syntax for
interpolation, i.e. `\(expression)`.  This means that you never have to worry about strings with
the $ character in them, which is rather frequent in some applications.
Also, Unicode sequences are represented as in Swift, i.e. as `\u{hexdigits}`, where there
can be from 1 to 6 hex digits. This syntax eliminates having to worry about always outputting
4 or 8 hex digits, to prevent problems with 0-9,A-F,a-f characters immediately following.

It also adds a string macro that instead of building a string, can print the strings and interpolated values directly, without having to create a string out of all the parts.
Finally, there are uppercase versions of the macros, which also supports the legacy sequences, $ for string interpolation, `\x` followed by 1 or 2 hex digits, `\u` followed by 1 to 4 hex digits, and `\U` followed by 1 to 8 hex digits.

The [StrFormat](https://github.com/JuliaString/StrFormat.jl) package adds type-based, C-style, and Python-style formatting, using the following escape characters (after `\`): `%` and `{`.
See the package for more details.

The [StrEntities](https://github.com/JuliaString/StrEntities.jl) package adds Emojis (starting with `\:` and ending with `:`), LaTeX entities (starting with `\<` and ending with `>`) similar to the Julia REPL, as well as HTML entities (starting with `&`, anding with `;`), and Unicode entities (starting with `\N{` and ending with `}` (similar to Python strings)
See the package for more details.

* `\` can be followed by: 0, $, ", ', \, a, b, e, f, n, r, t, u, v, (
(as well as any added by other packages, such as `StrFormat` or `StrEntities`)
In the legacy modes, x and U are also allowed after the `\`.
Unsupported characters give an error (as in Swift, and in recent Julia versions).

* `\0` outputs a nul byte (0x00) (note: as in Swift, octal sequences are not supported, just the nul byte)
* `\a` outputs the "alarm" or "bell" control code (0x07)
* `\b` outputs the "backspace" control code (0x08)
* `\e` outputs the "escape" control code (0x1b)
* `\f` outputs the "formfeed" control code (0x0c)
* `\n` outputs the "newline" or "linefeed" control code (0x0a)
* `\r` outputs the "return" (carriage return) control code (0x0d)
* `\t` outputs the "tab" control code (0x09)
* `\v` outputs the "vertical tab" control code (0x0b)

* `\u{<hexdigits>}` is used to represent a Unicode character, with 1-6 hex digits.

* `\(expression)` simply interpolates the value of the expression, the same as `$(expression)` in standard Julia string literals.
