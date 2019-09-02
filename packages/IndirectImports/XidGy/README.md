# IndirectImports

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://tkf.github.io/IndirectImports.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://tkf.github.io/IndirectImports.jl/dev)
![GitHub commits since tagged version](https://img.shields.io/github/commits-since/tkf/IndirectImports.jl/v0.1.1.svg)
[![Build Status](https://travis-ci.com/tkf/IndirectImports.jl.svg?branch=master)](https://travis-ci.com/tkf/IndirectImports.jl)
[![Codecov](https://codecov.io/gh/tkf/IndirectImports.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/tkf/IndirectImports.jl)
[![Coveralls](https://coveralls.io/repos/github/tkf/IndirectImports.jl/badge.svg?branch=master)](https://coveralls.io/github/tkf/IndirectImports.jl?branch=master)

IndirectImports.jl lets Julia packages call and extend (a special type
of) functions without importing the package defining them.  This is
useful for managing optional dependencies.

* Compared to Requires.jl, IndirectImports.jl's approach is more
  static and there is no run-time `eval` hence more compiler friendly.
  However, unlike Requires.jl, both upstream and downstream packages
  need to rely on IndirectImports.jl API.

* Compared to "XBase.jl" approach, IndirectImports.jl is more flexible
  in the sense that you don't need to create an extra package and keep
  it in sync with the "implementation" package(s).  However, unlike
  "XBase.jl" approach, IndirectImports.jl is usable only for
  functions, not for types.

## Example

```julia
# MyPlot/src/MyPlot.jl
module MyPlot
    using IndirectImports

    @indirect function plot end  # declare an "indirect function"

    @indirect function plot(x)  # optional
        # generic implementation
    end
end

# MyDataFrames/src/MyDataFrames.jl
module MyDataFrames
    using IndirectImports

    @indirect import MyPlot  # this does not actually load MyPlot.jl

    # you can extend indirect functions
    @indirect function MyPlot.plot(df::MyDataFrame)
        # you can call indirect functions
        MyPlot.plot(df.columns)
    end
end
```

You can install it with `]add IndirectImports`.  See more details in
the [documentation](https://tkf.github.io/IndirectImports.jl/dev/).
