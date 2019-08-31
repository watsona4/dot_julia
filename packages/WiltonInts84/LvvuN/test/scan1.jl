using WiltonInts84
using StaticArrays
using Test

p1 = SVector(0.0, 0.0, 0.0)
p2 = SVector(1.0, 0.0, 0.0)
p3 = SVector(0.0, 1.0, 0.0)
h = 0.1

x = -0.5 : 0.01 : 1.5
y = -0.5 : 0.01 : 1.5

r, R = 0.0, 0.15
fails = 0
M = zeros(typeof(h), length(x), length(y))
for i in eachindex(x)
    for j in eachindex(y)
        _c = SVector(x[i],y[j],h)
        try
            _I, _K = wiltonints(p1,p2,p3,_c,r,R,Val{0})
            M[i,j] = _I[2]
        catch
            # @show i j _c
            global fails += 1
        end
    end
end

# There are still some cases where the package fails,
# but at least lets make sure that number does not increase...
@test fails == 20
