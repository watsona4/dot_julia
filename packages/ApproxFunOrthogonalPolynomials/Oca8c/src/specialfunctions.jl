

# project to interval if we are not on the interview
# TODO: need to work out how to set piecewise domain

/(c::Number,f::Fun{S}) where {S<:ContinuousSpace} = Fun(map(f->c/f,components(f)),PiecewiseSpace)
^(f::Fun{S},c::Integer) where {S<:ContinuousSpace} = Fun(map(f->f^c,components(f)),PiecewiseSpace)
^(f::Fun{S},c::Number) where {S<:ContinuousSpace} = Fun(map(f->f^c,components(f)),PiecewiseSpace)


^(f::Fun{<:PolynomialSpace},k::Integer) = intpow(f,k)

#TODO: implement
^(f::Fun{Jacobi},k::Integer) = intpow(f,k)
^(f::Fun{Jacobi},k::Real) = Fun(f,Chebyshev)^k


function log(f::Fun{<:PolynomialSpace{<:IntervalOrSegment}})
    g = log(setdomain(f, ChebyshevInterval()))
    setdomain(g, domain(f))
end



# ODE gives the first order ODE a special function op satisfies,
# RHS is the right hand side
# growth says what to use to choose a good point to impose an initial condition
for (op,ODE,RHS,growth) in ((:(exp),"D-f'","0",:(real)),
                            (:(asinh),"sqrt(f^2+1)*D","f'",:(real)),
                            (:(acosh),"sqrt(f^2-1)*D","f'",:(real)),
                            (:(atanh),"(1-f^2)*D","f'",:(real)),
                            (:(erfcx),"D-2f*f'","-2f'/sqrt(π)",:(real)),
                            (:(dawson),"D+2f*f'","f'",:(real)))
    L,R = Meta.parse(ODE),Meta.parse(RHS)
    @eval $op(f::Fun{<:ContinuousSpace}) = Fun(map(f->$op(f),components(f)),PiecewiseSpace)
end


for OP in (:abs,:sign,:log,:angle)
    @eval $OP(f::Fun{<:ContinuousSpace{<:Any,<:Real},<:Real}) =
            Fun(map($OP,components(f)),PiecewiseSpace)
end

sin(f::Fun{S,T}) where {S<:Union{Ultraspherical,Chebyshev},T<:Real} = imag(exp(im*f))
cos(f::Fun{S,T}) where {S<:Union{Ultraspherical,Chebyshev},T<:Real} = real(exp(im*f))


## Second order functions with parameter ν

for (op,ODE,RHS,growth) in ((:(hankelh1),"f^2*f'*D^2+(f*f'^2-f^2*f'')*D+(f^2-ν^2)*f'^3","0",:(imag)),
                            (:(hankelh2),"f^2*f'*D^2+(f*f'^2-f^2*f'')*D+(f^2-ν^2)*f'^3","0",:(imag)),
                            (:(besselj),"f^2*f'*D^2+(f*f'^2-f^2*f'')*D+(f^2-ν^2)*f'^3","0",:(imag)),
                            (:(bessely),"f^2*f'*D^2+(f*f'^2-f^2*f'')*D+(f^2-ν^2)*f'^3","0",:(imag)),
                            (:(besseli),"f^2*f'*D^2+(f*f'^2-f^2*f'')*D-(f^2+ν^2)*f'^3","0",:(real)),
                            (:(besselk),"f^2*f'*D^2+(f*f'^2-f^2*f'')*D-(f^2+ν^2)*f'^3","0",:(real)),
                            (:(besselkx),"f^2*f'*D^2+((-2f^2+f)*f'^2-f^2*f'')*D-(f+ν^2)*f'^3","0",:(real)),
                            (:(hankelh1x),"f^2*f'*D^2+((2im*f^2+f)*f'^2-f^2*f'')*D+(im*f-ν^2)*f'^3","0",:(imag)),
                            (:(hankelh2x),"f^2*f'*D^2+((-2im*f^2+f)*f'^2-f^2*f'')*D+(-im*f-ν^2)*f'^3","0",:(imag)))
    L,R = Meta.parse(ODE),Meta.parse(RHS)
    @eval begin
        function $op(ν,fin::Fun{S,T}) where {S<:Union{Ultraspherical,Chebyshev},T}
            f=setcanonicaldomain(fin)

            g=chop($growth(f),eps(T))
            xmin = isempty(g.coefficients) ? leftendpoint(domain(g)) : argmin(g)
            xmax = isempty(g.coefficients) ? rightendpoint(domain(g)) : argmax(g)
            opfxmin,opfxmax = $op(ν,f(xmin)),$op(ν,f(xmax))
            opmax = maximum(abs,(opfxmin,opfxmax))
            while opmax≤10eps(T) || abs(f(xmin)-f(xmax))≤10eps(T)
                xmin,xmax = rand(domain(f)),rand(domain(f))
                opfxmin,opfxmax = $op(ν,f(xmin)),$op(ν,f(xmax))
                opmax = maximum(abs,(opfxmin,opfxmax))
            end
            D=Derivative(space(f))
            B=[Evaluation(space(f),xmin),Evaluation(space(f),xmax)]
            u=\([B;eval($L)],[opfxmin;opfxmax;eval($R)];tolerance=eps(T)*opmax)

            setdomain(u,domain(fin))
        end
    end
end


#TODO ≤,≥




## Piecewise Space

# Return the locations of jump discontinuities
#
# Non Piecewise Spaces are assumed to have no jumps.
function jumplocations(f::Fun)
    eltype(domain(f))[]
end

# Return the locations of jump discontinuities
function jumplocations(f::Fun{S}) where{S<:Union{PiecewiseSpace,ContinuousSpace}}
    d = domain(f)

    if ncomponents(d) < 2
      return eltype(domain(f))[]
    end

    dtol=10eps(eltype(d))
    ftol=10eps(cfstype(f))

    dc = components(d)
    fc = components(f)

    isjump = isapprox.(leftendpoint.(dc[2:end]), rightendpoint.(dc[1:end-1]), rtol=dtol) .&
           .!isapprox.(first.(fc[2:end]), last.(fc[1:end-1]), rtol=ftol)

    locs = rightendpoint.(dc[1:end-1])
    locs[isjump]
end



