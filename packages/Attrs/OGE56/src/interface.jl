
struct NoSuchAttr end

struct Attr{S} end

@inline getattr(x, f::Symbol) = getattr(x, Attr{f}())

@inline setattr!(x, f::Symbol, y) = setattr!(x, Attr{f}(), y)

@inline literal_getattr(x, ::Attr{F}) where F = getproperty(x, F)

@inline literal_setattr!(x, ::Attr{F}, y) where F = setproperty!(x, F, y)

@generated function trygetfield(x, ::Attr{F}) where F
    hasfield = F in fieldnames(x)
    quote
        $(Expr(:meta, :inline))
        $(hasfield ? :(Base.getfield(x, $(Meta.quot(F)))) : :(NoSuchAttr()))
    end
end

@generated function trygetfield(x, f::Symbol)
    fields = Meta.quot.(fieldnames(x))
    quote
        $(Expr(:meta, :inline))
        $([:(f === $a && return Base.getfield(x, $a)) for a in fields]...)
        NoSuchAttr()
    end
end

@generated function trysetfield!(x, ::Attr{F}, y) where F
    hasfield = F in fieldnames(x)
    quote
        $(Expr(:meta, :inline))
        $(hasfield ? :(Base.setfield!(x, $(Meta.quot(F)), y)) : :(NoSuchAttr()))
    end
end

@generated function trysetfield!(x, f::Symbol, y)
    fields = Meta.quot.(fieldnames(x))
    quote
        $(Expr(:meta, :inline))
        $([:(f === $a && return Base.setfield!(x, $a, y)) for a in fields]...)
        NoSuchAttr()
    end
end

@inline attrnames(::Type{<:NamedTuple{Names}}) where Names = Names

function attrnames(::Type{T}) where T
    fields = fieldnames(T)
    attrs = collect(Symbol, fields)
    attrset = Set(attrs)
    for m in methods(getattr, (T, Attr)).ms
        sig = m.sig
        while isa(sig, UnionAll)
            sig = sig.body
        end
        attr = sig.parameters[3].parameters[1]
        if !(attr isa TypeVar)
            attr::Symbol
            if !(attr in attrset)
                push!(attrset, attr)
                push!(attrs, attr)
            end
        end
    end

    if length(attrs) == length(fields)
        fields
    else
        sort!(view(attrs, (length(fields) + 1):length(attrs)))
        Tuple(attrs)
    end
end

@inline attrnames(x) = attrnames(typeof(x))

@inline function default_literal_getattr(x, f::Attr)
    res = trygetfield(x, f)
    if res ≡ NoSuchAttr()
        getattr(x, f)
    else
        res
    end
end

@inline function default_literal_setattr!(x, f::Attr, y)
    res = trysetfield!(x, f, y)
    if res ≡ NoSuchAttr()
        setattr!(x, f, y)
    else
        res
    end
end

@inline function default_getproperty(x, f::Symbol)
    res = trygetfield(x, f)
    if res ≡ NoSuchAttr()
        getattr(x, Attr{f}())
    else
        res
    end
end

@inline function default_setproperty!(x, f::Symbol, y)
    res = trysetfield!(x, f, y)
    if res ≡ NoSuchAttr()
        setattr!(x, Attr{f}(), y)
    else
        res
    end
end
