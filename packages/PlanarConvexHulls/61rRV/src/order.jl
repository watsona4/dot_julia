"""
$(TYPEDEF)

A `VertexOrder` represents the order in which the vertices of a [`ConvexHull`](@ref)
are stored.
"""
abstract type VertexOrder end
orientation_comparator(o::VertexOrder) = orientation_comparator(typeof(o))
edge_normal_sign_operator(o::VertexOrder) = orientation_comparator(typeof(o))

"""
$(TYPEDEF)

Counterclockwise vertex order.
"""
struct CCW <: VertexOrder end
orientation_comparator(::Type{CCW}) = >
edge_normal_sign_operator(::Type{CCW}) = +

"""
$(TYPEDEF)

Clockwise vertex order.
"""
struct CW <: VertexOrder end
orientation_comparator(::Type{CW}) = <
edge_normal_sign_operator(::Type{CW}) = -
