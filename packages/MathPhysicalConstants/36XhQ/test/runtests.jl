using MathPhysicalConstants
using Base.Test

@testset begin
    @test MathPhysicalConstants.MKS.PlancksConstantH == 6.62606896e-34
    @test MathPhysicalConstants.SI.PlanckConstantH == 6.62607015e-34
    @test MathPhysicalConstants.SI.SanchezElectrConstant == 137.035999139
    #\\\ @test iszero(measurement(MathPhysicalConstants.IS.SanchezElectrConstant) - measurement(MathPhysicalConstants.IS.SanchezElectrConstant))
    # \\\ @test setprecision(BigFloat, 768) do; precision(ustrip(big(c))) end == 768
    #\\\@test measurement(h) === measurement(h)
    #\\\@test iszero(measurement(α) - measurement(α))
    #\\\@test isone(measurement(BigFloat, atm) / measurement(BigFloat, atm))
    #\\\@test iszero(measurement(BigFloat, ħ) - (measurement(BigFloat, h) / 2big(pi)))
    #\\\@test isone(measurement(BigFloat, ħ) / (measurement(BigFloat, h) / 2big(pi)))
end
