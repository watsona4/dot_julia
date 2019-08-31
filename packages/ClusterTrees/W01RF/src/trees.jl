export data
export children
export update!
# export insert!
export root

"""
    data(tree, node)

Retrieve the data aka payload associated with the given node.
"""
function data end


"""
    root(tree)

Return a proxy for the root of the tree.
"""
function root end


"""
    insert!(tree, parent, data)

Insert a node carrying 'data' as a new child of 'parent'
"""
function insert! end

"""
    The expression `children(tree,node)` returns an iterator that will produce
    a sequence of node iterators. These values do not have a lot of meaning by
    themselves, but can be used in conjunction with the tree object. E.g:

        data(tree, node_itr)
        children(tree, node_itr)

    In fact, the node iterators should be regarded as lightweight proxies for
    the underlying node and their attached data payload. The node objects
    themselves are of limited use for the client programmer as they are an
    implementation detail of the specific tree being used.
"""
function children end

function haschildren end

"""
Traverse the tree depth first, executing the function `f(tree, node, level)`
at every node. If `f` returns `false`, recursion is halted and the next node
on the current level is visited.
"""
function depthfirst(f, tree, node=root(tree), level=1)
    f(tree, node, level) || return
    for c in ClusterTrees.children(tree, node)
        depthfirst(f, tree, c, level+1)
    end
end

function print_tree(tree, node=root(tree); maxdepth=0)
    depthfirst(tree) do tree, node, level
        print("-"^(level-1))
        println(ClusterTrees.data(tree, node))
        return level == maxdepth ? false : true
    end
end


function route! end

"""
    update!(f, tree, node, data, router!)

Algorithm to update or add nodes of the tree. `router!` and `updater!` are
user supplied functions:

    router!(tree, node)

Returns the next candidate `node` until the node for insertion is reaches. Note
that this function potentially created new nodes. Arrival at the destination is
indicated by returning the same node that was passed as the second argument.

    f(tree, node, data)

Update the destination node `node`. Typically, `data` is added in some sense
to the data residing at the desitination node.
"""
function update!(f, tree, state, data, target)
    while true
        next_state = route!(tree, state, target)
        next_state == state && break
        state = next_state
    end
    node = state[1]
    f(tree, node, data)
    return node
end

struct DepthFirstIterator{T,N}
    tree::T
    node::N
end

Base.IteratorSize(::DepthFirstIterator) = Base.SizeUnknown()

function Base.iterate(itr::DepthFirstIterator)
    chitr = children(itr.tree,itr.node)
    stack = Any[(chitr, iterate(chitr))]
    iterate(itr, stack)
end

function Base.iterate(itr::DepthFirstIterator, stack)
    isempty(stack) && return nothing
    while true
        chditr, next = last(stack)
        if next != nothing
            node, state = next
            chitr = children(itr.tree, node)
            push!(stack, (chitr, iterate(chitr)))
        else
            pop!(stack)
            isempty(stack) && return (itr.node, stack)
            chitr, (node, state) = last(stack)
            stack[end] = (chitr, iterate(chitr, state))
            return node, stack
        end
    end
end

function leaves(tree, node=root(tree))
    Iterators.filter(n->!haschildren(tree,n), DepthFirstIterator(tree,node))
end
