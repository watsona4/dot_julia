using CompScienceMeshes
using Test
using SauterSchwabQuadrature

pI = point(1,5,3)
pII = point(2,5,3)
pIII = point(7,1,0)
pVI = point(10,11,12)
pVII = point(10,11,13)
pVIII = point(11,11,12)

Sourcechart = simplex(pI,pII,pIII)
Testchart = simplex(pVI,pVII,pVIII)

Accuracy = 12
pd = PositiveDistance(SauterSchwabQuadrature._legendre(Accuracy,0.0,1.0))

function integrand(x,y)
			return(((x-pI)'*(y-pVII))*exp(-im*1*norm(x-y))/(4pi*norm(x-y)))
end

function INTEGRAND(û,v̂)
   n1 = neighborhood(Testchart, û)
   n2 = neighborhood(Sourcechart, v̂)
   x = cartesian(n1)
   y = cartesian(n2)
   output = integrand(x,y)*jacobian(n1)*jacobian(n2)
   return(output)
end

result = sauterschwab_parameterized(INTEGRAND, pd)-
             verifintegral2(Sourcechart, Testchart, integrand, Accuracy)

@test norm(result) < 1.e-3
