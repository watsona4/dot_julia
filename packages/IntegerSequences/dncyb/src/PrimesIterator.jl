# This file includes portions that were formerly part of Julia in modified form.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module PrimesIterator

export ModulePrimesIterator
export Primes, PrimePi, PrimeSieve

"""
* Primes, PrimePi, PrimeSieve
"""
const ModulePrimesIterator = ""

# Primes generating functions

const wheel         = [4,  2,  4,  2,  4,  6,  2,  6]
const wheel_primes  = [7, 11, 13, 17, 19, 23, 29, 31]
const wheel_indices = [0,0,0,0,0,0,0,1,1,1,1,2,2,3,3,3,3,4,4,5,5,5,5,6,6,6,6,6,6,7,7]

@inline function wheel_index(n)
    d, r = divrem(n - 1, 30)
    return 8d + wheel_indices[r + 2]
end

@inline function wheel_prime(n)
    d, r = (n - 1) >>> 3, (n - 1) & 7
    return 30d + wheel_primes[r + 1]
end

#Internal function
function mask(limit::Int)
    limit < 7 && throw(ArgumentError("The condition limit ≥ 7 must be met."))
    n = wheel_index(limit)
    m = wheel_prime(n)
    sieve = ones(Bool, n)
    @inbounds for i = 1:wheel_index(isqrt(limit))
        if sieve[i]
            p = wheel_prime(i)
            q = p^2
            j = (i - 1) & 7 + 1
            while q ≤ m
                sieve[wheel_index(q)] = false
                q += wheel[j] * p
                j = j & 7 + 1
            end
        end
    end
    return sieve
end

#Internal function
function mask(lo::Int, hi::Int)
    7 ≤ lo ≤ hi || throw(ArgumentError("The condition 7 ≤ lo ≤ hi must be met."))
    lo == 7 && return mask(hi)
    wlo, whi = wheel_index(lo - 1), wheel_index(hi)
    m = wheel_prime(whi)
    sieve = ones(Bool, whi - wlo)
    hi < 49 && return sieve
    small_sieve = mask(isqrt(hi))
    @inbounds for i = 1:length(small_sieve)  # don't use eachindex here
        if small_sieve[i]
            p = wheel_prime(i)
            j = wheel_index(2 * div(lo - p - 1, 2p) + 1)
            q = p * wheel_prime(j + 1)
            j = j & 7 + 1
            while q ≤ m
                sieve[wheel_index(q) - wlo] = false
                q += wheel[j] * p
                j = j & 7 + 1
            end
        end
    end
    return sieve
end

"""
Return the prime sieve, as a `BitArray`, of the positive integers (from `lo`, if specified) up to `hi`. Useful when working with either primes or composite numbers.
"""
function PrimeSieve(lo::Int, hi::Int)
    0 < lo ≤ hi || throw(ArgumentError("The condition 0 < lo ≤ hi must be met."))
    sieve = falses(hi - lo + 1)
    lo ≤ 2 ≤ hi && (sieve[3 - lo] = true)
    lo ≤ 3 ≤ hi && (sieve[4 - lo] = true)
    lo ≤ 5 ≤ hi && (sieve[6 - lo] = true)
    hi < 7 && return sieve
    wheel_sieve = mask(max(7, lo), hi)
    lsi = lo - 1
    lwi = wheel_index(lsi)
    @inbounds for i = 1:length(wheel_sieve)   # don't use eachindex here
        sieve[wheel_prime(i + lwi) - lsi] = wheel_sieve[i]
    end
    return sieve
end

function PrimeSieve(lo::T, hi::T) where {T <: Integer}
    lo ≤ hi ≤ typemax(Int) && return PrimeSieve(Int(lo), Int(hi))
    throw(ArgumentError("Both endpoints of the interval to sieve must be ≤ $(typemax(Int)), got $lo and $hi."))
end

PrimeSieve(limit::Int) = PrimeSieve(1, limit)

function PrimeSieve(n::Integer)
    n ≤ typemax(Int) && return PrimeSieve(Int(n))
    throw(ArgumentError("Requested number of primes must be ≤ $(typemax(Int)), got $n."))
end

"""
Return the collection of the prime numbers (from `lo`, if specified) up to `hi`.
"""
function Primes(lo::Int, hi::Int)
    lo ≤ hi || throw(ArgumentError("The condition lo ≤ hi must be met."))
    list = Int[]
    lo ≤ 2 ≤ hi && push!(list, 2)
    lo ≤ 3 ≤ hi && push!(list, 3)
    lo ≤ 5 ≤ hi && push!(list, 5)
    hi < 7 && return list
    lo = max(2, lo)
    sizehint!(list, 5 + floor(Int, hi / (log(hi) - 1.12) - lo / (log(lo) - 1.12 * (lo > 7))))
    sieve = mask(max(7, lo), hi)
    lwi = wheel_index(lo - 1)
    # don't use eachindex here
    @inbounds for i = 1:length(sieve)
        sieve[i] && push!(list, wheel_prime(i + lwi))
    end
    return list
end

Primes(n::Int) = Primes(1, n)

"""
Return the number of primes ``≤ n``.
"""
PrimePi(n::Int) = length(Primes(1, n))

#START-TEST-########################################################

using Test

function test()
    @testset "Primes" begin
        @test PrimePi(2^14) == 1900
        @test PrimePi(10^6) == 78498
    end
end

function demo()
    println(Primes(0, 100))
    println(Primes(90, 100))
    println(PrimePi(10000))
end

"""
primepi = PrimePi(1000000)
0.005080 seconds (5 allocations: 876.141 KiB)
"""
function perf()
    @time primepi = PrimePi(1000000)
end

function main()
    test()
    demo()
    perf()
end

main()

end # module

#=

[2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]
[97]
1229

  0.005080 seconds (5 allocations: 876.141 KiB)

=#
