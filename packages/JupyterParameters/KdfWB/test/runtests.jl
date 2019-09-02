#=
    runtest
    Copyright © 2019 Mark Wells <mwellsa@gmail.com>

    Distributed under terms of the AGPL-3.0 license.
=#

using Test
using JSON
using DataStructures
using IJulia

using JupyterParameters

function get_outputs( jsondict :: OrderedDict
                    , cell     :: Integer
                    )
    return jsondict["cells"][cell]["outputs"][1]["data"]["text/plain"][1]
end

function get_kernel()
    return JupyterParameters.get_kernels()[1]
end

"""
this is to test without having to rely on the kernel in testfile.ipynb matching kernels on
local
"""
function change_kernel(jsondict :: OrderedDict) 
    jsondict["metadata"]["kernelspec"]["name"] = get_kernel()
    return jsondict
end

origfile = tempname()*".ipynb"
cp((@__DIR__)*"/testfile.ipynb", origfile, force=true)
outfile = tempname()*".ipynb"

try
    @testset "testing JupyterParam" begin
        origdict = change_kernel(JSON.parsefile(origfile, dicttype=OrderedDict))
        open(origfile, "w") do outf
            JSON.print(outf, origdict, 1)
        end
    
        deleteat!(ARGS,eachindex(ARGS))
    
        i = JupyterParameters.find_parameters_cell(origdict)
        origcell = JupyterParameters.view_source(origdict,i)
        origcell1 = origcell[1]
        origcell2 = origcell[2]
        origcell3 = origcell[3]
        x = "y"
        y = "7"
        xy = "2"
    
        push!(ARGS, origfile, outfile)
        push!(ARGS,"--x",x)
        push!(ARGS,"--y",y)
        push!(ARGS,"--xy",xy)
        jjnbparam()
        
        outdict = JSON.parsefile(outfile, dicttype=OrderedDict)
        
        origcell = JupyterParameters.view_source(origdict,1)
        outcell  = JupyterParameters.view_source(outdict,1)
    
        @test outcell[1] == string("x = \"$x\"\n")
        @test outcell[2] == string("y = $y\n")
        @test outcell[3] == string("xy = $xy")
    
        outcell  = get_outputs(outdict,2)
        @test outcell == "9"
    
        outcell  = get_outputs(outdict,3)
        @test outcell == "\"y\""
    

        @test origcell1 == JupyterParameters.view_source(origdict,i)[1]
        @test origcell2 == JupyterParameters.view_source(origdict,i)[2]
        @test origcell3 == JupyterParameters.view_source(origdict,i)[3]
    end
    
    @testset "jupyter nb extensions" begin
        x = "y"
    
        deleteat!(ARGS,eachindex(ARGS))
        push!(ARGS, origfile, outfile)
        push!(ARGS,"--x",x)
        kernel = get_kernel()
        push!(ARGS,"--kernel_name",kernel)
        push!(ARGS,"--timeout","-1")
        jjnbparam()
    
        outdict = JSON.parsefile(outfile, dicttype=OrderedDict)
        outcell = JupyterParameters.view_source(outdict,1)
        @test outcell[1] == string("x = \"$x\"\n")
    end
    
    @testset "error testing" begin
        x = "y"
    
        deleteat!(ARGS,eachindex(ARGS))
        push!(ARGS, origfile, outfile)
        push!(ARGS,"--x",x)
        push!(ARGS,"--kernel_name","ajnkfnq234iqnwerht")
        @test_throws ErrorException jjnbparam()
    end
finally
    for file in [origfile, outfile]
        try
            rm(file, force=true)
        catch Exception
            println("Couldn't remove ", file)
        end
    end
end
