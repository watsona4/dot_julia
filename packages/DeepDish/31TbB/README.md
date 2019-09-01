# DeepDish.jl

[![Build Status](https://travis-ci.com/portugueslab/DeepDish.jl.svg?branch=master)](https://travis-ci.com/portugueslab/DeepDish.jl)

A simple package to load HDF5 files saved by the [DeepDish](https://github.com/uchicago-cs/deepdish) python library in Julia. Currently, only lists of simple types, dictionaries, numpy arrays and [pandas](https://pandas.pydata.org/) DataFrames are supported, as well as recursive structures of lists and dictionaries of the same.

The only exported function is

`load_deepdish(f)`

where f is the path to the h5 file.
