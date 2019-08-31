using ClusterTrees
using StaticArrays
using Test

const P = SVector{3,Float64}

using DelimitedFiles
Q = readdlm(joinpath(@__DIR__,"points.dlm"), Float64)
points = [SVector{3,Float64}(Q[i,:]) for i in axes(Q,1)]

root_center = P(0.5,0.5,0.5)
root_size = 0.5
root_node = ClusterTrees.LevelledTrees.HNode(ClusterTrees.PointerBasedTrees.Node(ClusterTrees.LevelledTrees.Data(0,Int[]), 0, 0, 0, 0), 0)
tree = ClusterTrees.LevelledTrees.LevelledTree([root_node], 1, root_center, root_size, Int[1])

smallest_box_size = 0.1
root_sector = 0
root_sfc_state = 1
root_depth = 1
for i in 1:length(points)
    router = ClusterTrees.LevelledTrees.Router(smallest_box_size, points[i])
    root_state = root(tree), root_center, root_size, root_sfc_state, root_depth
    ClusterTrees.update!(tree, root_state, i, router)  do tree, node, data
        push!(ClusterTrees.data(tree,node).values, data)
    end
end

# ClusterTrees.print_tree(tree)

num_bins = 3
bins = [P[] for i in 1:num_bins]

num_printed = 0
num_points = 0
num_nodes = length(tree.nodes)
for (i,node) in enumerate(ClusterTrees.DepthFirstIterator(tree, root(tree)))
    # println(node, ": ", tree.nodes[node])
    b = div((i-1)*num_bins, num_nodes) + 1
    append!(bins[b], points[ClusterTrees.data(tree,node).values])
    global num_printed += 1
    global num_points += length(data(tree,node).values)
end

ordered_points = reduce(append!, bins)
ordered_points = [p[i] for p in ordered_points, i = 1:3]
@test num_printed == length(tree.nodes)
@test num_points == length(points)

num_points = 0
ordered_points = P[]
for b in ClusterTrees.LevelledTrees.LevelIterator(tree, length(tree.levels))
    global num_points += length(ClusterTrees.data(tree,b).values)
    append!(ordered_points, points[ClusterTrees.data(tree,b).values])
end
@test num_points == length(points)

@test length(tree.levels) == 4
@test ClusterTrees.LevelledTrees.numlevels(tree) == 4
lvl1 = collect(ClusterTrees.LevelledTrees.LevelIterator(tree,1))
@test lvl1 == [1]
lvl2 = collect(ClusterTrees.LevelledTrees.LevelIterator(tree,2))
@test lvl2 == [10,13,2,5,23]
lvl3 = collect(ClusterTrees.LevelledTrees.LevelIterator(tree,3))
@test lvl3 == [19,11,21,16,14,3,8,6,24]
lvl4 = collect(ClusterTrees.LevelledTrees.LevelIterator(tree,4))
@test lvl4 == [20,18,12,22,17,15,4,9,7,25]
