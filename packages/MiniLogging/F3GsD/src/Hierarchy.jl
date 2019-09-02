module Hierarchy

export Tree, parent_node

include("ancestors.jl")

# - A node is a dot-separated string representing hierarchy.
# - E.g. `""`, `a`, `a.b`, `a.bb.ccc`.
# - `a.b..c` & `a.b.c.` & `.a.b` are not valid.
# A parent node is the nearest ancestor node in `Tree`, fallback to `""` of not found.

struct Tree
    parent_node::Dict{String, String}
    # node => descendants
    # @assert has_node(t, descendant)
    placeholders::Dict{String, Vector{String}}

    Tree() = new(Dict{String, String}(), Dict{String, Vector{String}}())
end

has_node(t::Tree, node::String) = haskey(t.parent_node, node)
has_placeholder(t::Tree, node::String) = haskey(t.placeholders, node)
"""
For external usage only.
"""
parent_node(t::Tree, node::String) = t.parent_node[node]


"""
- Register `node` in `t`.
- Update parent nodes.
"""
function Base.push!(t::Tree, node::String)
    if has_node(t, node)
        return
    end

    if has_placeholder(t, node)
        # Fulfill a placeholder.
        descendants = pop!(t.placeholders, node)
        fix_descendants!(t, node, descendants)
    end

    parent_node = prepare_parent!(t, node)
    t.parent_node[node] = parent_node
end


"""
- `@assert has_node(t, node)`.
- Return the parent node of `node`.
- Register `node` as descendant of all its ancestor placeholders up to its parent node,
- since the further ancestor placeholders do not affect the parent node of `node` if they are fulfilled.
"""
function prepare_parent!(t::Tree, node::String)::String
    # Default.
    parent_node = ""

    for ancestor in Ancestors(node)
        if has_node(t, ancestor)
            # Hierarchy of `ancestor` is complete.
            # Found `parent_node`.
            parent_node = ancestor
            return parent_node
        end

        if has_placeholder(t, ancestor)
            # Register as a descendant.
            push!(t.placeholders[ancestor], node)
        else
            # Create a `Placeholder`.
            t.placeholders[ancestor] = String[node]
        end
    end

    parent_node
end


"""
- `@assert has_placeholder(t, placeholder)`.
- Replace the parent nodes of the descendants with `node` if `is_ancestor_or_self(parent_node, node)`
"""
function fix_descendants!(t::Tree, node::String, descendants::Vector{String})
    for descendant in descendants
        parent_node = t.parent_node[descendant]
        # Here we don't need strict ancestor check as it is slower.
        if is_ancestor_or_self(parent_node, node)
            t.parent_node[descendant] = node
        end
    end
end

end