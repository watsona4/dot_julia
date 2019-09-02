# module TestIPython

if lowercase(get(ENV, "CI", "false")) == "true"
    let
        if VERSION < v"0.7.0-"
            setup_code = ""
        else
            setup_code = Base.load_path_setup_code()
        end
        path = joinpath(@__DIR__, "install_dependencies.jl")
        code = """
        $setup_code
        include("$(escape_string(path))")
        """
        run(`$(Base.julia_cmd()) -e $code`)
        # Run install_dependencies.jl in a separate process since it
        # may re-build PyCall.  In that case, we need to load
        # re-precompiled PyCall and IPython.
    end
end

include("preamble.jl")

IPython.envinfo()

ipy_opts = @time IPython._start_ipython(:ipython_options)
ipy_main = ipy_opts["user_ns"]["Main"]

@testset "Main" begin
    _setproperty!(ipy_main, :x, 17061)
    @test x == 17061
end

include("test_julia_repl.jl")
include("test_convenience.jl")

IPython.test_ipython_jl(inprocess=true)

# end  # module
