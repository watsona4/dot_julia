using StanDump
using StanRun

srand(UInt32[0x5b02bb69, 0xf5693c2c, 0xb0101f2a, 0xc44fb3ce]) # consistent runs

sp = StanRun.Program(Pkg.dir("StanSamples", "test", "testmodel", "test"))

M1 = 3
M2 = 5
N = 100
μ = 1.0
σ = 0.5
ν = 1.0
α = randn(M1, M2)*σ + μ
X = randn(M1, M2, N)*ν .+ α

standump(sp, @vardict M1 M2 N X)

StanRun.make(sp, StanRun.EXECUTABLE, force = true)
StanRun.sample(sp, 1)
