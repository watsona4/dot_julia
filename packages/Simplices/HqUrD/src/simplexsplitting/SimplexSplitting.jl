__precompile__(true)

module SimplexSplitting

using LinearAlgebra
using Printf
using Distributions
using Parameters

include("../even_sampling.jl")
include("complementary.jl")
include("simplex_split.jl")
include("simplex_subdivision.jl")
include("simplex_subdivision_single.jl")
include("heaviside.jl")
include("embed.jl")
include("triangulate.jl")
include("refine_triangulation.jl")
include("refine_triangulation_with_images.jl")
include("invariantset.jl")
include("centroids_radii.jl")
include("simplexvolumes.jl")
include("refine_recursive.jl")
include("refine_recursive_withimages.jl")
include("refine_t.jl")
include("refine_variable_k.jl")
include("orientations.jl")

export tensordecomposition, simplex_split, simplicial_subdivision_single,
simplicial_subdivision, embed, Embedding, embedding, embedding_ex, triangulate, Triangulation, triang_from_embedding, embedding_example, refine_triangulation, simplex_volumes,
refine_triangulation_images, invariantset, centroids_radii2, refine_recursive, refine_recursive_images, refine_variable_k!, refine_variable_k_new, refine_variable_k_newnew, query_refinement,
refine_t!,
gaussian_embedding, centroids_radii2, example_triangulation,
gaussian_embedding_arr,
random_embedding,
orientations,
Simplex,
find_simplex, find_imsimplex,
get_simplices, get_imagesimplices,
maybeintersecting_simplices, maybeintersecting_imsimplices
end # module
