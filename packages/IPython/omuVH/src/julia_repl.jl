@static if VERSION >= v"0.7.0-"
    using REPL
    using REPL: LineEdit
else
    using Base: REPL, LineEdit
end

"""
    afterreplinit(f)

Like `atreplinit` but triggers `f` even after REPL is initialized when
it is called.
"""
function afterreplinit(f)
    # See: https://github.com/JuliaLang/Pkg.jl/blob/v1.0.2/src/Pkg.jl#L338
    function wrapper(repl)
        if isinteractive() && repl isa REPL.LineEditREPL
            f(repl)
        end
    end
    if isdefined(Base, :active_repl)
        wrapper(Base.active_repl)
    else
        atreplinit() do repl
            @async begin
                wait_repl_interface(repl)
                wrapper(repl)
            end
        end
    end
end

function wait_repl_interface(repl)
    for _ in 1:20
        try
            repl.interface.modes[1].keymap_dict
            return
        catch
        end
        sleep(0.05)
    end
end

# Register keybind '.' in Julia REPL:

function on_dot_press(s, _...)
    if isempty(s) || position(LineEdit.buffer(s)) == 0
        @static if VERSION >= v"0.7.0-"
            start_ipython()
        else
            # Force current_module() inside IPython to be Main:
            Base.eval(Main, :($start_ipython()))
        end
        println()
        LineEdit.refresh_line(s)
    else
        LineEdit.edit_insert(s, '.')
    end
end

function init_repl(repl)
    ipy_prompt_keymap = Dict{Any,Any}('.' => on_dot_press)

    main_mode = repl.interface.modes[1]
    main_mode.keymap_dict = LineEdit.keymap_merge(main_mode.keymap_dict,
                                                  ipy_prompt_keymap)
end
# See: https://github.com/JuliaInterop/RCall.jl/blob/master/src/RPrompt.jl
