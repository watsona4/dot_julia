#=
    roche
    Copyright © 2018 Mark Wells <mwellsa@gmail.com>

    Distributed under terms of the AGPL-3.0 license.
=#

include("lagrangian_points.jl")

#---------------------------------------------------------------------------------------------------
####################################################################################################
#---------------------------------------------------------------------------------------------------
function get_syncpar( ε :: Float64 ) :: Float64
    @assert( ε < 1.0
           , string( "eccentricity must be less than 1 not "
                   , ε
                   )
           )
    if ε >= 0.05
        return sqrt((1.0 + ε)/(1.0 - ε)^3.0)
    end
    return 1.0
end
#---------------------------------------------------------------------------------------------------
####################################################################################################
#---------------------------------------------------------------------------------------------------
function get_Ω(ϱ, q, δ, λ, ν, F)
    # equation 3.16 PHOEBE
    term1 = 1/ϱ
    sqrt_term = δ^2 + ϱ^2 - 2*ϱ*λ*δ
    @assert( !(sqrt_term < 0)
           , string( "issue in sqrt term"
                   , "\n\texpected result to be non-negative instead of ", sqrt_term
                   , "\n\tvarrho = ", ϱ
                   , "\n\tq = "     , q
                   , "\n\tdelta = " , δ
                   , "\n\tlambda = ", λ
                   , "\n\tnu = "    , ν
                   , "\n\tF = "     , F
                   )
           )
    term2 = q*( 1/sqrt(sqrt_term) - ϱ*λ/(δ^2) )
    term3 = 0.5*(F^2)*(1 + q)*(ϱ^2)*(1 - ν^2)
    return term1 + term2 + term3
end
#---------------------------------------------------------------------------------------------------
####################################################################################################
#---------------------------------------------------------------------------------------------------
function get_Ωpole( r :: Float64
                  , δ :: Float64
                  , q :: Float64
                  )       :: Float64
    #      get_Ω(ϱ, δ, q, λ, ν, F)
    return get_Ω(r, δ, q, 0, 1, 0)
end
#---------------------------------------------------------------------------------------------------
function get_Ωpnt( r :: Float64
                 , δ :: Float64
                 , q :: Float64
                 , F :: Float64
                 )   :: Float64
    #      get_Ω(ϱ, δ, q, λ, ν, F)
    return get_Ω(r, δ, q, 1, 0, F)
end
#function get_Ω_pnt2( r :: Float64
#                   , δ :: Float64
#                   , q :: Float64
#                   , F :: Float64
#                   )   :: Float64
#    #      get_Ω(ϱ, δ, q, λ, ν, F)
#    return get_Ω( δ - r
#                , δ, q, 1, 0, F)
#end
#---------------------------------------------------------------------------------------------------
####################################################################################################
#---------------------------------------------------------------------------------------------------
function get_Ω_Lpnt( pnt :: Int
                   , q
                   , δ
                   , F
                   )
    ϱ = get_lagrangian_pnt(pnt,q,δ)
    if (pnt == 1) || (pnt == 2)
        return get_Ω(ϱ, q, δ, 1.0, 0.0, F)
    elseif pnt == 3
        return get_Ω(ϱ, q, δ, -1.0, 0.0, F)
    elseif pnt == 4
        return get_Ω(ϱ, q, δ, cosd(60), sind(60), F)
    elseif pnt == 5
        return get_Ω(ϱ, q, δ, cosd(60), -sind(60), F)
    else
        error("unrecognized value of pnt")
    end
end
#---------------------------------------------------------------------------------------------------
####################################################################################################
#---------------------------------------------------------------------------------------------------
function xyz_to_λμν(x,y,z)
    r = sqrt(x^2 + y^2 + z^2)
    return (x,y,z)./r
end
#---------------------------------------------------------------------------------------------------
####################################################################################################
#---------------------------------------------------------------------------------------------------
function rλμν_to_xyz( r :: Float64
                    , λ :: Float64
                    , μ :: Float64
                    , ν :: Float64
                    )   :: Tuple{ Float64
                                , Float64
                                , Float64
                                }
    return λ*r, μ*r, ν*r
end
#---------------------------------------------------------------------------------------------------
function rλμν_to_xyz( rs :: Array{Float64,1}
                    , λs :: Array{Float64,1}
                    , μs :: Array{Float64,1}
                    , νs :: Array{Float64,1}
                    )    :: Tuple{ Array{Float64,1}
                                 , Array{Float64,1}
                                 , Array{Float64,1}
                                 }
    @assert( length(rs) == length(λs)
                        == length(μs)
                        == length(νs)
           , "Dimension mismatch!"
           )
    n = length(rs)
    xs = Array{Float64,1}(n)
    ys = Array{Float64,1}(n)
    zs = Array{Float64,1}(n)

    for (i,(r,λ,μ,ν)) in enumerate(zip(rs,λs,μs,νs))
        xs[i],ys[i],zs[i] = rλμν_to_xyz(r, λ, μ, ν)
    end
    return xs,ys,zs
end
#---------------------------------------------------------------------------------------------------
####################################################################################################
#---------------------------------------------------------------------------------------------------
function fillout_factor( ϱpole :: Float64
                       , δ :: Float64
                       , q :: Float64
                       , F :: Float64
                       )   :: Float64

    Ωpole = get_Ωpole(ϱpole, δ, q)

    ΩL1 = get_Ω_Lpnt(1, q, δ, F)
    ΩL2 = get_Ω_Lpnt(2, q, δ, F)
    return (Ωpole - ΩL1)/(ΩL2 - ΩL1)
end
#---------------------------------------------------------------------------------------------------
####################################################################################################
#---------------------------------------------------------------------------------------------------
function roche_eff_radius(δ,q)
    # formula 2 from Eggleton
    q_e = 1/q   # Egg mass-ratio is M1/M2 whereas we define mass-ratio as M2/M1
    numer = 0.49*q_e^(2/3)
    denom = 0.6*q_e^(2/3) + log(1 + q_e^(1/3))
    r_L = numer/denom
    return δ*r_L
end

#function get_ϱlim(x1, x2, λ, ν, δ)
#    if iszero(λ)
#        return δ
#    else
#        return sqrt((λ*x)^2 + (ν*δ)^2)
#    end
#end


#using Optim
#
#function get_ϱ1( pot :: Float64
#               , q   :: Float64
#               , δ   :: Float64
#               , λs  :: Array{Float64,1}
#               , νs  :: Array{Float64,1}
#               , F   :: Float64
#               ; tol = 1e-5
#               )     :: Array{Float64,1}
#    @assert(length(λs) == length(νs), "Mismatched sizes!")
#    ϱs = Array{Float64,1}(length(λs))
#
#    xL1 = get_lagrangian_pnt(1,q)
#    xL3 = get_lagrangian_pnt(1,q)
#    
#    f(ϱ,λ,ν) = abs(pot - get_Ω(ϱ, q, δ, λ, ν, F))
#
#    c = 0
#    for (i,(λ,ν)) in enumerate(zip(λs,νs))
#        if iszero(λ)
#            ϱlim = δ
#        elseif λ > 0
#            ϱlim = sqrt((λ*xL1)^2 + (ν*δ)^2)
#        elseif λ < 0
#            ϱlim = sqrt((λ*xL2)^2 + (ν*δ)^2)
#        end
#
#        res = optimize(ϱ -> f(ϱ,λ,ν), 0, ϱlim, Brent())
#
#        ϱres = Optim.minimizer(res)
#
#        x,y,z = rλμν_to_xyz(ϱres, λ, 0.0, ν)
#        if (Optim.minimum(res) < tol) && (x <= xL1)
#            ϱs[i] = ϱres 
#        else
#            c += 1
#            ϱs[i] = NaN
#        end
#        #if minres > 0.01
#        #    println("issue with solution")
#        #end
#    end
#    println("bads: ", c)
#
#    return ϱs
#end
#
#function get_ϱ2( pot :: Float64
#               , q   :: Float64
#               , δ   :: Float64
#               , λs  :: Array{Float64,1}
#               , νs  :: Array{Float64,1}
#               , F   :: Float64
#               ; tol = 1e-5
#               )     :: Array{Float64,1}
#    @assert(length(λs) == length(νs), "Mismatched sizes!")
#    ϱs = Array{Float64,1}(length(λs))
#
#    potp = get_Ω_prime(pot, q)
#    qp = 1/q
#
#    xL1 = 1 - abs(get_lagrangian_pnt(1,q))
#    println("xL1 from ϱ2: ", xL1)
#
#    xL2 = 1 - abs(get_lagrangian_pnt(2,q))
#    println("xL2 from ϱ2: ", xL2)
#
#    f(ϱ,λ,ν) = abs(potp - get_Ω(ϱ, qp, δ, λ, ν, F))
#
#    c = 0
#    for (i,(λ,ν)) in enumerate(zip(λs,νs))
#
#        if iszero(λ)
#            ϱlim = δ
#        elseif λ > 0
#            ϱlim = sqrt((λ*xL1)^2 + (ν*δ)^2)
#        else
#            ϱlim = sqrt((λ*xL2)^2 + (ν*δ)^2)
#        end
#
#        #println("ϱlim: ", ϱlim)
#        res = optimize(ϱ -> f(ϱ,λ,ν), 0, ϱlim, Brent())
#
#        ϱres = Optim.minimizer(res)
#
#        tol = Optim.minimum(res)
#
#        x,y,z = rλμν_to_xyz(ϱres, λ, 0.0, ν)
#        if (Optim.minimum(res) < tol) && (x <= xL1)
#            ϱs[i] = ϱres 
#        else
#            c += 1
#            ϱs[i] = NaN
#        end
#        #if minres > 0.01
#        #    println("issue with solution")
#        #end
#    end
#    println("bads: ", c)
#
#    return ϱs
#end

#function test_fillout()
#    q = 0.5
#    r1 = 0.2
#    r2 = 0.1
#    ε = 0.0
#    d = 1.0 - ε
#
#    println("d: ", d)
#    println("q: ", q)
#    println("ε: ", ε)
#
#    fval = fillout_factor(r1, d, q, ε)
#    println(fval)
#
#    q = 0.5
#    r1 = 0.2
#    r2 = 0.1
#    ε = 0.5
#    d = 1.0 - ε
#
#    println("d: ", d)
#    println("q: ", q)
#    println("ε: ", ε)
#    fval = fillout_factor(r1, d, q, ε)
#    println(fval)
#
#
#
#    q = 0.5
#    r1 = 0.2
#    r2 = 0.1
#    ε = 0.99
#    d = 1.0 - ε
#
#    println("d: ", d)
#    println("q: ", q)
#    println("ε: ", ε)
#    fval = fillout_factor(r1, d, q, ε)
#    println(fval)
#
#
#
#end
#test_fillout()
