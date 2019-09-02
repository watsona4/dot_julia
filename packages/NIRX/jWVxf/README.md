# NIRX.jl

[![Build Status](https://travis-ci.com/rob-luke/NIRX.jl.svg?branch=master)](https://travis-ci.com/rob-luke/NIRX.jl)

Read [NIRX](https://nirx.net/) functional near-infrared spectroscopy files in Julia.


## Installation

```julia
] add NIRX
```


## Usage

Read NIRX data:
```julia
triggers, header_info, info, wl1, wl2, config = read_NIRX("path/to/your/data")
```


## Tests

Tests are automatically run on continuous integration servers. Run the tests locally:
```julia
] test NIRX
```
