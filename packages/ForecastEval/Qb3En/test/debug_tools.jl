using StatsBase, Distributions, DependentBootstrap
using ForecastEval

#Function for generating data
function gen_data(testtype::Symbol, N::Int)
	y = randn(N);
	if testtype == :mean
		x = Vector{Float64}[ randn(N) + 0.1*k for k = -10:1:10 ]
		xbc = randn(N)
	elseif testtype == :var
		x = Vector{Float64}[ sqrt(k) * randn(N) for k = 1.5:-0.05:0.5 ]
		xbc = randn(N)
	elseif testtype == :varsmall
		x = Vector{Float64}[ sqrt(k) * randn(N) for k = 1.2:-0.02:0.8 ]
		xbc = randn(N)
	elseif testtype == :same
		x = Vector{Float64}[ randn(N) for k = 1:20 ]
		xbc = randn(N)
	else
		error("Invalid testtype")
	end
	return(y, x, xbc)
end
vvtomat{T}(x::Vector{Vector{T}})::Matrix{T} = T[ x[m][n] for n = 1:length(x[1]), m = 1:length(x) ]
mattovv{T}(x::Matrix{T})::Vector{Vector{T}} = Vector{T}[ x[:, m] for m = 1:size(x, 2) ]


#----------------------------------------
# DEBUG TOOLS FOR DIEBOLD-MARIANO
#----------------------------------------
(y, x, xbc) = gen_data(:var, 1000);
dmB = Array(DMTest, length(x));
dmH = Array(DMTest, length(x));
for k = 1:length(x)
	xL = (x[k] - y).^2;
	xbcL = (xbc - y).^2;
	lD = xL - xbcL;
	dmB[k] = dm(lD, dmmethod=:boot);
	dmH[k] = dm(lD, dmmethod=:hac);
end
pvalB = Float64[ dmB[k].pvalue for k = 1:length(x) ];
bestB = Int[ dmB[k].bestinput for k = 1:length(x) ];
tailB = Int[ dmB[k].tailregion for k = 1:length(x) ];
statB = Float64[ dmB[k].teststat for k = 1:length(x) ];
println("pvalB = $pvalB");
println("bestB = $bestB");
println("tailB = $tailB");
println("statB = $statB");
pvalH = Float64[ dmH[k].pvalue for k = 1:length(x) ];
bestH = Int[ dmH[k].bestinput for k = 1:length(x) ];
tailH = Int[ dmH[k].tailregion for k = 1:length(x) ];
statH = Float64[ dmH[k].teststat for k = 1:length(x) ];
println("pvalH = $pvalH");
println("bestH = $bestH");
println("tailH = $tailH");
println("statH = $statH");

#----------------------------------------
# DEBUG TOOLS FOR REALITY CHECK
#----------------------------------------
M = 100;
rcOut = Array(RCTest, M);
for m = 1:M
	(y, x, xbc) = gen_data(:varsmall, 1000);
	xbcloss = (xbc - y).^2;
	ld = Vector{Float64}[ (x[k] - y).^2 - xbcloss for k = 1:length(x) ];
	rcOut[m] = rc(vvtomat(ld), alpha=0.05)
end
pvalRC = Float64[ rcOut[m].pvalue for m = 1:M ]
rejH0RC = Int[ rcOut[m].rejH0 for m = 1:M ]
println("pval = $pvalRC")
println("rejH0 = $rejH0RC")
println("rej prop = $(sum(rejH0RC)/M)")

#----------------------------------------
# DEBUG TOOLS FOR SPA TEST
#----------------------------------------
M = 200;
spaOut = Array(SPATest, M);
for m = 1:M
	(y, x, xbc) = gen_data(:varsmall, 1000);
	xbcloss = (xbc - y).^2;
	ld = Vector{Float64}[ (x[k] - y).^2 - xbcloss for k = 1:length(x) ];
	spaOut[m] = spa(vvtomat(ld), alpha=0.05)
end
pvalSPAu = Float64[ spaOut[m].pvalue_u for m = 1:M ];
pvalSPAc = Float64[ spaOut[m].pvalue_c for m = 1:M ];
pvalSPAl = Float64[ spaOut[m].pvalue_l for m = 1:M ];
pvalSPAauto = Float64[ spaOut[m].pvalueauto for m = 1:M ];
rejH0SPA = Int[ spaOut[m].rejH0 for m = 1:M ];
println("pval_u = $pvalSPAu")
println("pval_u rej prop = $(sum(pvalSPAu .< 0.05) / M)")
println("pval_l = $pvalSPAl")
println("pval_l rej prop = $(sum(pvalSPAl .< 0.05) / M)")
println("pval_c = $pvalSPAc")
println("pval_c rej prop = $(sum(pvalSPAc .< 0.05) / M)")
println("pval_auto = $pvalSPAauto")
println("pval_auto rej prop = $(sum(pvalSPAauto .< 0.05) / M)")
println("rejH0 = $rejH0SPA")
println("rej prop = $(sum(rejH0SPA)/M)")

#----------------------------------------
# DEBUG TOOLS FOR MCS
#----------------------------------------
M = 10;
mcsOut = Array(MCSTest, M);
for m = 1:M
	(y, x, xbc) = gen_data(:varsmall, 1000);
	xloss = Vector{Float64}[ (x[k] - y).^2 for k = 1:length(x) ];
	mcsOut[m] = mcs(vvtomat(xloss), alpha=0.05);
end
inQFLine = Vector{Int}[ mcsOut[m].inQF for m = 1:M ];
outQFLine = Vector{Int}[ mcsOut[m].outQF for m = 1:M ];
pValQFLine = Vector{Float64}[ mcsOut[m].pvalueQF for m = 1:M ];
inMTLine = Vector{Int}[ mcsOut[m].inMT for m = 1:M ];
outMTLine = Vector{Int}[ mcsOut[m].outMT for m = 1:M ];
pValMTLine = Vector{Float64}[ mcsOut[m].pvalueMT for m = 1:M ];
println("")
for m = 1:M ; println("$(m)) inQF = $(inQFLine[m])") ; end ;
println("")
for m = 1:M ; println("$(m)) outQF = $(outQFLine[m])") ; end ;
println("")
for m = 1:M ; println("$(m)) pValQF = $(pValQFLine[m])") ; end ;
println("")
println("")
for m = 1:M ; println("$(m)) inMT = $(inMTLine[m])") ; end ;
println("")
for m = 1:M ; println("$(m)) outMT = $(outMTLine[m])") ; end ;
println("")
for m = 1:M ; println("$(m)) pValMT = $(pValMTLine[m])") ; end ;
