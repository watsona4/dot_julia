using Test
using ExtensibleScheduler

@testset "Action" begin

    function return_noparam()
        "Returned from return_noparam"
    end

    function return_args(x)
        "Returned from return_args with $x"
    end

    function return_kwargs(; a="default")
        "Returned from return_kwargs with a=$a"
    end

    @testset "noparam" begin
        action = Action(return_noparam)
        expected = "Returned from return_noparam"
        @test run(action) == expected

        action = Action(return_noparam, ()...; Dict()...)
        @test run(action) == expected
    end

    @testset "args" begin
        action = Action(return_args, 3)
        expected = "Returned from return_args with 3"
        @test run(action) == expected        
    end

    @testset "kwargs" begin
        action = Action(return_kwargs; Dict(:a=>5)...)
        expected = "Returned from return_kwargs with a=5"
        @test run(action) == expected        
    end


end
