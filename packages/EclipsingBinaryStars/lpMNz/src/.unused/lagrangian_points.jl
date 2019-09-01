#=
    lagrangian_points
    Copyright © 2018 Mark Wells <mwellsa@gmail.com>

    Distributed under terms of the AGPL-3.0 license.
=#

using Optim

#"""
#return distance to lagrangian pnt from m1
#where
#    m1 @ x = 0 
#    m2 @ x = 1
#    R is distance from m1 to m2
#"""
#function get_lagrangian_pnt( pnt :: Int
#                           , m1  :: Float64
#                           , m2  :: Float64
#                           )
#    @assert( (m1 > 0) && (m2 > 0)
#           , "Input values must be positive real numbers"
#           )
#
#    M2 = min(m1,m2)
#    M1 = max(m1,m2)
#
#    # r is measured from M2
#    μ = M2/(M1 + M2)
#    z = cbrt(μ/3)
#    if pnt == 1
#        r = z - z^2/3 - z^3/9 + 58*z^4/81
#    elseif pnt == 2
#        r = z + z^2/3 - z^3/9 + 50*z^4/81
#    elseif pnt == 3
#        r = 1 - 7*μ/12 - 1127*μ^3/20736 - 7889*μ^4/248832
#    else
#        error("Unrecognized value of pnt")
#    end
#
#    # r is measured from M2
#    # if M2 is m1
#    if m1 < m2
#        if pnt == 3
#            abs(1 + r)
#        else
#            return abs(r)
#        end
#    else
#        if pnt == 1
#            return abs(1 - r)
#        elseif pnt == 2
#            return abs(1 + r)
#        elseif pnt == 3
#            return abs(r)
#        else
#            error("Unrecognized value of pnt")
#        end
#    end
#end
function get_L1( m1  :: Float64
               , m2  :: Float64
               )

    M2 = min(m1,m2)
    M1 = max(m1,m2)

    # r is measured from M2
    μ = M2/(M1 + M2)
    z = cbrt(μ/3)
    r = z - z^2/3 - z^3/9 + 58*z^4/81

    # r is measured from M2
    # if M2 is m1
    if m1 < m2
        return abs(r)
    else
        return abs(1 - r)
    end
end


function get_lagrangian_pnt( pnt :: Int
                           , q   :: Float64
                           )     :: Float64
    if pnt == 1
        return get_L1(1.0, q)
    end
end


#function jupitersun()
#    M2 = 955e-6
#    M1 = 1.0
#    q = M2/M1
#
#    # in meters
#    sma = 7.7834e11
#    refL1 = 7.2645e11
#    refL2 = 8.3265e11
#    refL3 = 7.7791e11
#
#    L1 = get_lagrangian_pnt(1,q)
#    println("\nL1: ", L1*sma)
#    println("(L1-refL1)/refL1 = ", (L1*sma - refL1)/refL1)
#
#    #L2 = get_lagrangian_pnt(2,q)
#    #println("\nL2: ", L2*sma)
#    #println("(L2-refL2)/refL2 = ", (L2*sma - refL2)/refL2)
#
#    #L3 = get_lagrangian_pnt(3,q)
#    #println("\nL3: ", L3*sma)
#    #println("(L3-refL3)/refL3 = ", (L3*sma - refL3)/refL3)
#
#    q = M1/M2
#
#    # have to mod these values to compare to references
#    L1 = 1 - get_lagrangian_pnt(1,q)
#    println("\nL1: ", L1*sma)
#    println("(L1-refL1)/refL1 = ", (L1*sma - refL1)/refL1)
#
#    #L2 = get_lagrangian_pnt(2,q) + 1
#    #println("\nL2: ", L2*sma)
#    #println("(L2-refL2)/refL2 = ", (L2*sma - refL2)/refL2)
#
#    #L3 = get_lagrangian_pnt(3,q) - 1
#    #println("\nL3: ", L3*sma)
#    #println("(L3-refL3)/refL3 = ", (L3*sma - refL3)/refL3)
#
#end
#jupitersun()
