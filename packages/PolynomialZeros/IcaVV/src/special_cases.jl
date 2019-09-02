## Special cases
## linear, quadratic, cubic

## return function name for special case: identity, solve_linear, solve_quadratic, solve_cubic
function special_case(ps::Vector{S}, T) where {S}
    deg = length(ps) - 1  # [p0, p1, ..., pn]
    if deg == 1
        hasmethod(solve_linear, (Vector{S}, Type{T}))    && return solve_linear
    elseif deg == 2
        hasmethod(solve_quadratic, (Vector{S}, Type{T})) && return solve_quadratic
    elseif deg == 3
        hasmethod(solve_cubic, (Vector{S}, Type{T}))     && return solve_cubic
#    elseif deg == 5
#        hasmethod(solve_quintic, (Vector{S}, Type{T}))   && return solve_quintic
    end

    return identity
end
        
    

## Assume ps = [p_0, p_1, ..., p_n] with  p_n \neq 0, but possibly p_0 = 0

## Linear
check_linear(ps) = length(ps) == 2 || throw(DomainError())
## Over C
function solve_linear(ps::Vector{Complex{T}}, ::Type{Over.CC{S}}) where {T <: Real, S}
    check_linear(ps)
    Complex{S}[-ps[1] / ps[2]]
end
solve_linear(ps::Vector{T}, ::Type{Over.CC{S}}) where {T <: Real, S} = solve_linear(complex.(ps,zeros(T,2)), Over.CC{S})

## Over R
function solve_linear(ps::Vector{T}, ::Type{Over.RR{S}}) where {T <: Real, S}
    check_linear(ps)
    S[-ps[1] / ps[2]]
end

## Over Q
function solve_linear(ps::Vector{T}, ::Type{Over.QQ{S}}) where {T <: Integer, S}
    check_linear(ps)
    Rational{S}[-ps[1] // ps[2]]
end
function solve_linear(ps::Vector{Rational{T}}, ::Type{Over.QQ{S}}) where {T <: Integer, S}
    check_linear(ps)
    Rational{S}[-ps[1] // ps[2]]
end

## Over Z
function solve_linear(ps::Vector{T}, ::Type{Over.ZZ{S}}) where {T <: Integer, S}
    check_linear(ps)
    q,r = divrem(-ps[1], ps[2])
    if r == 0
        S[q]
    else
        zeros(S, 0)
    end
end

## Quadratic
check_quadratic(ps) = length(ps) == 3 || throw(DomainError())


## Kahan quadratic equation with fma
##  https://people.eecs.berkeley.edu/~wkahan/Qdrtcs.pdf

## solve ax^2 - 2bx + c
function qdrtc(a::T, b::T, c::T) where {T <: Real}
    # z1, z2 roots of ax^2 - 2bx + c
    d = discr(a,b,c)  # (b^2 - a*c), as 2 removes 4
    
    if d <= 0
        r = b/a  # real
        s = sqrt(-d)/a #imag
        return (r,s,r,-s)
    else
        r = sqrt(d) * (sign(b) + iszero(b)) + b
        return (r/a, zero(T), c/r, zero(T))
    end
end

## more work could be done here.
function discr(a::T,b::T,c::T) where {T}
    pie = 3.0 # depends on 53 or 64 bit...
    d = b*b - a*c
    e = b*b + a*c

    pie*abs(d) > e && return d

    p = b*b
    dp = muladd(b,b,-p)
    q = a*c
    dq = muladd(a,c,-q)

    (p-q) + (dp - dq)
end


function solve_quadratic(ps::Vector{T}, U::Type{Over.CC{S}}) where {T <: Real, S}
    check_quadratic(ps)
    iszero(ps[1]) && return vcat(zero(S), solve_linear(ps[2:end], U))
    
    
    r1,i1,r2,i2 = qdrtc(ps[3], -(0.5) * ps[2], ps[1])
    Complex{S}[complex(r1, i1), complex(r2, i2)]
end

function solve_quadratic(ps::Vector{T}, U::Type{Over.RR{S}}) where {T <: Real, S}
    check_quadratic(ps)
    iszero(ps[1]) && return vcat(zero(S), solve_linear(ps[2:end], U))
    
    r1,i1,r2,i2 = qdrtc(ps[3], -(0.5) * ps[2], ps[1])
    if iszero(i1)
        S[r1, r2]
    else
        zeros(S,0)
    end
end



## Cubic
check_cubic(ps) = length(ps) == 4 || throw(DomainError())

# C -> C
function solve_cubic(ps::Vector{Complex{T}}, U::Type{Over.CC{S}}) where {T <: Real, S}
    check_cubic(ps)
    iszero(ps[1]) && return solve_quadratic(ps[2:end], U)

    [PolynomialRoots.solve_cubic_eq(ps)...]
end

# R -> C XXX Can be faster
function solve_cubic(ps::Vector{T}, U::Type{Over.CC{S}}) where {T <: Real, S}
    check_cubic(ps)
    iszero(ps[1]) && return solve_quadratic(ps[2:end], U)

    [PolynomialRoots.solve_cubic_eq(complex.(ps, zeros(T,4)))...]
end


# R -> R
function solve_cubic(ps::Vector{T}, U::Type{Over.RR{S}}) where {T <: Real, S}
    check_cubic(ps)
    iszero(ps[1]) && return solve_quadratic(ps[2:end], U)

    ## https://en.wikipedia.org/wiki/Cubic_function#Algebraic_solution

    d,c,b,a = ps
    Delta = 18 * prod(ps) - 4b^3 * d + b^2 * c^2 - 4a*c^3 - 27 * a^2 * d^2
    Delta0 = b^2 - 3a*c
    Delta1 = 2b^3 - 9*a*b*c + 27*a^2 * d

    
    if Delta == 0 # one or two (with a double root)
        
        if iszero(Delta0)
            return ones(S,3) * (-b/(3a))
        else
            return S[(9a*d - b*c)/(2Delta0), (9a*d - b*c)/(2Delta0), (4a*b*c - 9a^2*d - b^3)/(a * Delta0)]
        end
        
    elseif Delta < 0 # one real root

        if iszero(Delta0)
            C = cbrt((0.5) * (2*sign(Delta1)*abs(Delta1)))
            
        else
            Delta2 = sqrt(-27*a^2*Delta)
            C = cbrt((0.5)* ( Delta1 + Delta2)) 
            
        end
        return S[-1/(3a)*(b+C+Delta0/C)]
            
        
        
    elseif Delta > 0 # 3 distinct real roots

        p, q = (3a*c  - b^2)/(3a^2), (2b^3 - 9a*b*c + 27a^2*d) / (27a^3)

        if iszero(p)
            return ones(S,3) * (-b/(3a))
        else
            return S[2*sqrt(-p/3)*cos(1/3 * acos((3q)/(2p) * sqrt(-3/p)) - 2pi*k/3) for k in 0:2] - b/(3a)
        end
        
    end

end



check_quintic(ps::Vector) = length(ps) == 6 || throw(DomainError())
# C -> C
function solve_quintic(ps::Vector{Complex{T}}, U::Type{Over.CC{S}}) where {T <: Real, S}
    check_quintic(ps)

    PolynomialRoots.roots5(ps)
end
