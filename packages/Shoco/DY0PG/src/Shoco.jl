module Shoco

let depsfile = joinpath(@__DIR__, "..", "deps", "deps.jl")
    if !isfile(depsfile)
        error("Shoco is not properly installed. Please run Pkg.build(\"Shoco\")",
              " and restart Julia.")
    end
    include(depsfile)
end

__init__() = check_deps()

export compress, decompress

function compress(s::AbstractString)
    isempty(s) && return ""
    # The output should be no longer than the input
    compressed = Vector{UInt8}(undef, sizeof(s))
    # The function modifies `compressed` and returns the number of bytes written
    nbytes = ccall((:shoco_compress, libshoco), Int,
                   (Ptr{Cchar}, Csize_t, Ptr{UInt8}, Csize_t),
                   s, 0, compressed, sizeof(s))
    nbytes > 0 || error("Compression failed for input $s")
    resize!(compressed, nbytes)
    return String(compressed)
end

function decompress(s::AbstractString)
    isempty(s) && return ""
    # The decompressed string will be at most twice as long as the input
    decompressed = Vector{UInt8}(undef, 2 * sizeof(s))
    nbytes = ccall((:shoco_decompress, libshoco), Int,
                   (Ptr{Cchar}, Csize_t, Ptr{UInt8}, Csize_t),
                   s, sizeof(s), decompressed, 2 * sizeof(s))
    nbytes > 0 || error("Decompression failed for input $s")
    resize!(decompressed, nbytes)
    return String(decompressed)
end

end # module
