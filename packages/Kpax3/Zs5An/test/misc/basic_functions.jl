# This file is part of Kpax3. License is MIT.

function test_basic_functions_shuffleunits()
  x = [1; 2; 3; 4; 5; 6]
  y = [1; 2; 3; 4; 5; 6]

  S = 4

  N = 1000000

  p1 = 1 / factorial(length(x))
  p2 = 1 / factorial(S)

  v1 = 0
  v2 = 0

  for i in 1:N
    Kpax3.shuffleunits!(x)

    if x == [3; 1; 2; 4; 5; 6]
      v1 += 1
    end

    Kpax3.shuffleunits!(y, S)

    if y == [2; 1; 3; 4; 5; 6]
      v2 += 1
    end
  end

  v1 /= N
  v2 /= N

  @test isapprox(v1, p1, atol=0.005)
  @test isapprox(v2, p2, atol=0.005)

  nothing
end

test_basic_functions_shuffleunits()
