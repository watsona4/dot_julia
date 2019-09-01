"""

This is the "supertype" (actually, a type union) for the concrete
DutyCycle types ([`CoherentDutyCycle{T,U,V}`](@ref) and
[`IncoherentDutyCycle{T,U,V}`](@ref)) provided by this package.

"""
const DutyCycle{T,U,V} = Union{
    CoherentDutyCycle{T,U,V},
    IncoherentDutyCycle{T,U,V}
}
DutyCycle{T,U,V}(d::CoherentDutyCycle{T,U,V}) where {T,U,V} = d
DutyCycle{T,U,V}(d::IncoherentDutyCycle{T,U,V}) where {T,U,V} = d
