"""
DifferenceLists, (c) 2018, Bill Burdick (William R. Burdick Jr.)
MIT Licensed (see LICENSE file).
"""

module DifferenceLists

export DL, dl, concat, push, pushfirst, todl, dlconcat

"""
    DL(func)

Given function `func`, construct a difference list.

Difference lists are highly efficient, immutable, concatenate and prepend in constant time, and iterate in time N.

# Examples
```jldoctest
julia> [x for x = dl(1, 2, 3)]
3-element Array{Int64,1}:
 1
 2
 3
```
"""
struct DL
    func
end

"""
    dl()::DL
    dl(items...)::DL

Construct a difference list of `items`.

# Examples
```jldoctest
julia> dl()
dl()

julia> dl(1)
dl(1)

julia> dl(1, 2, 3)
dl(1, 2, 3)

julia> dl(1, dl(2, 3), 4)
dl(1, dl(2, 3), 4)
```
"""
dl() = DL(last -> last)
dl(items...) = todl(items)

"""
    todl(items)

Create a difference list from something you can iterate over

# Examples
```jldoctest
julia> todl([1, 2, 3])
dl(1, 2, 3)
```
"""
todl(items) = DL(last -> nextFor(items, iterate(items), last))
todl(dl::DL) = dl

"""
    nextFor(items, state, last)

Compute the next iteration value for an embedded collection.
"""
nextFor(items, ::Nothing, last) = last
nextFor(items, (item, state), last) = item, (items, state, last)

"""
    push(item, dl::DL)

Push an item onto the end of a difference list.

# Examples
```jldoctest
julia> push(2, push(1, dl(7, 8, 9)))
dl(7, 8, 9, 1, 2)
```
"""
push(dl::DL, items...) = concat(dl, todl(items))

"""
    pushfirst(item, dl::DL)

Push an item onto the front of a difference list.

# Examples
```jldoctest
julia> pushfirst(1, pushfirst(2, dl(7, 8, 9)))
dl(1, 2, 7, 8, 9)
```
"""
pushfirst(dl::DL, items...) = concat(todl(items), dl)

"""
    concat(lists::DL...)::DL

Concatenate difference lists in constant time

See also: [`dl`](@ref)

# Examples
```jldoctest
julia> concat(dl(1, 2), dl(3, 4))
dl(1, 2, 3, 4)

julia> concat(dl(1), dl(2))
dl(1, 2)
```
"""
concat(lists::DL...) = DL(last -> foldr((x, y) -> x.func(y), lists, init=last))
dlconcat(lists...) = DL(last -> foldr((x, y) -> x.func(y), map(todl, lists), init=last))

"""
    (a::DL)(lists::DL...)::DL

A difference list itself can be used as shorthand for concat.

See also: [`dl`](@ref), [`concat`](@ref)

# Examples
```jldoctest
julia> dl(1, 2)(dl(3, 4), dl(5, 6, 7))
dl(1, 2, 3, 4, 5, 6, 7)
```
"""
(a::DL)(lists...) = concat(a, map(todl, lists)...)

# Iteration support
Base.iterate(d::DL) = d.func(nothing)
Base.iterate(::DL, cur::Tuple{Any, Any}) = cur
Base.iterate(::DL, (items, state, last)::Tuple{Any, Any, Any}) = nextFor(items, iterate(items, state), last)
Base.iterate(::DL, ::Nothing) = nothing
Base.IteratorSize(::DL) = Base.SizeUnknown()

# value display support
Base.show(io::IO, dl::DL) = print(io, "dl(", join([sprint(show, x) for x = dl], ", "), ")")

end # module
