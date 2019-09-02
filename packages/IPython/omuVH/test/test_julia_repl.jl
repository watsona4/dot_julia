module TestJuliaREPL

include("preamble.jl")
using IPython: init_repl, afterreplinit, REPL

@static if VERSION >= v"0.7.0-"
    using REPL: TextTerminal
else
    using Base.Terminals: TextTerminal
end


@testset "afterreplinit" begin
    repl = afterreplinit(identity)
    if isinteractive()
        @test repl === Base.active_repl
    else
        @test repl === nothing
    end
end


struct DummyTerminal <: TextTerminal
end

function dummy_repl()
    if VERSION >= v"0.7.0-"
        hascolor = false
        repl = REPL.LineEditREPL(DummyTerminal(), hascolor)
    else
        repl = REPL.LineEditREPL(DummyTerminal())
    end
    repl.interface = REPL.setup_interface(repl)
    return repl
end

function dummy_initialized_repl()
    repl = dummy_repl()
    init_repl(repl)
    return repl
end

@testset "init_repl" begin
    repl = dummy_initialized_repl()
    keymap_dict = repl.interface.modes[1].keymap_dict
    @test haskey(keymap_dict, '.')
end

end  # module
