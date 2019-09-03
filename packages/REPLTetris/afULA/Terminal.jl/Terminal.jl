module Terminal

using Compat, Compat.REPL, Crayons
export rawmode, clear_screen, readKey, put, terminal_screen

@compat function __init__()
    global terminal
    terminal = REPL.Terminals.TTYTerminal(get(ENV, "TERM", is_windows() ? "" : "dumb"), stdin, stdout, stderr)
end

include("rawmode.jl")
include("cursor.jl")
include("readkey.jl")

end #module