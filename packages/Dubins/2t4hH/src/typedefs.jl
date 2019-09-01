export
    DubinsPathType, SegmentType, DubinsPath,
    LSL, LSR, RSL, RSR, RLR, LRL,
    EDUBOK, EDUBCOCONFIGS, EDUBPARAM, EDUBBADRHO, EDUBNOPATH, EDUBBADINPUT

@enum DubinsPathType LSL LSR RSL RSR RLR LRL
@enum SegmentType L_SEG S_SEG R_SEG

DIRDATA = Dict{Int,Vector{SegmentType}}(
                                        Int(LSL) => [L_SEG, S_SEG, L_SEG],
                                        Int(LSR) => [L_SEG, S_SEG, R_SEG],
                                        Int(RSL) => [R_SEG, S_SEG, L_SEG],
                                        Int(RSR) => [R_SEG, S_SEG, R_SEG],
                                        Int(RLR) => [R_SEG, L_SEG, R_SEG],
                                        Int(LRL) => [L_SEG, R_SEG, L_SEG]
                                       )

"""
The data structure that holds the full dubins path.

Its data fields are as follows:

* the initial configuration, qi,
* the params vector that contains the length of each segment, params,
* the turn-radius, ρ, and,
* the Dubins path type given by the @enum DubinsPathType
"""
mutable struct DubinsPath
    qi::Vector{Float64}            # the initial configuration
    params::Vector{Float64}        # the lengths of the three segments
    ρ::Float64                     # turn radius
    path_type::DubinsPathType   # the path type
end

"""
Empty constructor for the DubinsPath type
"""
DubinsPath() = DubinsPath(zeros(3), zeros(3), 1., LSL)

"""
This data structure holds the information to compute the Dubins path
in the transformed coordinates where the initial (x,y) is translated to the
origin, the final the coordinate axis is rotated to make the x-axis aligned with
the line joining the two points. The variable names follow the convention used
in the paper "Classification of the Dubins set" by Andrei M. Shkel and Vladimir Lumelsky
"""
mutable struct DubinsIntermediateResults
    α::Float64                  # transformed α
    β::Float64                  # transformed β
    d::Float64                  # transformed d
    sa::Float64                 # sin(α)
    sb::Float64                 # sin(β)
    ca::Float64                 # cos(α)
    cb::Float64                 # cos(β)
    c_ab::Float64               # cos(α-β)
    d_sq::Float64               # d²
end

"""
Empty constructor for the DubinsIntermediateResults data type
"""
function DubinsIntermediateResults(q0::Vector{Float64}, q1::Vector{Float64}, ρ::Float64)

    ir = DubinsIntermediateResults(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.)

    dx = q1[1] - q0[1]
    dy = q1[2] - q0[2]
    D = sqrt(dx*dx + dy*dy)
    d = D / ρ
    Θ = 0

    # test required to prevent domain errors if dx=0 and dy=0
    (d > 0) && (Θ = mod2pi(atan(dy, dx)))
    α = mod2pi(q0[3] - Θ)
    β = mod2pi(q1[3] - Θ)
    ir.α = α
    ir.β = β
    ir.d = d
    ir.sa = sin(α)
    ir.sb = sin(β)
    ir.ca = cos(α)
    ir.cb = cos(β)
    ir.c_ab = cos(α-β)
    ir.d_sq = d*d

    return ir
end

const EDUBOK = 0                # no error
const EDUBCOCONFIGS = 1         # colocated configurations
const EDUBPARAM = 2             # path parameterization error
const EDUBBADRHO = 3            # the rho value is invalid
const EDUBNOPATH = 4            # no connection between configurations with this word
const EDUBBADINPUT = 5          # uninitialized inputs to functions
TOL = 1e-10                     # tolerance
