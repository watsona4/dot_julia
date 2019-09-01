using Test
using ExtensibleScheduler: Priority
using Dates

@testset "Priority Tests" begin

    @testset "Priority Equality" begin
        p1 = Priority(DateTime(2010, 1, 1), 0)
        p2 = Priority(DateTime(2010, 1, 1), 0)
        @test p1 == p2
    end

    @testset "Priority Inequality" begin
        @testset "Same DateTime" begin
            p1 = Priority(DateTime(2010, 1, 1), 0)
            p2 = Priority(DateTime(2010, 1, 1), 1)
            @test p1 != p2
        end

        @testset "Same priority level" begin
            p1 = Priority(DateTime(2010, 1, 1), 0)
            p2 = Priority(DateTime(2010, 1, 2), 0)
            @test p1 != p2
        end
    end

    @testset "Priority order" begin
        p1 = Priority(DateTime(2010, 1, 2), 0)
        p2 = Priority(DateTime(2010, 1, 1), 0)
        @test p2 > p1

        p1 = Priority(DateTime(2010, 1, 1), 1)
        p2 = Priority(DateTime(2010, 1, 1), 0)
        @test p2 > p1
    end
end
