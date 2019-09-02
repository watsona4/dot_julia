# Memory / disk storage

By default the full time series of an observable is kept in memory. This is the most convenient option as it renders element access and error computation fast. However, sometimes it is preferable to track the time series on disk rather than completely in memory:

* Abrupt termination: the simulation might be computationally expensive, thus slow, and might abort abruptly (maybe due to cluster outage or time limit). In this case, one probably wants to have a restorable "memory dump" of the so far recorded measurements to not have to restart from scratch.

* Memory limit: the tracked observable might be large, i.e. a large complex matrix. Then, storing a long time series might make the simulation exceed a memory limit (and often stop unexpectedly). Keeping the time series memory on disk solves this problem.


## "Disk observables"

A "disk observable" is an `Observable` that every once in a while dumps it's time series memory to disk and only keeps the latest data points in memory. You can create a "disk observable" as

```julia
obs = Observable(Float64, "myobservable"; inmemory=false, alloc=100)
```

It will record measurements in memory until the preallocated time series buffer (`alloc=100`) overflows in which case it saves it's time series memory to disk (`outfile`). In the above example this will happen after 100 measurements.

Apart from the special construction (`inmemory=false`) everything else stays the same as for default in-memory observables. For example, we can still get the mean via `mean(obs)`, access time series elements with `obs[idx]` and load the full time series to memory at any point through `timeseries(obs)`.

!!! note

    The observable's memory dump contains meta information, like name, element type, element size etc., as well as time series memory chunks. The dumping is implemented in the method `MonteCarloObservable.flush`. Note that the observable's memory is **not** a full backup of the observable itself (see [`saveobs`](@ref)). Should the simulation terminate abruptly one can nonetheless restore most of the so-far recorded information using [`loadobs_frommemory`](@ref) and [`timeseries_frommemory`](@ref). Measurements that hadn't been dumped yet, because they were still in the preallocated buffer, are lost though.