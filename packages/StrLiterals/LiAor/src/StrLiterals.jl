__precompile__(true)
""""
Enhanced string literals

String literals with Swift-like format, extendable at run-time

Copyright 2016-2018 Gandalf Software, Inc., Scott P. Jones
Licensed under MIT License, see LICENSE.md
"""
module StrLiterals

using ModuleInterfaceTools

const NEW_ITERATE = VERSION >= v"0.7.0-DEV.5127"
const str_next = @static NEW_ITERATE ? iterate : next
const is_empty = isempty
const is_valid = isvalid
const is_printable = isprint
const TypeOrFunc = Union{DataType,Function}

@static if VERSION < v"0.7-"
    outhex(v, p=1)   = hex(v, p)
    _sprint(f, s)    = sprint(endof(s), f, s)
    _sprint(f, s, c) = sprint(endof(s), f, s, c)
else
    outhex(v, p=1)   = string(v, base=16, pad=p)
    _sprint(f, s)    = sprint(f, s; sizehint=lastindex(s))
    _sprint(f, s, c) = sprint(f, s, c; sizehint=lastindex(s))
end

@api develop NEW_ITERATE, str_next

@api develop! interpolated_parse, interpolated_parse_vec, s_parse_unicode, s_parse_legacy, 
              s_print_unescaped_legacy, s_print_unescaped, s_print_escaped, s_print,
              s_escape_string, s_unescape_string, s_unescape_str, s_unescape_legacy

@api public "@f_str", "@pr_str", "@F_str", "@PR_str", "@sym_str"
export @f_str, @pr_str, @F_str, @PR_str, @sym_str

const AbsChar = @static isdefined(Base, :AbstractChar) ? AbstractChar : Char

const parse_chr   = Dict{Char, Function}()
const interpolate = Dict{Char, Function}()
const string_type = Ref{TypeOrFunc}(String)

const SymStr = Union{Symbol, AbstractString}

@api develop throw_arg_err, hexerr, parse_error, check_expr, check_done

str_done(str::AbstractString, pos::Integer) =
    @static V6_COMPAT ? done(str, pos) : (pos > ncodeunits(str))

parse_error(s) = throw(@static V6_COMPAT ? ParseError(s) : Base.Meta.ParseError(s))
incomplete_expr_error() = parse_error("Incomplete expression")
check_expr(ex) = isa(ex, Expr) && (ex.head === :continue) && incomplete_expr_error()
check_done(str, pos, msg) = str_done(str, pos) && parse_error(string(msg, " in ", repr(str)))

"""
Create a symbol from a string (that allows for interpolation and escape sequences)
"""
macro sym_str(str) ; QuoteNode(interpolated_parse(str, Symbol)) ; end

"""
String macro with more Swift-like syntax, plus support for emojis and LaTeX names
"""
macro f_str(str) ; interpolated_parse(str, string_type[]) ; end
macro f_str(str, args...)
    for v in args ; dump(v) end
    interpolated_parse(str, string_type[])
end

"""
String macro with more Swift-like syntax, plus support for emojis and LaTeX names, also legacy
"""
macro F_str(str) ; interpolated_parse(str, string_type[], true) ; end

"""
String macros that calls print directly
"""
macro pr_str(str) ; s_print(str, false) ; end
macro PR_str(str) ; s_print(str, true) ; end

throw_arg_err(msg)      = parse_error(msg)
throw_arg_err(msg, val) = parse_error(string(msg, repr(val)))

"""
Handle Unicode character constant, of form \\u{<hexdigits>}
"""
function s_parse_unicode(io, str,  pos)
    check_done(str, pos, "Incomplete \\u{...}")
    chr, pos = str_next(str, pos)
    chr != '{' && throw_arg_err("\\u missing opening { in ", str)
    check_done(str, pos, "Incomplete \\u{...}")
    beg = pos
    chr, pos = str_next(str, pos)
    num::UInt32 = 0
    cnt = 0
    while chr != '}'
        check_done(str, pos, "\\u{ missing closing }")
        (cnt += 1) > 6 && throw_arg_err("Unicode constant too long in ", str)
        num = num<<4 + chr - ('0' <= chr <= '9' ? '0' :
                              'a' <= chr <= 'f' ? 'a' - 10 :
                              'A' <= chr <= 'F' ? 'A' - 10 :
                              throw_arg_err("\\u missing closing } in ", str))
        chr, pos = str_next(str, pos)
    end
    cnt == 0 && throw_arg_err("\\u{} has no hex digits in ", str)
    ((0x0d800 <= num <= 0x0dfff) || num > 0x10ffff) &&
        throw_arg_err("Invalid Unicode character constant ", str[beg-3:pos-1])
    print(io, Char(num))
    pos
end

"""
String interpolation parsing, allow legacy \$, \\xHH, \\uHHHH, \\UHHHHHHHH
"""
s_print_unescaped_legacy(io, str::AbstractString) = s_print_unescaped(io, str, true)

"""
String interpolation parsing
Based on code resurrected from Julia base:
https://github.com/JuliaLang/julia/blob/deab8eabd7089e2699a8f3a9598177b62cbb1733/base/string.jl
"""
function s_print_unescaped(io, str::AbstractString, flg::Bool=false)
    pos = 1
    while !str_done(str, pos)
        chr, pos = str_next(str, pos)
        if !str_done(str, pos) && chr == '\\'
            chr, pos = str_next(str, pos)
            if (chr == 'u' ||  chr == 'U' || chr == 'x')
                if flg
                    pos = s_parse_legacy(io, str, pos, chr)
                elseif chr == 'u'
                    pos = s_parse_unicode(io, str, pos)
                else
                    throw_arg_err(string("\\", chr, " only supported in legacy mode (i.e. ",
                                         "F\"...\" or PR\"...\""))
                end
            elseif haskey(parse_chr, chr)
                pos = parse_chr[chr](io, str, pos, chr)
            else
                chr = (chr == '0' ? '\0' :
                       chr == '$' ? '$'  :
                       chr == '"' ? '"'  :
                       chr == '\'' ? '\'' :
                       chr == '\\' ? '\\' :
                       chr == 'a' ? '\a' :
                       chr == 'b' ? '\b' :
                       chr == 't' ? '\t' :
                       chr == 'n' ? '\n' :
                       chr == 'v' ? '\v' :
                       chr == 'f' ? '\f' :
                       chr == 'r' ? '\r' :
                       chr == 'e' ? '\e' :
                       throw_arg_err(string("Invalid \\", chr, " sequence in "), str))
                write(io, UInt8(chr))
            end
        else
            print(io, chr)
        end
    end
end

hexerr(chr) = throw_arg_err("\\$chr used with no following hex digits")

function s_parse_legacy(io, str, pos, chr)
    str_done(str, pos) && hexerr(chr)
    beg = pos
    max = chr == 'x' ? 2 : chr == 'u' ? 4 : 8
    if str[pos] == '{'
        max == 4 || throw_arg_err("{ only allowed with \\u")
        return s_parse_unicode(io, str, pos)
    end
    num = cnt = 0
    while (cnt += 1) <= max && !str_done(str, pos)
        chr, nxt = str_next(str, pos)
        num = '0' <= chr <= '9' ? num << 4 + chr - '0' :
              'a' <= chr <= 'f' ? num << 4 + chr - 'a' + 10 :
              'A' <= chr <= 'F' ? num << 4 + chr - 'A' + 10 : break
        pos = nxt
    end
    cnt == 1 && hexerr(chr)
    if max == 2
        write(io, UInt8(num))
    elseif is_valid(Char, num)
        print(io, Char(num))
    else
        throw_arg_err("Invalid Unicode character constant ", str[beg-2:pos-1])
    end
    pos
end

s_unescape_string(str::AbstractString) = _sprint(s_print_unescaped, str)

function s_print_escaped(io, str::AbstractString, esc::Union{AbstractString, AbsChar})
    pos = 1
    while !str_done(str, pos)
        chr, pos = str_next(str, pos)
        chr == '\0'         ? print(io, "\\0") :
        chr == '\e'         ? print(io, "\\e") :
        chr == '\\'         ? print(io, "\\\\") :
        chr in esc          ? print(io, '\\', chr) :
        '\a' <= chr <= '\r' ? print(io, '\\', "abtnvfr"[Int(chr)-6]) :
        is_printable(chr)   ? print(io, chr) : print(io, "\\u{", outhex(chr%UInt32), "}")
    end
end

s_escape_string(str::AbstractString) = _sprint(s_print_escaped, str, '\"')

s_print(str::AbstractString, flg::Bool=false) =
    s_print(str, flg, flg ? s_unescape_str : s_unescape_legacy)

function s_print(str::AbstractString, flg::Bool, unescape::Function)
    sx = interpolated_parse_vec(str, unescape, flg)
    (length(sx) == 1 && isa(sx[1], String)
     ? Expr(:call, :print, sx[1])
     : Expr(:call, :print, sx...))
end

function interpolated_parse(str::AbstractString, strfun::TypeOrFunc, flg::Bool, unescape::Function,
                            p::Function)
    sx = interpolated_parse_vec(str, unescape, flg)
    ((length(sx) == 1 && isa(sx[1], String)) ? strfun(sx[1])
     : Expr(:call, strfun, Expr(:call, :sprint, p, sx...)))
end

function interpolated_parse_vec(s::AbstractString, unescape::Function, flg::Bool=false)
    sx = []
    i = j = 1
    while !str_done(s, j)
        c, k = str_next(s, j)
        if c == '\\' && !str_done(s, k)
            c = s[k]
            if c == '('
                # Handle interpolation
                is_empty(s[i:j-1]) ||
                    push!(sx, unescape(s[i:j-1]))
                ex, j = parse(Expr, s, k, greedy=false)
                check_expr(ex)
                push!(sx, esc(ex))
                i = j
            elseif haskey(interpolate, c)
                i = j = interpolate[c](sx, s, unescape, i, j, k)
            elseif flg && c == '$'
                is_empty(s[i:j-1]) ||
                    push!(sx, unescape(s[i:j-1]))
                i = k
                # Move past \\, c should point to '$'
                c, j = str_next(s, k)
            else
                j = k
            end
        elseif flg && c == '$'
            is_empty(s[i:j-1]) ||
                push!(sx, unescape(s[i:j-1]))
            ex, j = parse(Expr, s, k, greedy=false)
            check_expr(ex)
            push!(sx, esc(ex))
            i = j
        else
            j = k
        end
    end
    is_empty(s[i:end]) ||
        push!(sx, unescape(s[i:j-1]))
    sx
end

function s_unescape_str(str)
    str = s_unescape_string(str)
    is_valid(String, str) ? str : throw_arg_err("Invalid UTF-8 sequence")
end
function s_unescape_legacy(str)
    str = _sprint(s_print_unescaped_legacy, str)
    is_valid(String, str) ? str : throw_arg_err("Invalid UTF-8 sequence")
end

interpolated_parse(str::AbstractString, strfun::TypeOrFunc, flg::Bool, u::Function) =
    interpolated_parse(str, strfun, flg, u, print)

interpolated_parse(str::AbstractString, strfun::TypeOrFunc, flg::Bool=false) =
    interpolated_parse(str, strfun, flg, flg ? s_unescape_legacy : s_unescape_str)

@api freeze

end # module StrLiterals
