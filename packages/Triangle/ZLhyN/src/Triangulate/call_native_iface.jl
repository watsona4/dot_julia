include("../NativeInterface/native.jl")

function call_basic_triangulation(flat_vertices::Vector{Cdouble}, flat_vertices_map::Vector{Cint})
    return NativeInterface.basic_triangulation(flat_vertices, flat_vertices_map)
end

function call_constrained_triangulation(flat_vertices::Vector{Cdouble}, flat_vertices_map::Vector{Cint}, flat_vertices_edge::Vector{Cint})
    return NativeInterface.constrained_triangulation(flat_vertices, flat_vertices_map, flat_vertices_edge)
end

function call_constrained_triangulation_bounded(flat_vertices::Vector{Cdouble}, flat_vertices_map::Vector{Cint}, flat_vertices_edge::Vector{Cint}, flat_boundary_edges::Vector{Cint})
    options = NativeInterface.TriangulateOptions()
    options.pslg = true

    return NativeInterface.constrained_triangulation_bounded(flat_vertices, flat_vertices_map, flat_vertices_edge, flat_boundary_edges, options)
end

function call_constrained_triangulation_bounded(flat_vertices::Vector{Cdouble}, flat_vertices_map::Vector{Cint}, flat_vertices_edge::Vector{Cint}, flat_boundary_edges::Vector{Cint}, flat_holes::Vector{Cdouble})
    options = NativeInterface.TriangulateOptions()
    options.pslg = true

    return NativeInterface.constrained_triangulation_bounded(flat_vertices, flat_vertices_map, flat_vertices_edge, flat_boundary_edges, flat_holes, options)
end