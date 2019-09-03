using Test
using RiemannComplexNumbers

a = 2+3IM
b = 4-5IM

@test a+b == 6-2im
@test a/0 == ComplexInf
@test isinf(a/0)
@test Complex(a)==a
@test hash(a) == hash(Complex(a))
@test isnan((a-a)/(b-b))
@test Inf + IM == Inf + 2*im
@test ComplexInf * ComplexInf == ComplexInf
@test isnan(ComplexInf + ComplexInf)
@test isnan(0*ComplexInf)

@test 1/a == inv(a)
@test a' == conj(a)

@test one(RC) == 1
@test zero(RC) == 0

z = RC(2+3im)
@test z*z == -5 + 12im
@test z/z == 1
@test z^3 == z*z*z
@test z^(-1) == 1/z
@test sqrt(RC(-1)) == IM
@test exp(2+3im) == exp(2+3IM)
@test angle(IM) == pi/2
z = 3 - 4IM
@test abs(z*z) == 25
@test abs(z*z) == z'*z

@test abs(exp(log(-1+0IM)) + 1) < 1e-10
@test abs(log(exp(-1+2IM)) - (-1+2IM)) < 1e-10

a = RC(3.0 + 0.0im)
b = a'
@test a==b
@test !isequal(a,b)

@test ComplexNaN != NaN
@test isequal(ComplexNaN,NaN)
