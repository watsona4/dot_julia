# DumbCompleter

[![Build Status](https://travis-ci.com/christopher-dG/DumbCompleter.jl.svg?branch=master)](https://travis-ci.com/christopher-dG/DumbCompleter.jl)

A dumb code completer.

## Usage (Julia)

The main entrypoint to this package for Julia code is `completions`.

```julia
julia> using DumbCompleter: completions

julia> leaves = completions("P")
7-element Array{DumbCompleter.Leaf,1}:
 DumbCompleter.Leaf(:PROGRAM_FILE, String, Base)
 DumbCompleter.Leaf(:Pair, UnionAll, Base)
 DumbCompleter.Leaf(:PartialQuickSort, UnionAll, Base)
 DumbCompleter.Leaf(:PermutedDimsArray, UnionAll, Base)
 DumbCompleter.Leaf(:Pipe, DataType, Base)
 DumbCompleter.Leaf(:PipeBuffer, typeof(PipeBuffer), Base)
 DumbCompleter.Leaf(:Ptr, UnionAll, Core)

julia> leaf = first(leaves);

julia> leaf.name
:PROGRAM_FILE

julia> leaf.type
String

julia> leaf.mod
Base

julia> completions("P", Core)  # "Core" or :Core work, too.
4-element Array{DumbCompleter.Leaf,1}:
 DumbCompleter.Leaf(:PhiCNode, DataType, Core)
 DumbCompleter.Leaf(:PhiNode, DataType, Core)
 DumbCompleter.Leaf(:PiNode, DataType, Core)
 DumbCompleter.Leaf(:Ptr, UnionAll, Core)
```

To load some new modules, use `activate!`.

```julia
julia> using DumbCompleter: activate!, completions

julia> activate!(@__DIR__)

julia> DumbCompleter.completions("js")
1-element Array{DumbCompleter.Leaf,1}:
 DumbCompleter.Leaf(:json, typeof(JSON.Writer.json), JSON)

julia> DumbCompleter.completions("a", :Pkg)
2-element Array{DumbCompleter.Leaf,1}:
 DumbCompleter.Leaf(:activate, typeof(Pkg.API.activate), Pkg)
 DumbCompleter.Leaf(:add, typeof(Pkg.API.add), Pkg)
```

## Usage (Emacs)

First, make sure you have [Company](http://company-mode.github.io) set up.
Then, put `emacs/julia-dumbcompleter.el` somewhere on your load path.
Lastly, add `(require 'julia-dumbcompleter)` somewhere in your `init.el`.

To load modules from the package you're developing, use `jldc/activate` and enter your package's root directory.

## Integration

Supporting a new text editor is not too hard, and just involves maintaining a server process and its IO.
To start a server, run the following:

```julia
using DumbCompleter
ioserver()
```

Then, send requests to the server process's standard input as JSON.
Currently, the available commands are:

- `{"type": "completions", "module": "Module.Name.Or.Null", "text": "prefix_to_complete"}`
- `{"type": "activate", "path": "package/root/directory"}`

The JSON response, written to standard output, contains an `error` field which is `null` or a string describing an error.
For `completions` requests, the response contains a `completions` field that looks like this:

```json
[
  {
    "name":   "variable name",
    "type":   "value's type",
    "module": "module owning the type"
  }
]
```

For `activate` requests, the response contains no other fields.
