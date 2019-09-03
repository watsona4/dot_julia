module RingLists
export RingList, insertafter!, previous

import Base: ==, length, getindex, keys, haskey, insert!, eltype
import Base: Vector, show, hash, reverse, first, delete!, Set

struct RingList{T}
    data::Dict{T,T}
    revdata::Dict{T,T}
end

"""
`RingList{T}()` creates a new, empty `RingList` holding elements of type `T`.
Example: `RingList{Int}()`.

`RingList(list)` creates a new `RingList` from the elements in the
one-dimensional array `list`. Example: `RingList([1,2,3])`.

`RingList(x...)` creates a new `RingList` from the arguments.
Example: `RingList(1,2,3)`.
"""
function RingList(T::Type=Any)
    return RingList(Dict{T,T}(),Dict{T,T}())
end

function _rev(d::Dict{T,T}) where T
    rd = Dict{T,T}()
    for k in keys(d)
        v = d[k]
        rd[v] = k
    end
    return rd
end

function RingList(vals::Vector{T}) where T
    d = Dict{T,T}()
    n = length(vals)
    if n != length(unique(vals))  # check there are no repeats
        error("List of values may not have a repeat")
    end
    if n == 0
        return RingList(d,d)
    end
    if n==1
        a = vals[1]
        d[a] = a
        return RingList(d,d)
    end
    for i=1:n-1
        a = vals[i]
        b = vals[i+1]
        d[a] = b
    end
    a = vals[end]
    b = vals[1]
    d[a] = b
    return RingList(d,_rev(d))
end

function RingList(x...)
    return RingList(collect(x))
end

function RingList{T}() where T
    d = Dict{T,T}()
    return RingList(d,d)
end

==(a::RingList,b::RingList) = a.data == b.data
length(a::RingList) = length(a.data)
keys(a::RingList) = keys(a.data)
getindex(a::RingList, x) = a.data[x]

"""
`previous(a,x)` returns the element `y` so that `a[y]==x`.
"""
previous(a::RingList, x) = a.revdata[x]

haskey(a::RingList,x) = haskey(a.data,x)
eltype(a::RingList{T}) where T = T

"""
`first(a::RingList, true_first::Bool = false)` returns
an element of `a`. If `true_first` is `true`, then try to
return the smallest element held in `a`.
"""
function first(a::RingList, true_first::Bool = false)
    if true_first
        try
            x = minimum(keys(a))
            return x
        catch
        end
    end
    return first(a.data)[1]
end


"""
`insert!(a,x)` adds the element `x` into `a`.
No guarantee where it will go. See also
`insertafter!`
"""
function insert!(a::RingList{T},x::T) where T
    if length(a) == 0
        a.data[x] = x
        a.revdata[x] = x
        return nothing
    end
    if haskey(a,x)
        error("$x already in this RingList")
    end
    y = first(a)  # get the other elements
    if length(a) == 1
        a.data[x] = y
        a.data[y] = x
        a.revdata[x] = y
        a.revdata[y] = x
        return nothing
    end
    # y-->z   becomes y --> x --> z
    z = a[y]
    a.data[y] = x
    a.data[x] = z

    a.revdata[z] = x
    a.revdata[x] = y

    nothing
end

"""
`insertafter!(a::RingList,x,y)` inserts `x` into `a` after `y`.
"""
function insertafter!(a::RingList, x, y)
    if haskey(a,x)
        error("Element $x alread in this RingList")
    end
    if !haskey(a,y)
        error("Element $y not in this RingList, cannot insert after")
    end
    # who is currently after y?
    z = a[y]
    # we have y --> z
    # and change to y --> x --> z

    a.data[y] = x
    a.data[x] = z

    a.revdata[x] = y
    a.revdata[z] = x

    nothing
end

"""
`delete!(a,x)` removes `x` from the `RingList`.
"""
function delete!(a,x)
    if !haskey(a,x)
        error("$x not in the RingList")
    end
    if length(a)==1
        delete!(a.data,x)
        return
    end

    # prev --> x --> next
    next = a[x]
    prev = previous(a,x)
    delete!(a.data,x)
    delete!(a.revdata,x)
    a.data[prev] = next
    a.revdata[next] = prev
    return
end


function Vector(a::RingList{T}) where T
    n = length(a)
    if n == 0
        return T[]
    end
    K = keys(a)
    result = Vector{T}(undef,n)

    result[1] = first(a,true)

    i = 1
    while i<n
        i += 1
        result[i] = a[result[i-1]]
    end

    return result
end

"""
`reverse(a::RingList)` returns a new `RingList` containing the
same elements as `a` but in reverse order.
"""
reverse(a::RingList{T}) where T = RingList{T}(a.revdata,a.data)

Set(a::RingList{T}) where T = Set{T}(keys(a))



function show(io::IO, a::RingList{T}) where T
    v = Vector(a)
    result = "RingList{$T}("
    n = length(a)
    for i=1:n
        result *= "$(v[i])"
        if i<n
            result *= ","
        end
    end
    result *= ")"
    print(io, result)
end

hash(a::RingList) = hash(a.data)
hash(a::RingList, h::UInt64) = hash(a.data, h)


end # module
