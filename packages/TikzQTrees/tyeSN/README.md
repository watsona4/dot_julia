# TikzQTrees.jl

[![Build Status](https://travis-ci.org/dharasim/TikzQTrees.jl.svg?branch=master)](https://travis-ci.org/dharasim/TikzQTrees.jl)
[![codecov.io](http://codecov.io/github/dharasim/TikzQTrees.jl/coverage.svg?branch=master)](http://codecov.io/github/dharasim/TikzQTrees.jl?branch=master)

Plotting trees using [TikzPictures.jl](https://github.com/JuliaTeX/TikzPictures.jl) and the latex package [tikz-qtree](https://www.ctan.org/pkg/tikz-qtree).

## Installation
The package can be installed by:
```
(v0.7) pkg> add https://github.com/dharasim/TikzQTrees.jl
```

TikzQTrees is build on top of [TikzPictures.jl](https://github.com/JuliaTeX/TikzPictures.jl). If you can install TikzPictures, you should also be able to use TikzQTrees.

## Usage

The package implements a wrapper type `TikzQTree` of tree data types which implement the functions
- `value(tree)` that returns the value of the root of the tree, and
- `children(tree)` that returns an iterator over the children of the root of the tree.

It also provides `SimpleTree`, an example of a type that can be wrapped into `TikzQTree`:

```julia
mutable struct SimpleTree{T}
    value    :: T
    children :: Vector{SimpleTree{T}}
end
```

TikzQTrees are converted into TikzPictures to show them in the Juno plot pane and IJulia notebooks. In the REPL, the tex code of the tikz-qtree is printed.

```julia
julia> using TikzQTrees, TikzPictures

julia> tree = SimpleTree("root", [SimpleTree("left"), SimpleTree("right")]);

julia> TikzQTree(tree)
[.root left right ]

julia> save(SVG("test_tree"), TikzPicture(TikzQTree(tree)))

```

The saved plot is:

<p align="center">
  <img src="tree_plots/test_tree.svg" width="140"/>
</p>

## One more thing

This package additionally provides the macro `@qtree` for pretty printing of Julia's syntax trees:

```julia
julia> qt = @qtree a * (b+c) == a*b + a*c
[.{==} [.{*} {a} [.{+} {b} {c} ] ] [.{+} [.{*} {a} {b} ] [.{*} {a} {c} ] ] ]

julia> save(SVG("distributivity"), TikzPicture(qt))

```

<p align="center">
  <img src="tree_plots/distributivity.svg" width="300"/>
</p>

[TreeView.jl](https://github.com/JuliaTeX/TreeView.jl) is a related package that implements a macro `@tree` which is build on top of [TikzGraphs.jl](https://github.com/JuliaTeX/TikzGraphs.jl).
