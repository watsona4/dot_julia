println("Building LiterateOrg.jl")

# Bootstrap package by extracting all package code to a Julia file and
# include it.

src_file = joinpath(dirname(@__FILE__), "..", "src", "LiterateOrg.org")

deps_dir = joinpath(dirname(@__FILE__), "..", "deps")
bootstrap_file = joinpath(deps_dir, "bootstrap.jl")

start_code_pat = r"[ ]*#\+begin_src[ ]+julia(.*)"
end_code_pat = r"[ ]*#\+end_src"

println("Bootstrapping LiterateOrg.jl to $(bootstrap_file)")

code_mode = false

open(src_file) do infile
    open(bootstrap_file, "w") do outfile
        for line in readlines(infile)
            global code_mode
            if occursin(start_code_pat, lowercase(line))
                code_mode = true
                continue
            elseif occursin(end_code_pat, lowercase(line))
                code_mode = false
                continue
            end
            code_mode && write(outfile, "$(line)\n")
        end
    end
end

println("Running bootstrap file")

# This is necessary for included test expressions to work.
if VERSION.major > 0 || VERSION.minor > 6
    using Test
else
    using Base.Test
end
include(bootstrap_file)
rm(bootstrap_file)

println("Tangling LiterateOrg.jl")

tangle_package(src_file, "LiterateOrg")
