using Nemo

RR, x = PolynomialRing(Nemo.QQ, "x")

n = 64 #degree
P = zero(RR)
bernoulli_cache(n)
for k = 0:n
    global P
    coefficient = (binom(n,k))*(bernoulli(n-k))
    P = P + coefficient*x^k
end #P is now the Bernoulli polynomial of degree 64

using Ccluster

bInit = [fmpq(0,1),fmpq(0,1),fmpq(100,1)] #box centered in 0 + sqrt(-1)*0 with width 100
precision = 53                          #get clusters of size 2^-53
Coeffs = ccluster(P, bInit, precision)

function getApproximation( dest::Ptr{acb_poly}, preci::Int )

    function getApp(prec::Int)::Nemo.acb_poly
        eps=fmpq(1,fmpz(2)^prec)
        R = Nemo.RealField(prec)
        C = Nemo.ComplexField(prec)
        CC, y = PolynomialRing(C, "y")
        res = zero(CC)
        for i=1:n
            btemp = [ Coeffs[i][2][1], Coeffs[i][2][2], 2*Coeffs[i][2][3] ]
            temp = ccluster(P, btemp, prec)
            approx::Nemo.acb = C( Nemo.ball(R(temp[1][2][1]),R(eps)), Nemo.ball(R(temp[1][2][2]),R(eps)))
            res = res + approx*y^(i-1)
        end
        return res
    end
    
    precTemp::Int = 2*preci
    poly = getApp(precTemp)
    
    while Ccluster.checkAccuracy( poly, preci ) == 0
            precTemp = 2*precTemp
            poly = getApp(precTemp)
    end
    
    Ccluster.ptr_set_acb_poly(dest, poly)
end

bInit = [fmpq(0,1),fmpq(0,1),fmpq(100,1)] #box centered in 0 + sqrt(-1)*0 with width 100
precision = 53                          #get clusters of size 2^-53
Roots = ccluster(getApproximation, bInit, precision, verbosity="silent")

using CclusterPlot #only if you have installed CclusterPlot.jl

plotCcluster(Roots, bInit, focus=true) #use true instead of false to focus on clusters
