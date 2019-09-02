using PolynomialZeros
const AMVW = PolynomialZeros.AMVW
using Polynomials
using Test
using LinearAlgebra

# transformations

# # givens rotation
# @testset "Givens rotations" begin
#     a,b = complex(1.0, 2.0), complex(2.0, 3.0)
#     c,s,r = AMVW.givensrot(a,b)
#     @test norm(([c -conj(s); s conj(c)] * [a,b])[2]) <= 4eps(Float64)
#     a,b = complex(rand(2)...), complex(rand(2)...)
#     c,s,r = AMVW.givensrot(a,b)
#     @test norm(([c -conj(s); s conj(c)] * [a,b])[2]) <= 4eps(Float64)
# end




# # dflip
# @testset "D flip" begin
#     # t1 = pi/3;
#     # alpha = complex(cos(t1), sin(t1))
#     # d = AMVW.ComplexComplexRotator(alpha, complex(0.0, 0.0), 1)
#     # u = one(AMVW.ComplexComplexRotator{Float64})
#     # AMVW.vals!(u, complex(1.0, 2.0), complex(2.0, 3.0)); AMVW.idx!(u, 2)
#     # M = AMVW.as_full(u, 3) * AMVW.as_full(d,3)
#     # AMVW.Dflip(u, d)
#     # M1 = AMVW.as_full(d, 3) * AMVW.as_full(u,3)
#     # u = M - M1
#     # @test  maximum(norm.(u)) <= 4eps()



#     # complexrealrotator is different
#     #  U --> U D
#     # D         D
#     # r1,r2 = ones(AMVW.ComplexRealRotator{Float64},2)
#     # AMVW.vals!(r1, complex(1.0, 2.0), 2.0); AMVW.idx!(r1, 1)
#     # di = one(AMVW.ComplexRealRotator{Float64})
#     # AMVW.vals!(di, complex(cos(pi/3), sin(pi/3)), 0.0); AMVW.idx!(di, 2)
#     # M = AMVW.as_full(di, 3) * AMVW.as_full(r1, 3)
#     # AMVW.Dflip(di, r1)
#     # dic = copy(di); AMVW.idx!(dic, AMVW.idx(r1))
#     # M1 = AMVW.as_full(r1, 3) * AMVW.as_full(dic, 3) * AMVW.as_full(di, 3)
#     # @test maximum(norm.(M - M1)) <= 4eps()

#     ## D   -->      D
#     ##   U      U D
#     ##
#     # r1,r2 = ones(AMVW.ComplexRealRotator{Float64},2)
#     # AMVW.vals!(r1, complex(1.0, 2.0), 2.0); AMVW.idx!(r1, 2)
#     # di = one(AMVW.ComplexRealRotator{Float64})
#     # AMVW.vals!(di, complex(cos(pi/3), sin(pi/3)), 0.0); AMVW.idx!(di, 1)
#     # M = AMVW.as_full(di, 3) * AMVW.as_full(r1, 3)
#     # AMVW.Dflip(di, r1)
#     # dic = copy(di); AMVW.idx!(dic, AMVW.idx(r1))
#     # M1 = AMVW.as_full(r1, 3) * AMVW.as_full(dic, 3) * AMVW.as_full(di, 3)
#     # @test maximum(norm.(M - M1)) <= 4eps()

#     # ##
#     # ## Q   --> D   Q
#     # ##   D       D
#     # r1,r2 = ones(AMVW.ComplexRealRotator{Float64},2)
#     # AMVW.vals!(r1, complex(1.0, 2.0), 2.0); AMVW.idx!(r1, 1)
#     # di = one(AMVW.ComplexRealRotator{Float64})
#     # AMVW.vals!(di, complex(cos(pi/3), sin(pi/3)), 0.0); AMVW.idx!(di, 2)
#     # M = AMVW.as_full(r1, 3) * AMVW.as_full(di, 3)
#     # AMVW.Dflip(di, r1)
#     # dic = copy(di); AMVW.idx!(dic, AMVW.idx(r1))
#     # M1 = AMVW.as_full(dic, 3) * AMVW.as_full(di, 3) * AMVW.as_full(r1, 3)
#     # @test maximum(norm.(M - M1)) <= 4eps()

# end

# @testset "Fuse" begin
#     ##
#     # fuse
#     r1,r2 = ones(AMVW.ComplexComplexRotator{Float64},2)
#     AMVW.vals!(r1, complex(1.0, 2.0), complex(2.0, 3.0)); AMVW.idx!(r1, 1)
#     AMVW.vals!(r2, complex(3.0, 2.0), complex(5.0, 3.0)); AMVW.idx!(r2, 1)
#     M = AMVW.as_full(r1,2) * AMVW.as_full(r2, 2)
#     AMVW.fuse(r1, r2, Val{:left})
#     M1 = AMVW.as_full(r1, 2)
#     u = M - M1
#     @test maximum(norm.(u)) <= 4eps()



#     r1,r2 = ones(AMVW.ComplexRealRotator{Float64},2)
#     AMVW.vals!(r1, complex(1.0, 2.0), 2.0); AMVW.idx!(r1, 1)
#     AMVW.vals!(r2, complex(3.0, 2.0), 5.0); AMVW.idx!(r2, 1)
#     M = AMVW.as_full(r1,2) * AMVW.as_full(r2, 2)
#     alpha = AMVW.fuse(r1, r2, Val{:left})
#     M1 = AMVW.as_full(r1, 2) * diagm(0 => [alpha, conj(alpha)])
#     u = M - M1
#     @test maximum(norm.(u)) <= 4eps()


#     r1,r2 = ones(AMVW.ComplexRealRotator{Float64},2)
#     AMVW.vals!(r1, complex(1.0, 2.0), 2.0); AMVW.idx!(r1, 1)
#     AMVW.vals!(r2, complex(3.0, 2.0), 5.0); AMVW.idx!(r2, 1)
#     M = AMVW.as_full(r1,2) * AMVW.as_full(r2, 2)
#     alpha = AMVW.fuse(r1, r2, Val{:right})
#     M1 =  AMVW.as_full(r2, 2)  * diagm(0 => [alpha, conj(alpha)])
#     u = M - M1
#     @test maximum(norm.(u)) <= 4eps()

# end

# ## Cascade
# @testset "Cascade" begin
#     D1, Q1, Q2,Q3,Q4 =  AMVW._ones(AMVW.ComplexRealRotator{Float64},5)
#     alpha = complex(1.0, -1.0)
#     alpha = alpha/norm(alpha)
#     AMVW.vals!(D1, alpha, 0.0); AMVW.idx!(D1, 1)
#     AMVW.vals!(Q2, complex(1.0, 2.0), 2.0); AMVW.idx!(Q2, 2)
#     AMVW.vals!(Q3, complex(3.0, 2.0), 5.0); AMVW.idx!(Q3, 3)
#     AMVW.vals!(Q4, complex(2.0, 2.0), 3.0); AMVW.idx!(Q4, 4)

#     M1 = AMVW.as_full(D1, 5) * AMVW.as_full(Q2, 5) * AMVW.as_full(Q3, 5) * AMVW.as_full(Q4, 5)
#     D = ones(Complex{Float64}, 5)
#     Qs = [Q1, Q2, Q3, Q4]
#     AMVW.cascade(Qs, D, alpha, 1, 4)
#     M2 = AMVW.as_full(Q2, 5) * AMVW.as_full(Q3, 5) * AMVW.as_full(Q4, 5) * diagm(0 => D)

#     u = M1 - M2
#     @test maximum(norm.(u)) <= 4eps()

# end

# ##
# # turnover
# @testset "Turnover" begin
#     r1,r2,r3 = AMVW._ones(AMVW.ComplexComplexRotator{Float64}, 3)
#     AMVW.vals!(r1, complex(1.0, 2.0), complex(2.0, 3.0)); AMVW.idx!(r1, 1)
#     AMVW.vals!(r2, complex(3.0, 2.0), complex(5.0, 3.0)); AMVW.idx!(r2, 2)
#     AMVW.vals!(r3, complex(4.0, 2.0), complex(6.0, 3.0)); AMVW.idx!(r3, 1)

#     M = AMVW.as_full(r1,3) * AMVW.as_full(r2,3) * AMVW.as_full(r3,3)
#     AMVW.turnover(r1, r2, r3, Val{:right})
#     M1 =  AMVW.as_full(r3,3) * AMVW.as_full(r1,3) * AMVW.as_full(r2,3)
#     u = M - M1
#     @test maximum(norm.(u)) <= 4eps()



#     r1,r2,r3 = AMVW._ones(AMVW.ComplexRealRotator{Float64}, 3)
#     AMVW.vals!(r1, complex(1.0, 2.0), 2.0); AMVW.idx!(r1, 1)
#     AMVW.vals!(r2, complex(3.0, 2.0), 5.0); AMVW.idx!(r2, 2)
#     AMVW.vals!(r3, complex(4.0, 2.0), 6.0); AMVW.idx!(r3, 1)

#     M = AMVW.as_full(r1,3) * AMVW.as_full(r2,3) * AMVW.as_full(r3,3)
#     AMVW.turnover(r1, r2, r3, Val{:right})
#     M1 =  AMVW.as_full(r3,3) * AMVW.as_full(r1,3) * AMVW.as_full(r2,3)
#     u = M - M1
#     @test maximum(norm.(u)) <= 4eps()
#     AMVW.turnover(r3, r1, r2, Val{:left})
#     M2 = AMVW.as_full(r1,3) * AMVW.as_full(r2,3) * AMVW.as_full(r3,3)
#     u = M - M1
#     @test maximum(norm.(u)) <= 4eps()

# end


# # passthrough
# @testset "Passthrough" begin
#     r1,r2,r3 = AMVW._ones(AMVW.ComplexRealRotator{Float64}, 3)
#     AMVW.vals!(r1, complex(1.0, 2.0), 2.0); AMVW.idx!(r1, 1)
#     t1,t2,t3=pi/3,pi/4, pi/5
#     cplx(t) = complex(cos(t), sin(t))
#     D = [cplx(t) for t in [t1,t2,t3]]
#     M = diagm(0 =>D) * AMVW.as_full(r1, 3)
#     AMVW.passthrough(D, r1)
#     M1 = AMVW.as_full(r1, 3) * diagm(0 => D)
#     u = M - M1
#     @test maximum(norm.(u)) <= 4eps()


# end


@testset "poly_roots" begin

    ## real coeffs
    rs = [1.0, 2.0, 3.0]
    p = poly(rs)
    rts =  AMVW.poly_roots(p.a)
    sort!(rts, by=norm)
    @test maximum(norm.(rts - rs)) <= 1e-6

    # complex coeffs
    rs = [1.0, 2.0, 3.0, 4.0 + 1.0im]
    p = poly(rs)
    rts = AMVW.poly_roots(p.a)
    sort!(rts, by=norm)
    @test maximum(norm.(rts - rs)) <= 1e-6


    # # ComplexComplex
    # rs = [1.0, 2.0, 3.0, 4.0+0im]
    # p = poly(rs)
    # qs, k = AMVW.reverse_poly(p.a)
    # state = AMVW.ComplexComplexSingleShift(qs)
    # AMVW.init_state(state)
    # AMVW.AMVW_algorithm(state)
    # rts = complex.(state.REIGS, state.IEIGS)
    # sort!(rts, by=norm)
    # @test maximum(norm.(rts - rs)) <= 1e-6

    ## simple cases
    n=1
    rs = [1.0]
    p = poly(rs)
    rts = AMVW.poly_roots(p.a)
    @test maximum(norm.(rts - rs)) <= 1e-6

    rs = [1.0 + im]
    p = poly(rs)
    rts = AMVW.poly_roots(p.a)
    @test maximum(norm.(rts - rs)) <= 1e-6

    # n = 2
    rs = [1.0, 2.0]
    p = poly(rs)
    rts = AMVW.poly_roots(p.a)
    sort!(rts, by=norm)
    @test maximum(norm.(rts - rs)) <= 1e-6

    rs = [1.0, 2.0+im]
    p = poly(rs)
    rts = AMVW.poly_roots(p.a)
    sort!(rts, by=norm)
    @test maximum(norm.(rts - rs)) <= 1e-6

    # zeros
    rs = [1.0, 2.0, 3.0, 0.0, 0.0]
    sort!(rs, by=norm)
    p = poly(rs)
    rts = AMVW.poly_roots(p.a)
    sort!(rts, by=norm)
    @test maximum(norm.(rts - rs)) <= 1e-6

    rs = [1.0, 2.0, 3.0+im, 0.0, 0.0]
    sort!(rs, by=norm)
    p = poly(rs)
    rts = AMVW.poly_roots(p.a)
    sort!(rts, by=norm)
    @test maximum(norm.(rts - rs)) <= 1e-6

end

@testset "pencil factorization" begin
    pr = poly([1.0, 2.0, 3.0])
    rts = AMVW.poly_roots(coeffs(pr), pencil=AMVW.basic_pencil)
    @test maximum(norm.(pr.(rts))) <= 1e-12

    pi = poly([im+1.0, 2.0, 3.0])
    rts = AMVW.poly_roots(coeffs(pi),  pencil=AMVW.basic_pencil)
    @test maximum(norm.(pi.(rts))) <= 1e-12

end
