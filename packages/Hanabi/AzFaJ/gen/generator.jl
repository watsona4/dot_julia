using Clang

const HANABI_H = joinpath(@__DIR__, "..", "deps", "usr", "include", "pyhanabi.h") |> normpath

wc = init(; headers = [HANABI_H],
            output_file = joinpath(@__DIR__, "libhanabi_api.jl"),
            common_file = joinpath(@__DIR__, "libhanabi_common.jl"),
	    clang_includes = [CLANG_INCLUDE],
            header_wrapped = (root, current) -> root == current,
	    header_library = x->"libpyhanabi",
            clang_diagnostics = true)

run(wc)
