using ForTheBadge
using Test

testdir = "$(@__DIR__)/../assets/tests"

ispath(testdir) && rm(testdir, recursive = true)
ispath(testdir) || mkpath(testdir)

cd(testdir)

@testset "create badges" begin
    badge("FOR THE", "BADGE")

    @test true
end

print("Created 1 badge.  Tests over for now!")
