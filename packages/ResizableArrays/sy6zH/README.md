# Resizable arrays for Julia

| **Documentation**               | **License**                     | **Build Status**                                                | **Code Coverage**                                                   |
|:--------------------------------|:--------------------------------|:----------------------------------------------------------------|:--------------------------------------------------------------------|
| [![][doc-dev-img]][doc-dev-url] | [![][license-img]][license-url] | [![][travis-img]][travis-url] [![][appveyor-img]][appveyor-url] | [![][coveralls-img]][coveralls-url] [![][codecov-img]][codecov-url] |

The ResizableArray package provides multi-dimensional arrays which are
resizable and which are intended to be as efficient as Julia arrays.  This
circumvents the Julia limitation that only uni-dimensional arrays (of type
`Vector`) are resizable.  The only restriction is that the number of dimensions
of a resizable array must be left unchanged.

Resizable arrays may be useful in a variety of situations.  For instance to
avoid re-creating arrays and therefore to limit the calls to Julia garbage
collector which may be very costly for real-time applications.

Unlike [ElasticArrays](https://github.com/JuliaArrays/ElasticArrays.jl) which
provides arrays that can grow and shrink, but only in their last dimension, any
dimensions of ResizableArray instances can be changed (providing the number of
dimensions remain the same).  Another difference is that you may use a custom
Julia object to store the elements of a resizable array, not just a
`Vector{T}`.

[doc-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[doc-stable-url]: https://emmt.github.io/ResizableArrays.jl/stable

[doc-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[doc-dev-url]: https://emmt.github.io/ResizableArrays.jl/dev

[license-url]: ./LICENSE.md
[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat

[travis-img]: https://travis-ci.org/emmt/ResizableArrays.jl.svg?branch=master
[travis-url]: https://travis-ci.org/emmt/ResizableArrays.jl

[appveyor-img]: https://ci.appveyor.com/api/projects/status/github/emmt/ResizableArrays.jl?branch=master
[appveyor-url]: https://ci.appveyor.com/project/emmt/ResizableArrays-jl/branch/master

[coveralls-img]: https://coveralls.io/repos/emmt/ResizableArrays.jl/badge.svg?branch=master&service=github
[coveralls-url]: https://coveralls.io/github/emmt/ResizableArrays.jl?branch=master

[codecov-img]: http://codecov.io/github/emmt/ResizableArrays.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/emmt/ResizableArrays.jl?branch=master
