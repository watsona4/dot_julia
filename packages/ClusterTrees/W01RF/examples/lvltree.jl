using ClusterTrees
using StaticArrays
using CompScienceMeshes

const P = SVector{3,Float64}


mesh = meshsphere(1.0, 0.15)
# points = [rand(P) for i in 1:800]
points = vertices(mesh)

# using DelimitedFiles
# Q = readdlm("points.dlm", Float64)
# points = [SVector{3,Float64}(Q[i,:]) for i in axes(Q,1)]

root_center = P(0,0,0)
root_size = 1.0
root_node = ClusterTrees.LevelledTrees.HNode(ClusterTrees.PointerBasedTrees.Node(ClusterTrees.LevelledTrees.Data(0,Int[]), 0, 0, 0, 0), 0)
tree = ClusterTrees.LevelledTrees.LevelledTree([root_node], 1, root_center, root_size, Int[1])

smallest_box_size = 0.1
root_sector = 0
root_sfc_state = 1
root_depth = 1
for i in 1:length(points)
    router = ClusterTrees.LevelledTrees.Router(smallest_box_size, points[i])
    root_state = root(tree), root_center, root_size, root_sfc_state, root_depth
    ClusterTrees.update!(tree, root_state, i, router) do tree, node, data
        push!(ClusterTrees.data(tree,node).values, data)
    end
end

ClusterTrees.print_tree(tree)

num_bins = 3
bins = [P[] for i in 1:num_bins]

num_printed = 0
num_points = 0
num_nodes = length(tree.nodes)
for (i,node) in enumerate(ClusterTrees.DepthFirstIterator(tree, root(tree)))
    b = div((i-1)*num_bins, num_nodes) + 1
    append!(bins[b], points[ClusterTrees.data(tree,node).values])
    global num_printed += 1
    global num_points += length(data(tree,node).values)
end

ordered_points = reduce(append!, bins)
ordered_points = [p[i] for p in ordered_points, i = 1:3]
@assert num_printed == length(tree.nodes)
@show num_points
@show length(points)
@assert num_points == length(points)

num_points = 0
ordered_points = P[]
for b in ClusterTrees.LevelledTrees.LevelIterator(tree, length(tree.levels))
    global num_points += length(ClusterTrees.data(tree,b).values)
    append!(ordered_points, points[ClusterTrees.data(tree,b).values])
end
@assert num_points == length(points)

# using Plots
# plot()
# for i in 1:length(bins)
#     scatter!(bins[i])
# end
# plot!(legend=false)
