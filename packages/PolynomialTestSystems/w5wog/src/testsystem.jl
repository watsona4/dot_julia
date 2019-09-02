export TestSystem, nvariables, equations, mixed_volume, nsolutions,
    nreal_solutions, bezout_number, multi_bezout_number

struct TestSystem{T}
    equations::Vector{Polynomial{true, T}}
    bezout_number::Int
    multi_homogeneous_bezout_number::Union{Nothing, Tuple{Int, Vector{Vector{PolyVar{true}}}}}
    mixed_volume::Union{Nothing, Int}
    nsolutions::Union{Nothing, Int}
    nreal_solutions::Union{Nothing, Int}
end

"""
    TestSystem(equations;
        multi_bezout_number=nothing,
        mixed_volume=nothing,
        nsolutions=nothing,
        nreal_solutions=nothing)

Create a `TestSystem`.
"""
function TestSystem(equations;
    multi_bezout_number=nothing,
    mixed_volume=nothing,
    nsolutions=nothing,
    nreal_solutions=nothing)
    bezout_number = prod(MP.maxdegree, equations)
    TestSystem(equations, bezout_number, multi_bezout_number, mixed_volume,nsolutions, nreal_solutions)
end


"""
    equations(::TestSystem)

Get the the polynomial system.
"""
equations(S::TestSystem) = S.equations

"""
    nvariables(::TestSystem)

Obtain the number of variables of the test system.
"""
nvariables(S::TestSystem) = maximum(MP.nvariables, S.equations)

"""
    mixed_volume(system)::Union{Nothing, Int}

Returns the number mixed volume of the system if known.
"""
mixed_volume(F::TestSystem) = F.mixed_volume

"""
    nsolutions(system)::Union{Nothing, Int}

Returns the number of (complex) solutions of the system if known.
"""
nsolutions(F::TestSystem) = F.nsolutions

"""
    nreal_solutions(system)::Union{Nothing, Int}

Returns the number of real solutions of the system if known.
"""
nreal_solutions(F::TestSystem) = F.nreal_solutions

"""
    bezout_number(system)

Returns the bezout number of the system.
"""
bezout_number(F::TestSystem) = F.bezout_number

"""
    multi_bezout_number(system)::Union{Nothing, Tuple{Int, Vector{Vector{PolyVar{true}}}}}

Returns a tuple containing the multi-homogeneous bezout number
as well as the corresponding grouping of the variables if known.
"""
multi_bezout_number(F::TestSystem) = F.multi_homogeneous_bezout_number
