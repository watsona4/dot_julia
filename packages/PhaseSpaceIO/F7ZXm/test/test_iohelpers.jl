module TestIOHelpers
using Test
using PhaseSpaceIO: setbit, getbit

@testset "getbit, setbit" begin
    for _ in 1:1000
        T = UInt32
        x = rand(T)
        i,j = rand(1:sizeof(T), 2)
        val = rand(Bool)
        xi = setbit(x,val, i)
        @test getbit(xi, i) == val
        if i == j 
            @test getbit(xi, j) == val
        else
            @test getbit(xi, j) == getbit(x, j)
        end
    end
end

@testset "getbit" begin
    T = UInt32
    @test getbit(T(1) << 23, 23) == true
    @test getbit(T(1) << 23, 2) == false
    
    for i in 1:sizeof(T)
        x = one(T) << i
        @test getbit(x, i) == true
        for j in 1:sizeof(T)
            i == j && continue
            @test getbit(x, j) == false
        end
    end
    
    for _ in 1:100
        x = rand(T)
        y = rand(T)
        i = rand(1:sizeof(T))
        @test getbit(~x, i) === ~getbit(x, i)
        @test getbit(x,i) & getbit(y, i) === getbit(x&y, i)
        @test getbit(x,i) | getbit(y, i) === getbit(x|y, i)
    end
end

end #module
