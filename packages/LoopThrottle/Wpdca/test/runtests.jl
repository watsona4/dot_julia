module LoopThrottleTest

using LoopThrottle
using Test

function fast_while_loop_throttle(i0, i_increment, imax, rate, min_sleep_time)
    i = i0
    nloops = 0
    elapsed = @elapsed begin
        @throttle i while i < imax
            i += i_increment
            nloops += 1
        end max_rate=rate min_sleep_time=min_sleep_time
    end
    elapsed, nloops, i
end

function fast_while_loop_test(i0, i_increment, imax, rate, min_sleep_time)
    elapsed, nloops, i = fast_while_loop_throttle(i0, i_increment, imax, rate, min_sleep_time)
    @test nloops == div(imax - i0, i_increment)
    @test i == i0 + nloops * i_increment
    @test elapsed ≈ i_increment * (nloops - 1) / rate atol = 1e-2
end

@testset "fast while loop" begin
    # compile
    fast_while_loop_throttle(0, 2, 2000, Inf, 0.01)

    # test
    fast_while_loop_test(0, 2, 2000, 1000., 0.01)
    fast_while_loop_test(6, 3, 3000, 2000., 0.01)
    fast_while_loop_test(0, 1, 10, 5., 0.01)
end

@testset "fast for loop" begin
    n = 1000
    function f()
        result = 0
        @throttle i for i = 0 : n
            result += i
        end max_rate = 2 * n
        result
    end

    result = f()
    @test result == div(n * (n + 1), 2)
    elapsed = @elapsed f()
    @test elapsed ≈ 0.5 atol = 5e-2
end

@testset "fencepost" begin
    function f()
        @throttle i for i = 0 : 1
            nothing
        end
    end
    f()
    elapsed = @elapsed f()
    @test elapsed ≈ 1. atol = 1e-2
end

@testset "slow for loop" begin
    n = 10
    iteration_time = 0.2

    f = function ()
        @throttle i for i = 1 : n
            sleep(iteration_time)
        end max_rate = 10.
    end

    g = function ()
        for i = 1 : n
            sleep(iteration_time)
        end
    end

    f()
    g()
    @test @elapsed(f()) ≈ @elapsed(g()) atol = 1e-2
end

end
