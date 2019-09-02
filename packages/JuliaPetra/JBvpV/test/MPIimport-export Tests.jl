n = 4

srcMap = BlockMap(4*n, comm)
desMap = BlockMap(n*numProc(comm), collect((1:n) .+ n*(pid%4)), comm)

function basicMPITest(impor)
    if isa(impor, Import)
        data = impor.importData
    else
        data = impor.exportData
    end
    @test srcMap == data.source
    @test desMap == data.target
    @test 0 == data.numSameIDs
    @test isa(data.distributor, Distributor{UInt64, UInt16, UInt32})
    @test [] == data.permuteToLIDs
    @test [] == data.permuteFromLIDs
    #TODO test remoteLIDs, exportLIDs, exportPIDs
    @test true == data.isLocallyComplete
end


# basic import
basicMPITest(Import(srcMap, desMap))
basicMPITest(Import(srcMap, desMap, nothing))

# basic export
basicMPITest(Export(srcMap, desMap))
basicMPITest(Export(srcMap, desMap, nothing))
