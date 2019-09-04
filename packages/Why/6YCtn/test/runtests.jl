using Test, Why
println("Starting tests")
for i = 1:10000
    @test typeof(why())==String
    @test length(why())>0
end
