function showDutyCycleType(
    io::IO,
    typename::String,
    T, U, V
)
    # turn on color --- this is a dirty hack (consider that the output
    # terminal might not support colors!)
    superio = IOContext(io, :color => true)
    printstyled(superio, typename, bold=true)
    print(io, "{")
    printstyled(superio, repr(T), color=:red)
    print(io, ",")
    printstyled(superio, repr(V), color=:yellow)
    print(io, ",")
    printstyled(superio, repr(U), color=:green)
    print(io, "}")
end
Base.show(io::IOContext, d::Type{DutyCycle{T,U,V}}) where {
    T<:Number, U<:Real, V<:NoDimNum
} = showDutyCycleType(io, "DutyCycle", T, U, V)
Base.show(io::IOContext, d::Type{CoherentDutyCycle{T,U,V}}) where {
    T<:Number, U<:Real, V<:NoDimNum
} = showDutyCycleType(io, "CoherentDutyCycle", T, U, V)
Base.show(io::IOContext, d::Type{IncoherentDutyCycle{T,U,V}}) where {
    T<:Number, U<:Real, V<:NoDimNum
} = showDutyCycleType(io, "IncoherentDutyCycle", T, U, V)

# REPL display
#Base.summary(io::IO, x::DutyCycle{T,U,V}) where {T,U,V} =
#    "DutyCycle{$T,$U,$V}"
#Base.summary(io::IO, x::Type{DutyCycle{T,U,V}}) where {T,U,V} =
#    "Type{DutyCycle{$T,$U,$V}}"
