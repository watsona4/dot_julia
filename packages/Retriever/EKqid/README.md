
| **Documentation**                                                               | **PackageEvaluator**                                                                            | **Build Status**                                                                                |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![][docs-stable-img]][docs-stable-url] [![][docs-latest-img]][docs-latest-url] |[![][license-img]][license-url]   | [![][travis-img]][travis-url] |

[docs-stable-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-stable-url]: https://weecology.github.io/Retriever.jl/latest/intro.html
[docs-latest-img]: https://readthedocs.org/projects/retrieverjl/badge/?version=latest
[docs-latest-url]: https://weecology.github.io/Retriever.jl/latest/intro.html
[travis-img]: https://travis-ci.org/weecology/Retriever.jl.svg?branch=master
[travis-url]: https://travis-ci.org/weecology/Retriever.jl
[license-img]: http://img.shields.io/badge/license-MIT-blue.svg
[license-url]: https://raw.githubusercontent.com/weecology/Retriever.jl/master/LICENSE

# Retriever

Julia wrapper for the Data Retriever software.

Data Retriever automates the tasks of finding, downloading,
and cleaning up publicly available data, and then stores them in a local database or as .csv files.
Simply put, it's a package manager for data.
This allows data analysts to spend a majority of their time in analysing rather than in cleaning up or managing data.

## Installation

To use Retriever, you first need to [install Retriever](http://www.data-retriever.org), a core python package.

### Database Management Systems

Depending on the database management systems you wish to use, follow the `Setting up servers` [documentation of the retriever](https://github.com/weecology/retriever). You can change the credentials to suit your server settings.

The Retriever Julia package depends on a few Julia packages that will be installed automatically.

Ensure that Pycall is using the same Python path where the retriever Python package is installed.

You can change that path to a desired path as below.

```julia

julia> ENV["PYTHON"]="Python path where the retriever python package is installed"
# Build Pycall to enable the use of the new path
Pkg.build("PyCall")

```

To install Retriever Julia package

```julia

julia> Pkg.add("Retriever")

```

To install from Source, download or checkout the source from the [github page](https://github.com/weecology/Retriever.jl.git).

Go to `Retriever.jl` directory and. Run Julia.

```Julia

julia> include("src/Retriever.jl")

```

## Example of installing the Datasets

```julia

# Using default parameter as the arguments
julia> Retriever.install_postgres("iris")
 # Passing user specfic arguments
julia> Retriever.install_postgres("iris", user = "postgres",
		password="Password12!", host="localhost", port=5432)

```

```julia

julia> Retriever.install_csv("iris")
julia> Retriever.install_mysql("iris")
julia> Retriever.install_sqlite("iris")
julia> Retriever.install_msaccess("iris")
julia> Retriever.install_json("iris")
julia> Retriever.install_xml("iris")

```

Creating docs.

To create docs, first refer to the
[Documenter docs](https://juliadocs.github.io/Documenter.jl/stable/man/guide).
To test doc locally run make.jl

```Shell

julia --color=yes make.jl

```

or simply

```Shell

julia make.jl

```

## Using Docker

To run tests using docker

`docker-compose run --service-ports retrieverj julia test/runtests.jl`

To run the image interactively

`docker-compose run --service-ports retrieverj /bin/bash`

To test docs in docker

` docker-compose run --service-ports retrieverj bash -c "cd docs &&  julia make.jl"`

Acknowledgments
---------------

Development of this software is funded by [the Gordon and Betty Moore
Foundation's Data-Driven Discovery
Initiative](http://www.moore.org/programs/science/data-driven-discovery) through
[Grant GBMF4563](http://www.moore.org/grants/list/GBMF4563) to Ethan White and
started as [Shivam Negi](https://www.linkedin.com/in/shivam-negi-64a227103/)'s [Google Summer of Code](https://summerofcode.withgoogle.com/)
