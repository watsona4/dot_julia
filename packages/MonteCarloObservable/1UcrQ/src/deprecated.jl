@deprecate error(obs::Observable) std_error(obs::Observable)
export error

@deprecate binning_error(ts) std_error(ts, method=:full)
export binning_error

@deprecate jackknife_error(g, obs...) jackknife(g, obs...)[2]

@deprecate rename(obs::Observable, name) rename!(obs::Observable, name)
export rename

@deprecate add!(obs::Observable, measurement; kw...) push!(obs::Observable, measurement; kw...)