using CompScienceMeshes
using Test
using SauterSchwabQuadrature

pI = point(1,5,3)
pII = point(2,5,3)
pIII = point(7,1,0)

Sourcechart = Testchart = simplex(pI, pII, pIII)

Accuracy = 12
cf = CommonFace(SauterSchwabQuadrature._legendre(Accuracy,0.0,1.0))

function integrand(x,y)
			return(((x-pI)'*(y-pII))*exp(-im*1*norm(x-y))/(4pi*norm(x-y)))
end

function INTEGRAND(û,v̂)
	n1 = neighborhood(Testchart, û)
	n2 = neighborhood(Sourcechart, v̂)
	x = cartesian(n1)
	y = cartesian(n2)
	output = integrand(x,y)*jacobian(n1)*jacobian(n2)

return(output)
end

result = sauterschwab_parameterized(INTEGRAND, cf)-
		   verifintegral1(Sourcechart, Testchart, integrand, Accuracy)

@test norm(result) < 1.e-3

include(joinpath(dirname(@__FILE__),"numquad.jl"))

# Test the use of SauterSchwabQuadrature with the kernel generator utility
# using BEAST
using CompScienceMeshes
using StaticArrays

t1 = simplex(
    @SVector[0.180878, -0.941848, -0.283207],
    @SVector[0.0, -0.980785, -0.19509],
    @SVector[0.0, -0.92388, -0.382683])

rt = RTRefSpace{Float64}()
kernel_cf(x,y) = 1/norm(cartesian(x)-cartesian(y))
igd = generate_integrand_uv(kernel_cf, rt, rt, t1, t1)

t1 = simplex(
    @SVector[0.180878, -0.941848, -0.283207],
    @SVector[0.0, -0.980785, -0.19509],
    @SVector[0.0, -0.92388, -0.382683])

i5 = sauterschwab_parameterized(igd, CommonFace(SauterSchwabQuadrature._legendre(5,0.0,1.0)))
i10 = sauterschwab_parameterized(igd, CommonFace(SauterSchwabQuadrature._legendre(10,0.0,1.0)))

iref = numquad_cf(kernel_cf, rt, rt, t1, t1, zero(i5))

# # BEAST will arbitrate
# tqd = BEAST.quadpoints(rt, [t1], (12,))
# bqd = BEAST.quadpoints(rt, [t1], (13,))
#
# SE_strategy = BEAST.WiltonSEStrategy(
#   tqd[1,1],
#   BEAST.DoubleQuadStrategy(
# 	tqd[1,1],
# 	bqd[1,1],
#   ),
# )
#
# op = BEAST.MWSingleLayer3D(0.0, 4.0π, 0.0)
# z2 = zeros(3,3)
# BEAST.momintegrals!(op, rt, rt, t1, t1, z2, SE_strategy)
#
# @test i5  ≈ iref atol=1e-3
# @test i10 ≈ iref atol=1e-3
# @test i10 ≈ i5   atol=1e-6
