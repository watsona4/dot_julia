module MerkleTrees

export MerkleTree,
       merkle_parent, merkle_parent_level, merkle_root,
       root, populate!

include("hash.jl")

"""
    merkle_parent(hash1::Vector{UInt8}, hash2::Vector{UInt8})
    -> Vector{UInt8}

Takes the binary hashes and calculates the hash256
"""
function merkle_parent(hash1::Vector{UInt8}, hash2::Vector{UInt8})
    hash256(append!(copy(hash1), hash2))
end

"""
    merkle_parent_level(Vector{Vector{UInt8}})
    -> Vector{Vector{UInt8}}

Takes a list of binary hashes and returns a list that"s half
the length
Returns an error if the list has exactly 1 element
"""
function merkle_parent_level(hashes::Vector{Vector{UInt8}})
    h = copy(hashes)
    if length(h) == 1
        error("Cannot take a parent level with only 1 item")
    end
    if length(h) % 2 == 1
        push!(h, h[end])
    end
    parent_level = Vector{UInt8}[]
    for i in 1:2:length(h)
        parent = merkle_parent(h[i], h[i + 1])
        push!(parent_level, parent)
    end
    parent_level
end

"""
    merkle_root(hashes::Vector{Vector{UInt8}})
    -> Vector{UInt8}

Takes a list of binary hashes and returns the merkle root
"""
function merkle_root(hashes::Vector{Vector{UInt8}})
    current_level = hashes
    while length(current_level) > 1
        current_level = merkle_parent_level(current_level)
    end
    current_level[1]
end

mutable struct MerkleTree
    total::Integer
    max_depth::Integer
    nodes
    current_depth::Integer
    current_index::Integer
    MerkleTree(total, max_depth, nodes, current_depth::Integer=1, current_index::Integer=1) = new(total, max_depth, nodes, current_depth, current_index)
end

"""
    MerkleTree(x::Integer) -> MerkleTree

Create a MerkleTree of `x` elements
"""
function MerkleTree(total::Integer)
    max_depth = 1 + ceil(Integer, log2(total))
    nodes = Vector{Union{Nothing, Vector{UInt8}}}[]
    for depth in 1:max_depth
        num_items = ceil(Integer, total / 2.0^(max_depth - depth))
        level_hashes = fill(nothing, num_items)
        push!(nodes, level_hashes)
    end
    MerkleTree(total, max_depth, nodes)
end

function show(io::IO, z::MerkleTree)
    result, depth = "", 1
    for level in z.nodes
        items, index = "", 1
        for h in level
            if h == nothing
                short = "  Nothing   "
            else
                short = " " * bytes2hex(h)[1:8] * "..."
            end
            if depth == z.current_depth && index == z.current_index
                result *= (items * "*" * short[2:end-2] * " *")
            else
                result *= (items * short)
            end
            index +=1
        end
        result *= (items * "\n")
        depth += 1
    end
    print(io, result)
end


"""
Reduce depth by 1 and halve the index
"""
function up!(tree::MerkleTree)
    if tree.current_depth != 1
        tree.current_depth -= 1
        tree.current_index = div(tree.current_index + 1, 2)
    end
end

"""
Increase depth by 1 and double the index
"""
function left!(tree::MerkleTree)
    tree.current_depth += 1
    tree.current_index = tree.current_index * 2 - 1
end

"""
Increase depth by 1 and double the index - 1
"""
function right!(tree::MerkleTree)
    tree.current_depth += 1
    tree.current_index *= 2;
end

"""
    root(tree::MerkleTree)
    -> Union{Nothing, Vector{UInt8}}

Returns the value of the tree root
"""
function root(tree::MerkleTree)
    tree.nodes[1][1]
end

"""
    set_current_node!(tree::MerkleTree, value::Vector{UInt8})
    -> Nothing

Set `value` to current node
"""
function set_current_node!(tree::MerkleTree, value::Vector{UInt8})
    tree.nodes[tree.current_depth][tree.current_index] = value
end

"""
    get_left_node(tree::MerkleTree)
    -> Union{Nothing, Vector{UInt8}}

Returns the value of the current node
"""
function get_current_node(tree::MerkleTree)
    tree.nodes[tree.current_depth][tree.current_index]
end

"""
    get_left_node(tree::MerkleTree)
    -> Union{Nothing, Vector{UInt8}}

Returns the value of the left children
"""
function get_left_node(tree::MerkleTree)
    tree.nodes[tree.current_depth + 1][tree.current_index * 2 - 1]
end

"""
    get_right_node(tree::MerkleTree)
    -> Union{Nothing, Vector{UInt8}}

Returns the value of the right children
"""
function get_right_node(tree::MerkleTree)
    tree.nodes[tree.current_depth + 1][tree.current_index * 2]
end

"""
    is_leaf(tree::MerkleTree) -> Bool

Checks current node is a leaf
"""
function is_leaf(tree::MerkleTree)
    tree.current_depth == tree.max_depth
end

"""
    right_exists(tree::MerkleTree) -> Bool

Check if a right children exists
"""
function right_exists(tree::MerkleTree)
    try
        length(tree.nodes[tree.current_depth + 1]) >= tree.current_index * 2
    catch
        false
    end
end

"""
    populate!(tree::MerkleTree, flag_bits::Vector{Bool},
              hashes::Vector{Vector{UInt8}})
    -> Nothing

Fills a Merkle Tree with a list of hashes
"""
function populate!(tree::MerkleTree, flag_bits::Vector{Bool}, hashes::Vector{Vector{UInt8}})
    while root(tree) == nothing
        if is_leaf(tree)
            popfirst!(flag_bits)
            set_current_node!(tree, popfirst!(hashes))
            up!(tree)
        else
            left_hash = get_left_node(tree)
            if left_hash == nothing
                if !(popfirst!(flag_bits))
                    set_current_node!(tree, popfirst!(hashes))
                    up!(tree)
                else
                    left!(tree)
                end
            elseif right_exists(tree)
                right_hash = get_right_node(tree)
                if right_hash == nothing
                    right!(tree)
                else
                    set_current_node!(tree, merkle_parent(left_hash, right_hash))
                    up!(tree)
                end
            else
                set_current_node!(tree, merkle_parent(left_hash, left_hash))
                up!(tree)
            end
        end
    end
    if length(hashes) != 0
        error("hashes not all consumed ", length(hashes))
    end
    for flag_bit in flag_bits
        if flag_bit
            error("flag bits not all consumed")
        end
    end
end

end # module
