"""
A package for handling observables in a Markov Chain Monte Carlo simulation.

See http://github.com/crstnbr/MonteCarloObservable.jl for more information.
"""
module MonteCarloObservable

    using Statistics
    using JLD, EllipsisNotation, Lazy, Reexport
    import HDF5

    @reexport using BinningAnalysis

    abstract type AbstractObservable end

    include("helpers.jl")
    include("shared.jl")
    include("observable.jl")
    include("lightobservable.jl")

    # general
    export Observable, DiskObservable, LightObservable
    export @obs, @diskobs

    # statistics
    export tau, iswithinerrorbars
    export std_error
    export jackknife
    export mean, var, std

    # interface
    export push!, append!, reset!
    export timeseries, ts
    export rename!, name
    export inmemory, isinmemory, length, eltype, getindex, view, isempty, ndims, size, iterate

    # io
    export saveobs, loadobs, listobs, rmobs
    export export_result, export_error
    export loadobs_frommemory
    export timeseries_frommemory, timeseries_frommemory_flat, mean_frommemory, error_frommemory
    export timeseries_flat, ts_flat
    export getfrom
    export flush
    export ObservableResult, load_result

    # deprecations
    include("deprecated.jl")
end
