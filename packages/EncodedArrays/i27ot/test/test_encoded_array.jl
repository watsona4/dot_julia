# This file is a part of EncodedArrays.jl, licensed under the MIT License (MIT).

using EncodedArrays
using Test

@testset "encoded_array" begin
    data = rand(Int16(-1000):Int16(2000), 21)
    codec = VarlenDiffArrayCodec()

    data_enc = data |> codec

    @testset "ctors and conversions" begin
        @test @inferred(Array(data_enc)) == data
        @test typeof(Array(data_enc)) == Array{eltype(data),1}
        @test @inferred(Array{Int16}(data_enc)) == data
        @test @inferred(Array{Int16,1}(data_enc)) == data
        @test @inferred(Vector(data_enc)) == data
        @test @inferred(Vector{Int16}(data_enc)) == data
        @test typeof(Vector{Int16}(data_enc)) == Vector{Int16}
        @test @inferred(Vector{Int32}(data_enc)) == data
        @test typeof(Vector{Int32}(data_enc)) == Vector{Int32}

        @test @inferred(convert(Array, data_enc)) == data
        @test typeof(convert(Array, data_enc)) == Array{eltype(data),1}
        @test @inferred(convert(Array{Int16}, data_enc)) == data
        @test @inferred(convert(Array{Int16,1}, data_enc)) == data
        @test @inferred(convert(Vector, data_enc)) == data
        @test @inferred(convert(Vector{Int16}, data_enc)) == data
        @test typeof(convert(Vector{Int16}, data_enc)) == Vector{Int16}
        @test @inferred(convert(Vector{Int32}, data_enc)) == data
        @test typeof(convert(Vector{Int32}, data_enc)) == Vector{Int32}
    end

    @testset "collect" begin
        @test @inferred(collect(data_enc)) == data
        @test typeof(collect(data_enc)) == typeof(data)
    end

    @testset "getindex" begin
        @test @inferred(data_enc[:]) == data
        @test typeof(data_enc[:]) == Array{eltype(data),1}

        @test @inferred(data_enc[:]) == data
        @test @inferred(data_enc[1:21]) == data
        @test @inferred(data_enc[5:15]) == data[5:15]
        @test @inferred(data_enc[7]) == data[7]
    end

    @testset "setindex!" begin
        tmp = zero.(data)
        @test (tmp[:] = data_enc) == data

        tmp = vcat(zero.(data), zero.(data))
        tmp2 = copy(tmp)
        tmp[10:30] = data_enc
        tmp2[10:30] = data
        @test tmp == tmp2
    end

    @testset "equality" begin
        @test @inferred data == data_enc
        @test @inferred data_enc == data
        @test @inferred data_enc == data_enc
    end

    @testset "append!" begin
        A = similar(data, 0)
        @test @inferred(append!(A, data_enc)) === A
        @test A == data

        A = data[1:4]
        @test @inferred(append!(A, data_enc)) === A
        @test A == vcat(data[1:4], data)
    end

    @testset "append!" begin
        A = similar(data)
        @test @inferred(copyto!(A, data_enc)) === A
        @test A == data

        @test_throws BoundsError @inferred(copyto!(similar(data, 5), data_enc))
    end
end # testset
