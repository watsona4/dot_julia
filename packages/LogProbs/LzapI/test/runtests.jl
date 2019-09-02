using LogProbs
using Test

p = LogProb(0.2)
q = LogProb(0.5)
r = LogProb(0.1)

@test p * q ≈ r
@test float(p+q) ≈ 0.7
@test log(p) == -1.6094379124341003
@test information(q) ≈ 1
@test r * LogProb(2) ≈ p
@test q - p ≈ LogProb(.3)
@test p / q ≈ LogProb(.4)
@test p + zero(LogProb) ≈ p
@test p *  one(LogProb) ≈ p
@test p < q
@test LogProb(0) < p

@test one(LogProb).log == 0
@test zero(LogProb).log == -Inf

@test string(p) == "LogProb(0.2)"

@test let d = Dict(LogProb(x) => x for x in [0.2, 0.5, 0.1])
    (d[p], d[q], d[r]) == (0.2, 0.5, 0.1)
end

@test let s = rand(LogProb)
    s.log == log(s)
end
