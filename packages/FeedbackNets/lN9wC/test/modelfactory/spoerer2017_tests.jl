@testset "Spoerer2017" begin
    batchsize = 5
    channels = 3
    classes = 12
    maps = 45
    input1 = rand(28, 28, 1, batchsize)
    input2 = rand(32, 32, 3, batchsize)

    # test B model
    B = spoerer_model_b(Float32)
    @test size(B(input1)) == (10, batchsize)
    B = spoerer_model_b(Float64, channels=channels, inputsize=(32,32), classes=classes)
    @test size(B(input2)) == (classes, batchsize)

    # test model BK
    BK = spoerer_model_bk(Float32)
    @test size(BK(input1)) == (10, batchsize)
    BK = spoerer_model_bk(Float64, channels=channels, inputsize=(32,32), classes=classes)
    @test size(BK(input2)) == (classes, batchsize)

    # test model BF
    BF = spoerer_model_bf(Float32)
    @test size(BF(input1)) == (10, batchsize)
    BF = spoerer_model_bf(Float64, channels=channels, inputsize=(32,32), classes=classes)
    @test size(BF(input2)) == (classes, batchsize)

    # test model BL
    BL = spoerer_model_bl(Float32)
    h = Dict(
        "l1" => zeros(Float32, 28, 28, 32, batchsize),
        "l2" => zeros(Float32, 14, 14, 32, batchsize)
    )
    model = Flux.Recur(BL, h)
    @test size(model(input1)) == (10, batchsize)
    BL = spoerer_model_bl(
        Float64, channels=channels, inputsize=(32,32), classes=classes, features=maps
    )
    h = Dict(
        "l1" => zeros(32, 32, maps, batchsize),
        "l2" => zeros(16, 16, maps, batchsize)
    )
    model = Flux.Recur(BL, h)
    @test size(model(input2)) == (classes, batchsize)

    # test model BT
    BT = spoerer_model_bt(Float32)
    h = Dict(
        "l2" => zeros(Float32, 14, 14, 32, batchsize)
    )
    model = Flux.Recur(BT, h)
    @test size(model(input1)) == (10, batchsize)
    BT = spoerer_model_bt(
        Float64, channels=channels, inputsize=(32,32), classes=classes, features=maps
    )
    h = Dict(
        "l2" => zeros(16, 16, maps, batchsize)
    )
    model = Flux.Recur(BT, h)
    @test size(model(input2)) == (classes, batchsize)

    # test model BLT
    BLT = spoerer_model_blt(Float32)
    h = Dict(
        "l1" => zeros(Float32, 28, 28, 32, batchsize),
        "l2" => zeros(Float32, 14, 14, 32, batchsize)
    )
    model = Flux.Recur(BLT, h)
    @test size(model(input1)) == (10, batchsize)
    BLT = spoerer_model_blt(
        Float64, channels=channels, inputsize=(32,32), classes=classes, features=maps
    )
    h = Dict(
        "l1" => zeros(32, 32, maps, batchsize),
        "l2" => zeros(16, 16, maps, batchsize)
    )
    model = Flux.Recur(BLT, h)
    @test size(model(input2)) == (classes, batchsize)

end # @testset "Spoerer2017"
