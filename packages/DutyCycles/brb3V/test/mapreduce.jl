@testset "mapreduce" begin
    # cases is a vector of tupels (desc, collection, sum, product)
    cases = []
    
    # simplest cases: no DutyCycle (to assert that nothing got broken)
    push!(cases, ("Real", [1,2,3.0,4], 10.0, 24.0))
    push!(cases, ("Unitful", [1m,2.0m,3m], 6.0m, 6.0m^3))
    
    # simple case: no units (but mixed types)
    Na = [check(dutycycle(0.5, onvalue=1)), 1, 3]
    Nsum = check(check(dutycycle(0.5, onvalue=1)) + 1 + 3)
    Nprod = check(check(dutycycle(0.5, onvalue=1)) * 1 * 3)
    push!(cases, ("DutyCycle and Float64", Na, Nsum, Nprod))
    
    # the critical case is mixing types, and using a Unitful.Quantity
    La = [check(dutycycle(0.5, onvalue=1))*1m, 1m, 3m]
    Lsum = check(check(dutycycle(0.5, onvalue=1m)) + 1m + 3m)
    Lprod = check(check(dutycycle(0.5, onvalue=1m)) * 1m * 3m)
    push!(cases, ("DutyCycle and Unitful", La, Lsum, Lprod))

    # these broken tests should be made to work without (re)defining
    # methods Base.sum or Base.prod. The problem is simply connected
    # to conversion (and corresponding implementation of Base.:+ and
    # Base.:*).
    @testset "$(case[1])" for case in cases
        desc, c, s, p = case
        @testset "sum" begin
            @test mean(check(sum(c))) ≈ mean(s)
            @test check(sum(c)) ≈ s
            @test check(sum(reverse(c))) ≈ s
            @test mean(check(sum(reverse(c)))) ≈ mean(s)
        end
        @testset "prod" begin
            @test mean(check(prod(c))) ≈ mean(p)
            @test check(prod(c)) ≈ p
            @test check(prod(reverse(c))) ≈ p
            @test mean(check(prod(reverse(c)))) ≈ mean(p)
        end
    end
end
