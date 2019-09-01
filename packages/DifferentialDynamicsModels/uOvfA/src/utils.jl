macro maintain_type(expr)    # ensures that subtypes of StaticArrays.FieldVector maintain their type upon manipulation
    full_name = expr.args[2].args[1]                                     # MyType{T} or MyType
    short_name = full_name isa Symbol ? full_name : full_name.args[1]    # MyType
    @assert expr.args[2].args[2].args[1] == :FieldVector "@maintain_type is defined only for subtypes of FieldVector"
    N = expr.args[2].args[2].args[2]                                     # N in FieldVector{N,T}
    T = expr.args[2].args[2].args[3]                                     # T in FieldVector{N,T}
    st_method = if short_name == full_name
        :(StaticArrays.similar_type(::Type{$short_name}, ::Type{$T}, s::Size{($N,)}) = $short_name)
    else
        :(StaticArrays.similar_type(::Type{<:$short_name}, ::Type{$T}, s::Size{($N,)}) where {$T} = $full_name)
    end
    quote
        $(esc(expr))
        $(esc(st_method))
    end
end

function ode_heun(fn, y0, Tf, Ti=zero(Tf), N=10)
    dt = (Tf - Ti)/N
    y = y0
    t = Ti
    for i in 1:N
        k1 = dt*fn(y, t)
        k2 = dt*fn(y + k1, t + dt)
        y = y + (k1 + k2)/2
        t = t + dt
    end
    y
end

function ode_rk4(fn, y0, Tf, Ti=zero(Tf), N=10)
    dt = (Tf - Ti)/N
    y = y0
    t = Ti
    for i in 1:N
        k1 = dt*fn(y, t)
        k2 = dt*fn(y + k1/2, t + dt/2)
        k3 = dt*fn(y + k2/2, t + dt/2)
        k4 = dt*fn(y + k3, t + dt)
        y = y + (k1 + 2*k2 + 2*k3 + k4)/6
        t = t + dt
    end
    y
end

@inline mod2piF(x::T) where {T} = mod(x, 2*T(pi))
@inline function adiff(x, y)
    d = mod2piF(x - y)
    ifelse(d <= π, d, d - 2*oftype(d, π))
end
