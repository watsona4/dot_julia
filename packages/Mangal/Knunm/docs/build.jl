push!(LOAD_PATH,"../src/")

using Pkg
Pkg.activate(".")

_required = ["Weave", "Plots"]

Pkg.add.(_required)

using Mangal
using Weave

_path_elements = ["docs", "src", "vignettes"]
_jmd_files = filter(x -> endswith(x, ".Jmd"), readdir(joinpath(_path_elements...)))
_files_to_compile = [joinpath(_path_elements..., f) for f in _jmd_files]

for _file in _files_to_compile
    weave(_file, doctype="github")
end

Pkg.rm.(_required)
