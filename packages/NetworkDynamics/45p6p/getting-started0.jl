using Pkg
Pkg.activate(".")
using Revise

struct nd_dummy{T}
    e::AbstractArray{T}
end

function nd_dummy()
    nd_dummy{Float64}(zeros(4))
end

function (ndd::nd_dummy{T})(x::AbstractArray{T}) where T
    ndd.e[1] + x[1]
end

function (ndd::nd_dummy{U})(x::AbstractArray{T}) where T where U
    println("Types not compatible")
end


include("src/NetworkDynamics.jl")
using .NetworkDynamics
using LightGraphs
using LinearAlgebra
using DifferentialEquations

g = barabasi_albert(10,5)

#= vertex! is basically dv = sum(e_d) - sum(e_s), so basically simple diffusion with the addition
of staticedge! and odeedge! below. =#

function vertex!(dv, v, e_s, e_d, p, t)
    # Note that e_s and e_d might be empty, the code needs to be able to deal
    # with this situation.
    dv .= 0
    for e in e_s
        dv .-= e
    end
    for e in e_d
        dv .+= e
    end
    nothing
end

odeedge! = (dl,l,v_s,v_d,p,t) -> dl .= 1000*(v_s - v_d - l)
staticedge! = (l,v_s,v_d,p,t) -> l .= v_s - v_d

# We construct the Vertices and Edges with dimension 2.

odevertex = ODEVertex(vertex!,2,[1 0; 0 1],[:v,:v])
odeedge = ODEEdge(odeedge! ,2)
staticedge = StaticEdge(staticedge!, 2)

vertexes = [odevertex for v in vertices(g)]
edgices = [odeedge for e in edges(g)]

nd! = network_dynamics(vertexes,edgices,g)

x0 = rand(nd!.dim_nd)

test_prob = ODEProblem(test,x0,h0,(0.,5.))
test_sol = solve(test_prob)

using Plots

plot(test_sol, vars = 21:40)
