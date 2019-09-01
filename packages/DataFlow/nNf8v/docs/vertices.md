DataFlow provides two things, a graph data structure and a common syntax for describing graphs. You're not tied down to using either of these things; you could use the syntax and immediately convert graphs to an adjacency matrix for processing, for example, or you could generate the graphs through other means while taking advantage of DataFlow's library of common graph operations.

DataFlow explicitly keeps the data structure very simple and doesn't try to attach any kind of meaning to it. The graphs could represent straightforward Julia programs, or Bayesian networks, or an electrical circuit. Libraries using DataFlow will probably want to extend the syntax and manipulate the graph in order to generate appropriate code for the application.

## Data Structures

DataFlow actually comes with two related data structures, the `DVertex` and the `IVertex`. Both represent nodes in a graph with inputs/outputs to/from other nodes in the graph. `IVertex` is input-linked, somewhat like a linked list – it keeps a reference to nodes which serve as input. `DVertex` is doubly-linked, analogous to a doubly-linked list – it refers to its input as well as all the nodes which take it as input. DVertex are technically more expressive but are also much harder to work with, so it's usually best to convert to input-linked as soon as possible (via `DataFlow.il()` for example).

```julia
type IVertex{T} <: Vertex{T}
  value::T
  inputs::Vector{IVertex{T}}
  # outputs::Set{IVertex{T}} # DVertex has this in addition
end
```

`IVertex` can be seen as very similar to an `Expr` object in Julia. For example, the expression `x+length(xs)` will be stored in a very similar way:

```julia
Expr(:call, :+, x, Expr(:call, :length, :xs))
IVertex(:+, IVertex(:x), IVertex(:length, IVertex(:xs)))
```

The key difference is that *object identity* is important in DataFlow graphs. Say we build an expression tree like this:

```julia
foo = Expr(:call, :length, :xs)
Expr(:call, :+, foo, foo)
```

This prints as `length(xs)+length(xs)` regardless of the fact that we reused the `length(xs)` expression object. In DataFlow the reuse makes a big difference:

```julia
g = IVertex{Any}

g(:+, g(:length, g(:xs)), g(:length, g(:xs)))
> IVertex(length(xs) + length(xs))

foo = g(:length, g(:xs))
g(:+, foo, foo)
> IVertex(
  gazelle = length(xs)
  gazelle + gazelle)
```

The reuse is now encoded in the program graph. Note that the data structure above has no conception of a "variable" since the flow of data is directly represented; instead, variables will be generated for us if and when they are needed in the syntax conversion.

## Algorithms

The basic approach to working with DataFlow graphs is to use the same techniques as are used for trees in functional programming. That is, you can write algorithms which generate a new graph by recursively walking over the old one. This is packaged up in functions like `prewalk` and `postwalk` which allow you apply a function to each node in the graph.

For example:

```julia
foo = g(:+, g(:length, g(:xs)), g(:length, g(:ys)))
> IVertex{Any}(length(xs)+length(ys))

postwalk(foo) do v
  value(v) == :length && value(v[1]) == :xs ? g(:lx) : v
end
> IVertex(lx + length(ys))
```

(The difference between `pre`- and `postwalk` is the order of traversal, which you can see using `@show`.) In this way you can do things like find and replace on graphs, as well as more complex structural transformations. At this point we also have everything we need to implement common subexpression elimination:

```julia
cse(v::IVertex, cache = Dict()) =
  postwalk(x -> get!(cache, x, x), v)
```

We replace each node in the graph by retrieving it from a dict where values refer to themselves. This ensures that any values that are `==` will also be `===` in the resulting graph, so that common expressions are reused.

```julia
foo = @flow length(xs)+length(xs)
> DVertex(length(xs) + length(xs))

cse(foo)
> IVertex(
  ram = length(xs)
  ram + ram)
```

Generally you should be able to stick to using DataFlow's high-level operations like `postwalk`, but in some cases you may need to write a recursive algorithm from scratch. This looks exactly like writing the same algorithm over a tree, with the caveats that (1) identical nodes may be reached by more than one route down the tree and (2) there may be cycles in the graph which cause infinite loops for naive recursion. This sounds like a nightmare but in fact we can kill these two tricky birds with a single stone; we simply memoize the function so that visiting repeated nodes ends the recursion. Make sure to cache the result of the current call *before* recursing.

```julia
function replace_xs(g, cache = ObjectIdDict())
  # Early exit if we've already processed this node
  haskey(cache, g) && return cache[g]
  # Create the new (empty) node and cache it
  cache[g] = g′ = typeof(g)(value(g) == :xs ? :foo : value(g))
  # For each input of the original node, process it and push
  # the result into the new node
  thread!(g′, (replace_xs(v, cache) for v in inputs(g))...)
end

foo = DataFlow.cse(@flow length(xs)+length(xs))
> IVertex(
  ant = length(xs)
  ant + ant)

replace_xs(foo)
> IVertex(
  manatee = length(foo)
  manatee + manatee)
```

In this case forgetting the cache would result in a fairly un-disastrous `length(foo)+length(foo)`, but in other cases it could result in a hang.
