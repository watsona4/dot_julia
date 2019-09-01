#=
    binary
    Copyright © 2018 Mark Wells <mwellsa@gmail.com>

    Distributed under terms of the AGPL-3.0 license.
=#

#---------------------------------------------------------------------------------------------------
####################################################################################################
#---------------------------------------------------------------------------------------------------

struct Star
    m :: typeof(1.0Msun)
    r :: typeof(1.0Rsun)
end

function Base.show( io :: IO
                  , v  :: Star
                  )
    print( io, (short(v.m), short(v.r)))
end
