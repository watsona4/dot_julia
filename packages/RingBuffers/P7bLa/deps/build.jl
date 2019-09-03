using BinaryProvider
using Compat

const verbose = "--verbose" in ARGS
const prefix = Prefix(joinpath(@__DIR__, "usr"))

# BinaryProvider v0.3.2 has libdir(prefix) bug on windows
@static if Compat.Sys.iswindows()
    file_path = joinpath(prefix.path, "lib", string("pa_ringbuffer_", Sys.ARCH, "-w64-mingw32.dll"))
    product = FileProduct(file_path, :libpa_ringbuffer)
else
    product = LibraryProduct(prefix, "pa_ringbuffer", :libpa_ringbuffer)
end
satisfied(product; verbose=verbose) && write_deps_file(joinpath(@__DIR__, "deps.jl"), [product])
