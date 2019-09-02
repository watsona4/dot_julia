using Test, LinearFractionalTransformations

f = LFT(1,0,0,1)  # identity
@test f(1+im) == 1+im
@test f[1+im] == 1+im


f = LFT(2,0,0,1)  # f(x) = 2x
@test f(-im) == -2im

g = inv(f)
@test g(im) == 0.5im

g = f*f
@test g(2-im) == 4*(2-im)

f = LFT(1,2+im, 3,0, 1-im,5)
@test f(1)==2+im
@test f(3)==0
@test f(1-im)==5

g = inv(f)
@test g(0) == 3

@test LFT() == g*f

f = LFT(0,1,1,0)
@test f(Inf) == 0
@test isinf(f(0))


f = LFT(3-im, 2+im, 6)
@test f(3-im) == 0
@test f(2+im) == 1
@test isinf(f(6))
