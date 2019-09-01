# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMBeam.jl/blob/master/LICENSE

"""
    Beam2D

Euler-Bernoulli beam for 2d problems.
"""
struct Beam2D <: FieldProblem end

FEMBase.get_unknown_field_name(::Problem{Beam2D}) = "displacement"

function FEMBase.assemble_elements!(::Problem{Beam2D}, ::Assembly,
                               elements::Vector{Element{B}}, ::Float64) where B

    for element in elements
        @info("Not doing anything useful right now (someone should implement).")
    end

    return nothing
end
