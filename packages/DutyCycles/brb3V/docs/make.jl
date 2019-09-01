import Pkg;
# use a separate Project for building docs; see
# https://discourse.julialang.org/t/psa-use-a-project-for-building-your-docs/14974
Pkg.activate("docs")
Pkg.instantiate()

# to find parent project
if !("." in LOAD_PATH)
    push!(LOAD_PATH, ".")
end

# to find parent project when building docs in docs/build/
if !("../.." in LOAD_PATH)
    push!(LOAD_PATH, "../..")
end

using Documenter, DocStringExtensions, DutyCycles

push!(LOAD_PATH, joinpath(dirname(pathof(DutyCycles))))

makedocs(
    sitename="quantum-factory.de",
    format = Documenter.HTML(prettyurls = false),
    modules = [DutyCycles],
    strict = true
)

# re-activate parent Project
Pkg.activate(".")
