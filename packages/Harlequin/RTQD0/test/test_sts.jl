sts = SegmentedTimeSpan(
    start_time = 0.0,
    sampling_time = 1.0,
    segment_duration = 3600,
    num_of_segments = 24,
)

@test length(sts) == 24
@test minimum(sts[1]) == 0.0
@test maximum(sts[1]) == 3600.0 - 1.0

for idx in eachindex(sts)
    @test length(sts[idx]) == 3600
end

for cur_time_span in sts
    @test length(cur_time_span) == 3600
end

@test maximum(sts[end]) == 86400.0 - 1.0


sts = SegmentedTimeSpan(
    start_time = 0.0,
    sampling_time = 1,
    segment_duration = 3,
    num_of_segments = 4,
)

sequence = []
for cur_segment in sts
    append!(sequence, collect(cur_segment))
end

@test sequence == collect(0.0:1.0:11.0)
