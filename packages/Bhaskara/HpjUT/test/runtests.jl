using Test
using Bhaskara

test(f, g, r=0:0.001:π, e=0.002) = maximum(@. abs(f(r)-g(r)) ) < e

@test test(bsin, Base.sin)
@test test(b2sin, Base.sin, -π:0.001:π)
@test test(Bhaskara.sin, Base.sin, -3π:0.001:3π)

@test test(Bhaskara.sind180, Base.sind, 0:0.1:180)
@test test(Bhaskara.sind360, Base.sind, -180:0.1:180)
@test test(Bhaskara.sind, Base.sind, -1000:0.1:1000)

@test test(bcos, Base.cos, -0.5π:0.001:0.5π)
@test test(Bhaskara.cos, Base.cos, -3π:0.001:3π)

@test bsin(big(0.1)) isa BigFloat
@test bsin(Float32(0.2)) isa Float32
@test bcos(big(0.1)) isa BigFloat
@test bcos(Float32(0.2)) isa Float32

