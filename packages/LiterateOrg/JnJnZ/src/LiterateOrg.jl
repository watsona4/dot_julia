__precompile__()

module LiterateOrg

const codefile = joinpath(dirname(@__FILE__), "literate_org_tangled_code.jl")
if isfile(codefile)
    include(codefile)
else
    error("LiterateOrg not properly installed. Please run Pkg.build(\"LiterateOrg\") then restart Julia.")
end

end # module
