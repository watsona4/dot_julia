# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module EulerTransforms

using Nemo, NumberTheory

export ModuleEulerTransforms
export EulerTransform
export V006171, L006171, V107895, L107895, V061256, L061256
export V190905, L190905, V275585, L275585, V290351, L290351
export V052847, L052847

"""
* V006171, L006171, V107895, L107895, V061256, L061256, V190905, L190905, V275585, L275585, V290351, L290351
"""
const ModuleEulerTransforms = ""

"""
Return the Euler transform of f.
"""
function EulerTransform(f::Function)
    function E(n)
        haskey(CacheET, (f, n)) && return CacheET[(f, n)]
        n == 0 && return ZZ(1)
        a(j) = ZZ(sum(d*f(Int(d)) for d in Divisors(j)))
        b = sum(a(j) * E(n-j) for j in 1:n)
        r = div(b, n)
        CacheET[(f, n)] = r
        return r
    end
end

const CacheET = Dict{Tuple{Function, Int}, fmpz}()

"""
Return the number of factorization patterns of polynomials of degree n over integers.
"""
V006171(n) = EulerTransform(τ)(n)

"""
Return a list of length len of the Euler transform of tau.
"""
L006171(len) = [V006171(n) for n in 0:len-1]

"""
Return the Euler transform of sigma.
"""
V061256(n) = EulerTransform(σ)(n)

"""
Return a list of length len of the Euler transform of sigma.
"""
L061256(len) = [V061256(n) for n in 0:len-1]

"""
Return the Euler transform of sigma_2.
"""
V275585(n) = EulerTransform(σ2)(n)

"""
Return a list of length len of the Euler transform of sigma_2.
"""
L275585(len) = [V275585(n) for n in 0:len-1]

"""
Return the Euler transform of the factorial.
"""
V107895(n) = EulerTransform(fac)(n)

"""
Return a list of length len of the Euler transform of the factorial.
"""
L107895(len) = [V107895(n) for n in 0:len-1]

"""
Return the Euler transform of the swinging factorial (A056040).
"""
V190905(n) = EulerTransform(n -> div(fac(n), fac(div(n, 2))^2))(n)

"""
Return a list of length len of the Euler transform of the swinging factorial.
"""
L190905(len) = [V190905(n) for n in 0:len-1]

"""
Return the Euler transform of the Bell numbers.
"""
V290351(n) = EulerTransform(Nemo.bell)(n)

"""
Return a list of length len of the Euler transform of the Bell numbers.
"""
L290351(len) = [V290351(n) for n in 0:len-1]

"""
Return the Euler transform of [0, 1, 2, 3, ...].
"""
V052847(n) = EulerTransform(k -> k-1)(n)

"""
Return a list of length len of the Euler transform of [0, 1, 2, 3, ...].
"""
L052847(len) = [V052847(n) for n in 0:len-1]


#START-TEST-########################################################

using Test, SeqTests

function test()

    @testset "EulerTransform" begin

        if is_oeis_installed()

            L = [L107895, L190905, L061256, L275585, L006171, L290351, L052847]
            SeqTest(L, 'L')

            V = [V107895, V190905, V061256, V275585, V006171]
            for v in V SeqTest(v, 'V', 0) end
        end
    end
end

function demo()
end

"""
for n in 0:150 V107895(n) end ::
    0.303605 seconds (1.01 M allocations: 32.276 MiB, 29.90% gc time)
"""
function perf()
    @time (for n in 0:150 V107895(n) end)
end

function main()
    test()
    demo()
    perf()
end

main()

end # module
