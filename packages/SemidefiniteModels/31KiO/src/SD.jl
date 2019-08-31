# Methods for the Semidefinite interface

@compat abstract type AbstractSDModel <: MPB.AbstractMathProgModel end
export AbstractSDModel

MPB.@define_interface begin
    SDModel
    setconstrB!
    setconstrentry!
    setobjentry!
end
