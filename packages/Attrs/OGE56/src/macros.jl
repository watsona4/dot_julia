
function match_setproperty!(ex)
    if Meta.isexpr(ex, :(=)) && length(ex.args) == 2
        getprop = match_getproperty(ex.args[1])
        if getprop !== nothing
            return getprop..., ex.args[2]
        end
    end
    return nothing
end

function match_getproperty(ex)
    if Meta.isexpr(ex, :.) && length(ex.args) == 2 &&
        isa(ex.args[2], QuoteNode) &&
        isa(ex.args[2].value, Symbol)
        return ex.args[1], ex.args[2].value
    end
    return nothing
end

function match_call(ex)
    if Meta.isexpr(ex, :function)
        @assert length(ex.args) == 2
        return :function, ex.args[1], ex.args[2]
    elseif Meta.isexpr(ex, :(=)) && length(ex.args) == 2
        first, rest = ex.args
        if Meta.isexpr(first, :where) || Meta.isexpr(first, :call)
            return :(=), first, rest
        end
    end
    nothing
end

function deepliteralattrs(ex::Expr)

    ex.head == :quote && return ex
    callexpr = match_call(ex)
    if callexpr !== nothing
        head, decl, body = callexpr
        return Expr(head, decl, deepliteralattrs(body))
    end

    setprop = match_setproperty!(ex)
    if setprop !== nothing
        tgt, field, src = map(deepliteralattrs, setprop)
        return :(Attrs.literal_setattr!($tgt,
                                        Attr{$(Meta.quot(field))}(), $src))
    end

    getprop = match_getproperty(ex)
    if getprop !== nothing
        src, field = map(deepliteralattrs, getprop)
        return :(Attrs.literal_getattr($src, Attr{$(Meta.quot(field))}()))
    end

    newex = Expr(ex.head)
    changed = false
    for a in ex.args
        a′ = deepliteralattrs(a)
        push!(newex.args, a′)
        changed = (changed || a !== a′)
    end

    return changed ? newex : ex
end

function deepliteralattrs(ex)
    return ex
end

macro literalattrs(ex)
    deepliteralattrs(ex) |> esc
end

macro defattrs(T)
    DT, params = Meta.isexpr(T, :where) ?
                  (T.args[1], T.args[2:end]) :
                  (T, ())

    @gensym x f y

    quote
        @inline Attrs.literal_getattr(
            $x::$DT, $f::Attrs.Attr) where {$(params...)} =
                Attrs.default_literal_getattr($x, $f)

        @inline Base.getproperty(
            $x::$DT, $f::Base.Symbol) where {$(params...)} =
                Attrs.default_getproperty($x, $f)

        @inline Attrs.literal_setattr!(
            $x::$DT, $f::Attrs.Attr, $y) where {$(params...)} =
                Attrs.default_literal_setattr!($x, $f, $y)

        @inline Base.setproperty!(
            $x::$DT, $f::Base.Symbol, $y) where {$(params...)} =
                Attrs.default_setproperty!($x, $f, $y)

        @inline Base.propertynames($x::$DT) where {$(params...)} =
            Attrs.attrnames($x)
    end |> esc
end
