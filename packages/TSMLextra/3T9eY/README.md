| **Documentation** | **Build Status** | **Help** |
|:---:|:---:|:---:|
| [![][docs-dev-img]][docs-dev-url] [![][docs-stable-img]][docs-stable-url] | [![][travis-img]][travis-url] [![][codecov-img]][codecov-url] | [![][slack-img]][slack-url] [![][gitter-img]][gitter-url] |

### TSMLextra extends [TSML](https://github.com/IBM/TSML.jl) machine learning models by incorporating ScikitLearn and Caret libraries through a common API.

TSMLextra relies on [PyCall.jl](https://github.com/JuliaPy/PyCall.jl) and [RCall.jl](https://github.com/JuliaInterop/RCall.jl)
to expose external ML libraries using a common API for heterogenous combination of ML ensembles. It  introduces three types of ensembles: VoteEnsemble, StackEnsemble, and BestEnsemble.
Each ensemble allows heterogenous combinations of ML libraries from R, Python, and Julia.

The design/framework of this package is influenced heavily by Samuel Jenkins' [Orchestra.jl](https://github.com/svs14/Orchestra.jl) and Paulito Palmes [CombineML.jl](https://github.com/ppalmes/CombineML.jl) packages.

## Package Features

- extends TSML to include external machine learning libraries from R's caret and Python's scikitlearn
- uses common API wrappers for ML training and prediction of heterogenous libraries

## Installation
TSMLextra is in the Julia Official package registry. The latest release can be installed at the Julia prompt using Julia's package management which is triggered by pressing `]` at the julia prompt:

```julia
julia> ]
(v1.1) pkg> add TSMLextra
```

Or, equivalently, via the `Pkg` API:

```julia
julia> using Pkg
julia> Pkg.add("TSMLextra")
```

## Documentation

- [**STABLE**][docs-stable-url] &mdash; **documentation of the most recently tagged version.**
- [**DEVEL**][docs-dev-url] &mdash; *documentation of the in-development version.*

## Project Status

TSMLextra is tested and actively developed on Julia `1.0` and above for Linux and macOS.

There is no support for Julia versions `0.4`, `0.5`, `0.6` and `0.7`.

## Overview

TSMLextra allows mixing of heterogenous ML libraries from Python's ScikitLearn, R's Caret, and Julia using a common API for seamless ensembling to create complex models for robust time-series prediction.

Generally, you will need the different transformers and utils in TSML for time-series processing. To use them, it is standard in TSML code to have the following declared at the topmost part of your application:

- #### Load TSML and supporting submodules
```julia
using TSML 
using TSMLextra
```

- #### Setup different transformers
```julia
# Setup source data and filters to aggregate and impute hourly
fname = joinpath(dirname(pathof(TSML)),"../data/testdata.csv")

csvreader = DataReader(Dict(:filename=>fname,:dateformat=>"dd/mm/yyyy HH:MM"))
valgator = DateValgator(Dict(:dateinterval=>Dates.Hour(1))) # aggregator
valnner = DateValNNer(Dict(:dateinterval=>Dates.Hour(1)))   # imputer
stfier = Statifier(Dict(:processmissing=>true))             # get statistics
mono = Monotonicer(Dict()) # normalize monotonic data
outnicer = Outliernicer(Dict(:dateinterval => Dates.Hour(1))) # normalize outliers
```

- #### Load csv data, aggregate, and get statistics
```julia
# Setup pipeline without imputation and run
mpipeline1 = Pipeline(Dict(
  :transformers => [csvreader,valgator,stfier]
 )
)
fit!(mpipeline1)
respipe1 = transform!(mpipeline1)

# Show statistics including blocks of missing data stats
@show respipe1
```

 - #### Load csv data, aggregate, impute, and get statistics
```julia
# Add imputation in the pipeline and rerun
mpipeline2 = Pipeline(Dict(
  :transformers => [csvreader,valgator,valnner,stfier]
 )
)
fit!(mpipeline2)
respipe2 = transform!(mpipeline2)

# Show statistics including blocks of missing data stats
@show respipe2
```

- #### Load csv data, aggregate, impute, and normalize outliers
```julia
# Add imputation in the pipeline and rerun
mpipeline2 = Pipeline(Dict(
  :transformers => [csvreader,valgator,valnner,outnicer]
 )
)
fit!(mpipeline2)
respipe2 = transform!(mpipeline2)

# Show statistics including blocks of missing data stats
@show respipe2
```

- #### Load csv data, aggregate, impute, and normalize monotonic data
```julia
# Add imputation in the pipeline and rerun
mpipeline2 = Pipeline(Dict(
  :transformers => [csvreader,valgator,valnner,mono]
 )
)
fit!(mpipeline2)
respipe2 = transform!(mpipeline2)

# Show statistics including blocks of missing data stats
@show respipe2
```

## Feature Requests and Contributions

We welcome contributions, feature requests, and suggestions. Here is the link to open an [issue][issues-url] for any problems you encounter. If you want to contribute, please follow the guidelines in [contributors page][contrib-url].

## Help usage

Usage questions can be posted in:
- [Julia Community](https://julialang.org/community/) 
- [Gitter TSML Community][gitter-url]
- [Julia Discourse forum][discourse-tag-url]


[contrib-url]: https://github.com/IBM/TSML.jl/blob/master/CONTRIBUTORS.md
[issues-url]: https://github.com/IBM/TSML.jl/issues

[discourse-tag-url]: https://discourse.julialang.org/

[gitter-url]: https://gitter.im/TSMLearning/community
[gitter-img]: https://badges.gitter.im/ppalmes/TSML.jl.svg

[slack-img]: https://img.shields.io/badge/chat-on%20slack-yellow.svg
[slack-url]: https://julialang.slack.com


[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://ibm.github.io/TSML.jl/stable/
[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://ibm.github.io/TSML.jl/latest/

[travis-img]: https://travis-ci.org/ppalmes/TSMLextra.jl.svg?branch=master
[travis-url]: https://travis-ci.org/ppalmes/TSMLextra.jl

[codecov-img]: https://codecov.io/gh/IBM/TSML.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/IBM/TSML.jl
