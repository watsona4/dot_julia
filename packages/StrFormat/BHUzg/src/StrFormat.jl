__precompile__(true)
""""
Add C, Python and type-based formatting to Str string literals

Copyright 2016-2018 Gandalf Software, Inc., Scott P. Jones
Licensed under MIT License, see LICENSE.md
"""
module StrFormat

using ModuleInterfaceTools

@api extend! Format, StrLiterals

function _parse_format(str, pos, fun)
    ex, j = parse(Expr, str, pos; greedy=false)
    check_expr(ex)
    ex, k = parse(Expr, string("a", str[pos:j-1]), 1, greedy=true)
    check_expr(ex)
    isa(ex, Symbol) && (println(string("a", str[pos:j-1])) ; dump(ex))
    ex.args[1] = fun
    ex, j
end

function _parse_fmt(sx::Vector{Any}, s::AbstractString, unescape::Function,
                    i::Integer, j::Integer, k::Integer)
    # Move past \\, k should point to '%'
    c, k = str_next(s, k)
    check_done(s, k, "Incomplete % expression")
    # Handle interpolation
    isempty(s[i:j-1]) || push!(sx, unescape(s[i:j-1]))
    if s[k] == '('
        # Need to find end to parse to
        ex, j = _parse_format(s, k, Format.fmt)
    else
        # Move past %, c should point to letter
        beg = k
        while true
            c, k = str_next(s, k)
            check_done(s, k, "Incomplete % expression")
            s[k] == '(' && break
        end
        ex, j = _parse_format(s, k, Format.cfmt)
        insert!(ex.args, 2, s[beg-1:k-1])
    end
    push!(sx, esc(ex))
    j
end

function _parse_pyfmt(sx::Vector{Any}, s::AbstractString, unescape::Function,
                      i::Integer, j::Integer, k::Integer)
    # Move past \\, k should point to '{'
    c, k = str_next(s, k)
    check_done(s, k, "Incomplete {...} Python format expression")
    # Handle interpolation
    isempty(s[i:j-1]) || push!(sx, unescape(s[i:j-1]))
    beg = k # start location
    c, k = str_next(s, k)
    while c != '}'
        check_done(s, k, string("\\{ missing closing } in ", c))
        c, k = str_next(s, k)
    end
    check_done(s, k, "Missing (expr) in Python format expression")
    c, k = str_next(s, k)
    c == '(' || parse_error(string("Missing (expr) in Python format expression: ", c))
    # Need to find end to parse to
    ex, j = _parse_format(s, k-1, Format.pyfmt)
    insert!(ex.args, 2, s[beg:k-3])
    push!(sx, esc(ex))
    j
end

function __init__()
    StrLiterals.interpolate['%'] = _parse_fmt
    StrLiterals.interpolate['{'] = _parse_pyfmt
end

end # module StrFormat
