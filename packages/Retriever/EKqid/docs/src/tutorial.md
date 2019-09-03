# Data Retriever using Julia

The wrapper module for [Data Retriever](http://data-retriever.org) has been implemented as [Retriever](https://github.com/weecology/Retriever.jl.git).
All the functions work and feel the same as the python Retriever module.
The module has been created using ``PyCall`` hence all the functions are analogous to the functions of Retriever python module.


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

(Note: If you want help in installing Julia you can follow this [tutorial](https://medium.com/@shivamnegi2019/julia-beginners-guide-part-1-a9c369128c78)

## Tutorial

Get list of all the available datasets in Retriever.

```julia

    """ Function Definition """
    function dataset_names()

```

```julia

    julia> Retriever.dataset_names()

```

Updating scripts to the latest version.

```julia

    """ Function Definition """
    function check_for_updates()

```

```julia

    julia> Retriever.check_for_updates()

```

Delete information stored by Retriever which could be scripts, connections or data.

```julia

    """ Function Definition """
    function reset_retriever(; scope::AbstractString="all")

```

```julia

    """ Using default variable all"""
    julia> Retriever.reset_retriever()
    """ Set scope as scripts """
    julia> Retriever.reset_retriever(scope="scripts")

```

To download datasets the ``download`` function can be used.

```julia

    """ Function Definition """
    function download(dataset; path::AbstractString="./", quite::Bool=false,
                subdir::Bool=false, use_cache::Bool=false, debug::Bool=false)


```

```julia

    julia> Retriever.download("iris")

```

Installing scripts into engines.


```julia

    """ Function Definition """
    function install_csv(dataset; table_name=nothing, compile::Bool=false,
                debug::Bool=false, quite::Bool=false, use_cache::Bool=true)

    function install_mysql(dataset; user::AbstractString="root",
                password::AbstractString="", host::AbstractString="localhost",
                port::Int=3306, database_name=nothing, table_name=nothing,
                compile::Bool=false, debug::Bool=false, quite::Bool=false,
                use_cache::Bool=true)

    function install_postgres(dataset; user::AbstractString="postgres",
                password::AbstractString="", host::AbstractString="localhost",
                port::Int=5432, database::AbstractString="postgres",
                database_name=nothing, table_name=nothing, compile::Bool=false,
                debug::Bool=false, quite::Bool=false, use_cache::Bool=true)

    function install_sqlite(dataset; file=nothing, table_name=nothing,
                compile::Bool=false, debug::Bool=false, quite::Bool=false,
                use_cache::Bool=true)

    function install_msaccess(dataset; file=nothing, table_name=nothing,
                compile::Bool=false, debug::Bool=false, quite::Bool=false,
                use_cache::Bool=true)

    function install_json(dataset; table_name=nothing, compile::Bool=false,
                debug::Bool=false, quite::Bool=false, use_cache::Bool=true)

    function install_xml(dataset; table_name=nothing, compile::Bool=false,
                debug::Bool=false, quite::Bool=false, use_cache::Bool=true)

```

```julia

    julia> Retriever.install_csv("iris")
    julia> Retriever.install_mysql("iris")
    julia> Retriever.install_postgres("iris")
    julia> Retriever.install_sqlite("iris")
    julia> Retriever.install_msaccess("iris")
    julia> Retriever.install_json("iris")
    julia> Retriever.install_xml("iris")

```