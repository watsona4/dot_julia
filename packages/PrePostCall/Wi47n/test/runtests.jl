using Test
using PrePostCall

struct NNegativeException <: Exception end
struct NSmallerException <: Exception end
struct NLargerException <: Exception end
struct NZeroException <: Exception end
struct BeforeException <: Exception end
struct FixLengthException <: Exception end

@pre function positive(x::Int)
    x<0 && throw(NNegativeException())
end

@pre function larger(x,y)
    x<y && throw(NSmallerException())
end

@post function not0(res::Int)
    res==0 && throw(NZeroException())
end

@post function smaller(x,y)
    x>y && throw(NLargerException())
end

@post function fixLength(v::Vector{Float64})
    length(v)>3 && throw(FixLengthException())
end

@post function multret(x,y)
    x>y && throw(NSmallerException())
end

module Level1
using PrePostCall
using Test
struct InModException <: Exception end
@pre function inmod(x::Int)
    throw(InModException())
end
@inmod function foo(x)
    x
end
function bar(x)
    foo(x)
end
function baz(x)
    @test_throws InModException foo(x)
end
end

@testset "PrePostCall" begin
    @testset "Pre-Single" begin
        @positive function foo(x::Int,y::T) where T<:Number
            return x^y
        end
        @positive a function foo2(a::Int,y::T) where T<:Number
            return a^y
        end
        @test foo(10,10) == 10^10
        @test_throws NNegativeException foo(-1,10)
        @test foo2(10,10) == 10^10
        @test_throws NNegativeException foo2(-1,10)
    end

    @testset "Pre-Two" begin
        @larger function foo(x::Int,y::T) where T<:Number
            return x^y
        end
        @larger a,y function foo2(a::Int,y::T) where T<:Number
            return a^y
        end
        @test foo(10,10) == 10^10
        @test_throws NSmallerException foo(-1,10)
        @test foo2(10,10) == 10^10
        @test_throws NSmallerException foo2(-1,10)
    end

    @testset "Pre-Multiple" begin
        @positive @larger function foo(x::Int,y::T) where T<:Number
            return x^y
        end
        @larger x,b @positive function foo2(x::Int,b::T) where T<:Number
            return x^b
        end
        @test foo(10,10) == 10^10
        @test foo2(10,10) == 10^10
        @test_throws NNegativeException foo(-1,10)
        @test_throws NSmallerException foo2(-1,10)
        @test_throws NNegativeException foo2(-1,-2)
        @test_throws NSmallerException foo2(1,20)
    end

    @testset "Post-Single" begin
        @not0 function foo(x::Int,y::T) where T<:Number
            x^y
        end
        @not0 a function foo2(x::Int,y::T) where T<:Number
            a = x^y
            return 2*a
        end
        @not0 a function foo3(x::Int,y::T) where T<:Number
            a = x^y
            throw(BeforeException())
            return a
        end
        @test foo(10,10) == 10^10
        @test_throws NZeroException foo(0,10)
        @test foo2(10,10) == 2*10^10
        @test_throws NZeroException foo2(0,10)
        @test_throws BeforeException foo3(0,10)
    end

    @testset "Post-Two" begin
        @smaller x,a function foo(x::Int,a::T) where T<:Number
            return x^a
        end
        @smaller res,con function foo2(x::Int,y::T) where T<:Number
            con = 100
            res = x^y
            return res
        end
        @test foo(10,10) == 10^10
        @test_throws NLargerException foo(2,0)
        @test foo2(5,2) == 5^2
        @test_throws NLargerException foo2(10,10)
    end
    @testset "Pre-Post" begin
        @not0 @larger y,x function foo(x::Int,y::T) where T<:Number
            return x^y
        end
        @test foo(2,3) == 2^3
        @test_throws NSmallerException foo(2,1) 
        @test_throws NZeroException foo(0,2) 
    end
    @testset "Module" begin
        @test_throws Main.Level1.InModException Level1.foo(1)
        @test_throws Main.Level1.InModException Level1.bar(1)
        Main.Level1.baz(1)
    end
    @testset "No return" begin
        v = [1.0,2.0,3.0]
        @fixLength v function foo!(v)
            push!(v,1.0)
        end
        @fixLength v function baz!(v)
            v[1] = 2.0
        end
        @test baz!(v) == nothing
        @test_throws FixLengthException foo!(v)
    end
    
    @testset "Multiple Return" begin
        @multret function foo(x,y)
            return x,y
        end
        @test_throws NSmallerException foo(2,1)
        @test foo(1,2) == (1,2)
    end

    @testset "Short Syntax explicit Pre" begin
        @positive x @positive y z function foo(x,y,z)
            return (x,y,z)
        end
        @test foo(1,2,3) == (1,2,3)
        @test_throws NNegativeException foo(-1,2,3) 
        @test_throws NNegativeException foo(1,-2,3) 
        @test_throws NNegativeException foo(1,2,-3) 
    end

    @testset "Short Syntax explicit Post" begin
        @not0 x @not0 y z function foo(x,y,z)
            return (x,y,z)
        end
        @test foo(1,2,3) == (1,2,3)
        @test_throws NZeroException foo(0,2,3) 
        @test_throws NZeroException foo(1,0,3) 
        @test_throws NZeroException foo(1,2,0) 
    end
    
end

