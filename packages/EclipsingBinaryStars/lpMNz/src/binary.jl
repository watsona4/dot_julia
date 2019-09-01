#=
    binary
    Copyright © 2018 Mark Wells <mwellsa@gmail.com>

    Distributed under terms of the AGPL-3.0 license.
=#

struct Binary
    pri :: Star
    sec :: Star
    orb :: Orbit
    P :: TimeDay{Float64}
    roche :: Roche
end

function Base.show( io :: IO
                  , v  :: Binary
                  )
    print(io, (pri = v.pri, sec = v.sec, orb = v.orb, P = short(v.P), roche = v.roche))
end

"""
create Binary given primary, secondary, period, eccn, inclination, arg. of peri
"""
function getBinary( pri :: Star
                  , sec :: Star
                  , P   :: Time
                  , ε   :: Float64
                  , i   :: AngleRad
                  , ω   :: AngleRad
                  )
    orb = Orbit( uconvert(Rsun,kep3rd_get_semimajor(pri.m,sec.m,P))
               , ε , i , ω
               )
    return Binary( pri , sec , orb , P
                 , get_roche(pri, sec, orb)
                 )
end

"""
getBinary given primary, secondary, semimajor (Rsol), eccn, inclination, arg. of peri
"""
function getBinary( pri :: Star
                  , sec :: Star
                  , orb :: Orbit
                  )     :: Binary
    return Binary( pri , sec , orb
                 , kep3rd_get_period(pri.m,sec.m,orb.a)
                 , get_roche(pri, sec, orb)
                 )
end
