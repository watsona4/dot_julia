module DutyCycles

# export types and constructors (types.jl and constructors*.jl)
export AbstractDutyCycle
export AbstractCoherentDutyCycle, AbstractIncoherentDutyCycle
export DutyCycle
export CoherentDutyCycle, IncoherentDutyCycle
# export special constructor-like methods (constructors.jl)
export cycle, dutycycle

# export methods used to retrieve default values (defaults.jl)
export default_period

# export accessors (accessors.jl)
export period, coherencetime, fundamental_frequency
export waveform, spectrum, psd, valueat
export values
export fractionaldurations, fractionaltimes, durations

# export main methods (from various source code files)
export mean, rms, autoavg, autoavgfunc # statistics.jl
export maxval, minval, extremavals # statistics.jl
export phaseshift, phaseshift! # helpers.jl
export incoherent, incoherent! # modification.jl

# export coherence metods (coherence.jl)
export iscoherent, hascoherence_ratio, coherence_ratio

# have the rest in a file to easy development (allow
# `include("all.jl")` as a replacement for restarting julia and `using
# DutyCycles`).
include("all.jl")

end # module
