module CircularList

import Base: insert!, delete!, length, size, eltype, iterate, show

export circularlist, length, size, current, previous, next, 
    insert!, delete!, shift!, forward!, backward!,
    eltype, iterate, show, head, tail

"""
Doubly linked list implementation
"""
mutable struct Node{T} 
    data::Union{T, Nothing} 
    prev::Union{Node{T}, Nothing}
    next::Union{Node{T}, Nothing}
end

"""
List is used to hold a pre-allocated vector of nodes.
"""
mutable struct List{T} 
    nodes::Vector{Node{T}}      # preallocated array of nodes
    current::Node{T}            # current "head" or the circular list
    length::Int                 # number of active elements
    last::Int                   # last index of the nodes array
    capacity::Int               # size of the nodes array
end

"Create a circular list with the specified data element."
function circularlist(data::T; capacity = 100) where T
    nodes = [Node{T}(nothing, nothing, nothing) for _ in 1:capacity]
    n = nodes[1]
    n.data = data
    n.prev = n
    n.next = n
    return List(nodes, n, 1, 1, capacity)
end

"Create a circular list from any vector"
function circularlist(vec::AbstractVector{T}; kw...) where T
    CL = circularlist(vec[1]; kw...)
    for i in 2:length(vec)
        insert!(CL, vec[i])
    end
    forward!(CL)  # move one more step to the original head
    return CL
end

"Returns the length of the circular list"
length(CL::List) = CL.length

"Allocates a new uninitialized node in the circular list"
function allocate!(CL::List, T::DataType)
    if CL.last == CL.capacity   # exceeded capacity...auto resize.
        newcapacity = CL.capacity * 2
        additional  = newcapacity - CL.capacity
        CL.nodes = vcat(CL.nodes, [Node{T}(nothing, nothing, nothing) for _ in 1:additional])
        CL.capacity = newcapacity
    end
    CL.length += 1
    CL.last += 1
    return CL.nodes[CL.last]
end

"Insert a new node after the current node and return the new node."
function insert!(CL::List, data) 
    cl = CL.current
    
    n = allocate!(CL, typeof(data))  # make a new node and arrange prev/next pointers
    n.data = data
    n.prev = cl
    n.next = cl.next

    cl.next = n         # fix prev node's next pointer
    n.next.prev = n     # fix next node's prev pointer
    
    CL.current = n     # move pointer to newly inserted node
    return CL
end

"""
Delete current node and return the previous node.

_Warning_: removed nodes are not reclaimed from memory for simplicity reasons
"""
function delete!(CL::List)
    length(CL) == 1 && error("cannot remove last item in circular list")
    cl = CL.current
    cl.prev.next = cl.next   # fix prev node's next pointer
    cl.next.prev = cl.prev   # fix next node's prev pointer
    CL.current = cl.prev    # reset List's current pointer to prev
    CL.length -= 1
    return CL
end

"""
Shift the current pointer forward or backward.
"""
function shift!(CL::List, steps::Int, direction::Symbol)
    for i in 1:steps
        if direction == :forward 
            CL.current = CL.current.next
        elseif direction == :backward
            CL.current = CL.current.prev
        else
            error("Wrong direction: $direction")
        end
    end
    return CL
end

"Shift the current pointer forward."
forward!(CL::List) = shift!(CL, 1, :forward)

"Shift the current pointer backward."
backward!(CL::List) = shift!(CL, 1, :backward)

"Return the current node."
current(CL::List) = CL.current

"Return the previous node."
previous(CL::List) = CL.current.prev

"Return the ext node."
next(CL::List) = CL.current.next

"Return the head of the list (current node)."
head(CL::List) = CL.current

"Return the tail of the list (last node)"
tail(CL::List) = CL.current.prev

"Iteration protocol implementation."
function iterate(CL::List, (el, i) = (CL.current, 1))
    i > CL.length && return nothing
    return (el.data, (el.next, i + 1))
end

"Return the element type of the list"
eltype(CL::List) = typeof(CL.current.data)

"Return the size of the list."
size(CL::List) = (CL.length, )

"Show list."
function show(io::IO, CL::List{T}) where T
    print(io, "CircularList.List(")
    i = 1
    for x in CL
        show(io, x)
        i += 1
        i <= length(CL) && print(io, ",")
    end
    print(io, ")")
end

"Show node"
function show(io::IO, node::Node{T}) where T
    print(io, "CircularList.Node(")
    show(io, node.data)
    print(io, ")")
end

end # module

