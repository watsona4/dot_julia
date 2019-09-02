#TODO: Write more tests
using Test
using GymSpaces

test_case1 = (
    Discrete(3),
    TupleSpace((Discrete(5), Discrete(10))),
    TupleSpace((Discrete(5), Box([0, 0], [1, 5], Float32))),
    TupleSpace((Discrete(5), Discrete(2), Discrete(2))),
    MultiDiscrete([2, 2, 100]),
    DictSpace(Dict("position" => Discrete(5),
                   "velocity" => Box([0, 0], [1, 5], Float32)))
)

test_case2 = (
    (Discrete(3), Discrete(4)),
    (MultiDiscrete([2, 2, 100]), MultiDiscrete([2, 2, 8])),
    (MultiBinary(8), MultiBinary(7)),
    (Box([-10, 0], [10, 10], Float32), Box([-10, 0], [10, 9], Float32)),
    (TupleSpace([Discrete(5), Discrete(10)]), TupleSpace([Discrete(1), Discrete(10)])),
    (DictSpace(Dict("position" => Discrete(5))), DictSpace(Dict("position" => Discrete(4)))),
    (DictSpace(Dict("position" => Discrete(5))), DictSpace(Dict("speed" => Discrete(5)))),
)

@testset "samples are in the same space" begin
    @testset "$space" for space in test_case1
        sample_1 = sample(space)
        sample_2 = sample(space)
        @test sample_1 ∈ space
        @test sample_2 ∈ space
    end
end

@testset "test inequality" begin
    @testset "$spaces" for spaces in test_case2
        space1, space2 = spaces
        @test space1 != space2
    end
end




# Special tests for the Box Space

test_case_box1 = (
    [2, -1, (3, 2), Int32],
    [-2, -4, (2,), Float32],
    [4.4, -2, (1, 4, 3), Int32],
    [2.2, -6, (3, ), Float32]
)

@testset "low > high for integers" begin
    @testset "$case" for case in test_case_box1
        if case[4] <: Integer
            case[1] = ceil(case[1])
            case[2] = floor(case[2])
        end
        correctlow = case[4](case[2]) .+ zeros(case[4], case[3])
        correcthigh = case[4](case[1]) .+ zeros(case[4], case[3])
        testbox = Box(case...)
        @test testbox.low == correctlow
        @test testbox.high == correcthigh
    end
end

test_case_box2 = (
    [[3, 1, 2], [2, 1, 5], Float32],
)

@testset "low > high for arrays" begin
    @testset "$case" for case in test_case_box2
        @test try
            Box(case...)  # Box for array must give an AssertionError when
        catch(y)          # low > high
            isa(y, AssertionError) && true
        end
    end
end


test_case_box3 = (
    ([-2.1, 0.3, 5.7], [3.2, 1.6, 10.3]),
    (-3.2, 4.4, (5,))
)

@testset "Data type is integer and bounds are of floating type" begin
    @testset "$case" for case in test_case_box3
        test_box = Box(case..., Int32)
        @test all(test_box.low .>= case[1])
        @test all(test_box.high .<= case[2])
    end
end

test_case_box4 = (
    (Box([3, 3, 1], [8, 9, 10], Int32) => Box([3, 3, 1], [8, 9, 10], Int32)),
    (Box([0, 0, 1], [2, 4, 3], UInt16) => Box([0, 0, 1], [2, 4, 3], UInt8)),
)

@testset "Equal box spaces" begin
    @testset "$case" for case in test_case_box4
        @test case.first == case.second
    end
end

test_case_box5 = (
    (Box([2.2, 3.1], [6.7, 8.3], Float32) => Box([2.2, 3.1], [6.7, 8.3], Float64)),
    (Box(0, 126, (3, 2), UInt32) => Box(0, 126, (3, 2), Float32)),
)

@testset "Unequal box spaces with equal bounds and unequal dtypes" begin
    @testset "$case" for case in test_case_box5
        @test case.first != case.second
    end
end
