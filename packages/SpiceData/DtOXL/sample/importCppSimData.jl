#Import CppSimData or explain how to install.

try
eval(:(import CppSimData))
catch e
msg = "This sample requires data installed in the CppSimData module."
msg *= "\nTo continue demo, install with the following:\n\n"
msg *= "    Pkg.clone(\"git://github.com/ma-laforge/CppSimData.jl\")"
@info(msg)
println();println()
rethrow(e)
end


#Last line
