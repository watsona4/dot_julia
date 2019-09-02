using MathPhysicalConstants, Measurements, Unitful

using Test

using MathPhysicalConstants

@testset begin
    @test MathPhysicalConstants.MKS.PlancksConstantH == 6.62606896e-34
    @test iszero(measurement(MathPhysicalConstants.IS.SanchezElectrConstant) - measurement(MathPhysicalConstants.IS.SanchezElectrConstant))
    # \\\ @test setprecision(BigFloat, 768) do; precision(ustrip(big(c))) end == 768
    #\\\@test measurement(h) === measurement(h)
    #\\\@test iszero(measurement(α) - measurement(α))
    #\\\@test isone(measurement(BigFloat, atm) / measurement(BigFloat, atm))
    #\\\@test iszero(measurement(BigFloat, ħ) - (measurement(BigFloat, h) / 2big(pi)))
    #\\\@test isone(measurement(BigFloat, ħ) / (measurement(BigFloat, h) / 2big(pi)))
end

