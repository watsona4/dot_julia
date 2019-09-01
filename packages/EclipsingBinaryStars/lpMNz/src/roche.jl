#=
    roche
    Copyright © 2019 Mark Wells <mwellsa@gmail.com>

    Distributed under terms of the GPL-3.0 license.
=#

"""
Eggleton's (1983) 1% accuracy approximation
r₁/a = roche_radius(M₁/M₂)
r₂/a = roche_radius(M₂/M₁)
"""
function roche_radius( q :: Real )
    return (0.49q^(2/3))/(0.6*q^(2/3) + log(1 + q^(1/3)))
end

roche_radius(M₁, M₂) = roche_radius(M₁/M₂)

struct Roche
    r₁_a :: Float64
    rlof₁ :: Bool
    r₂_a :: Float64
    rlof₂ :: Bool
end

function Base.show( io :: IO
                  , v  :: Roche
                  )
    print(io, ( r₁_a = short(v.r₁_a) , rlof₁ = v.rlof₁
              , r₂_a = short(v.r₂_a) , rlof₂ = v.rlof₂
              )
         )
end

"""
Eggleton's (1983) 1% accuracy approximation
r₁/a = roche_radius(M₁/M₂)
r₂/a = roche_radius(M₂/M₁)
"""
function get_roche( pri :: Star
                  , sec :: Star
                  , orb :: Orbit
                  ; fill_factor :: Number = 0.7
                  )
    # the roche radii is smallest at periastron
    r₁_a = roche_radius(pri.m, sec.m)
    r₂_a = roche_radius(sec.m, pri.m)

    a_peri = orb.a*(1-orb.ε)
    return Roche( r₁_a , pri.r > fill_factor*(r₁_a * a_peri)
                , r₂_a , sec.r > fill_factor*(r₂_a * a_peri)
                )
end
