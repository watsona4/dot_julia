# This file is created to ease testing. Instead of issueing the `pkg>
# test` command, one can `julia include("src/all.jl")` and then `julia
# include("test/all.jl")` for better speed.
using Test
using Logging, Unitful, Base.Filesystem, Measurements
# Unitful: import units but do not import V (Volt) because it collides
# with the common type perametrization using T,U,V,D
using Unitful: Hz, s, ms, µs, mV, A, mA, W, mW, m, mbar
import Statistics # this has name conflicts with this package (method
                  # mean), so do not use `using` with it

# define log test patterns
warn_coherence =
    r"default period: adding coherence by removing rel. uncertainty.*"
warn_dimensions =
    r"default period: dimensions given that differ from the input.*"
warn_coh = (:warn, warn_coherence)
warn_dim = (:warn, warn_dimensions)

# define a few helper methods to aid testing

# helper method to access the underlying type U in
# Unitful.AbstractQuantity{T,D,U}
_extractU(
    ::Unitful.AbstractQuantity{T,D,U}
) where {T,D,U} = U

# helper method to access the underlying type D in
# Unitful.AbstractQuantity{T,D,U}
_extractD(
    ::Unitful.AbstractQuantity{T,D,U}
) where {T,D,U} = D

# helper for use with the return value of promote
function _typeof_promote(u, v, extrainfo="")
    pupv = promote(u, v)
    @assert(length(pupv) == 2)
    pu, pv = pupv
    if typeof(pu) !== typeof(pv)
        #@error "Promoted types do not match" u v pu pv
        if length(extrainfo) > 0
            extrainfo = string("; ", extrainfo)
        end
        error(
            "types of promoted ",
            u,
            " and ",
            v,
            " do not match: ",
            typeof(pu),
            " and ",
            typeof(pv),
            extrainfo,
            " with promote_type ",
            promote_type(typeof(u), typeof(v))
        )
    else
        return typeof(pu)
    end
    error("unreachable statement")
end

# the actual tests
@testset "DutyCycles" begin
    include("helpers.jl") # tests for src/helpers.jl
    include("constructors.jl") # tests for constructors*.jl
    include("constructor-like.jl") # tests for cycle, dutycycle from
                                   # constructors.jl
    include("accessors.jl")
    include("promotion.jl")
    include("comparisons.jl")
    include("coherence.jl")
    include("operators.jl")
    include("mapreduce.jl")
    include("statistics.jl")
    include("waveforms.jl")
    include("regression.jl") # tests for past (and current) bugs
end

# the following include must come last, as these tests include messing
# with defaults (the default_period method); however, To Do: One could
# improve the other tests to not be senstive to that
include("predoctests.jl") # attempts to pre-test what will be
                          # encountered in doctests later, as faling
                          # doctests give poor feedback about the
                          # cause of the failure
