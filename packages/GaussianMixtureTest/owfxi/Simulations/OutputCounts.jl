
import GaussianMixtureTest
using DelimitedFiles
using StatsBase:counts


Ctrue = parse(Int, ARGS[1]); B=200
C_max = max(5, (2*Ctrue - 1))

n_vec = [80, 100, 200, 300, 500, 800, 1000]
nn=length(n_vec)
bic_choice = fill(0, B, nn)
ks_choice = fill(0, B, nn)
ks_choice_tapering = fill(0, B, nn)
thecounts = fill(0, C_max, nn, 3)
for ik in 1:nn
    n2 = n_vec[ik]
    teststat = readdlm("compare_$(Ctrue)_$(n2).csv")
    for b in 1:B
        bic_choice[b, ik] = findmin(teststat[b, 1:C_max])[2]
        for C in 1:C_max
            if teststat[b, C_max+C] >= log(n2)/n2
                ks_choice_tapering[b, ik] = C
                break
            end
        end
        for C in 1:C_max
            if teststat[b, C_max + C] >= 0.05
                ks_choice[b, ik] = C
                break
            end
        end
    end

    thecounts[:, ik, 1] = counts(bic_choice[:,ik], 1:C_max)
    thecounts[:, ik, 2] = counts(ks_choice[:,ik], 1:C_max)
    thecounts[:, ik, 3] = counts(ks_choice_tapering[:,ik], 1:C_max)
end
res = transpose(thecounts[Ctrue,:,:]) ./ B
display(res)
println()
using RCall
@rput res n_vec

R"""
library(xtable)
res = as.data.frame(res)
colnames(res) = n_vec
rownames(res) = c("BIC", "Seq. Test 0.05", "Seq. Test log(n)/n")
print(xtable(res))
"""
