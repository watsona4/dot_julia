using BDF, Compat.Test

origFilePath = joinpath(dirname(@__FILE__), "Newtest17-256.bdf")

dats, evtTab, trigs, statusChan = readBDF(origFilePath)

for ci in ([1, 2, 3], [1, 2, 3, 4, 5, 6], 1:14, [1, 3, 9, 11, 15], [5, 2, 7])

    local dats2, evtTab2, trigs2, statusChan2 = readBDF(origFilePath, channels = ci)

    @test size(dats2, 2) == size(dats, 2)
    @test size(dats2, 1) == length(ci)
    
    #@test_approx_eq(dats[ci, :], dats2)
    @test isequal(dats[ci, :], dats2)
    @test statusChan2 == statusChan
        
end

for (chanLabs, chanNum) in zip((["A1", "A2"], ["A1", "A3"], ["A3", "A1", "A11", "A16"]), ([1, 2], [1, 3], [3, 1, 11, 16]))

    local dats2, evtTab2, trigs2, statusChan2 = readBDF(origFilePath, channels = chanLabs)
    
    @test size(dats2, 2) == size(dats, 2)
    @test size(dats2, 1) == length(chanLabs)
    
    #@test_approx_eq(dats[el, :], dats2)
    #@test dats[el, :] ≈ dats2
    @test isequal(dats[chanNum, :], dats2)

    @test statusChan2 == statusChan
end

@test_throws(ErrorException, readBDF(origFilePath, channels = ["Z1", "A2"]))
