export Cubic, Spline, npatches, funk

# see http://mathworld.wolfram.com/CubicSpline.html

import Base: getindex, show

"""
`Cubic(a,b,c,d)` is a 3rd degree polynomial `a+bx+cx^2+dx^3`.
Use `f(x)` to evalue `f` at the value `x`.
"""
struct Cubic
    a::Number
    b::Number
    c::Number
    d::Number
end

(f::Cubic)(x::Number) = f.a + x*(f.b + x*(f.c+x*f.d))

"""
`f'` where `f` is a `Cubic` or `Spline` is the derivative
of `f`.
"""
Base.adjoint(f::Cubic) = Cubic(f.b,2f.c,3f.d,0)

struct Spline
    patches::Array{Cubic,1}
    closed::Bool
end

is_closed(S::Spline) = S.closed


function Base.adjoint(S::Spline)
    plist = adjoint.(S.patches)
    return Spline(plist,S.closed)
end

"""
`Spline(vals,kind)` returns a cubic spline based on the values in `vals`.
The resulting spline `S` will have the property that `S(1)==y[1]`,
`S(2)==y[2]`, and so on up to `S(n)==y[n]` where `n` is the length of `y`.

+ If `kind` is `:open` then the second derivatives at the end points will be zero. (This is the default.)
+ If `kind` is `:closed` then we assume that we are interpolating a periodic function where `S(n+1)==S(1)`.
"""
function Spline(y::Array{T,1},kind::Symbol=:open)::Spline where T<:Number
    n = length(y)
    if kind == :open
        @assert n>2 "Open splines must have at least three points"
        return open_spline(y)
    end
    if kind == :closed
        @assert n>3 "Closed splines must have at least four points"
        return closed_spline(y)
    end

    error("Spline type must be :open or :closed, not $kind")
end

function npatches(S::Spline)
    return length(S.patches)
end

function show(io::IO, S::Spline)
    adjective = is_closed(S) ? "Closed" : "Open"
    print(io, "$adjective spline with $(npatches(S)) patches")
end


getindex(S::Spline, idx::Int) = S.patches[idx]

"""
`funk(S)` converts the Spline `S` into a callable function
(e.g., that can be passed to `plot`).
"""
function funk(S)::Function
    return x -> S(x)
end

function (S::Spline)(x::Real)
    np = npatches(S)

    if is_closed(S)

        p = Int(floor(x))
        x = mod(x,np)
        p = Int(floor(x))

        if p==0
            p = np
            x += np
        end
        f = S[p]
        return f(x-p)
    end

    # open spline
    p = Int(floor(x))
    if x < 1
        p = 1
    end

    if p > np
        p = np
    end
    f = S[p]
    return f(x-p)
end


function open_spline(y::Array{T,1})::Spline where T<:Number
    n = length(y)
    M = zeros(n,n)
    for i=1:n
        M[i,i] = 4
    end
    M[1,1] = 2
    M[n,n] = 2

    for i=1:n-1
        M[i,i+1] = 1
        M[i+1,i] = 1
    end

    rhs = zeros(T,n)
    rhs[1] = 3*(y[2]-y[1])
    for k=2:n-1
        rhs[k] = 3*(y[k+1]-y[k-1])
    end
    rhs[n] = 3*(y[n]-y[n-1])

    D = M\rhs

    a = zeros(Number,n-1)
    b = zeros(Number,n-1)
    c = zeros(Number,n-1)
    d = zeros(Number,n-1)

    for j=1:n-1
        a[j] = y[j]
        b[j] = D[j]
        c[j] = 3*(y[j+1]-y[j])-2D[j]-D[j+1]
        d[j] = 2*(y[j]-y[j+1])+D[j]+D[j+1]
    end
    return Spline( [ Cubic(a[i],b[i],c[i],d[i]) for i=1:n-1 ] , false)
end

function closed_spline(y::Array{T,1})::Spline where T <: Number
    yy = copy(y)
    n = length(y)
    prepend!(yy,y[end-3:end])
    append!(yy,y[1:4])

    S = open_spline(yy)

    plist = S.patches[5:end-3]
    return Spline(plist,true)

end
