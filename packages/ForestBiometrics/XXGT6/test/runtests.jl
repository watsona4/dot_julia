using Test
using ForestBiometrics
#no idea if i should use this here or in individual scripts?

@testset "EquilibriumMoistureContent" begin include("EquilibriumMoistureContent_test.jl") end

@testset "ForestStocking" begin include("ForestStocking_test.jl") end

@testset "GingrichStocking_chart" begin include("GingrichStocking_chart_test.jl") end

#1/5/19 failing, need to re-do readtable part
#@testset "HeightDub" begin include("HeightDub_test.jl") end

@testset "LimitingDistance" begin include("LimitingDistance_test.jl") end

@testset "SDI_chart" begin include("SDI_chart_test.jl") end

@testset "VolumeEquations" begin include("VolumeEquations_test.jl") end
