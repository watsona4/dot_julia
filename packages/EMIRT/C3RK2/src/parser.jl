module Parser
using ..Types
export autoparse, configparser, argparser!, shareprms!

function str2list(s, splitter=";")
    ret = []
    for e in split(s, splitter)
        if e!=""
            append!(ret, [autoparse(e)])
        end
    end
    return ret
end

# auto conversion of string
function autoparse(s)
    if s==""
        return nothing
    elseif contains(s, ";")
        return str2list(s, ";")
    elseif length(s)>1 && s[1]=='('
        @assert s[end]==')'
        # a tuple
        return tuple(autoparse(s[2:end-1])...)
    elseif contains(s, ",")
        return str2list(s, ",")
    elseif s=="yes" || s=="Yes"|| s=="y" || s=="Y" || s=="true" || s=="True"
        return true
    elseif s=="no" || s=="No" || s=="n" || s=="N" || s=="false" || s=="False"
        return false
    elseif contains(s, "/") || occursin(r"^[A-z]", s) || typeof(Meta.parse(s))==Symbol || typeof(Meta.parse(s)) == Expr
        # directory or containing alphabet not all number
        return s
    else
        return Meta.parse(s)
    end
end

"""
parse the lines
`Inputs:`
lines: cofiguration file name or lines of configuration file

`Outputs:`
pd: Dict, dictionary containing parameters
"""
function configparser(fname::AbstractString)
    if contains(fname, "[") && contains(fname, "]") && contains(fname, "=")
        # this is actually the content of the config file!
        lines = split(fname, "\n")
    else
        # this is really a file name
        lines = readlines(fname)
    end
    return configparser(lines)
end

function configparser(lines::Vector)
    # initialize the parameter dictionary
    pd = ParamDict()
    # default section name
    sec = :section
    # analysis the lines
    for l in lines
        # remove space and \n
        l = replace(l, "\n", "")
        l = replace(l, " ", "")
        if occursin(r"^\s*#", l) || occursin(r"^\s*\n", l)
            continue
        elseif occursin(r"^\s*\[.*\]", l)
            # update the section name
            m = match(r"\[.*\]", l)
            sec = Symbol( m.match[2:end-1] )
            pd[sec] = Dict()
        elseif occursin(r"^\s*.*\s*=", l)
            k, v = split(l, '=')
            k = Symbol(k)
            # assign value to dictionary
            pd[sec][k] = autoparse( v )
        end
    end
    return pd
end

"""
parse configuration file for Directed Acyclic Graph (DAG) computation
"""
function dagparser(fname::AbstractString)
    lines = readlines(fname)
    return dagparser(lines)
end

function dagparser(lines::Vector)
    # initialize the parameter dictionary
    pd = Vector(Dict)
    # temporary dictionary

    # default section name
    sec = :section
    # analysis the lines
    for l in lines
        # remove space and \n
        l = replace(l, "\n", "")
        l = replace(l, " ", "")
        if occursin(r"^\s*#", l) || occursin(r"^\s*\n", l)
            continue
        elseif occursin(r"^\s*\[.*\]", l)
            # update the section name
            m = match(r"\[.*\]", l)
            sec = Symbol( m.match[2:end-1] )
            pd[sec] = Dict()
        elseif occursin(r"^\s*.*\s*=", l)
            k, v = split(l, '=')
            k = Symbol(k)
            # assign value to dictionary
            pd[sec][k] = autoparse( v )
        end
    end
    return pd
end

"""
parameter dictionary
input can be some default dictionary

Note that all the key was one character, which is the first non '-' character!
suppose that the argument is as follows:
--flbl label.h5 --range 2,4-6
the returned dictionary will be
pd[:f] = "label.h5"
pd[:r] = [2,4,5,6]
"""
function argparser!(pd::Dict{Symbol, Any}=Dict() )
    println("default parameters: $(pd)")
    # argument table, two rows
    @assert length(ARGS) % 2 ==0
    argtbl = reshape(ARGS, 2,Int64( length(ARGS)/2))

    # traverse all the argument table columns
    for c in 1:size(argtbl,2)
        @assert argtbl[1,c][1]=='-'
        # key and value
        k = Symbol( replace(argtbl[1,c],"-","")[1] )
        v = autoparse( argtbl[2,c] )
        pd[k] = v
    end
    println("parameters after command line parsing: $(pd)")
end

# share the gneral parameters in each section
function shareprms!(pd::ParamDict, gnkey::Symbol=:gn, is_keep=true)
    @assert haskey(pd, gnkey)
    for k1 in keys(pd)
        if k1 != gnkey
            for (k2,v2) in pd[gnkey]
                pd[k1][k2] = v2
            end
        end
    end
    if !is_keep
        delete!(pd, gnkey)
    end
    return pd
end

end # end of module
