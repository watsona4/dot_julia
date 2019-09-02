__precompile__()
module HilbertSpaceFillingCurve

    export hilbert

    const depsfile = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
    if isfile(depsfile)
        include(depsfile)
    else
        error("HilbertSpaceFillingCurve not properly installed. Please run Pkg.build(\"HilbertSpaceFillingCurve\") then restart Julia.")
    end

    const bitmask_t = Culonglong
    global const bits_per_byte = 8

    function hilbert(d::T, ndims, nbits = 32) where T <: Integer
        @assert ndims*nbits <= sizeof(bitmask_t) * bits_per_byte

        p = bitmask_t.(zeros(ndims))
        ccall((:hilbert_i2c, libhilbert), Nothing, (Int,Int,bitmask_t,Ptr{bitmask_t}),ndims,nbits,d,p) 
        Int.(p)
    end

    function hilbert(p::Vector{T}, ndims, nbits = 32) where T <: Integer
        @assert ndims*nbits <= sizeof(bitmask_t) * bits_per_byte
        @assert length(p) == ndims

        Int(ccall((:hilbert_c2i, libhilbert), bitmask_t, (Int,Int,Ptr{bitmask_t}),ndims,nbits, bitmask_t.(p)))
    end

end # module
