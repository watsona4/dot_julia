module BracedErrors
using Decimals

export bracederror

function sigdig(d::Decimal, dig::Integer = 2)
	s = string(d.c)
	length(s) + d.q - dig
end

function getdig(d::Decimal, i::Integer)
	s = string(d.c)
	ind = -i + length(s) + d.q
	if 1 ≤ ind ≤ length(s)
		s[ind]
	elseif  ind > length(s)
		"0"
	elseif i ≤ 0
		"0"
	else
		""
	end
end

function get_val_str(d::Decimal, dig::Integer; delim = ".")

	i = max(0, length(string(d.c)) + d.q - 1):-1:min(0, dig)
	r = string(getdig.(d, i[i.≥0])...)
	if length(i[i.<0]) > 0
		r *= delim * string(getdig.(d, i[i.<0])...)
	end
	return r
end

get_err_str(d::Decimal, dig::Integer) = string(getdig.(d, (length(string(d.c)) + d.q - 1):-1:min(dig,0))...)

obracket = Dict(:r => "(", :s => "[", :q => "{", :a => "<", :l => "|", :^ => "^{", :_ => "_{")
cbracket = Dict(:r => ")", :s => "]", :q => "}", :a => ">", :l => "|", :^ => "}", :_ => "}")

"""
bracederror(μ::Real, σ::NTuple{N,Real}; dec::Int = 2, suff::NTuple{N,String} = ntuple(i->"", N), bracket::NTuple{N,Symbol} = ntuple(i->:r, N))
Providing a value `μ` and a tuple of errors `σ` it creates a string with the value followed by the errors in brackets.

This notation is commonly used in sciencific papers and this function provide an automated way of getting the appropriate string.
# Keyword Arguments
- `dec::Int = 2`: number of decimals to round the errors to
- `suff::NTuple{AbstractString} = ("",)`: optional suffix after the brackets
- `bracket::NTuple{Symbol} = :r`: type of the brackets
- `delim = "."`: the delimeter string
`bracket` can take the values: $(keys(obracket)) which correspond to $(values(obracket)).

For conviniece following method are also added:
`bracederror(μ::Real, σ::Real; dec::Int = 2, suff::String = "", bracket::Symbol = :r, kwargs...)`
`bracederror(μ::Real, σ::Real...; dec::Int = 2, suff = ntuple(i->"",length(σ)), bracket = ntuple(i->:r, length(σ)), kwargs...)`
"""
function bracederror(μ::Real, σ::NTuple{N,Real}; dec::Int = 2, suff::NTuple{N,AbstractString} = ntuple(i->"", N), bracket::NTuple{N,Symbol} = ntuple(i->:r, N), delim::AbstractString = ".") where N

	dμ = decimal(μ)
	dσ = decimal.(round.(σ, RoundUp, sigdigits = dec))

	dig = min(sigdig(dμ, dec), sigdig.(dσ, dec)...)

	r = dμ.s == 0 ? "" : "-"
	r *= get_val_str(decimal(round(μ, digits = max(0,-dig))), dig; delim = delim)
	for i ∈ 1:length(dσ)
		r *= obracket[bracket[i]] * get_err_str(dσ[i], dig) * cbracket[bracket[i]] * suff[i]
	end

	return r
end

bracederror(μ::Real, σ::Real; dec::Int = 2, suff::String = "", bracket::Symbol = :r, kwargs...) = bracederror(μ, (σ,); dec = dec, suff = (suff,), bracket = (bracket,), kwargs...)
bracederror(μ::Real, σ::Real...; dec::Int = 2, suff = ntuple(i->"",length(σ)), bracket = ntuple(i->:r, length(σ)), kwargs...) = bracederror(μ, σ; dec = dec, suff = suff, bracket = bracket, kwargs...)


### unexported due to common used symbol ±
μ ± ε = bracederror(μ, ε...)
±(μ, ε...; kwargs...) = bracederror(μ, ε...; kwargs...)

end # BracedErrors

