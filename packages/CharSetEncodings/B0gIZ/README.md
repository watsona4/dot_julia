# CharSetEncodings

| **Info** | **Windows** | **Linux & MacOS** | **Package Evaluator** | **CodeCov** | **Coveralls** |
|:------------------:|:------------------:|:---------------------:|:-----------------:|:---------------------:|:-----------------:|
| [![][license-img]][license-url] | [![][app-s-img]][app-s-url] | [![][travis-s-img]][travis-url] | [![][pkg-s-img]][pkg-url] | [![][codecov-img]][codecov-url] | [![][coverall-s-img]][coverall-s-url]
| [![][gitter-img]][gitter-url] | [![][app-m-img]][app-m-url] | [![][travis-m-img]][travis-url] | [![][pkg-m-img]][pkg-url] | [![][codecov-img]][codecov-url] | [![][coverall-m-img]][coverall-m-url]

[license-img]:  http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat
[license-url]:  LICENSE.md

[gitter-img]:   https://badges.gitter.im/Join%20Chat.svg
[gitter-url]:   https://gitter.im/JuliaString/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge

[travis-url]:   https://travis-ci.org/JuliaString/CharSetEncodings.jl
[travis-s-img]: https://travis-ci.org/JuliaString/CharSetEncodings.jl.svg
[travis-m-img]: https://travis-ci.org/JuliaString/CharSetEncodings.jl.svg?branch=master

[app-s-url]:    https://ci.appveyor.com/project/ScottPJones/charsetencodings-jl
[app-m-url]:    https://ci.appveyor.com/project/ScottPJones/charsetencodings-jl/branch/master
[app-s-img]:    https://ci.appveyor.com/api/projects/status/08ylxl46exltiemd?svg=true
[app-m-img]:    https://ci.appveyor.com/api/projects/status/08ylxl46exltiemd/branch/master?svg=true

[pkg-url]:      http://pkg.julialang.org/?pkg=CharSetEncodings
[pkg-s-img]:    http://pkg.julialang.org/badges/CharSetEncodings_0.6.svg
[pkg-m-img]:    http://pkg.julialang.org/badges/CharSetEncodings_0.7.svg

[codecov-url]:  https://codecov.io/gh/JuliaString/CharSetEncodings.jl
[codecov-img]:  https://codecov.io/gh/JuliaString/CharSetEncodings.jl/branch/master/graph/badge.svg

[coverall-s-url]: https://coveralls.io/github/JuliaString/CharSetEncodings.jl
[coverall-m-url]: https://coveralls.io/github/JuliaString/CharSetEncodings.jl?branch=master
[coverall-s-img]: https://coveralls.io/repos/github/JuliaString/CharSetEncodings.jl/badge.svg
[coverall-m-img]: https://coveralls.io/repos/github/JuliaString/CharSetEncodings.jl/badge.svg?branch=master

## Architecture
This provides the basic types and mode methods for dealing with character sets, encodings,
and character set encodings.

## Types
Currently, there are the following types:

* `CodeUnitTypes`  a Union of the 3 codeunit types (UInt8, UInt16, UInt32) for convenience
* `CharSet`        a struct type, which is parameterized by the name of the character set and the type needed to represent a code point
* `Encoding`       a struct type, parameterized by the name of the encoding

## Built-in Character Sets / Character Set Encodings
* `Binary`  For storing non-textual data as a sequence of bytes, 0-0xff

* `ASCII`   ASCII (Unicode subset, 0-0x7f)
* `Latin`   Latin-1 (ISO-8859-1) (Unicode subset, 0-0xff)
* `UCS2`    UCS-2 (Unicode subset, 0-0xd7ff, 0xe000-0xffff, BMP only, no surrogates)
* `UTF32`   UTF-32 (Full Unicode, 0-0xd7ff, 0xe000-0x10ffff)

* `UniPlus` Unvalidated Unicode (i.e. like `String`, can contain invalid codepoints)

* `Text1`   Unknown 1-byte character set
* `Text2`   Unknown 2-byte character set
* `Text4`   Unknown 4-byte character set

## Built-in Encodings
* `UTF8Encoding`
* `Native1Byte`
* `Native2Byte`
* `Native4Byte`
* `NativeUTF16`
* `Swapped4Byte`
* `Swapped2Byte`
* `SwappedUTF16`
* `LE2`
* `BE2`
* `LE4`
* `BE4`
* `UTF16LE`
* `UTF16BE`
* `2Byte`
* `4Byte`
* `UTF16`

## Built-in CSEs
* `BinaryCSE`, `Text1CSE`, `ASCIICSE`, `LatinCSE`
* `Text2CSE`, `UCS2CSE`
* `Text4CSE`, `UTF32CSE`

* `UTF8CSE`    `UTF32CharSet`, all valid, using `UTF8Encoding`,
               conforming to the Unicode Organization's standard,
	       i.e. no long encodings, surrogates, or invalid bytes.

* `RawUTF8CSE` `UniPlusCharSet`, not validated, using `UTF8Encoding`,
               may have invalid sequences, long encodings, encode surrogates and characters
	       up to `0x7fffffff`

* `UTF16CSE`   `UTF32CharSet`, all valid, using `UTF16` Encoding (native order),
               conforming to the Unicode standard, i.e. no out of order or isolated surrogates.

## Internal Unicode subset types
* `_LatinCSE`   Indicates has at least 1 character > 0x7f, all <= 0xff
* `_UCS2CSE`    Indicates has at least 1 character > 0xff, all <= 0xffff
* `_UTF32CSE`   Indicates has at least 1 non-BMP character

## API
The `cse` function returns the character set encoding for a string type, string.
Returns `RawUTF8CSE` as a fallback for `AbstractString` (i.e. same as `String`)
The `charset` function returns the character set for a string type, string, character type, or character.
The `encoding` function returns the encoding for a type or string.
The `codeunit` function returns the code unit used for a character set encoding
The `cs"..."` string macro creates a CharSet type with that name
The `enc"..."` string macro creates an Encoding type with that name
The `@cse(cs, enc)` macro creates a character set encoding with the given character set and encoding

Also Exports the helpful constant `Bool` flags `BIG_ENDIAN` and `LITTLE_ENDIAN`
