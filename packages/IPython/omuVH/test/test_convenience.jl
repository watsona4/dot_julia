module TestConvenience

include("preamble.jl")

@testset "Convenience" begin
    @test_nothrow IPython.envinfo(devnull)
    @test IPython.pyversion("IPython") isa String
    if occursin(".dev", IPython._pyversion("IPython"))
        @test startswith(IPython.pyversion("IPython"),
                         IPython._pyversion("IPython"))
    else
        @test IPython.pyversion("IPython") == IPython._pyversion("IPython")
    end
    @test IPython.pyversion("__NON_EXISTING__") isa Nothing

    println("vvv DRY RUN vvv")
    @test_nothrow IPython.install_dependency("ipython"; dry_run=true)
    @test_nothrow IPython.install_dependency("spam"; dry_run=true)
    println("^^^ DRY RUN ^^^")

    @test IPython.yes_or_no(input=IOBuffer("yes\n"), output=devnull)
    @test IPython.yes_or_no(input=IOBuffer("no\n"), output=devnull) == false
    @test IPython.yes_or_no(input=IOBuffer("spam\n"), output=devnull) == false

    @test IPython.condajl_installation("IPython") isa Tuple
    @test IPython.conda_installation("IPython") isa Tuple
    @test IPython.pip_installation("IPython") isa Tuple
end

end  # module
