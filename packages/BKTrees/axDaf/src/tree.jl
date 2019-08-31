"""
Calculates the Hamming distance (numbers of different bits) between two numbers.
"""
hamming_distance(x::N1, y::N2) where {N1<:Integer, N2<:Integer} = count_ones(xor(x,y))



"""
A node in the B-K tree.
"""
mutable struct Node{T}
    item::Union{Nothing, T}
    children::Dict{Float64, Node{T}}
end

# Constructors
Node(item::T) where T = Node{T}(item, Dict{Float64, Node{T}}())

Node{T}() where T = Node{T}(nothing, Dict{Float64, Node{T}}())



"""
The B-K tree structure.
"""
mutable struct BKTree{T}
    f::Function     # distance function: df(x,y) should return the distance
    root::Node{T}    # node
end

# Parametric constructors (impossible to determine type from arguments alone)
BKTree{T}(f::Function) where {T} = BKTree(f, Node{T}())

BKTree{T}() where T = BKTree(Node{T}())

# Normal constructors
BKTree(root::Node{T}) where {T} = BKTree(hamming_distance, root) 

BKTree(item::T) where {T} = BKTree(hamming_distance, Node(item))

BKTree(f::Function, items::Vector{T}) where {T} = begin
    bkt = BKTree{T}(f) 
    for item in items
        add!(bkt, item)
    end
    return bkt
end

BKTree(items::Vector{T}) where {T} = begin
    bkt = BKTree{T}() 
    for item in items
        add!(bkt, item)
    end
    return bkt
end



# Show methods
show(io::IO, bkt::BKTree{T}) where T = 
    print(io, "B-K Tree{$T}, function=$(bkt.f), ",
          "$(length(bkt.root.children)) branches")

show(io::IO, node::Node{T}) where T = begin
    if node.item != nothing
        print(io, "B-K Node, item=$(node.item), $(length(node.children)) branches")
    else
        print(io, "B-K Node, no items.")
    end
end



# Useful functions
"""
Determines whether a Node in the BKTree is empty or not.
"""
is_empty_node(node::Node) = node.item == nothing ? true : false



"""
Adds a node (i.e. `Node{T}(item::T)`) to the tree.
"""
function add!(tree::BKTree{T}, item::T) where T
    if is_empty_node(tree.root) 
        tree.root = Node(item)
    else
        node = tree.root
        while true
            parent, children = node.item, node.children
            distance = tree.f(item, parent)
            node = get(children, distance, nothing)
            if node == nothing
                children[distance] = Node(item)
                break
            end
        end
    end
    return tree
end



"""
Find items in the tree whose distance is less or equal to
`n` and returns the top `k` items, ordered ascending according
to the distance.
"""
function find(tree::BKTree{T}, item::T, n::Int; k::Int=1) where {T}
    found = Vector{Tuple{Float64,T}}()
    candidates = Deque{Node{T}}()
    push!(candidates, tree.root)
    while !isempty(candidates)
        candidate = popfirst!(candidates)
        distance = tree.f(candidate.item, item)
        if distance <= n
            push!(found, (distance, candidate.item))
        end
        if !isempty(candidate.children)
            lower = distance - n
            upper = distance + n
            for (d, c) in candidate.children
                if lower <= d <= upper
                    push!(candidates, c)
                end
            end
        end
    end
    # Sort by distance
    k = min(k, length(found))
    sfound = sort(found, by=x->x[1], rev=false)[1:k]
    return sfound
end 
