module MetaArrays
export meta, MetaArray, getmeta, MetaUnion, getcontents

using Requires

function __init__()

  @require AxisArrays="39de3d68-74b9-583c-8d2d-e117c070f3a9" begin
    using .AxisArrays
    AxisArrays.AxisArray(x::MetaArray{<:AxisArray}) = getcontents(x)
    AxisArrays.axisdim(x::MetaArray{<:AxisArray},ax) =
      axisdim(getcontents(x),ax)
    AxisArrays.axes(x::MetaArray{<:AxisArray},i::Int...) =
      AxisArrays.axes(getcontents(x),i...)
    AxisArrays.axes(x::MetaArray{<:AxisArray},T::Type{<:Axis}...) =
      AxisArrays.axes(getcontents(x),T...)
    AxisArrays.axes(x::MetaArray{<:AxisArray}) = AxisArrays.axes(getcontents(x))
    AxisArrays.axisnames(x::MetaArray{<:AxisArray}) = axisnames(getcontents(x))
    AxisArrays.axisvalues(x::MetaArray{<:AxisArray}) = axisvalues(getcontents(x))

    Base.similar(x::MetaArray{<:AxisArray}) =
      MetaArray(getmeta(x),similar(getcontents(x)))
    Base.similar(x::MetaArray{<:AxisArray},ax1::Axis,axs::Axis...) =
      similar(x,eltype(x),ax1,axs...)
    function Base.similar(x::MetaArray{<:AxisArray},::Type{S},
                          ax1::Axis,axs::Axis...) where S
      MetaArray(getmeta(x),similar(getcontents(x),S,ax1,axs...))
    end
  end
end

struct MetaArray{A,M,T,N} <: AbstractArray{T,N}
  meta::M
  data::A
end
Base.convert(::Type{A},x::MetaArray) where A<:Array = convert(A,getcontents(x))
Base.convert(::Type{AbstractArray{T,N}},x::MetaArray{T,N}) where {T,N} = x
Base.convert(::Type{AbstractArray{T}},x::MetaArray{T}) where T = x
Base.unsafe_convert(::Type{Ptr{T}},x::MetaArray{<:Any,<:Any,T}) where T =
  Base.unsafe_convert(Ptr{T},getcontents(x))
Base.Array(x::MetaArray) = Array(getcontents(x))

function Base.zero(x::MetaArray)
  y = similar(x)
  y .= zero(eltype(x))
end
function Base.one(x::MetaArray)
  y = similar(x)
  y .= one(eltype(x))
end

"""
    MetaArray{A}(array,meta::A)

Create a meta array with custom metadata type `A`.

Normally it's recommended that you use `meta`; only use a custom meta-data
type if you plan to have a method specialize on the second type argument of
the MetaArray.
"""
function MetaArray(meta::M,data::A) where {M,T,N,A<:AbstractArray{T,N}}
  MetaArray{A,M,T,N}(meta,data)
end
function MetaArray(meta::M,data::MetaArray) where M
  MetaArray(combine(meta,getmeta(data)),getcontents(data))
end

"""
    meta(array;kwds...)

Wrap the array as a `MetaArray`, storing the given keyword values.
"""
meta(data::AbstractArray;meta...) = MetaArray(meta.data,data)

Base.getproperty(x::MetaArray,name::Symbol) = getproperty(getmeta(x),name)

"""
    getcontents(x::MetaArray)

Return the wrapped array stored in the `MetaArray`
"""
getcontents(x::MetaArray) = Base.getfield(x,:data)

"""
    getmeta(x::MetaArray)

Return the metadata stored in `MetaArray`
"""
getmeta(x::MetaArray) = Base.getfield(x,:meta)
function meta(data::MetaArray;meta...)
  MetaArray(merge(getmeta(data),meta.data),getcontents(data))
end

"""
    MetaUnion{T} = Union{MetaArray{<:T},T}

Type alias for defining a method that operates on both `T` and
a meta array of `T`.
"""
const MetaUnion{T} = Union{MetaArray{<:T},T}

function Base.show(io::IO,::MIME"text/plain",x::MetaArray) where M
  print(io,"MetaArray of ")
  show(io, "text/plain", getcontents(x))
end

struct UnknownMerge{A,B} end
metamerge(x::NamedTuple,y::NamedTuple) = merge(x,y)
metamerge(x::AbstractDict,y::AbstractDict) = merge(x,y)
function metamerge(x::A,y::B) where {A,B}
  x == y ? y : UnknownMerge{A,B}()
end

function checkmerge(::Nothing,v::UnknownMerge{A,B}) where {A,B}
  error("Metadata to combine is non-identical ",
        "and there is no known way to merge an object of type $A with an",
        " object of type $B. You can fix this by defining ",
        "`MetaArrays.metamerge` for these types.")
end
function checkmerge(k,v::UnknownMerge{A,B}) where {A,B}
  error("The field `$k` has non-identical values across metadata ",
        "and there is no known way to merge non-identical objects of type $A with an",
        " object of type $B. You can fix this by defining ",
        "`MetaArrays.metamerge` for these types.")
end
checkmerge(k,v) = nothing

# TOOD: file an issue with julia about mis-behavior of `merge`.
function combine(x,y)
  result = metamerge(x,y)
  checkmerge(nothing,result)
  result
end
function combine(x::NamedTuple,y::NamedTuple)
  result = combine_(x,iterate(pairs(x)),y)
  for (k,v) in pairs(result); checkmerge(k,v); end

  result
end
combine_(x,::Nothing,result) = result
function combine_(x,((key,val),state),result)
  newval = haskey(result,key) ? metamerge(val,result[key]) : val
  entry = NamedTuple{(key,)}((newval,))
  combine_(x,iterate(x,state),merge(result,entry))
end

struct NoMetaData end
combine(x,::NoMetaData) = x
combine(::NoMetaData,x) = x
combine(::NoMetaData,::NoMetaData) = NoMetaData()
MetaArray(meta::NoMetaData,data::AbstractArray) = error("Unexpected missing meta data")

# match array behavior of wrapped array (maintaining the metdata)
Base.size(x::MetaArray) = size(getcontents(x))
Base.axes(x::MetaArray) = Base.axes(getcontents(x))
Base.IndexStyle(x::MetaArray) = IndexStyle(getcontents(x))

# resolves some ambiguities in Base; borrowed from AxisArray (this may break at
# some future date)
using Base: ViewIndex, @propagate_inbounds, AbstractCartesianIndex
@propagate_inbounds Base.view(A::MetaArray, idxs::ViewIndex...) = MetaArray(getmeta(A),view(getcontents(A), idxs...))
@propagate_inbounds Base.view(A::MetaArray, idxs::Union{ViewIndex,AbstractCartesianIndex}...) = MetaArray(getmeta(A),view(getcontents(A), idxs...))
@propagate_inbounds Base.view(A::MetaArray, idxs...) = MetaArray(getmeta(A),view(getcontents(A), idxs...))

@propagate_inbounds Base.getindex(x::MetaArray,i::Int...) =
getindex(getcontents(x),i...)
@propagate_inbounds Base.getindex(x::MetaArray,i...) =
metawrap(x,getindex(getcontents(x),i...))
@propagate_inbounds Base.setindex!(x::MetaArray{<:Any,<:Any,T},v,i...) where T =
  setindex!(getcontents(x),v,i...)
@propagate_inbounds function Base.setindex!(x::MetaArray{<:Any,<:Any,T}, v::T,i::Int...) where T
  setindex!(getcontents(x),v,i...)
end
function Base.similar(x::MetaArray,::Type{S},dims::NTuple{<:Any,Int}) where S
  MetaArray(getmeta(x),similar(getcontents(x),S,dims))
end

# metawrap ensures that returned subarrays are properly wrapped in a meta
# array, *without* wrapping individual elements, in the event that some custom,
# non-integer index returns a single value
metawrap(x::MetaArray{<:Any,<:Any,T},val::T) where T = val
metawrap(x::MetaArray,val::AbstractArray) = MetaArray(getmeta(x),val)
metawrap(x::MetaArray,val) = error("Unexpected result type $(typeof(val)).")

# maintain stridedness of wrapped array, if present
Base.strides(x::MetaArray) = strides(getcontents(x))
Base.stride(x::MetaArray,i::Int) = stride(getcontents(x),i)

# the meta array broadcast style should retain the nested style information for
# whatever array type the meta array wraps
struct MetaArrayStyle{S} <: Broadcast.BroadcastStyle end
MetaArrayStyle(s::S) where S <: Broadcast.BroadcastStyle = MetaArrayStyle{S}()
Base.Broadcast.BroadcastStyle(::Type{<:MetaArray{A}}) where A =
  metastyle(Broadcast.BroadcastStyle(A))
Base.Broadcast.BroadcastStyle(a::MetaArrayStyle{A},b::MetaArrayStyle{B}) where {A,B} =
  metastyle(Broadcast.BroadcastStyle(A(),B()))
function Base.Broadcast.BroadcastStyle(a::MetaArrayStyle{A},b::B) where
  {A,B<:Broadcast.BroadcastStyle}

  a_ = A()
  left = metastyle(Broadcast.BroadcastStyle(a_,b))
  if !(left isa Broadcast.Unknown)
    left
  else
    metastyle(Broadcast.BroadcastStyle(b,a_))
  end
end
metastyle(x) = MetaArrayStyle(x)
metastyle(x::Broadcast.Unknown) = x

################################################################################
# custom broadcast overloading
#
# the wrapped arrays may define custom machinery for broadcasting: therefore, we
# must override each method that can be used to customize broadcasting
#
function meta_broadcasted(metas, bc::Broadcast.Broadcasted{S}) where S
  args = meta_.(metas,bc.args)
  Broadcast.Broadcasted{MetaArrayStyle{S}}(bc.f, args, bc.axes)
end
meta_broadcasted(metas, result) = MetaArray(reduce(combine,metas), result)

meta_(::NoMetaData,x) = x
meta_(meta,x) = MetaArray(meta,x)
getcontents_(x) = x
getcontents_(x::MetaArray) = getcontents(x)
getmeta_(x) = NoMetaData()
getmeta_(x::MetaArray) = getmeta(x)

# broadcasted:
function Base.Broadcast.broadcasted(::MetaArrayStyle{S}, f, xs...) where S
  bc = Broadcast.broadcasted(S(),f,getcontents_.(xs)...)
  meta_broadcasted(getmeta_.(xs), bc)
end

# instantiate:
# after instantiation, the broadcasted object is flattened and the
# argument contains all meteadata
function Base.Broadcast.instantiate(bc::Broadcast.Broadcasted{M}) where
  {S,M <: MetaArrayStyle{S}}

  # simplify
  bc_ = Broadcast.flatten(bc)
  # instantiate the nested broadcast (that the meta array wraps)
  bc_nested = Broadcast.Broadcasted{S}(bc_.f, getcontents_.(bc_.args))
  inst = Broadcast.instantiate(bc_nested)
  # extract and combine the meta data
  meta = reduce(combine,getmeta_.(bc_.args))
  # place the meta data on the first argument
  args = ((meta,inst.args[1]), Base.tail(inst.args)...)
  # return the instantiated metadata broadcasting
  Broadcast.Broadcasted{M}(bc_.f, args, bc_.axes)
end

# similar: becuase we bypass the default broadcast machinery no call to similar
# is made directly: similar will be called within the nested call to `copy`
# after the metadata has been stripped and the wrapped array is exposed

# copyto!:
function Base.copyto!(dest::AbstractArray,
                      bc::Broadcast.Broadcasted{<:MetaArrayStyle{S}}) where S
  args_ = (bc.args[1][2], Base.tail(bc.args)...)
  bc_ = Broadcast.Broadcasted{S}(bc.f, args_, bc.axes)
  copyto!(dest,bc_)
end

function Base.copyto!(dest::MetaArray, bc::Broadcast.Broadcasted{Nothing})
  copyto!(getcontents(dest),bc)
end

# copy:
function Base.copy(bc::Broadcast.Broadcasted{<:MetaArrayStyle{S}}) where S
  # because the axes have been instantiated, we can safely assume the first
  # argument contains the meta data
  args_ = (bc.args[1][2], Base.tail(bc.args)...)
  bc_ = Broadcast.Broadcasted{S}(bc.f, args_, bc.axes)
  MetaArray(bc.args[1][1], copy(bc_))
end

end # module
