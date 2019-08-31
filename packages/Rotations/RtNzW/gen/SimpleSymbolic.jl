module SimpleSymbolic

struct S
    x::Any
end

Base.show(io::IO, s::S) = print(io, s.x)

function Base.:+(s1::S, s2::S)
    if s1.x == 0
        return s2
    elseif s2.x == 0
        return s1
    else
        if isa(s1.x, Number) && isa(s2.x, Number)
            return S(s1.x + s2.x)
        else
            return S(string(s1.x) * " + " * string(s2.x))
        end
    end
end

function Base.:*(s1::S, s2::S)
    if s1.x == 1
        return s2
    elseif s2.x == 1
        return s1
    elseif s1.x == 0 || s2.x == 0
        return S(0)
    else
        if isa(s1.x, Number) && isa(s2.x, Number)
            return S(s1.x*s2.x)
        else
            if isa(s1.x, String) && isa(s2.x, String)
                if s1.x[1] == '-' && s2.x[1] == '-'
                    return S(string(s1.x[2:end]) * "*" * string(s2.x[2:end]))
                end
            end
            return S(string(s1.x) * "*" * string(s2.x))
        end
    end
end

using StaticArrays

mx1 = @SMatrix [S(1)  S(0)        S(0);
                S(0)  S("cosθ₁")  S("-sinθ₁");
                S(0)  S("sinθ₁")  S("cosθ₁")]

my1 = @SMatrix [S("cosθ₁")   S(0)  S("sinθ₁");
                S(0)         S(1)  S(0);
                S("-sinθ₁")  S(0)  S("cosθ₁")]

mz1 = @SMatrix [S("cosθ₁")  S("-sinθ₁")  S(0);
                S("sinθ₁")  S("cosθ₁")   S(0);
                S(0)        S(0)         S(1)]

mx2 = @SMatrix [S(1)  S(0)        S(0);
                S(0)  S("cosθ₂")  S("-sinθ₂");
                S(0)  S("sinθ₂")  S("cosθ₂")]

my2 = @SMatrix [S("cosθ₂")   S(0)  S("sinθ₂");
                S(0)         S(1)  S(0);
                S("-sinθ₂")  S(0)  S("cosθ₂")]

mz2 = @SMatrix [S("cosθ₂")  S("-sinθ₂")  S(0);
                S("sinθ₂")  S("cosθ₂")   S(0);
                S(0)        S(0)         S(1)]

mx3 = @SMatrix [S(1)  S(0)        S(0);
                S(0)  S("cosθ₃")  S("-sinθ₃");
                S(0)  S("sinθ₃")  S("cosθ₃")]

my3 = @SMatrix [S("cosθ₃")   S(0)  S("sinθ₃");
                S(0)         S(1)  S(0);
                S("-sinθ₃")  S(0)  S("cosθ₃")]

mz3 = @SMatrix [S("cosθ₃")  S("-sinθ₃")  S(0);
                S("sinθ₃")  S("cosθ₃")   S(0);
                S(0)        S(0)         S(1)]

v = @SVector [S("v[1]"), S("v[2]"), S("v[3]")]


myx = my1 * mx2
mxy = mx1 * my2
mxz = mx1 * mz2
mzx = mz1 * mx2
mzy = mz1 * my2
myz = my1 * mz2

myxy = my1 * mx2 * my3
myxz = my1 * mx2 * mz3
mxyx = mx1 * my2 * mx3
mxyz = mx1 * my2 * mz3
mxzx = mx1 * mz2 * mx3
mxzy = mx1 * mz2 * my3
mzxz = mz1 * mx2 * mz3
mzxy = mz1 * mx2 * my3
mzyz = mz1 * my2 * mz3
mzyx = mz1 * my2 * mx3
myzy = my1 * mz2 * my3
myzx = my1 * mz2 * mx3

export S, mx1, my1, mz1, mx2, my2, mz2, mx3, my3, mz3, v, mxy, myx, mxz, mzx, mzy, myz,
    myxy, myxz, mxyx, mxyz, mxzx, mxzy, mzxz, mzxy, mzyz, mzyx, myzy, myzx


end # module
