# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module Counts
using Nemo, NumberTheory

export ModuleCounts
export L000961, L002808, L005117, L013928, L025528, L065515
export L065855, L069637, L246547, L246655, L000720
export A007917, A151800, A257993
export PreviousPrime, NextPrime, PrimePiList
export takeFirst, Nth, Count, List, HilbertHotel

"""
* PreviousPrime, NextPrime, PrimePiList, takeFirst, Nth, Count, List, HilbertHotel
* L000961, L002808, L005117, L013928, L025528, L065515, L065855, L069637, L246547, L246655, L000720, A007917, A151800, A257993
"""
const ModuleCounts = ""

"""
Return a list of length len of integers ``≥ 0`` which are isA.
"""
function List(len, isA::Function)
    len ≤ 0 && return fmpz[]
    j, c = Int(0), Int(1)
    A = fill(ZZ(0), len)
    while c <= len
        if isA(j)
            A[c] = fmpz(j)
            c += 1
        end
        j += 1
    end
    A
end

"""
Iverson brackets.
"""
ι(b) = b ? 1 : 0

"""
Inverse Iverson brackets.
"""
ιι(n) = n == 0 ? true : false
 # The Unix way: A successful command returns a 0, while an unsuccessful one
 # returns a non-zero value that usually can be interpreted as an error code.

"""
Return a iterator of length n which has value 1 if isA(i) is true and otherwise 0.
"""
function Indicators(n, isA::Function)
    (ι(isA(i)) for i in 0:n - 1)
end

"""
Return a list of length len which gives the numbers of integers ≤ n which are isA. Integers start at ``n=0``.
```
julia> CountList(8, isPrime)
[0, 0, 1, 2, 2, 3, 3, 4]
```
"""
CountList(len::Int, isA::Function) = Accumulate(Indicators(len, isA))

# Consider two sequences A and invA. We say invA is the left inverse of A iff
# invA(A(n)) = n and A(n) is the least number m such that A(invA(m)) = A(n).
# A(invA(n)) = n if and only if isA(n) = true where 'isA' is the indicator
# function of the sequence A.
# We introduce 'Count' as the left inverse of 'Nth'. For example
# if Nth(n) = NthPrime(n) then Count(n) = PrimePi(n) (A000720).

"""
Return the numbers of integers in the range 0:n which are isA.
```
julia> Count(8, isPrime)
4
```
"""
Count(n::Int, isAb::Function) = Base.count((isAb(i) for i in 0:n))

"""
Return the numbers of integers in the range a:b which are isA.
```
julia> Count(3:8, isPrime)
3
```
"""
Count(r, isAb::Function) = Base.count((isAb(i) for i in r))

"""
Return a SeqArray listing the values satisfying the predicate isA for arguments ``0 ≤ x ≤ `` bound.
```
julia> FindUpTo(7, isPrime)
[2, 3, 5, 7]
```
"""
function FindUpTo(bound, isA::Function)
    bound < 0 && return fmpz[]
    filter(isA, 0:bound)
end

"""
Return the first ``n`` numbers satisfying the predicate isA.
"""
takeFirst(isA, n) = Iterators.take(Iterators.filter(isA, Iterators.countfrom(1)), n)

"""
Return a iterator listing the values satisfying the predicate isA for arguments in ``0 ≤ n ≤ bound .``
"""
function IterateUpTo(bound, isA::Function)
    (i for i in 0:bound if isA(i))
end

"""
Returns an integer which is the highest index in `b` for the value `a`. Whenever `a` is not a member of `b` it returns -1.
```
julia> L = List(10, isPrime); IndexIn(13, L)
5
```
"""
function IndexIn(a, b::AbstractArray)
    bdict = Dict(zip(b, 0:length(b)))
    get(bdict, fmpz(a), -1)
end

"""
Return the Nth integer which is isA. (For N ≤ 0 return 0.)
```
julia> Nth(7, isPrime)
17
```
"""
function Nth(N, isA::Function)
    N ≤ 0 && return 0
    n, c = Int(0), Int(0)
    while c < N
        i = isA(n)
        i && (c += 1)
        n += 1
    end
    n - 1
end

"""
Return the cumulative sum of an SeqArray.
"""
function Accumulate(A)
    R = fill(ZZ(0), length(A))
    i, acu = 1, 0
    for a in A
        acu += a
        R[i] = acu
        i += 1
    end
    R
end

"""
Return the smallest list of indicators of isA with ∑(A) = count.
```
julia> IndicatorsFind(7, isPrime)
[0, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1]
```
"""
function IndicatorsFind(count, isA::Function)
    count ≤ 0 && return []
    n, c = Int(0), Int(0)
    A = Int[]
    while c < count
        i = isA(n)
        i && (c += 1)
        push!(A, ι(i))
        n += 1
    end
    A
end

"""
Return the first integer ``n ≥ 0`` such that isA(n) = true.
```
julia> First(isPrime)
2
```
"""
function First(isA::Function)
    n = 0
    while !isA(n)
        n += 1
    end
    n
end

First(A::Array{Int}) = A == [] ? nothing : first(A)

"""
Return the element at the end of the list A if A is not empty, 0 otherwise.
"""
Last(A) = A == [] ? "undef" : A[end]

"""
Trick described by David Hilbert in a 1924 lecture "Über das Unendliche".
"""
HilbertHotel(guest, hotel) = prepend!(hotel, guest)

"""
Return largest ``0 < k < n`` such that isA(k) = true or nothing if no such ``k`` exists.
```
julia> Previous(7, isPrime)
5
```
"""
function Previous(n, isA::Function)
    n == nothing && return First(isA)
    while true
        n -= 1
        isA(n) && break
        # This definition avoids throwing an exception. Alternatively:
        # n < 0 && throw(ArgumentError("Not defined for $n."))
        n < 0 && return First(isA)
    end
    n
end

"""
Return least ``k > n ≥ 0`` such that isA(k) = true. NOTE: It is assumed that such a ``k`` exists! (If not, the function will run forever.)
```
julia> Next(7, isPrime)
11
```
"""
function Next(n, isA::Function)
    ((n ≤ 0) || (n == nothing)) && return First(isA)
    while true
        n += 1
        isA(n) && break
    end
    n
end

"""
Return a list of composite numbers of length len. (Numbers which have more than one prime divisor.)
```
julia> L002808(8)
[4, 6, 8, 9, 10, 12, 14, 15]
```
"""
L002808(len) = List(len, isComposite)

"""
Return a list of the number of composite numbers ``≤ n``.
```
julia> L065855(8)
[0, 0, 0, 0, 1, 1, 2, 2]
```
"""
L065855(len) = CountList(len, isComposite)

"""
Return a list of squarefree numbers of length len. (Numbers which are not divisible by a square greater than 1.)
```
julia> L005117(8)
[1, 2, 3, 5, 6, 7, 10, 11]
```
"""
L005117(len) = List(len, isSquareFree)

"""
Return a list of the number of squarefree numbers ``< n``.
```
julia> L013928(8)
[0, 1, 2, 3, 3, 4, 5, 6]
```
"""
L013928(len) = CountList(len, isSquareFree)

"""
Return a list of powers of primes of length len. (Numbers of the form ``p^k`` where ``p`` is a prime and ``k ≥ 0``.)
```
julia> L000961(8)
[1, 2, 3, 4, 5, 7, 8, 9]
```
"""
L000961(len) = List(len, isPowerOfPrimes)

"""
Return the number of powers of primes ``≤ n``. (Powers of primes are numbers of the form ``p^k`` where ``p`` is a prime and ``k ≥ 0``.)
```
julia> L065515(8)
[0, 1, 2, 3, 4, 5, 5, 6]
```
"""
L065515(len) = CountList(len, isPowerOfPrimes)

"""
Return a list of prime powers of length len. (Numbers of the form ``p^k`` where ``p`` is a prime and ``k ≥ 1``.)
```
julia> L246655(8)
[2, 3, 4, 5, 7, 8, 9, 11]
```
"""
L246655(len) = List(len, isPrimePower)

"""
Return a list of the number of prime powers ``≤ n`` with exponents ``k ≥ 1``.
```
julia> L025528(8)
[0, 0, 1, 2, 3, 4, 4, 5]
```
"""
L025528(len) = CountList(len, isPrimePower)

"""
Return a list of perfect powers of length len. (Numbers of the form ``p^k`` where ``p`` is a prime and ``k ≥ 2``.
```
julia> L246547(8)
[4, 8, 9, 16, 25, 27, 32, 49]
```
"""
L246547(len) = List(len, isPerfectPower)

"""
Return a list of the number of prime powers ``≤ n`` with exponents ``k ≥ 2``.
```
julia> L069637(8)
[0, 0, 0, 0, 1, 1, 1, 1]
```
"""
L069637(len) = CountList(len, isPerfectPower)

# cf. also:
# A067535 Smallest squarefree number >= n.
# A070321 Largest squarefree number <= n.
# A025528 Number of prime powers <= n with exponents > 0.
# A000015 Smallest prime power >= n.
# A031218 Largest prime power <= n
# A167184 Smallest prime power >= n that is not prime.
# A081676 Largest perfect power <= n

"""
Return the largest prime in ``N`` (the semiring of natural numbers including zero) less than n for ``n ≥ 0``.
 (The `prev_prime` function of Mathematica, Maple, Magma and SageMath.)
"""
A007917(n::Int) = Previous(n, isPrime)

"""
Return the largest prime in ``Z`` (the ring of all integers) less than ``n`` for ``n ≥ 0`` (cf. A007917).
"""
PreviousPrime(n::Int) = n ∈ [0, 1, 2] ? -2 : Previous(n - 1, isPrime)

"""
Return least prime ``> n``. The next_prime function of Mathematica, Maple, Magma and SageMath (cf. A151800).
"""
NextPrime(n::Int) = Next(n, isPrime)

"""
Return least prime ``> n``. The `next_prime` function of Mathematica, Maple, Magma and SageMath.
"""
A151800(n::Int) = Next(n, isPrime)

"""
Return the list of number of primes ``≤ n`` for ``n ≥ 0``.

```
julia> PrimePiList(8)

[0, 0, 1, 2, 2, 3, 3, 4]
```
"""
PrimePiList(len::Int) = CountList(len, isPrime)

"""
Return the list of number of primes ``≤ n`` for ``n ≥ 0``.

```
julia> L000720(8)

[0, 0, 1, 2, 2, 3, 3, 4]
```
"""
L000720(len::Int) = PrimePiList(len)

"""
Return the index of the least prime not dividing ``n``.
"""
function A257993(n::Int)
    c, p = 1, 2
    while n % p == 0
        p = NextPrime(p)
        c += 1
    end
    c
end

#START-TEST-########################################################

using Test, SeqTests, SeqUtils

function test()

    indicators = [isPositive, isEven, isSquare, isPrime]
    indicatorNames = ["isPositive", "isEven", "isSquare", "isPrime"]

    len = 14
    @testset "Counts" begin

        @test Nth(96, isPrime) == 503
        @test Nth(97, isPrime) == 509
        @test Nth(98, isPrime) == 521

        # In other words: 97 is the 25-th prime.
        @test Count(96, isPrime) == 24
        @test Count(97, isPrime) == 25
        @test Count(98, isPrime) == 25

        @test List(24, isPrime)[end] == 89
        @test List(25, isPrime)[end] == 97

        for (i, isA) in enumerate(indicators)
            # This test shows that the logic behind 'Nth' and 'Count' is OK.
            for n in 1:len
               @test isA(n) == (Nth(Count(n, isA), isA) == n)
               @test     n  ==  Count(Nth(n, isA), isA)
            end
        end

        a = [A257993(n) for n in 1:10]
        b = [1, 2, 1, 2, 1, 3, 1, 2, 1, 2]
        @test all(a .== b)

        if is_oeis_installed()
            L = [
            L000961, L002808, L005117, L013928, L246547, L246655
            # L025528, L065515, L065855, L069637, L000720
            ]
            SeqTest(L, 'L')
        end
    end
end

function demo()

    indicators = [isNonnegative, isPositive, isEven, isComposite,
    isSquare, isSquareFree, isPrimePower, isPowerOfPrimes,
    isPerfectPower, isPrime
    ]
    indicatorNames = ["isNonnegative", "isPositive", "isEven", "isComposite",
    "isSquare", "isSquareFree", "isPrimePower", "isPowerOfPrimes",
    "isPerfectPower", "isPrime"
    ]

    println()
    len = 14
    for (i, isA) in enumerate(indicators)

        println("Predicate      ", indicatorNames[i])
        println("First          ", First(isA))
        println("---")

        println("Nth            ", [Nth(n, isA) for n in 0:len])
        print("List           ") ; Println(List(len, isA))
        println("FindUpTo       ", FindUpTo(len, isA))
        println("IterateUpTo    ", [k for k in IterateUpTo(len, isA)])
        println("---")

        println("IndicatorsFind ", IndicatorsFind(len, isA))
        println("Indicators     ", [k for k in Indicators(len, isA)])
        println("---")

        println("IndexIn (list) ", [IndexIn(fmpz(n), List(len, isA)) for n in 0:len])

        println("Count   (list) ", [Count(n, isA) for n in 0:len - 1])
        print("CountList      ") ; Println(CountList(len, isA))

        println("Previous(n)    ", [Previous(n, isA) for n in 0:len])
        println("Next(n)        ", [Next(n, isA)  for n in 0:len])
        println("Nth(Count(n))  ", [Nth(Count(n, isA), isA) for n in 0:len])
        println("Count(Nth(n))  ", [Count(Nth(n, isA), isA) for n in 0:len])

        println('='^66)
    end
end

"""
[A257993(n) for n in 1:10000]
    0.000635 seconds (9.20 k allocations: 221.859 KiB)
PrimePiList(10000)
    0.002290 seconds (35.82 k allocations: 637.891 KiB)
"""
function perf()
    @time [A257993(n) for n in 1:10000]
    GC.gc()
    @time PrimePiList(10000)
end

function main()
    test()
    demo()
    perf()
end

main()

end # module
