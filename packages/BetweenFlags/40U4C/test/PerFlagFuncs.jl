using Test
using BetweenFlags.PerFlagFuncs

@testset "split_by_consecutives edge case" begin
  @test [1] == split_by_consecutives([1])[1]
end

@testset "merge_odd_even" begin
  a = [1, 3, 5]
  b = [2, 4, 6]
  c = merge_even_odd(a, b)
  @test all([x==y for (x, y) in zip(c, [1, 2, 3, 4, 5, 6])])
end

function get_alternating_consecutive_filter(A, B)
  dupes = [x for x in A for y in B if x==y]
  A = [x for x in A if !any([x == y for y in dupes])]
  B = [x for x in B if !any([x == y for y in dupes])]
  sort!(A)
  sort!(B)
  (C, D) = get_alternating_consecutive_vector(A, B)
  M = merge_even_odd(C, D)
  return M
end

@testset "get_alternating_consecutive_vector" begin
  # A few general cases:
  A = [11, 5, 6, 20, 2, 1, 4, 15, 12, 7, 18, 14]
  B = [5, 3, 16, 17, 13, 9, 20, 14, 1, 11]
  M_correct = [2, 3, 4, 9, 6, 9, 7, 13, 12, 13, 15, 16]
  M = get_alternating_consecutive_filter(A, B)
  @test all([x==y for (x,y) in zip(M, M_correct)])

  A = [1, 3, 4, 5, 6, 7, 10, 11, 15, 16, 17]
  B = [2, 8, 9]
  M_correct = [1, 2, 3, 8, 4, 8, 5, 9, 6, 9]
  M = get_alternating_consecutive_filter(A, B)
  @test all([x==y for (x,y) in zip(M, M_correct)])

  A = [5, 7, 14, 20]
  B = [1, 4, 9, 13, 17]
  M_correct = [5, 9, 7, 9, 14, 17]
  M = get_alternating_consecutive_filter(A, B)
  @test all([x==y for (x,y) in zip(M, M_correct)])

  # Empty result case:
  A = [8, 10]
  B = [4]
  M_correct = Int64[]
  M = get_alternating_consecutive_filter(A, B)
  @test all([x==y for (x,y) in zip(M, M_correct)])

  # Some edge cases:
  A = Int64[]
  B = [4]
  M_correct = Int64[]
  M = get_alternating_consecutive_filter(A, B)
  @test all([x==y for (x,y) in zip(M, M_correct)])

  A = [1]
  B = Int64[]
  M_correct = Int64[]
  M = get_alternating_consecutive_filter(A, B)
  @test all([x==y for (x,y) in zip(M, M_correct)])

  A = Int64[]
  B = Int64[]
  M_correct = Int64[]
  M = get_alternating_consecutive_filter(A, B)
  @test all([x==y for (x,y) in zip(M, M_correct)])
end


@testset "Test generator" begin
  # This function is a bit difficult to test automatically.
  # So, this is a test generator, and its test results are
  # trivially satisfied.

  # print_IO = false
  N_A = Base.rand(10:50)[1]
  N_B = Base.rand(10:50)[1]
  A = unique([Base.rand(1:20)[1] for x in 1:Base.rand(1:N_A)])
  B = unique([Base.rand(1:20)[1] for x in 1:Base.rand(1:N_B)])
  dupes = [x for x in A for y in B if x==y]
  A = [x for x in A if !any([x == y for y in dupes])]
  B = [x for x in B if !any([x == y for y in dupes])]
  sort!(A)
  sort!(B)
  # if print_IO
  #   print("\n------------------------- Original\n")
  #   print("A = ", A,"\n")
  #   print("B = ", B,"\n")
  # end
  (C, D) = get_alternating_consecutive_vector(A, B)
  M = merge_even_odd(C, D)
  @test all([x==y for (x,y) in zip(M, M)])
  # if print_IO
  #   print("M = ", M,"\n")
  #   print("\n-------------------------\n")
  # end
end
