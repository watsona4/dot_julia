#_____________________________________________________________________
#                            Alice's code
#
using Statistics

abstract type AbstractPolygon end


mutable struct Polygon <: AbstractPolygon
    x::Vector{Float64}
    y::Vector{Float64}
end


# Retrieve the number of vertices, and their X and Y coordinates
vertices(p::Polygon) = length(p.x)
coords_x(p::Polygon) = p.x
coords_y(p::Polygon) = p.y

# Move, scale and rotate a polygon
function move!(p::Polygon, dx::Real, dy::Real)
    p.x .+= dx
    p.y .+= dy
end

function scale!(p::Polygon, scale::Real)
    m = mean(p.x); p.x = (p.x .- m) .* scale .+ m
    m = mean(p.y); p.y = (p.y .- m) .* scale .+ m
end

function rotate!(p::Polygon, angle_deg::Real)
    θ = float(angle_deg) * pi / 180
    R = [cos(θ) -sin(θ); sin(θ) cos(θ)]
    x = p.x .- mean(p.x)
    y = p.y .- mean(p.y)
    (x, y) = R * [x, y]
    p.x = x .+ mean(p.x)
    p.y = y .+ mean(p.y)
end

#_____________________________________________________________________
#                             Bob's code
#

mutable struct RegularPolygon <: AbstractPolygon
    polygon::Polygon

    radius::Float64
end


function RegularPolygon(n::Integer, radius::Real)
    @assert n >= 3
    θ = range(0, stop=2pi-(2pi/n), length=n)
    c = radius .* exp.(im .* θ)
    return RegularPolygon(Polygon(real(c), imag(c)), radius)
end

# Compute length of a side and the polygon area
side(p::RegularPolygon) = 2 * p.radius * sin(pi / vertices(p))
area(p::RegularPolygon) = side(p)^2 * vertices(p) / 4 / tan(pi / vertices(p))

# Forward methods from `RegularPolygon` to `Polygon`
vertices(p1::RegularPolygon) = vertices(getfield(p1, :polygon))
coords_x(p1::RegularPolygon) = coords_x(getfield(p1, :polygon))
coords_y(p1::RegularPolygon) = coords_y(getfield(p1, :polygon))
move!(p1::RegularPolygon, p2::Real, p3::Real) = move!(getfield(p1, :polygon), p2, p3)
rotate!(p1::RegularPolygon, p2::Real) = rotate!(getfield(p1, :polygon), p2)
function scale!(p::RegularPolygon, scale::Real)
    scale!(p.polygon, scale) # call "super" method
    p.radius *= scale        # update internal state
end

# Attach a label to a polygon
mutable struct Named{T} <: AbstractPolygon
    polygon::T
    name::String
end
Named{T}(name, args...; kw...) where T = Named{T}(T(args...; kw...), name)
name(p::Named) = p.name

# Forward methods from `Named` to `Polygon`
vertices(p1::Named) = vertices(getfield(p1, :polygon))
coords_x(p1::Named) = coords_x(getfield(p1, :polygon))
coords_y(p1::Named) = coords_y(getfield(p1, :polygon))
move!(p1::Named, p2::Real, p3::Real) = move!(getfield(p1, :polygon), p2, p3)
rotate!(p1::Named, p2::Real) = rotate!(getfield(p1, :polygon), p2)
function scale!(p::Named, scale::Real)
    scale!(p.polygon, scale) # call "super" method
end
side(p1::Named) = side(getfield(p1, :polygon))
area(p1::Named) = area(getfield(p1, :polygon))

