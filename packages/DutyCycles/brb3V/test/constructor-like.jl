@testset "constuctor-like methods" begin
    # return the default tolerance for a type or value (fractional
    # duration)
    Utol(value) = sqrt(eps(one(value)))
    # same, but plus/minus an epsilon-like value
    Utolplus(value) = Utol(value) + 2eps(one(value))
    Utolminus(value) = Utol(value) - eps(one(value))
    @testset "cycle" begin
        @test CoherentDutyCycle{
            typeof(default_period()),Float64,Int
        } == typeof(check(cycle(
            0.3default_period() => 1,
            0.7default_period() => 0
        )))
        @test CoherentDutyCycle{
            typeof(default_period()),Float64,Int
        } == typeof(check(cycle(
            (0.3±Utolminus(1.0))default_period() => 1,
            (0.7±Utolminus(1.0))default_period() => 0
        )))
        # To Do: tighten the excess tolerances of 3 and 7 (which
        #        requires error propagation between them and the sum
        #        of durations)
        @test CoherentDutyCycle{
            typeof(default_period()),Measurement{Float64},Int
        } == typeof(check(cycle(
            (0.3±3Utolplus(1.0))default_period() => 1,
            (0.7±7Utolplus(1.0))default_period() => 0
        )))
    end
    @testset "dutycycle w/ duty" begin
        # To Do: It is unfortunate to use extremavals and mean
        #        before the main checks for them, so change this
        #        to compare the dutycycle(...) result with an
        #        equivalent all to cycle(...).
        @test  (0,3) == extremavals(check(dutycycle(0.5, onvalue=3)))
        @test (1,10) ==
            extremavals(check(dutycycle(0.5, offvalue=1, onvalue=10)))
        @test 5.5 ≈
            mean(check(dutycycle(0.5, offvalue=1, onvalue=10)))
        @test dutycycle(50Unitful.percent, period = 2) ≈
            cycle(1 => 2, 1 => 0)
    end
    @testset "dutycycle w/out duty" begin
        @test check(dutycycle(avg = 0.3)) ≈
            check(dutycycle(0.3, onvalue = 1.0))
        @test check(dutycycle(avg = 3//10, onvalue = 2)) ≈
            check(dutycycle(3//20, onvalue = 2))
        @test check(dutycycle(avg = 0.3, onvalue = 2.0)) ≈
            check(dutycycle(0.15, onvalue = 2.0))
        @test check(
            dutycycle(avg = 1.3, onvalue = 2.0, offvalue = 1.0)
        ) ≈ check(dutycycle(0.3, onvalue = 2.0, offvalue = 1.0))
    end
end
