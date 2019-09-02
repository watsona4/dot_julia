
#these tests take way too long to be included in the normal unit tests

using JuliaPetra
include("TypeStability.jl")
include("TestUtil.jl")

println("starting csrmatrix stability tests")
#stability tests
lidCount = length(stableLIDs)
pidCount = length(stablePIDs)
gidRange = 1:length(stableGIDs)
for Data in stableDatas
    for i in gidRange
        @inbounds GID = stableGIDs[i]
        for j in i:lidCount
            @inbounds LID = stableLIDs[j]
            for k in j:pidCount
                @inbounds PID = stablePIDs[k]
                @test is_stable(check_method(apply!, (MultiVector{Data, GID, PID, LID},
                                                        CSRMatrix{Data, GID, PID, LID},
                                                        MultiVector{Data, GID, PID, LID},
                                                        TransposeMode,
                                                        Data,
                                                        Data)))
            end
        end
    end
end

println("finished with csrmatrix stability tests")
