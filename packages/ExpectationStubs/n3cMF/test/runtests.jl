using ExpectationStubs
using ExpectationStubs: ExpectationValueMismatchError
using Test
using Test: @test_logs

@testset "basic stubbing" begin
    @stub foo
    @expect(foo(::Any)=32)
    @test foo(3)==32
    @test foo(4)==32

    @test_logs (:warn, "Expectation already set") @expect(foo(::Any)=34)
    @test foo(5)==34
end

@testset "multitype stubbing" begin
    @stub foo
    @expect(foo(::Int)=20)
    @expect(foo(::Bool)=39)
    @test foo(3)==20
    @test foo(false)==39
end

@testset "mulitple basic keyed stubs" begin
    @stub foo
    @expect(foo(1)=37)
    @expect(foo(2)=38)
    @test foo(2)==38
    @test foo(1)==37
end

@testset "multi-arg stubbing" begin
    @stub foo
    @expect(foo(4, ::Int)=32)
    @test foo(4,3)==32
    @test_throws ExpectationValueMismatchError foo(5, 3)==32
    @test_throws ExpectationValueMismatchError foo(3, 2.0)==32
end

@testset "mixed keyed stubs" begin
    @stub foo
    @expect(foo(1)=30)
    # Throws errors
    #@expect(foo(::Any)=370)
    @test_broken foo(2)==370
    @test foo(1)==30
end

@testset "All expectations used" begin
   @testset "value" begin 
        @stub foo
        @expect(foo(1)=30)
        @expect(foo(2)=35)

        foo(1)
        @test !all_expectations_used(foo)
        
        foo(2)
        @test all_expectations_used(foo)
    end
    @testset "typed" begin 
        @stub foo
        @expect(foo(::Int)=30)

        @test !all_expectations_used(foo)
        foo(2)
        @test all_expectations_used(foo)
    end

end

@testset "Expectations use count" begin

    @testset "basic" begin
        @stub foo
        @expect(foo(1)=30)
        @expect(foo(2)=35)
        @expect(foo(3)=40)

        @test @usecount(foo(1)) == 0
        foo(1)
        @test @usecount(foo(1)) == 1
        @test @usecount(foo(2)) == 0
        foo(1)
        
        @test @usecount(foo(1)) == 2

        @testset "total" begin
            foo(3)
            @test @usecount(foo(::Any)) == 3
            @test @usecount(foo(::Int)) == 3
        end
    end
end


@testset "Expectations used" begin

    @testset "basic" begin
        @stub foo
        @expect(foo(1)=30)
        @expect(foo(2)=35)

        @test foo(1) == 30
        @test @used(foo(1))
        @test !@used(foo(2))
    end

    @testset "mixed" begin
        @stub foo
        @expect(foo(::Int)=310)

        @test foo(105) == 310
        @test @used(foo(105))
        @test @used(foo(::Int))
        @test !@used(foo(2))
        @test !@used(foo(::Bool))
    end

    @testset "using a variable as the value #11" begin
        @stub bar

        b = 11
        @expect bar(b)=51

        @test bar(b) == 51
        @test @used bar(11)
        @test @used bar(b)
    end
end




########################################
include("donotcare.jl")
