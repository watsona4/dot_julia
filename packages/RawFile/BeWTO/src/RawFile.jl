module RawFile

export saveraw,readraw,rawsize,appendraw
export RawFile,RawFileIter,start,done,next

token = "RAWF"
version = 2
endtoken = "FIN"

mutable struct RawHeader
    version::UInt8
    eltype::Type
    sizes::Vector{Int64}
end

import Base.write

function write(f::IO,x::RawHeader)
    write(f,token)
    write(f,x.version)
    typename = string(x.eltype)
    write(f,UInt8(length(typename)))
    write(f,typename)
    write(f,UInt8(length(x.sizes)))
    write(f,x.sizes)
    return nothing
end

function readheader(f::IO)
    tok = String(read(f,length(token)))
    tok != token && error("Invalid token in RawFile")
    ver = read(f,UInt8)
    ver != version && warn("Incorrect RawFile version ($ver, current version $version)")
    lentypename = read(f,UInt8)
    typename = String(read(f,lentypename))
    eltype = eval(Meta.parse(typename))
    nd = read(f,UInt8)
    sizes = read!(f,Array{Int64}(undef,nd))
    RawHeader(ver,eltype,sizes)
end

"""
    saveraw{T<:Number,V}(a::AbstractArray{T,V},fname::String)

Save `a` to the file `fname`.
"""
function saveraw(a::AbstractArray{T,V},fname::String) where {T<:Number,V}
    header = RawHeader(version,eltype(a),collect(size(a)))
    open(fname,"w") do f
        write(f,header)
        write(f,a)
        write(f,endtoken)
    end
    return nothing
end

"""
    appendraw{T<:Number,V}(a::AbstractArray{T,V},fname::String)

Append the `AbstractArray` `a` to the file `fname`, along last dimension. Requires `a` to be the same
`Type` and shape (excluding last dimension)
"""
function appendraw(a::AbstractArray{T,V},fname::String) where {T<:Number,V}
    open(fname,"r+") do f
        h = readheader(f)
        h.eltype != eltype(a) && error("Trying to append RawFile with different data Type")
        Tuple(h.sizes[1:end-1]) != size(a)[1:end-1] && error("Trying to append RawFile with Array of different shape")
        h.sizes[end] += size(a)[end]
        seekstart(f)
        write(f,h)
        seekend(f)
        seek(f,position(f)-length(endtoken))
        write(f,a)
        write(f,endtoken)
    end
    return nothing
end

appendraw(a::T,fname::String) where {T<:Number} = appendraw([a],fname)


"""
    readraw(fname::String)

Read the file `fname` and return a reconstructed `Array` with the proper `Type` and size.
"""
function readraw(fname::String)
    open(fname) do f
        h = readheader(f)
        d = read!(f,Array{h.eltype}(undef,Tuple(h.sizes)))
        endtok = String(read(f,length(endtoken)))
        endtok != endtoken && error("Invalid end of RawFile")
        return d
    end
end

"""
    rawsize(fname::String)

Read size from file `fname`, returns `Tuple`
"""
function rawsize(fname::String)
    open(fname) do f
        h = readheader(f)
        return Tuple(h.sizes)
    end
end

mutable struct PartialRaw
    f::IO
    eltype::Type
    sizes::Array{Int64,1}
    total::Int
end

"""
    saveraw(func::Function,fname::String)

Save `Array`s progressively produced in `func`. Each partial `Array` needs to have
the same dimensions (excluding the last dimension), and are concatenated along the
last dimension.

# Examples
```julia-repl
julia> saveraw("test.raw") do f
           for i=1:10
               write(f,rand(100,10,5))
           end
       end

julia> rawsize("test.raw")
(100, 10, 50)
```
"""
function saveraw(func::Function,fname::String)
    open(fname,"w") do f
        p = PartialRaw(f,Int,[],0)
        func(p)
        write(f,endtoken)
        seekstart(f)
        p.sizes[end] = p.total
        write(f,RawHeader(version,p.eltype,p.sizes))
    end
    return nothing
end

function write(p::PartialRaw,d::AbstractArray{T,V}) where {T<:Number,V}
    if length(p.sizes)==0
        # This is the first Array we've seen
        p.sizes = collect(size(d))
        p.eltype = eltype(d)
        write(p.f,RawHeader(version,p.eltype,p.sizes))
    else
        Tuple(p.sizes[1:end-1]) != size(d)[1:end-1]  && error("Cannot write partial RawFile, all dimensions other than the last must be the same")
        p.eltype != eltype(d) && error("Cannot write partial RawFile, all data must be the same type")
    end
    write(p.f,d)
    p.total += size(d)[end]
    return nothing
end

"""
    RawFileIter(fname::String,num_batch::Int)

Creates an interator that will iterate through the file `fname`, returning `Array`s
with the last dimension `num_batch` (or less if EOF is reached).

# Examples
```julia-repl
julia> for d in RawFileIter("test.raw",20)
           info(size(d))
       end
INFO: (100, 10, 20)
INFO: (100, 10, 20)
INFO: (100, 10, 10)
```
"""
mutable struct RawFileIter
    fname::String
    num_batch::Int
end

mutable struct RawFileState
    i::Int
    total_length::Int
    num_batch::Int
    batch_step::Int
    batch_size::Array{Int,1}
    f::IO
    eltype::Type
end

import Base.iterate,Base.length

function finalize(s::RawFileState)
    close(s.f)
end

function iterate(r::RawFileIter)
    f = open(r.fname)
    h = readheader(f)
    batch_step = reduce(*,h.sizes[1:end-1])
    total_length = batch_step*h.sizes[end]
    batch_size = copy(h.sizes)
    i = 0
    s = RawFileState(i,total_length,r.num_batch,batch_step,batch_size,f,h.eltype)
    finalizer(finalize,s)

    return iterate(r,s)
end

function iterate(r::RawFileIter,state::RawFileState)
    if state.i < state.total_length
        this_len = Int(min(state.num_batch,(state.total_length-state.i)/state.batch_step))
        state.batch_size[end] = this_len
        d = read!(state.f,Array{state.eltype}(undef,Tuple(state.batch_size)))
        state.i += state.batch_step*this_len
        return (d,state)
    else
        endtok = String(read(state.f,length(endtoken)))
        endtok != endtoken && error("Invalid end of RawFile")
        return nothing
    end
end

function readraw(func::Function,fname::String,batch::Int)
    for d in RawFileIter(fname,batch)
        func(d)
    end
end

end
