__precompile__()

module AndersonMoore
# http://www.stochasticlifestyle.com/finalizing-julia-package-documentation-testing-coverage-publishing/

using Compat
using Compat.LinearAlgebra

# Set-up for callSparseAim
const lib = Compat.Libdl.dlopen(normpath(joinpath(dirname(@__FILE__), "..", "deps", "libAndersonMoore")))
const sym = Compat.Libdl.dlsym(lib, :callSparseAim)
  

# Include all files    
for (root, _, files) in walkdir(dirname(@__FILE__))
    for file in files
    	if file != "AndersonMoore.jl"  # else would cause endless loop
           include(joinpath(root, file))
	end # if
    end # inner for
end # outer for

# Export all functions
export exactShift!, numericShift!, shiftRight!, buildA!, augmentQ!, eigenSys!, reducedForm,
AndersonMooreAlg, sameSpan, deleteCols, deleteRows, callSparseAim, checkAM, err, gensysToAMA

end # module
