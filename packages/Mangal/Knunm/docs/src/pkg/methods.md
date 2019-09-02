This page presents the basic functions to access all of the data stored in
*mangal*.

!!! note "Naming conventions"
    Functions whose name is plural (*e.g* `networks`) will return a `Vector` of
    their type. Functions whose name is singular (*e.g.* `network`) return a single
    object. All functions returning a `Vector` can accept `Pair` object for querying.

In addition to the search by name (when available) and ID (for all objects),
most of the functions have methods to work on other types of objects. For
example, `networks` has a function taking a `MangalDataset` as an object, which
will retrieve the networks belonging to this dataset.

!!! danger "Paging matters!"
    The server returns (by default) 200 objects for a given query, and this number
    can be increased up to 1000. This may not be sufficient to retrieve the entire
    information, for example in networks with more than 200 nodes. Not paying
    attention to paging when using these functions directly (as opposed to within
    the `EcologicalNetworks` wrappers) means that you are at risk of *not working
    with the entire dataset*.

## A note on queries

The Mangal API is built on
[`epilogue`](https://github.com/dchester/epilogue#rest-api) -- this offers
sorting and filtering functionalities. These operations are referred to as
"queries" across the package. All queries are passed as *pairs*. For example,
filtering interactions that are of the mutualist type, and sorting them by `id`,
is done with:

~~~
interactions("type" => "mutualism", "sort" => "id")
~~~

## For datasets

```@docs
datasets
dataset
```

## Networks

```@docs
networks
network
```

## Interactions

```@docs
interactions
interaction
```

## Nodes

```@docs
nodes
node
```

## Reference taxon

```@docs
backbones
backbone
```

## References

```@docs
references
reference
```
