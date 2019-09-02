
@testset "Basic Tests" begin
    bob = Developer("Bob", 10000)
    alice = SpecializedDeveloper("Alice", 15000, "Julia")
    
    shortjob = ConcreteJob(10,bob)
    @test_throws MethodError (longjob = ConcreteJob(100,alice)) 
    longjob = Job(100,alice)

    @test bob.name == "Bob"
    @test bob.salary == 10000
        
    @test alice.name == "Alice" 
    @test alice.salary == 15000    
    @test alice.language == "Julia"
        
    @test sumsalaries(bob, alice) == 25000
    @test shortjob.assigned_dev.name == "Bob"
    @test longjob.assigned_dev.name == "Alice"
end

@testset "Concretify Tests" begin
    bob = Developer("Bob", 10000)
    alice = SpecializedDeveloper("Alice", 15000, "Julia")
    
    vec = Vector{Developer}()
    
    push!(vec, bob)
    push!(vec, alice)
    
    @test vec[1] == bob
    @test vec[2] == alice    
    
    @concretify vec2 = Vector{Developer}()
    
    push!(vec2, bob)
    @test_throws MethodError push!(vec2, alice)
        
    @test vec2[1] == bob    
end
