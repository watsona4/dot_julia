"""
# module FiniteStrains



# Examples

```jldoctest
julia>
```
"""
module FiniteStrains

export FiniteStrain,
    EulerianStrain,
    LagrangianStrain,
    NaturalStrain,
    InfinitesimalStrain,
    get_strain

struct FiniteStrain{T}
    v0::Float64
end

const EulerianStrain = FiniteStrain{:Eulerian}
const LagrangianStrain = FiniteStrain{:Lagrangian}
const NaturalStrain = FiniteStrain{:Natural}
const InfinitesimalStrain = FiniteStrain{:Infinitesimal}

get_strain(f::EulerianStrain, v::Float64)::Float64 = ((f.v0 / v)^(2 / 3) - 1) / 2
get_strain(f::LagrangianStrain, v::Float64)::Float64 = ((v / f.v0)^(2 / 3) - 1) / 2
get_strain(f::NaturalStrain, v::Float64)::Float64 = log(v / f.v0) / 3
get_strain(f::InfinitesimalStrain, v::Float64)::Float64 = 1 - (f.v0 / v)^(1 / 3)

end