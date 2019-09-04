using Profile, Random, Test, TrackingHeaps

function many_issorted_tests(
  Vs = [Int64, Float64, BigInt],
  Ks = [UInt16, Int64],
  Ns = [2, 3, 4, 7, 16],
  Os = [MinHeapOrder, MaxHeapOrder],
  Ss = [SafeFromYourself, NoTrainingWheels]
)
  for V in Vs, K in Ks, N in Ns, O in Os, S in Ss
    issorted_test(V, K, N, O, S)
  end
end

function issorted_test(
  ::Type{V}, ::Type{K}, N, ::Type{O}, ::Type{S}
) where {K, V, O, S}
  curr_lt(x, y) = TrackingHeaps.is_higher_than(O, x, y)
  @testset "track! and pop! can be used to (reverse) sort" begin
    mt0 = Random.MersenneTwister(0)
    if V == BigInt
      minbgv = parse(BigInt, "-10000000000000000000")
      maxbgv = parse(BigInt,  "10000000000000000000")
      values = rand(mt0, big.(minbgv:maxbgv), 1000)
    else
      values = rand(mt0, V, 1000)
    end
    heap = TrackingHeap(V; K = K, N = N, O = O, S = S)

    @test isempty(heap)

    size = 0
    for value in values
      track!(heap, value)
      size += 1
      @test length(heap) == size
    end

    sorted_values = empty(values)
    sizehint!(sorted_values, length(values))

    for i = 1:length(values)
      _, value = pop!(heap)
      size -= 1
      @test length(heap) == size
      push!(sorted_values, value)
    end

    @test isempty(heap)
    @test issorted(sorted_values; lt = curr_lt)
  end
end

# TODO: ideally we should test a method that uses other methods after 
# we already tested the individual parts, but this is not done here
function runtests()
  @testset "basic example usage" begin
    heap = TrackingHeap(Float64, K = UInt8)
    @test isempty(heap)
    @test iszero(length(heap))
    @test isa(length(heap), UInt8)
    expected_first_trck = next_tracker(heap)
    first_trck = track!(heap, 50.0)
    @test first_trck == expected_first_trck
    @test !isempty(heap)

    expected_second_trck = next_tracker(heap)
    second_trck = track!(heap, 25.0)
    @test second_trck == expected_second_trck
    @test length(heap) === UInt8(2)
    @test top(heap) == Pair(second_trck, 25.0)

    update!(heap, first_trck, 10.0)
    @test heap[first_trck] == 10.0
    @test top(heap) == Pair(first_trck, 10.0)

    heap[first_trck] = 5.0
    @test heap[first_trck] == 5.0
    @test top(heap) == Pair(first_trck, 5.0)

    heap[UInt8(10)] = 1.0
    @test heap[UInt8(10)] == 1.0
    @test top(heap) == Pair(UInt8(10), 1.0)

    renew_tracker!(heap, UInt8(10), UInt8(5))
    @test heap[UInt8(5)] == 1.0
    @test top(heap) == Pair(UInt8(5), 1.0)

    renew_tracker!(heap, UInt8(5)) # new trck will be largest already used + 1
    @test heap[UInt8(11)] == 1.0
    @test top(heap) == Pair(UInt8(11), 1.0)

    empty!(heap)
    @test isempty(heap)
    @test next_tracker(heap) === UInt8(12)
    first_trck = track!(heap, 7.0)
    @test first_trck === UInt8(12)
    @test heap[first_trck] == 7.0
    @test !isempty(heap)

    empty!!(heap)
    @test isempty(heap)
    @test next_tracker(heap) === UInt8(1)
    first_trck = track!(heap, 8.0)
    @test first_trck === UInt8(1)
    @test heap[first_trck] == 8.0
    @test !isempty(heap)

    vals_to_store = (1.0, 0.5, 3.5, 11.0, 77.7)
    popped_pair, trcks = pop_once_and_track_many!(heap, vals_to_store)
    @test popped_pair == Pair(Int8(1), 8.0)
    @test top(heap) == Pair(trcks[2], 0.5)
    @test length(heap) == UInt8(5)
    @test all(x -> x in heap, map(Pair, trcks, vals_to_store))
    @test all(x -> x in keys(heap), trcks)
    @test all(x -> x in values(heap), vals_to_store)

    ex_sval = extract_and_push!(heap, trcks[2], UInt8(12) => 0.8)
    @test ex_sval == 0.5
    @test top(heap) == Pair(UInt8(12), 0.8)
    @test length(heap) == UInt8(5)
    ex_sval = extract_and_push!(heap, trcks[5], UInt8(12) => 10.0)
    @test ex_sval == 77.7
    @test top(heap) == Pair(trcks[1], 1.0)
    @test heap[UInt8(12)] == 10.0
    @test length(heap) == UInt8(4) # 4 because 77.7 and 0.8 were removed

    iterated_pairs = [Pair(k, v) for (k, v) in heap]
    @test iterated_pairs == collect(pairs(heap))
    @test eltype(keys(heap)) == keytype(heap)
    @test eltype(values(heap)) == valtype(heap)

    popped_pair = pop!(heap)
    @test popped_pair == Pair(trcks[1], 1.0)
    @test top(heap) == Pair(trcks[3], 3.5)
    @test length(heap) == UInt8(3)

    delete!(heap, trcks[4])
    @test top(heap) == Pair(trcks[3], 3.5)
    @test length(heap) == UInt8(2)

    @test firstindex(heap) == trcks[3]
    @test lastindex(heap) == UInt8(12)
    @test heap[end] == 10.0

    other_heap = TrackingHeap(
      Float64, K = UInt8, init_pairs = [
        UInt8(12) => -9.0,
        UInt8(20) => 5.0,
        UInt8(100) => 15.0
      ]
    )
    merged_heap = merge(+, heap, other_heap)
    @test length(heap) == UInt8(2)
    @test length(other_heap) == UInt8(3)
    @test top(merged_heap) == Pair(UInt8(12), 1.0)
    @test length(merged_heap) == UInt8(4)

    other_heap = TrackingHeap(UInt8, K = Int64, init_val_coll = [0x00, 0x0A])
    renew_tracker!(other_heap, 1, 20)
    renew_tracker!(other_heap, 2, 100)
    merged_heap = merge(heap, other_heap)
    @test length(heap) == UInt8(2)
    @test length(other_heap) == UInt8(2)
    @test top(merged_heap) == Pair(20, UInt8(0))
    @test length(merged_heap) == UInt8(4)

    expected_next_trck = next_tracker(merged_heap)
    expected_return = (UInt8(0), expected_next_trck)
    @test expected_return == extract_and_track!(merged_heap, 20, UInt8(1))
    @test length(merged_heap) == 4
    @test top(merged_heap) == Pair(expected_next_trck, UInt8(1))

    heap = TrackingHeap(Float64, K = UInt8, init_val_heap = Float64[200.0])
    @test (Pair(UInt8(1), 200.0), UInt8(2)) == pop_and_track!(heap, 300.0)
    @test length(heap) == UInt8(1)
    @test top(heap) == Pair(UInt8(2), 300.0)

    @test get(heap, UInt8(1), 0.0) == 0.0
    @test length(heap) == UInt8(1)
    expected_next_trck = next_tracker(heap)
    @test get!(heap, UInt8(1), 0.0) == 0.0
    @test length(heap) == UInt8(2)
    @test top(heap) == Pair(UInt8(1), 0.0)
    @test getkey(heap, UInt8(1), UInt8(10)) == UInt8(1)
    @test getkey(heap, expected_next_trck, UInt8(20)) == UInt8(20)
    @test get(heap, UInt8(2), 0.0) == 300.0
    expected_next_trck = next_tracker(heap)
    @test get!(heap, UInt8(2), 0.0) == 300.0
    @test length(heap) == UInt8(2)

    @test get(() -> error("test wrong"), heap, UInt8(2)) == 300.0
    @test get!(() -> error("test wrong"), heap, UInt8(2)) == 300.0
    @test length(heap) == UInt8(2)

    @test get(() -> 7.0, heap, UInt8(20)) == 7.0
    @test length(heap) == UInt8(2)
    expected_next_trck = next_tracker(heap)
    @test get!(() -> 7.0, heap, UInt8(20)) == 7.0
    @test length(heap) == UInt8(3)
    @test heap[UInt8(20)] == 7.0
    @test !haskey(heap, expected_next_trck)

    @test eltype(heap) == Pair{keytype(heap), valtype(heap)}
  end

  many_issorted_tests()

  @testset "pop_and_track! also works" begin
    mt0 = Random.MersenneTwister(0)
    elems = rand(mt0, 1000)
    sorted_elems = sort(elems)
    threshold = 9 * div(length(elems), 10)
    best = sorted_elems[1:threshold]
    worst = sorted_elems[(threshold+1):length(elems)]
    elems_sorted_by_heap = Vector{eltype(elems)}()
    sizehint!(elems_sorted_by_heap, length(elems))

    heap = TrackingHeap(eltype(elems))
    for b_elem in best
      track!(heap, b_elem)
    end
    for w_elem in worst
      (_, e), _ = pop_and_track!(heap, w_elem)
      push!(elems_sorted_by_heap, e)
    end
    for _ = 1:length(best)
      _, e = pop!(heap)
      push!(elems_sorted_by_heap, e)
    end
    @test isempty(heap)
    @test elems_sorted_by_heap == sorted_elems
  end
end

# ugly workaround to get better track-allocation data (yes, run tests twice)
# the first time it compiles everything needed, and mess up the memory
# allocation as it counts allocation from the compilation process, then we
# reset the counters and run it again
for trial = 1:2
  Profile.clear_malloc_data()
  runtests()
end

