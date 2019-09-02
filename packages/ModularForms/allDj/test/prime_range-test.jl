include("../src/prime_range.jl")

function test_prime_range_length()
	print("prime_range.length...")
  
  @test length(prime_range(0)) == 0
  @test length(prime_range(1)) == 0
  @test length(prime_range(2)) == 1
  @test length(prime_range(100)) == 25 
	println("PASS")
end

function test_prime_range_elements()
	print("prime_range.elements...")
  
  @test prime_range(2) == [2]
  @test prime_range(10) == [2, 3, 5, 7]
  @test prime_range(100)[20] == 71
	println("PASS")
end

function test_prime_range()
	test_prime_range_length()
	test_prime_range_elements()

	println("")
end
