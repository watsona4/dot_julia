#=
    orbit
    Copyright © 2018 Mark Wells <mwellsa@gmail.com>

    Distributed under terms of the AGPL-3.0 license.
=#

"""
a³/P² = G(M₁+M₂)/(4π²)
P = √(a³(4π²) / (G(M₁+M₂)))
"""
function kep3rd_get_period( M₁ :: MassMsun
                          , M₂ :: MassMsun
                          , a  :: Length
                          )
    return sqrt(a^3*4π^2/((M₁.val + M₂.val)GMsun))
end

"""
a³/P² = G(M₁+M₂)/(4π²)
a = ∛(G(M₁+M₂)(P/(2π))²)
"""
function kep3rd_get_semimajor( M₁ :: MassMsun
                             , M₂ :: MassMsun
                             , P  :: Time
                             )
    return cbrt((M₁.val + M₂.val)GMsun*(P/(2π))^2)
end

struct Orbit
    a :: LengthRsun
    ε :: Float64
    i :: AngleRad
    ω :: AngleRad
end

function Base.show( io :: IO
                  , v  :: Orbit
                  )
    print(io, ( a = short(v.a)
              , ε = short(v.ε)
              , i = short(v.i)
              , ω = short(v.ω)
              )
         )
end
