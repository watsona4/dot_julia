
"""
	pvaluelocal(d::ContinuousUnivariateDistribution, x::Number ; tail::Symbol=:both)::Float64
	pvaluelocal{T<:Number}(d::Vector{T}, x::Number ; tail::Symbol=:both, as::Bool=false)::Float64

Obtain the p-value associated with the inputs.
d::ContinuousUnivariateDistribution -> d is the distribution under the null and x is the test statistic.
d::Vector{T} -> d is a bootstrapped vector of test statistics and x is the value of the test statistic under the null.
"""
function pvaluelocal(d::ContinuousUnivariateDistribution, x::Number ; tail::Symbol=:both)::Float64
	if tail == :both
		lpv = cdf(d, x)
		rpv = ccdf(d, x)
		lpv < rpv && return min(2*lpv, 1.0)
		return min(2*rpv, 1.0)
	elseif tail == :left
	    return cdf(d, x)
	elseif tail == :right
	    return ccdf(d, x)
	else
		error("Keyword argument tail=$(tail) is invalid")
	end
end
function pvaluelocal(xVec::Vector{T}, x::Number ; tail::Symbol=:both, as::Bool=false)::Float64 where {T<:Number}
	!as && (xVec = sort(xVec))
	i = searchsortedlast(xVec, x)
	if tail == :both
		lpv = Float64(i / length(xVec))
		rpv = 1.0 - lpv
		lpv < rpv && return min(2*lpv, 1.0)
		return min(2*rpv, 1.0)
	elseif tail == :left
		return Float64(i / length(xVec))
	elseif tail == :right
		return Float64(1.0 - (i / length(xVec)))
	else
		error("Keyword argument tail=$(tail) is invalid")
	end
end
