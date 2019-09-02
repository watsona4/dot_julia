#Import LibPSFC or explain how to install.

try
eval(:(import LibPSFC))
catch e
msg = "This sample requires data installed in the LibPSFC module."
msg *= "\nTo continue demo, install with the following:\n\n"
msg *= "    Pkg.clone(\"git://github.com/ma-laforge/LibPSFC.jl\")"
@info(msg)
println();println()
rethrow(e)
end


#Last line
