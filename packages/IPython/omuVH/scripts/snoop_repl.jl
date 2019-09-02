#!/bin/bash
# -*- mode: julia -*-
#=
exec ${JULIA:-julia} --startup-file=no -i \
    -e "include(popfirst!(ARGS))" "${BASH_SOURCE[0]}" \
    "$@"
=#

function start_repl(;
        interactive::Bool = true,
        quiet::Bool = true,
        banner::Bool = false,
        history_file::Bool = true,
        color_set::Bool = false,
        )
    if !(stdout isa Base.TTY)
        error("stdout is not a TTY")
    elseif !(stdin isa Base.TTY)
        error("stdin is not a TTY")
    end
    was_interactive = Base.is_interactive
    try
        # Required for Pkg.__init__ to setup the REPL mode:
        Base.eval(:(is_interactive = $interactive))

        @info "Starting REPL..."
        Base.run_main_repl(interactive, quiet, banner, history_file, color_set)
    finally
        Base.eval(:(is_interactive = $was_interactive))
    end
end

csv_path, = ARGS

let io = open(csv_path, "w")
    ccall(:jl_dump_compiles, Nothing, (Ptr{Nothing},), io.handle)
    try
        @info "Loading IPython..."
        using IPython
        start_repl()
    finally
        ccall(:jl_dump_compiles, Nothing, (Ptr{Nothing},), C_NULL)
        close(io)
    end
end
exit()
