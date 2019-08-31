module SimpleTrees

# using AbstractTrees
using ClusterTrees

struct TreeNode{T}
    num_children::Int
    data::T
end

struct SimpleTree{V <: (AbstractVector{N} where {N<:TreeNode})}
    nodes::V
end


struct ChildView{T} tree::T end
ClusterTrees.children(tree::SimpleTree, node=root(tree)) = collect(ChildView(node))
ClusterTrees.root(tree::SimpleTree) = tree
ClusterTrees.data(tree::SimpleTree, node=root(tree)) = first(node.nodes).data
ClusterTrees.haschildren(tree::SimpleTree, node=root(tree)) = (first(node.nodes).num_children > 0)

Base.IteratorSize(cv::ChildView) = Base.SizeUnknown()


function Base.iterate(itr::ChildView, state=(0,2))
    state[1] == first(itr.tree.nodes).num_children && return nothing
    child = itr.tree.nodes[state[2]]
    newstate = (state[1] + child.num_children + 1, state[2] + child.num_children + 1)
    return SimpleTree(view(itr.tree.nodes, state[2]:lastindex(itr.tree.nodes))), newstate
end

Base.getindex(tree::SimpleTree, i::Int) = tree.nodes[i]


# AbstractTrees.printnode(io::IO, tree::SimpleTree) = show(io, data(tree))

end # module SimpleTrees
