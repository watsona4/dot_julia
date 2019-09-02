using PolynomialFactors
using AbstractAlgebra
P = PolynomialFactors

## Wilkinson (good out to 50 or so, then issues)


@testset "Test factor over Poly{Int}" begin

## test of factoring over Z[x]
R, x = ZZ["x"]
f = (x-1)*(x-2)*(x-3)
U = P.poly_factor(f)
@test prod(collect(keys(U))) - f == zero(x)

f = (x-1)*(x-2)^2*(x-3)^3
U = P.poly_factor(f)
@test U[x-3] == 3
@test f - prod([k^v for (k,v) in U]) == zero(f)

f = (x-2)*(3x-4)^2*(6x-7)^2
U = P.poly_factor(f)
@test U[6x-7] == 2


f = (x^5 - x - 1)
U = P.poly_factor(f)
@test U[f] == 1


f = x^4
U = P.poly_factor(f)
@test U[x] == 4

d = Dict(x-1 => 3, 2x-3=>4, x^2+x+1=>3)
f = prod([k^v for (k,v) in  d])
U = P.poly_factor(f)
for (k,val) in d
   @test U[k] == val
end

end

@testset "Test factor over Poly{BigInt}" begin
## BigInt
## issue #40 in Roots.jl
R,x = ZZ["x"]
f = x^2 - big(2)^256
U = P.poly_factor(f)
@test U[x - big(2)^128] == 1


p = x^15 - 1
@test length(P.poly_factor(p)) == 4

p = 1 + x^3 + x^6 + x^9 + x^12
@test length(P.poly_factor(p)) == 2
@test p - prod([k^v for (k,v) in P.poly_factor(p)]) == zero(p)

W(n) = prod([x-i for i in 1:20])
U = P.poly_factor(W(20))
@test U[x-5] == 1


## Swinnerton-Dyer Polys are slow to resolve, as over `p` they factor into linears, but over Z are irreducible.
## so the "fish out" step exhausts all possibilities.
S1 = x^2 - 2	
U = P.poly_factor(S1)
@test U[S1] == 1

S2 = x^4 - 10*x^2 + 1
U = P.poly_factor(S2)
@test U[S2] == 1

S3 = x^8 - 40x^6 + 352x^4 - 960x^2 + 576
U = P.poly_factor(S3)
@test length(U) == 1


## Cyclotomic polys are irreducible over Z[x] too (https://en.wikipedia.org/wiki/Cyclotomic_polynomial)
C5 = x^4 + x^3 + x^2 + x + 1
U = P.poly_factor(C5)
@test U[C5] == 1

C10 = x^4 - x^3 + x^2 -x + 1
U = P.poly_factor(C10)
@test U[C10] == 1

C15 = x^8 - x^7 + x^5 - x^4 + x^3 - x + 1
U = P.poly_factor(C15)
@test U[C15] == 1

C25 = x^20 + x^15 + x^10 + x^5 + 1
U = P.poly_factor(C25)
@test U[C25] == 1

println("Test factor over Poly{Rational{BigInt}}")
## Rational
R,x = QQ["x"]
f = -17 * (x - 1//2)^3 * (x-3//4)^4
U = P.poly_factor(f)
@test U[-1 + 2x] == 3
@test f - prod([k^v for (k,v) in P.poly_factor(f)]) == zero(f)

end

# @testset "Test rational_roots" begin
# ### Rational roots
# R,x = ZZ["x"]
# W(n) = prod([x-i for i in 1:20])
# V = rational_roots(W(20))
# @test all(V .== 1:20)

# f = (2x-3)^4 * (5x-6)^7
# V = rational_roots(f)
# @test 3//2 in V
# @test 6//5 in V

# end

@testset "Test factormod" begin
    ## factormod
    R,x = ZZ["x"]
    
    # factormod has elements in GF(q)
    C10 = x^4 - x^3 + x^2 -x + 1
    U = P.factormod(C10, 5)
    # (1+x)^4
    @test length(U) == 1
    
    C25 = x^20 + x^15 + x^10 + x^5 + 1
    U = P.factormod(C25, 5)
    # (x+4)^20
    @test length(U) == 1
    
    U = P.factormod(x^4 + 1, 5)
    # (x^2+2)*(x^2+3)
    @test length(U) == 2
    
    U = P.factormod(x^4 + 1, 2)
    # (x+1)^4
    @test length(U) == 1
    
    p = 5x^5 - x^4 - 1
    U = P.factormod(p, 7)
    # 5 * (x^4+3*x^3+4*x^2+3*x+4) * (x + 1)
    V = 5 * (x^4+3*x^3+4*x^2+3*x+4) * (x + 1)
    vs = PolynomialFactors.poly_coeffs(V)
    ps = PolynomialFactors.poly_coeffs(p)
    ## v-p is not zero, v-pmod 7 should be:
    @test !all(iszero(vs - ps))
    @test all(iszero.(mod.(vs-ps,7)))

end
