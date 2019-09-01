export FlexVector, FlexOnes, FlexConvert, delete_entry!

struct FlexVector{S<:Any,T<:Number}
    data::Dict{S,T}
    function FlexVector{T}(dom) where T<:Number
        S = eltype(dom)
        d = Dict{S,T}()
        for x in dom
            d[x] = zero(T)
        end
        new{S,T}(d)
    end
end

"""
`FlexVector{T}(idx)` creates a new `FlexVector`
with entries indexed by `idx` filled with zeros of
type `T` (which defaults to `Number`)
"""
FlexVector(dom) = FlexVector{Float64}(dom)
FlexVector() = FlexVector(Int[])

"""
`FlexOnes(T,dom)` creates an all 1s vector indexed by `dom`.
If `T` is missing, values default to `Float64`.
"""
function FlexOnes(T::Type,dom)
    v = FlexVector{T}(dom)
    for x in dom
        v[x] = one(T)
    end
    return v
end

FlexOnes(dom) = FlexOnes(Float64,dom)

"""
`FlexConvert(vec)` converts the vector `vec` into a
`FlexVector`.
"""
function FlexConvert(v::Vector{T}) where T
    n = length(v)
    w = FlexVector{T}(1:n)
    for k=1:n
        w[k] = v[k]
    end
    return w
end

function Vector(v::FlexVector)
    klist = collect(keys(v))
    try
        sort!(klist)
    catch
    end
    n = length(klist)
    result = Array{valtype(v),1}(undef,n)
    for k=1:n
        result[k] = v[klist[k]]
    end
    return result
end



keys(v::FlexVector) = keys(v.data)
values(v::FlexVector) = values(v.data)

keytype(v::FlexVector) = keytype(v.data)
valtype(v::FlexVector) = valtype(v.data)

length(v::FlexVector) = length(v.data)
haskey(v::FlexVector, k) = haskey(v.data,k)

setindex!(v::FlexVector, x, i) = setindex!(v.data,x,i)

function getindex(v::FlexVector{S,T}, i)::T where {S,T}
    if haskey(v.data,i)
        return getindex(v.data,i)
    end
    return zero(T)
end

function show(io::IO,v::FlexVector{S,T}) where {S,T}
    klist = collect(keys(v))
    try
        sort!(klist)
    catch
    end
    println(io, "FlexVector{$S,$T}:")
    for k in klist
        println(io,"  $k => $(v.data[k])")
    end
    nothing
end

hash(v::FlexVector, h) = hash(v.data)
(==)(v::FlexVector, w::FlexVector) = v.data == w.data


##### Arithmetic #####

# The _mush helper function mushes two vectors together.
function _mush(v::FlexVector,w::FlexVector)::FlexVector
    A = Set(keys(v))
    B = Set(keys(w))
    AB = union(A,B)
    Tv = valtype(v)
    Tw = valtype(w)
    Tx = typeof(one(Tv) + one(Tw))

    result = FlexVector{Tx}(AB)
    return result
end

function (+)(v::FlexVector, w::FlexVector)::FlexVector
    result = _mush(v,w)

    for k in keys(result)
        result[k] = v[k]+w[k]
    end

    return result
end

function (-)(v::FlexVector, w::FlexVector)::FlexVector
    result = _mush(v,w)

    for k in keys(result)
        result[k] = v[k]-w[k]
    end

    return result
end

# This is a quick-and-dirty implementation. Can probably do something
# more efficient but nothing here is efficient :-)
function LinearAlgebra.dot(v::FlexVector,w::FlexVector)
    vw = _mush(v,w)
    for k in keys(vw)
        vw[k] = v[k]' * w[k]
    end
    return sum(values(vw))
end

function (*)(s::Number, v::FlexVector)::FlexVector
    if length(v) == 0
        return v
    end
    klist = collect(keys(v))
    x = s*v[klist[1]]

    sv = FlexVector{typeof(x)}(klist)  # place to hold the answer
    for k in klist
        sv[k] = s*v[k]
    end
    return sv
end

(-)(v::FlexVector) = -1 * v    # unary minus

sum(v::FlexVector) = sum(values(v))

"""
`delete_entry!(v,x)` deletes the entry indexed by `x` in the `FlexVector`
`x`.
"""
function delete_entry!(v::FlexVector, x)
    if haskey(v.data, x)
        delete!(v.data,x)
    end
    return v
end

function LinearAlgebra.adjoint(v::FlexVector)
    S = valtype(v)
    vv = FlexMatrix{S}(1,keys(v))
    for k in keys(v)
        vv[1,k] = v[k]'
    end
    return vv
end
