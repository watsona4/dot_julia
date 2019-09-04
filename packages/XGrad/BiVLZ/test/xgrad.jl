
mutable struct Linear2
    W::Matrix{Float64}
    b::Vector{Float64}    
end

Linear2() = Linear2(rand(1,1), rand(1))

predict(m::Linear2, x) = m.W * x .+ m.b

@testset "xgrad" begin

    loss2(m::Linear2, x, y) = sum((predict(m, x) .- y).^2)
    
    m = Linear2(randn(10, 20), randn(10)); x = randn(20, 200); y = rand(10, 200)
    inputs = [:m => m, :x => x, :y => y]
    ctx = Dict()
    mem = Dict()
    l, dm, dx, dy = xgrad(loss2; mem=mem, m=m, x=x, y=y)
    mem_len = length(mem)
    @test mem_len > 0
    l, dm, dx, dy = xgrad(loss2; mem=mem, m=m, x=x, y=y)
    @test length(mem) == mem_len
    m = Linear2(randn(10, 20), randn(10)); x = randn(20, 200); y = rand(10, 200)
    l, dm, dx, dy = xgrad(loss2; mem=mem, m=m, x=x, y=y)
    @test length(mem) == mem_len

end
