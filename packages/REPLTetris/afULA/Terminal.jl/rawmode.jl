function rawmode(f, hide_cursor=true)
    rawenabled = enableRawMode()
    rawenabled && hide_cursor && cursor_hide(terminal.out_stream)
    try
        f()
    finally
        rawenabled && disableRawMode(); cursor_show(terminal.out_stream)
    end
end

function enableRawMode()
    try
        REPL.Terminals.raw!(terminal, true)
        return true
    catch err
        warn("TerminalMenus: Unable to enter raw mode: $err")
    end
    return false
end

function disableRawMode()
    try
        REPL.Terminals.raw!(terminal, false)
        return true
    catch err
        warn("TerminalMenus: Unable to disable raw mode: $err")
    end
    return false
end