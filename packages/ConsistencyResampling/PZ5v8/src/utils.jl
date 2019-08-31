tx(x::Tuple) = x
tx(x::Number) = (x,)
tx(x) = tuple(x...)

zeros_tuple(::Type{Tuple{}}, m::Int) = ()
zeros_tuple(::Type{T}, m::Int) where T <: Tuple =
    (zeros(Base.tuple_type_head(T), m), zeros_tuple(Base.tuple_type_tail(T), m)...)

function Bootstrap.data_summary(x::Tuple)
    s = join(Bootstrap.data_summary.(x), "; ")
    return "Tuple: { $s }"
end
