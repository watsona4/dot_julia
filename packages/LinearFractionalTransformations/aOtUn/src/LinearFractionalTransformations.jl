# Linear fractional transformation "LFT"

module LinearFractionalTransformations

import Base.inv, Base.isequal, Base.show, Base.hash
import Base.==, Base.*, Base.getindex
export LFT, isequal, call


const complex_infinity = Inf + Inf * im

struct LFT
    M::Array{Complex{Float64},2}
    function LFT(a, b, c, d)
        if isinf(a) || isinf(b) || isinf(c) || isinf(d)
            error("Arguments must be finite: " * string((a,b,c,d) ))
        end

        if a*d-b*c == 0
            error("Singularity detected: " * string((a,b,c,d)) )
        end

        new( [ a b; c d])
    end
end

function LFT(M::Array)
    return LFT(M[1,1], M[1,2], M[2,1], M[2,2])
end

function LFT()
    return LFT(1,0,0,1)
end

# a --> 0, b-->1, and c--> oo
function LFT(a::Number, b::Number, c::Number)
    if a==b || b==c || a==c
        error("Three arguments must be distinct: "*string((a,b,c)))
    end

    if isinf(a)
        return LFT(0, b-c, 1, -c)
    end

    if isinf(b)
        return LFT(1, -a, 1, -c)
    end

    if isinf(c)
        return LFT(1, -a, 0, b-a)
    end

    # if all args are finite
    aa = (b-c)
    bb = (-a)*(b-c)
    cc = (b-a)
    dd = (-c)*(b-a)
    return LFT(aa,bb,cc,dd)
end

# a-->aa, b-->bb, c-->cc
function LFT(a::Number, aa::Number,
              b::Number, bb::Number,
              c::Number, cc::Number)
    f = LFT(a,b,c)
    g = LFT(aa,bb,cc)
    return inv(g)*f
end


#### Equality checking ####

# These need to be rewritten

function isequal(f::LFT, g::LFT)
    return f[0]==g[0] && f[1]==g[1] && f[Inf]==g[Inf]
    # h = f * inv(g)
    # I = h.M
    # return I[1,1]==I[2,2] && I[1,2]==I[2,1]==0
end

==(f::LFT,g::LFT) = isequal(f,g)

# Inverse transformation
function inv(L::LFT)
    a = L.M[1,1]
    b = L.M[1,2]
    c = L.M[2,1]
    d = L.M[2,2]
    return LFT(d,-b,-c,a)
end

# Composition
*(A::LFT, B::LFT) = LFT(A.M * B.M)

# Function application
function getindex(A::LFT, x::Number)
    if isinf(x)
        a = A.M[1,1]
        b = A.M[2,1]
        if b==0
            return complex_infinity
        end
        return a/b
    end
    w = A.M * [ x+0im ; 1.0+0im ]
    if w[2] == 0
        return complex_infinity
    end
    return w[1]/w[2]
end

# call(A::LFT, x::Number) = A[x]

(A::LFT)(x::Number) = A[x]

function show(io::IO, L::LFT)
    print(io, "LFT( ",
          L.M[1,1], " , ",
          L.M[1,2], " , ",
          L.M[2,1], " , ",
          L.M[2,2], " )"
          )
end


function hash(f::LFT, h::UInt64 = UInt64(0))
    z = 0.0 + 0.0*im # kludge to make -0.0 and -0.0im into +versions
    a = f[0]+z
    b = f[1]+z
    c = f[Inf]+z
    return hash(a,hash(b,hash(c,h)))
end


end # end of module "LFTs"
