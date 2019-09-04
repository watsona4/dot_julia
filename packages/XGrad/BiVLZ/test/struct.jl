mutable struct Linear
    W
    b
end

Linear() = Linear(rand(1,1), rand(1))


function linear_cost(m::Linear, x, y)
    sum((m.W * x .+ m.b .- y) .^ 2)
end
    
function linear_cost_flat(W, b, x, y)
    sum((W * x .+ b .- y) .^ 2)
end


@testset "struct" begin
    W = randn(500, 784)
    b = randn(500)
    m = Linear(W, b)
    x = randn(784, 100)
    y = randn(500)
    inputs = [:m => m, :x => x, :y => y]
    flat_inputs = [:W => W, :b => b, :x => x, :y => y]
        
    # first check that df with flat model is correct
    test_compare(linear_cost_flat; flat_inputs...)
    
    # now check that results from flat and structured models are the same
    df_flat = xdiff(linear_cost_flat; flat_inputs...)
    r, dW_, db_, dx_, dy_ = df_flat(W, b, x, y)
    
    df = xdiff(linear_cost; inputs...)
    r, dm, dx, dy = df(m, x, y)
        
    @test isapprox(dW_, dm.W)
    @test isapprox(db_, dm.b)
    @test isapprox(dx_, dx)
    @test isapprox(dy_, dy)
end
