using Clang

# LIBCLANG_HEADERS are those headers to be wrapped.
const LIBCLANG_INCLUDE = "/Users/$USER/local/helics-v2.0.0/include/helics/shared_api_library" |> normpath
const LIBCLANG_HEADERS = [joinpath(LIBCLANG_INCLUDE, header) for header in readdir(LIBCLANG_INCLUDE) if endswith(header, ".h")]

wc = init(; headers = LIBCLANG_HEADERS,
            output_file = joinpath(@__DIR__, "../src/lib.jl"),
            common_file = joinpath(@__DIR__, "../src/common.jl"),
            clang_includes = vcat(LIBCLANG_INCLUDE, CLANG_INCLUDE),
            clang_args = ["-I", joinpath(LIBCLANG_INCLUDE, "..")],
            header_wrapped = (root, current)->root == current,
            header_library = x->"libhelicsSharedLib",
            clang_diagnostics = true,
            )

run(wc)
