struct Material
    id::String
    hid::Int
    mat_type::MaterialType

    E::Float64
    ν::Float64
    ρ::Float64
    α::Float64
    G::Float64
    λ::Float64

    E₂::Float64
    f::Float64
    fᵤ::Float64
end

function IsoElastic(id,hid,E,ν,ρ,α)
    G=E/2/(1+ν)
    λ=E*ν/(1+ν)/(1-2ν)
    mat_type=Enums.ISOELASTIC
    Material(string(id),hid,mat_type,E,ν,ρ,α,G,λ,0,0,0)
end

function UniAxialMetal(id,hid,E,ν,ρ,α,E₂,f,fᵤ)
    G=E/2/(1+ν)
    λ=E*ν/(1+ν)/(1-2ν)
    mat_type=Enums.UNIAXIAL_METAL
    Material(id,hid,mat_type,E,ν,ρ,α,G,λ,E₂,f,fᵤ)
end

# end
