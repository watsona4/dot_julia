# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module CyclotomicBinaryForms
using Nemo, Counts, NumberTheory

export ModuleCyclotomicBinaryForms
export isA206864, F206864, I206864, L206864
export isA206942, F206942, I206942, L206942
export isA293654, F293654, I293654, L293654
export isA296095, F296095, I296095, L296095
export V299214, L299214
export isA299498, F299498, I299498, L299498
export isA299733, L299733
export isA299928, F299928, I299928, L299928
export isA299929, F299929, I299929, L299929
export isA299930, F299930, I299930, L299930
export isA325143, F325143, I325143, L325143
export isA325145, F325145, I325145, L325145

"""
E. Fouvry, C. Levesque, M. Waldschmidt,
[Representation of integers by cyclotomic binary forms](https://arxiv.org/pdf/1712.09019.pdf), arXiv:1712.09019 [math.NT], 2017.

* isA206864, F206864, I206864, L206864, isA206942, F206942, I206942, L206942, isA293654, F293654, I293654, L293654, isA296095, F296095, I296095, L296095, V299214, L299214, isA299498, F299498, I299498, L299498, isA299733, L299733, isA299928, F299928, I299928, L299928, isA299929, F299929, I299929, L299929, isA299930, F299930, I299930, L299930, isA325143, F325143, I325143, L325143, isA325145, F325145, I325145, L325145
"""
const ModuleCyclotomicBinaryForms = ""

#A206942########################################################################
"""
Is ``n`` a numbers of the form ``Phi_k(m)`` with ``k > 2`` and ``|m| > 1``
where ``Phi_k(m)`` denotes the ``k``-th cyclotomic polynomial evaluated at ``m``.
"""
function isA206942(n)
    if n < 3 return false end
    R, x = PolynomialRing(ZZ, "x")
    K = floor(Int, 5.383*log(n)^1.161) # Bounds from
    M = floor(Int, 2*sqrt(n/3))        # Fouvry & Levesque & Waldschmidt
    for k in 3:K
		c = cyclotomic(k, x)
        for m in 2:M
            n == subst(c, m) && return true
        end
    end
    return false
end

"""
Filter the integers which are A206942 and <= ``n``.
"""
F206942(n) = filter(isA206942, 1:n)

"""
Iterate over the first ``n`` integers which are A206942.
"""
I206942(n) = takeFirst(isA206942, n)

"""
Return the list of the first ``n`` integers which are A206942.
"""
L206942(n) = collect(I206942(n))

#A206864########################################################################

"""
Is ``n`` a prime of the form ``Phi_k(m)`` with ``k > 2`` and ``|m| > 1``
where ``Phi_k(m)`` denotes the ``k``-th cyclotomic polynomial evaluated at ``m``.
"""
isA206864(n) = isPrime(n) && isA206942(n)

"""
Filter the integers which are A206864 and <= ``n``.
"""
F206864(n) = (j for j in 1:n if isA206864(j))

"""
Iterate over the first ``n`` integers which are A206864.
"""
I206864(n) = takeFirst(isA206864, n)

"""
Return the list of the first ``n`` integers which are A206864.
"""
L206864(n) = collect(I206864(n))

#A299498########################################################################

"""
Is ``n`` primitively represented by a cyclotomic binary forms?
"""
function isA299498(n)
    isPrimeTo(n, k) = gcd(ZZ(n), ZZ(k)) == ZZ(1)
    R, x = PolynomialRing(ZZ, "x")
    K = floor(Int, 5.383*log(n)^1.161) # Bounds from
    M = floor(Int, 2*sqrt(n/3))  # Fouvry & Levesque & Waldschmidt
    N = QQ(n)

    for k in 3:K
        e = Int(eulerphi(ZZ(k)))
        c = cyclotomic(k, x)
        for m in 1:M, j in m+1:M if isPrimeTo(m, j)
            N == m^e*subst(c, QQ(j,m)) && return true
    end end end
    return false
end

"""
Filter the integers which are A299498 and <= ``n``.
"""
F299498(n) = (j for j in 1:n if isA299498(j))

"""
Iterate over the first ``n`` integers which are A299498.
"""
I299498(n) = takeFirst(isA299498, n)

"""
Return the list of the first ``n`` integers which are A299498.
"""
L299498(n) = collect(I299498(n))

"""
Count the number of cyclotomic binary forms which primitively represent ``n``.
"""
function countA299498(n)
    if n < 3 return 0 end
    isPrimeTo(n, k) = gcd(ZZ(n), ZZ(k)) == ZZ(1)
    R, x = PolynomialRing(ZZ, "x")
    K = floor(Int, 5.383*log(n)^1.161) # Bounds from
    M = floor(Int, 2*sqrt(n/3))  # Fouvry & Levesque & Waldschmidt
    N = QQ(n); count = 0

    for k in 3:K
        e = Int(eulerphi(ZZ(k)))
        c = cyclotomic(k, x)
        for m in 1:M, j in m+1:M if isPrimeTo(m, j)
            N == m^e*subst(c, QQ(j,m)) && (count += 1)
    end end end
    count
end
# [countA299498(n) for n in 1:100] |> println

#A299928########################################################################

"""
Is ``n`` represented by a cyclotomic binary form f(x, y) where x and y are prime numbers and 0 < y < x?
"""
function isA299928(n)
    R, z = PolynomialRing(ZZ, "z")
    K = floor(Int, 5.383*log(n)^1.161) # Bounds from
    M = floor(Int, 2*sqrt(n/3))  # Fouvry & Levesque & Waldschmidt
    N = QQ(n)
    P(u) = (p for p in u:M if isprime(ZZ(p)))
    for k in 3:K
        e = Int(eulerphi(ZZ(k)))
        c = cyclotomic(k, z)
        for y in P(2), x in P(y+1)
            N == y^e*subst(c, QQ(x, y)) && return true
        end
    end
    return false
end

"""
Filter the integers which are A299928 and <= ``n``.
"""
F299928(n) = (j for j in 1:n if isA299928(j))

"""
Iterate over the first ``n`` integers which are A299928.
"""
I299928(n) = takeFirst(isA299928, n)

"""
Return the list of the first ``n`` integers which are A299928.
"""
L299928(n) = collect(I299928(n))

#A299929########################################################################

"""
Is ``n`` a prime represented by a cyclotomic binary form f(x, y) where x and y are prime numbers and 0 < y < x?
"""
isA299929(n) = isPrime(n) && isA299928(n)

"""
Filter the integers which are A299929 and <= ``n``.
"""
F299929(n) = (j for j in 1:n if isA299929(j))

"""
Iterate over the first ``n`` integers which are A299929.
"""
I299929(n) = takeFirst(isA299929, n)

"""
Return the list of the first ``n`` integers which are A299929.
"""
L299929(n) = collect(I299929(n))

#A299930########################################################################

"""
Is ``n`` a prime represented by a cyclotomic binary form f(x, y) with x and y odd prime numbers and x > y.
"""
function isA299930(n)
    !isprime(ZZ(n)) && return false
    R, z = PolynomialRing(ZZ, "z")
    K = floor(Int, 5.383*log(n)^1.161)
    M = floor(Int, 2*sqrt(n/3))
    N = QQ(n)
    P(u) = (p for p in u:M if isprime(ZZ(p)))
    for k in 3:K
        e = Int(eulerphi(ZZ(k)))
        c = cyclotomic(k, z)
        for y in P(3), x in P(y+2)
            N == y^e*subst(c, QQ(x, y)) && return true
    end end
    return false
end

"""
Filter the integers which are A299930 and <= ``n``.
"""
F299930(n) = (j for j in 1:n if isA299930(j))

"""
Iterate over the first ``n`` integers which are A299930.
"""
I299930(n) = takeFirst(isA299930, n)

"""
Return the list of the first ``n`` integers which are A299930.
"""
L299930(n) = collect(I299930(n))

#A296095########################################################################

"""
Is ``n`` represented by a cyclotomic binary form?
"""
function isA296095(n)
    n < 3 && return false
    R, z = PolynomialRing(ZZ, "z")
    N = QQ(n)
    # Bounds from Fouvry & Levesque & Waldschmidt
    logn = log(n)^1.161
    K = floor(Int, 5.383*logn)
    M = floor(Int, 2*(n/3)^(1/2))
    k = 3
    while true
        c = cyclotomic(k, z)
        e = Int(eulerphi(ZZ(k)))
        if k == 7
            K = ceil(Int, 4.864*logn)
            M = ceil(Int, 2*(n/11)^(1/4))
        end
        for y in 2:M, x in 1:y
            N == y^e*subst(c, QQ(x, y)) && return true
        end
        k += 1
        k > K && break
    end
    return false
end

"""
Filter the integers which are A296095 and <= ``n``.
"""
F296095(n) = (j for j in 1:n if isA296095(j))

"""
Iterate over the first ``n`` integers which are A296095.
"""
I296095(n) = takeFirst(isA296095, n)

"""
Return the list of the first ``n`` integers which are A296095.
"""
L296095(n) = collect(I296095(n))

#A293654########################################################################

"""
Is ``n`` unrepresentable by a cyclotomic binary forms?
"""
function isA293654(n)
    if n < 3 return true end
    R, x = PolynomialRing(ZZ, "x")
    K = floor(Int, 5.383*log(n)^1.161) # Bounds from
    M = floor(Int, 2*sqrt(n/3)) # Fouvry & Levesque & Waldschmidt
    N = QQ(n); count = 0

    for k in 3:K
        e = Int(eulerphi(ZZ(k)))
        c = cyclotomic(k, x)
        for m in 1:M, j in 0:M if max(j, m) > 1
            N == m^e*subst(c, QQ(j,m)) && return false
    end end end
    return true
end

"""
Filter the integers which are A293654 and <= ``n``.
"""
F293654(n) = (j for j in 1:n if isA293654(j))

"""
Iterate over the first ``n`` integers which are A293654.
"""
I293654(n) = takeFirst(isA293654, n)

"""
Return the list of the first ``n`` integers which are A293654.
"""
L293654(n) = collect(I293654(n))

#A325143########################################################################

"""
Is ``n`` a prime represented by a cyclotomic binary form?
"""
function isA325143(n)
    (n < 3 || !isprime(ZZ(n))) && return false
    R, x = PolynomialRing(ZZ, "x")
    K = floor(Int, 5.383*log(n)^1.161) # Bounds from
    M = floor(Int, 2*sqrt(n/3)) # Fouvry & Levesque & Waldschmidt
    N = QQ(n)

    for k in 3:K
        e = Int(eulerphi(ZZ(k)))
        c = cyclotomic(k, x)
        for m in 1:M, j in 0:M if max(j, m) > 1
            N == m^e*subst(c, QQ(j,m)) && return true
    end end end
    return false
end

"""
Filter the integers which are A325143 and <= ``n``.
"""
F325143(n) = (j for j in 1:n if isA325143(j))

"""
Iterate over the first ``n`` integers which are A325143.
"""
I325143(n) = takeFirst(isA325143, n)

"""
Return the list of the first ``n`` integers which are A325143.
"""
L325143(n) = collect(I325143(n))

#A325145########################################################################

"""
Is ``n`` a prime unrepresentable by a cyclotomic binary form?
"""
isA325145(n) = isprime(ZZ(n)) && ! isA325143(n)

"""
Filter the integers which are A325145 and <= ``n``.
"""
F325145(n) = (j for j in 1:n if isA325145(j))

"""
Iterate over the first ``n`` integers which are A325145.
"""
I325145(n) = takeFirst(isA325145, n)

"""
Return the list of the first ``n`` integers which are A325145.
"""
L325145(n) = collect(I325145(n))

#A299214########################################################################

"""
Return the number of representations of ``n`` by cyclotomic binary forms.
"""
function V299214(n)
    if n < 3 return 0 end
    R, x = PolynomialRing(ZZ, "x")
    K = floor(Int, 5.383*log(n)^1.161) # Bounds from
    M = floor(Int, 2*sqrt(n/3))  # Fouvry & Levesque & Waldschmidt
    N = QQ(n); count = 0

    for k in 3:K
        e = Int(eulerphi(ZZ(k)))
        c = cyclotomic(k, x)
        for m in 1:M, j in 0:M if max(j, m) > 1
            N == m^e*subst(c, QQ(j,m)) && (count += 1)
    end end end
    4*count
end

"""
Return the initial list of V299214 of length len .
"""
L299214(len) = [V299214(i) for i in 1:len]

################################################################################

"""
Is n a prime represented in more than one way by cyclotomic binary forms f(x,y) with x and y prime numbers and y < x?
"""
function isA299733(n)
    if n < 3 || !isprime(ZZ(n)) return false end
    R, x = PolynomialRing(ZZ, "x")
    K = floor(Int, 5.383*log(n)^1.161) # Bounds from
    M = floor(Int, 2*sqrt(n/3)) # Fouvry & Levesque & Waldschmidt
    N = QQ(n); multi = 0

    for k in 3:K
        e = Int(eulerphi(ZZ(k)))
        c = cyclotomic(k, x)
        for m in 2:M if isprime(ZZ(m))
            for j in m:M if isprime(ZZ(j))
                if N == m^e*subst(c, QQ(j,m)) multi += 1
    end end end end end end
    multi > 1
end

"""
Return the list of the first ``n`` integers which are A299733.
"""
L299733(n) = [i for i in 1:n if isA299733(i)]

# L299733(1000) |> println

#START-TEST-########################################################

using Test, SeqTests

function test()
    @testset "CyclotomicForms" begin
        if is_oeis_installed()

            L = [L206942, L206864, L299498, L299928, L299929, L299930,
                 L299214, L296095, L293654]
            SeqTest(L, 'L')
        end
    end
end

function demo()
    println("\nIntegers which are A206942 and <= 32:")
    for n in 1:32
        isA206942(n) && println(n)
    end

    println("\nIterate over the first 32 integers which are A206942:")
    for i in I206942(32)
        print("$i, ")
    end

    println("\n\nFilter the integers which are A206942 and <= 60:")
    F206942(60) |> println

    println("\nReturn the list of the first 32 integers which are A206942:")
    L206942(32) |> println
end

"""
L299214(100) :: 1.822155 seconds (7.22 M allocations: 185.560 MiB, 36.76% gc time)
"""
function perf()
    @time L299214(100)
end

function main()
    test()
    demo()
    perf()
end

main()

end # module
