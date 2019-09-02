struct Ancestors
    node::String

    function Ancestors(node::String)
        if endswith(node, '.') || startswith(node, '.')
            error("Invalid node $node - Cannot end with `.`")
        end
        new(node)
    end
end


function Base.iterate(x::Ancestors, state=nothing)
    node = x.node
    if state == 0 || isempty(node)
        return nothing
    end

    if state == nothing
        state = lastindex(node)
    end

    r = findprev(".", node, state)
    if r == nothing
        return "", 0
    else
        @assert r.start == r.stop
        state = prevind(node, r.start)
        if node[state] == '.'
            error("Invalid node $node - Cannot have `..`")
        end
        return node[1:state], state
    end
end


Base.IteratorSize(::Type{Ancestors}) = Base.SizeUnknown()
Base.eltype(::Type{Ancestors}) = String

is_ancestor_or_self(ancestor::String, descendant::String) = startswith(descendant, ancestor)
