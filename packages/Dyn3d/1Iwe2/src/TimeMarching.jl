module TimeMarching

export HERKBody, RKParams

import Base: show

using Dyn3d
using LinearAlgebra

#-------------------------------------------------------------------------------
struct RKParams
  st::Int
  c::Vector{Float64}
  a::Matrix{Float64}
end

function RKParams(name::String)
"""
RKParams provides a set of HERK coefficients, expressed in Butcher table form.
    a: Runge-Kutta matrix in Butcher tableau    c | a
    b: weight vector in Butcher tableau         ------
    c: node vector in Butcher tableau             | b
    st: stage number
    p: method order of accuracy
"""
    # Scheme of 3-stage HERK in Liska's paper
    if name == "Liska"
        a = [0.0 0.0 0.0;
             0.5 0.0 0.0;
             √3/3 (3.0-√3)/3 0.0]
        b = [(3.0+√3)/6, -√3/3, (3.0+√3)/6]
        c = [0.0, 0.5, 1.0]
        st = 3
        p = 2
    # Brasey-Hairer 3-Stage HERK, table 2
    elseif name == "BH3"
        a = [0.0 0.0 0.0;
             1.0/3 0.0 0.0;
             -1.0 2.0 0.0]
        b = [0.0, 0.75, 0.25]
        c = [0.0, 1.0/3, 1.0]
        st = 3
        p = 3
    # Brasey-Hairer 5-Stage HERK, table 5
    elseif name == "BH5"
        a = [0.0 0.0 0.0 0.0 0.0;
             0.3 0.0 0.0 0.0 0.0;
             (1.0+√6)/30 (11.0-4*√6)/30 0.0 0.0 0.0;
             (-79.0-31*√6)/150 (-1.0-4*√6)/30 (24.0+11*√6)/25 0.0 0.0;
             (14.0+5*√6)/6 (-8.0+7*√6)/6 (-9.0-7*√6)/4 (9.0-√6)/4 0.0]
        b = [0.0, 0.0, (16.0-√6)/36, (16.0+√6)/36, 1.0/9]
        c = [0.0, 0.3, (4.0-√6)/10, (4.0+√6)/10, 1.0]
        st = 5
        p = 4
    elseif name == "Euler"
        a = ones(1,1)
        b = [1.0]
        c = [0.0]
        st = 1
        p = 1
    elseif name == "RK2"
        a = [0.0 0.0;
             0.5 0.0]
        b = [0.0, 1.0]
        c = [0.0, 0.5]
        st = 2
        p = 2
    elseif name == "RK22"
        a = [0.0 0.0;
             2/3 0.0]
        b = [1/4, 3/4]
        c = [0.0, 2/3]
        st = 2
        p = 2
    else
        error("This HERK scheme doesn't exist now.")
    end

    # modify for last stage
    a = [a; b']
    c = [c; 1.0]
    return RKParams(st, c, a)
end

#-------------------------------------------------------------------------------
const RK31 = RKParams("Liska")
const RK32 = RKParams("BH3")
const Euler = RKParams("Euler")
const RK2 = RKParams("RK2")
const RK22 = RKParams("RK22")
const RK4 = RKParams("BH5")

# contain herk algorithm
include("timemarching/herkbody.jl")


end
