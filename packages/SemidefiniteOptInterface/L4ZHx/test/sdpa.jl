@testset "SDPA reader-writer" begin
    optimizer = SDOI.MockSDOptimizer{Float64}()
    MOI.read!(optimizer, "example.sdpa")
    filename = tempname() * ".sdpa"
    MOI.write(optimizer, filename)
    @test readlines("example.sdpa")[2:end] == readlines(filename)
end
