module FieldDefaults

using FieldMetadata, Setfield
using FieldMetadata: @default, @redefault, default, units
using Base: tail

export @default_kw, @udefault_kw, @redefault_kw, @reudefault_kw, default_kw, udefault_kw

macro default_kw(ex)
    default_kw_macro(ex, :default_kw, false)
end

macro redefault_kw(ex)
    default_kw_macro(ex, :default_kw, true)
end

macro udefault_kw(ex) 
    default_kw_macro(ex, :udefault_kw, false) 
end

macro reudefault_kw(ex)
    default_kw_macro(ex, :udefault_kw, true)
end

default_kw_macro(ex, func, update) = begin
    typ = FieldMetadata.firsthead(ex, :struct) do typ_ex
        FieldMetadata.namify(typ_ex.args[2])
    end
    quote
        import FieldDefaults.default
        $(FieldMetadata.add_field_funcs(ex, :default; update=update))
        $(esc(typ))(;kwargs...) = $func($(esc(typ)); kwargs...)
    end
end

insert_kwargs(kwargs, T) = insert_kwargs(kwargs, get_default(T), T)
insert_kwargs(kwargs, defaults, T) = insert_kwargs(keys(kwargs.data), Tuple(kwargs.data), defaults, T)
insert_kwargs(keys::Tuple, vals, defaults, T) = begin
    fnames = fieldnames(T)
    key, val = keys[1], vals[1]
    key in fnames || error("$key is not a field of $T")
    ind = findfirst(n -> n == key, fnames)
    @set! defaults[ind] = val
    insert_kwargs(tail(keys), tail(vals), defaults, T)
end
insert_kwargs(keys::Tuple{}, vals, defaults, T) = defaults

default_kw(::Type{T}; kwargs...) where T =
    T(insert_kwargs(kwargs, T)...)

# Combined default() and units()
udefault_kw(::Type{T}; kwargs...) where T =
    T(insert_kwargs(kwargs, apply_units(get_default(T), units(T)), T)...)

apply_units(defs::Tuple, units::Tuple) = (defs[1] * units[1], apply_units(tail(defs), tail(units))...)
apply_units(defs::Tuple, units::Tuple{Number,Vararg}) = (defs[1], apply_units(tail(defs), tail(units))...)
apply_units(defs::Tuple{}, units::Tuple{}) = ()

get_default(args...) = default(args...)

end # module
