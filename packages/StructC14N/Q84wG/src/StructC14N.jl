module StructC14N

export canonicalize

import Base.convert

######################################################################
# Private functions
######################################################################

"""
  `convert(NamedTuple, str)`

  Convert a structure into a named tuple.
"""
function convert(::Type{NamedTuple}, str)
    k = fieldnames(typeof(str))
    return NamedTuple{k}(getfield.(Ref(str), k))
end


"""
  `findabbrv(v::Vector{Symbol})`

  Find all unique abbreviations of symbols in `v`.  Return a tuple of
  two `Vector{Symbol}`: the first contains all possible abbreviations;
  the second contains the corresponding un-abbreviated symbols.
"""
function findabbrv(symLong::Vector{Symbol})
    @assert length(symLong) >= 1
    symStr = String.(symLong)

    outAbbrv = Vector{Symbol}()
    outLong  = Vector{Symbol}()

    # Max length of string representation of keywords
    maxLen = maximum(length.(symStr))

    # Identify all abbreviations
    for len in 1:maxLen
        for i in 1:length(symStr)
            s = symStr[i]
            if length(s) >= len
                s = s[1:len]
                push!(outAbbrv, Symbol(s))
                push!(outLong , symLong[i])
            end
        end
    end

    # Identify unique abbreviations
    for sym in outAbbrv
        i = findall(outAbbrv .== sym)
        count = length(i)
        if count > 1
            deleteat!(outAbbrv, i)
            deleteat!(outLong , i)
        end
    end
    @assert length(unique(outLong)) == length(symLong) "Input symbols have ambiguous abbreviations"
    i = sortperm(outAbbrv)
    return (outAbbrv[i], outLong[i])
end


function myconvert(template, vv)
    if isa(template, Type)
        tt = template
    else
        tt = typeof(template)
    end

    if isa(tt, Union)
        if getfield(tt, :a) == Missing
            (ismissing(vv))  &&  (return vv)
            tt = getfield(tt, :b)
        elseif getfield(tt, :b) == Missing
            (ismissing(vv))  &&  (return vv)
            tt = getfield(tt, :a)
        end
    end

    if typeof(vv) <: AbstractString  &&  tt <: Number
        return convert(tt, Meta.parse(vv))
    end
    if typeof(vv) <: Number  &&  tt <: AbstractString
        return string(vv)
    end

    if length(methods(parse, (Type{tt}, typeof(vv)))) > 0
        return parse(tt, vv)
    end
    
    if length(methods(convert, (Type{tt}, typeof(vv)))) > 0
        return convert(tt, vv)
    end

    return tt(vv)
end


######################################################################
# Public functions
######################################################################


# input::NamedTuple
"""
  `canonicalize(template::NamedTuple, input::NamedTuple)`

  Canonicalize the `input` named tuple according to `template` and
  return the "canonicalized" named tuple.
"""
function canonicalize(template::NamedTuple, input::NamedTuple)
    (abbrv, long) = findabbrv(collect(keys(template)))

    # Default values.  Each element in the output vector is `Missing`
    # if the corresponding element in the tuple is a `Type`, otherwise
    # it is the value itself.
    tmp = collect(values(template))
    outval = Vector{Any}(undef, length(tmp))
    for i in 1:length(tmp)
        if isa(tmp[i], Type)
            outval[i] = missing
        else
            outval[i] = deepcopy(tmp[i])
        end
    end

    for i in 1:length(input)
        key = keys(input)[i]
        j = findall(key .== abbrv)
        if length(j) == 0
            error("Unexpected key: " * String(key))
        end
        @assert length(j) == 1
        j = j[1]
        k = findall(long[j] .== keys(template))
        @assert length(k) == 1
        k = k[1]
        outval[k] = myconvert(template[k], input[i])
    end
    return NamedTuple{keys(template)}(tuple(outval...))
end


"""
  `canonicalize(template::DataType, input::NamedTuple)`

  Canonicalize the `input` named tuple according to `template` and
  return the "canonicalized" structure.
"""
function canonicalize(template::DataType, input::NamedTuple)
    (abbrv, long) = findabbrv(collect(fieldnames(template)))

    #Default values
    outval = Vector{Any}(missing, length(fieldnames(template)))

    for i in 1:length(input)
        key = keys(input)[i]
        j = findall(key .== abbrv)
        if length(j) == 0
            error("Unexpected key: " * String(key))
        end
        @assert length(j) == 1
        j = j[1]
        k = findall(long[j] .== fieldnames(template))
        @assert length(k) == 1
        k = k[1]
        outval[k] = myconvert(fieldtype(template, k), input[i])
    end
    return template(outval...)
end


"""
  `canonicalize(template, input::NamedTuple)`

  Canonicalize the `input` named tuple according to `template` and
  return the "canonicalized" structure.
"""
canonicalize(template, input::NamedTuple) =
    return canonicalize(typeof(template), merge(convert(NamedTuple, template), input))


# input::Tuple
"""
  `canonicalize(template::NamedTuple, input::Tuple)`

  Canonicalize the `input` tuple according to `template`, and
  return the "canonicalized" named tuple.
"""
canonicalize(template::NamedTuple, input::Tuple) = canonicalize(template, NamedTuple{keys(template)}(input))


"""
  `canonicalize(template::DataType, input::Tuple)`

  Canonicalize the `input` tuple according to `template`, and
  return the "canonicalized" structure.
"""
canonicalize(template::DataType, input::Tuple) = canonicalize(template, NamedTuple{fieldnames(template)}(input))


"""
  `canonicalize(template, input::Tuple)`

  Canonicalize the `input` tuple according to the `template` structure, and
  return the "canonicalized" structure.
"""
canonicalize(template, input::Tuple) = canonicalize(template, NamedTuple{fieldnames(typeof(template))}(input))


"""
  `canonicalize(template, kwargs...)`

  Canonicalize the key/value pairs given as keywords according to the
  `template` structure or named tuple.
"""
function canonicalize(template; kwargs...)
    a = collect(kwargs)
    k = getindex.(a, 1)
    v = getindex.(a, 2)
    nt = NamedTuple{tuple(k...)}(tuple(v...))
    return canonicalize(template, nt)
end


end # module
