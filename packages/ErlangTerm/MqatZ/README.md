# ErlangTerm

*(De-)serialize Julia data in Erlang's external term format*

[![Build Status Unix][travis-badge]][travis-url] [![Build Status Windows][av-badge]][av-url] [![Codecov][codecov-badge]][codecov-url]

**ErlangTerm.jl** teaches Julia to talk to BEAM-based languages (Erlang, Elixir, ...) in their native tongue,
the [Erlang external term format](http://erlang.org/doc/apps/erts/erl_ext_dist.html).
The following data types are supported:

- `Int` <-> `Integer`
- `Float64` <-> `Float`
- `Symbol` <-> `Atom`
- `Tuple` <-> `Tuple`
- `Array` <-> `List`
- `Dict` <-> `Map`

## Installation

The package can be installed through Julia's package manager:

```julia
julia> import Pkg; Pkg.add("ErlangTerm")
```

## Usage

```julia
using ErlangTerm

# Take a Julia data structure...
d = Dict(:erlang => Dict(:id => 1, :greeting => "Hello, Erlang!"),
         :elixir => Dict(:id => 2, :greeting => "Hello, Elixir!"))

# ...serialize it...
binary = serialize(d)

# ...and deserialize it!
d1 = deserialize(binary)
```

[travis-badge]: https://travis-ci.org/helgee/ErlangTerm.jl.svg?branch=master
[travis-url]: https://travis-ci.org/helgee/ErlangTerm.jl
[av-badge]: https://ci.appveyor.com/api/projects/status/g0vxu3949t7gv744?svg=true
[av-url]: https://ci.appveyor.com/project/helgee/erlangterm-jl
[codecov-badge]: http://codecov.io/github/helgee/ErlangTerm.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/helgee/ErlangTerm.jl?branch=master
