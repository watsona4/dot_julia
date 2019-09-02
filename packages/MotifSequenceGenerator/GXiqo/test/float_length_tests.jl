using Test
using MotifSequenceGenerator

struct FloatShout
  shout::String
  dur::Float64
  start::Float64
end

using Random

let

N = 5

shouts = [FloatShout(uppercase(randstring(rand(3:5))), rand()+1, rand()) for k in 1:N]
shoutlimits(s::FloatShout) = (s.start, s.start + s.dur);
shouttranslate(s::FloatShout, n) = FloatShout(s.shout, s.dur, s.start + n);
q = 10.0

function shoutlens(R)
    l = 0
    for r in R
        a, b = shoutlimits(r)
        l += b - a
    end
    return l
end

@testset "Float Length δq=$(δq)" for δq in [1.0, 2.0]
    for j in 1:N
        r, s = random_sequence(shouts, q, shoutlimits, shouttranslate, δq)
        ℓ = shoutlens(r)
        @test q - δq ≤ ℓ ≤ q + δq
    end
end

@testset "Float Length, Weights, δq=$(δq)" for δq in [1.0, 2.0]
    weights = rand(1:5, N)
    for j in 1:N
        r, s = random_sequence(shouts, q, shoutlimits, shouttranslate, δq;
        weights = weights)
        ℓ = shoutlens(r)
        @test q - δq ≤ ℓ ≤ q + δq
    end
end

using MotifSequenceGenerator: DeadEndMotifs
@test_throws ArgumentError random_sequence(shouts, q, shoutlimits, shouttranslate, 0.0)
@test_throws DeadEndMotifs random_sequence(shouts, q, shoutlimits, shouttranslate, 0.000001)

end
