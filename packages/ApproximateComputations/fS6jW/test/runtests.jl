using Test
using ApproximateComputations

using ImportAll
@importall Base

@testset "Approximation Type" begin
## Approximation Tests
 a = Approximation(6.0)
 b = 4.0
 
 @test typeof(a - b) == Approximation{typeof(b)}
 @test typeof(a + b) == Approximation{typeof(b)}
 @test typeof(a * b) == Approximation{typeof(b)}
 @test typeof(a / b) == Approximation{typeof(b)}
 
 @test typeof(Get(a)) == Float64

end

@testset "AST Approximation" begin
	little(x)  = (x * 2) + 5
	
	@test UpdateEnvironmentForFunction(little) == nothing
	
	littletree = little(Variable(123))
	
	@test EmulateTree(littletree) == 251
	
	ReplaceSubTree(littletree, Variable(0), 1)
	
	@test EmulateTree(littletree) == 5
end

@testset "Loop Perforation" begin
	expr =	quote
				function newfunc()
					aa = 0
					for i in 1:10
						aa = aa + 1
					end
					aa
				end
			end
	
	LoopPerforation(expr, UnitRange, ClipFrontAndBack)
	eval(expr)
	@test newfunc() == 8

end

@testset "Memoisation" begin

	# Test custom overwrite hashing
	sinhash(fn, val) = hash(val)
	memoDict = Dict()
	ApproximateHashingMemoise(sin, memoDict, sinhash, 0.4)
	ApproximateHashingMemoise(sin, memoDict, sinhash, 0.1)
	
	@test ApproximateHashingMemoise(sin, memoDict, sinhash, 0.4) == 0.3894183423086505
	@test ApproximateHashingMemoise(sin, memoDict, sinhash, 0.1) == 0.09983341664682815

	# Test trending batched hash values
	trendingArray = []
	for i in 1:5000
	   push!(trendingArray,[0,0.0,0.0]) 
	end

	trendingsinhash(fn, val) = 1+Int64.(round(val*10.0))

	@test TrendingMemoisation(sin, trendingsinhash, trendingArray, 3, 0.5)  == 0.479425538604203
	@test TrendingMemoisation(sin, trendingsinhash, trendingArray, 3, 0.55) == 0.5226872289306592
	@test TrendingMemoisation(sin, trendingsinhash, trendingArray, 3, 0.51) == 0.48817724688290753
	@test TrendingMemoisation(sin, trendingsinhash, trendingArray, 3, 0.59) == 0.5563610229127838
	@test TrendingMemoisation(sin, trendingsinhash, trendingArray, 3, 0.59) == 0.5563610229127838
end