# Retriever

Julia wrapper for the Data Retriever software.

Data Retriever automates the tasks of finding, downloading,
and cleaning up publicly available data, and then stores them in a local database or as .csv files.
Simply put, it's a package manager for data.
This allows data analysts to spend a majority of their time in analysing rather than in cleaning up or managing data.

## Installation

To use Retriever, you first need to [install Retriever](http://www.data-retriever.org), a core python package.

To install Retriever using the Julia package manager


```julia

julia> Pkg.add("Retriever")

```

To install from Source, download or checkout the source from the [github page](https://github.com/weecology/Retriever.jl.git).

Go to `Retriever.jl/src`. Run Julia.

```julia

julia> include("Retriever.jl")

```

To create docs

```
julia --color=yes make.jl

```

or simply

```

julia make.jl

```
(Note: If you want help in installing Julia you can follow this [tutorial](https://medium.com/@shivamnegi2019/julia-beginners-guide-part-1-a9c369128c78)