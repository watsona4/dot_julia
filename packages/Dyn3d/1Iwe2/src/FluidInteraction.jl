module FluidInteraction

export BodyGrid, CutOut2d, DetermineNP
export AcquireBodyGridKinematics, IntegrateBodyGridDynamics, GenerateBodyGrid

using LinearAlgebra
using Dyn3d
using Interpolations

#-------------------------------------------------------------------------------
"""
    BodyGrid(bid::Int, np::Int, points, q_i, f_ex3d, f_ex6d)

Design this structure to contain body points coord, motion and forces used in fluid-structure interaction

## Fields

- `bid`: body id in the joint-body chain
- `np`: number of grid points on this body
- `points`: (x,y,z) coordinates of all body points in local body frame
- `q_i`: (x,y,z) coordinates of all body points in inertial frame
- `v_i`: velocity of all body points in inertial frame
- `f_ex3d`: external force(fluid force) on all body points in inertial frame
- `f_ex6d`: f_ex3d integrated through all body points on one body and described in 6d spatial vector form

## Constructors

- `BodyGrid(bid,np,points)`: initialize q_i, v_i, f_ex3d to be Vector of zeros(3),
                             f_ex6d to be zeros(6)
"""
mutable struct BodyGrid
    bid::Int
    np::Int
    points::Vector{Vector{Float64}}
    q_i::Vector{Vector{Float64}}
    v_i::Vector{Vector{Float64}}
    f_ex3d::Vector{Vector{Float64}}
    f_ex6d::Vector{Float64}
end
BodyGrid(bid,np,points) = BodyGrid(bid,np,points,[zeros(Float64,3) for i=1:np],
    [zeros(Float64,3) for i=1:np], [zeros(Float64,3) for i=1:np], zeros(Float64,6))

#-------------------------------------------------------------------------------
"""
    CutOut2d(bd::BodyDyn,bgs::Vector{BodyGrid})

This function need to be called only once after GenerateBodyGrid for 2d case of
flat plates.

In `Dyn3d`, bodies are constructed by quadrilateral/triangles(not lines) in z-x plane
for both 2d/3d cases. In `Whirl`, fluid in 2d cases are constructed in x-y plane.
Thus to describe plates as lines in x-y space, we cut out the info on
the other sides of the plate. Note that verts are formulated in clockwise
direction, with the left-bottom corner as origin.
"""
function CutOut2d(bd::BodyDyn,bgs::Vector{BodyGrid})
    if bd.sys.ndim == 2 && bd.bs[1].nverts == 4
        for i = 1:length(bgs)
            nverts = bd.bs[bgs[i].bid].nverts
            cutout = round(Int,(bgs[i].np-1)/nverts)
            bgs[i].np = round((bgs[i].np-1)/4)+1
            bgs[i].points = bgs[i].points[end:-1:end-cutout]
            bgs[i].q_i = bgs[i].q_i[end:-1:end-cutout]
            bgs[i].v_i = bgs[i].v_i[end:-1:end-cutout]
            bgs[i].f_ex3d = bgs[i].f_ex3d[end:-1:end-cutout]
        end
    else error("function Cutout2d currently only support quadrilateral shape.")
    end
    return bgs
end

#-------------------------------------------------------------------------------
"""
    DetermineNP(nbody::Int, Δx)

Run this function before running GenerateBodyGrid, to determine number of points
on a 2d body, in order to satisfy the desired number of points on the 1d body.

np = (# of points on 1d plate - 1)*4+1.
So np=201 has 51 points(1 body),
np=101 has 26 points(2 body),
np=49 has 13 points(4 body),
np=25 has 7 points(8 body), etc.
"""
function DetermineNP(nbody::Int, Δx::Float64;fine::Union{Float64,Int64}=1.0)
   # default total body length is 1
    n = round(Int,1/Δx) + 1
    while mod(n,nbody) != 0
        n +=1
    end
    n_per_b = round(Int,n/nbody)*fine
    if n_per_b < 5
        error("Use less number of bodys, otherwise too little points on a body")
    end
    return (n_per_b-1)*4+1
end

#-------------------------------------------------------------------------------
"""
    GenerateBodyGrid(bd::BodyDyn; np=101)

Given BodyDyn structure, where each body only consists of several verts(usually
4 for quadrilateral and 3 for triangle), return the verts position in inertial
frame of given number of points np by interpolation, of all bodies in the system.
"""
function GenerateBodyGrid(bd::BodyDyn; np=101)
    # here we assume the body chain consists of only 1 body, or several bodies
    # of the same shape
    @getfield bd (bs,sys)

    bodygrids = Vector{BodyGrid}(undef,sys.nbody)
    # for cases with only 1 body, which has more than 4 grid points(like a circle)
    if bs[1].nverts != 3 && bs[1].nverts != 4
        a = bs[1].verts
        bodygrids[1] = BodyGrid(1,bs[1].nverts,[a[i,:] for i =1:size(a,1)])
        return bodygrids
    end

    if (np-1) % bd.bs[1].nverts != 0 error("Number of points can't be divided by system.nverts") end

    bodygrids = Vector{BodyGrid}(undef,sys.nbody)
    for i = 1:sys.nbody
        bid = bs[i].bid
        verts_id = range(1, stop=np, length=bs[bid].nverts+1)
        verts = vcat(bs[bid].verts,bs[bid].verts[1,:]')
        it_x = interpolate((verts_id,), verts[:,1], Gridded(Linear()))
        it_y = interpolate((verts_id,), verts[:,2], Gridded(Linear()))
        it_z = interpolate((verts_id,), verts[:,3], Gridded(Linear()))
        grid = [[it_x(j),it_y(j),it_z(j)] for j=1:np]
        bodygrids[i] = BodyGrid(bid,np,grid)
    end
    return bodygrids
end

#-------------------------------------------------------------------------------
"""
    AcquireBodyGridKinematics(bd::BodyDyn, bgs::Vector{BodyGrid})

Given updated bd structure, which contains 3d bs[i].x_i in inertial frame and
6d bs[i].v of each body in the body local frame, return 3d linear q_i and v_i of
each body point in the inertial frame.
"""
function AcquireBodyGridKinematics(bd::BodyDyn, bgs::Vector{BodyGrid})
    @getfield bd (bs, sys)
    # pointer to pre-allocated array
    @getfield sys.pre_array (la_tmp1, la_tmp2)

    # the j-th q_i in body points of a body = bs[i].x_i + Xb_to_i*points[j]
    # the j-th v_i in body points of a body is calculated by transferring to
    # a coordinate that sits at the beginning point of the first body but with
    # zero angle.
    X_ref = zeros(Float64,6)
    for i = 1:length(bgs)
        b = bs[bgs[i].bid]
        if b.bid == 1
            X_ref = TransMatrix([zeros(Float64,3);b.x_i],la_tmp1,la_tmp2)
        end
    end

    for i = 1:length(bgs)
        b = bs[bgs[i].bid]
        for j = 1:bgs[i].np
            q_temp = [zeros(Float64, 3); bgs[i].points[j]]
            q_temp = [zeros(Float64, 3); b.x_i] + b.Xb_to_i*q_temp
            bgs[i].q_i[j] = q_temp[4:6]
            v_temp = bs[i].v + [zeros(Float64, 3); cross(bs[i].v[1:3],bgs[i].points[j])]
            bgs[i].v_i[j] = (X_ref*b.Xb_to_i*v_temp)[4:6]
        end
    end
    return bgs
end

#-------------------------------------------------------------------------------
"""
    IntegrateBodyGridDynamics(bd::BodyDyn, bgs::Vector{BodyGrid})

Given external 3d linear fluid force f_ex of each body point contained in updated
bgs structure, do intergral to return integrated 6d body force([torque,force])
exerting on the beginning of current body, desribed in inertial frame.
"""
function IntegrateBodyGridDynamics(bd::BodyDyn, bgs::Vector{BodyGrid})
    @getfield bd (bs,sys)
    # pointer to pre-allocated array
    @getfield sys.pre_array (la_tmp1, la_tmp2)

    # temporary memory
    r_temp1 = zeros(Float64,6)
    r_temp2 = zeros(Float64,6)
    f_temp = zeros(Float64,6)
    Xic_to_i = zeros(Float64,6,6)

    for i = 1:length(bgs)
        b = bs[bgs[i].bid]
        bgs[i].f_ex6d = zeros(Float64,6)
        for j = 1:bgs[i].np
            # linear force in inertial grid coord
            f_temp .= 0.0
            f_temp[4:6] .= bgs[i].f_ex3d[j]
            # get transform matrix from grid points in inertial frame to the origin of inertial frame
            r_temp1 .= 0.0
            r_temp1[4:6] .= bgs[i].points[1] .- bgs[i].points[j]
            r_temp1 .= b.Xb_to_i*r_temp1
            r_temp2 .= 0.0
            r_temp2[4:6] .= -b.x_i .+ r_temp1[4:6]
            Xic_to_i = TransMatrix(r_temp2,la_tmp1,la_tmp2)
            # express force in inertial frame at origin
            f_temp .= inv(Xic_to_i')*f_temp
            bgs[i].f_ex6d .+= f_temp
        end
    end
    return bgs
end


end
