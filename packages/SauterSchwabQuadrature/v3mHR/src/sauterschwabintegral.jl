using FastGaussQuadrature

abstract type SauterSchwabStrategy end

struct CommonFace{A}       <: SauterSchwabStrategy qps::A end
struct CommonEdge{A}       <: SauterSchwabStrategy qps::A end
struct CommonVertex{A}     <: SauterSchwabStrategy qps::A end
struct PositiveDistance{A} <: SauterSchwabStrategy qps::A end

function _legendre(n,a,b)
    x, w = FastGaussQuadrature.gausslegendre(n)
    w .*= (b-a)/2
    x = (x.+1)/2*(b-a).+a
    collect(zip(x,w))
end

function sauterschwab_parameterized(integrand, method::CommonFace)

	qps = method.qps
	sum(w1*w2*w3*w4*k3p_cf(integrand, η1, η2, η3, ξ)
		for (η1, w1) in qps, (η2, w2) in qps, (η3, w3) in qps, (ξ, w4) in qps)
end


function sauterschwab_parameterized(integrand, method::CommonEdge)

	qps = method.qps
	sum(w1*w2*w3*w4*k3p_ce(integrand, η1, η2, η3, ξ)
		for (η1, w1) in qps, (η2, w2) in qps, (η3, w3) in qps, (ξ, w4) in qps)
end


function sauterschwab_parameterized(integrand, method::CommonVertex)

	qps = method.qps
	sum(w1*w2*w3*w4*k3p_cv(integrand,η1, η2, η3, ξ)
		for (η1, w1) in qps, (η2, w2) in qps, (η3, w3) in qps, (ξ, w4) in qps)
end


function sauterschwab_parameterized(integrand, method::PositiveDistance)

	qps = method.qps
	sum(w1*w2*w3*w4*k3p_pd(integrand, η1, η2, η3, ξ)
		for (η1, w1) in qps, (η2, w2) in qps, (η3, w3) in qps, (ξ, w4) in qps)
end
