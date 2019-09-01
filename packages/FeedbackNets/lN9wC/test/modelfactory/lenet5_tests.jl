@testset "LeNet5" begin
    # Test that networks can be constructed, have the right length and that
    # outputs have the right shape
    batchsize = 5

    # Forward net:
    lenet = lenet5()
    input = rand(28, 28, 1, batchsize)
    @test length(lenet) == 9
    @test size(lenet(input)) == (10, batchsize)
    lenet = lenet5(pad=0)
    input = rand(32, 32, 1, batchsize)
    @test length(lenet) == 9
    @test size(lenet(input)) == (10, batchsize)

    # Feedback net:
    lenet = lenet5_fb()
    @test length(lenet) == 13
    input = rand(28, 28, 1, batchsize)
    net = wrapfb_lenet5(lenet, batchsize)
    @test net.init isa Dict
    @test net.state isa Dict
    @test net.init["conv2"] == zeros(10, 10, 16, batchsize)
    @test net.init["fc1"] == zeros(1, 1, 120, batchsize)
    @test size(net(input)) == (10, batchsize)
end # @testset "LeNet5"
