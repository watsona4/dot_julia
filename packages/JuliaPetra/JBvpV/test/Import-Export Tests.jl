#mainly just exercies the basic constructors

n = 8

serialComm = SerialComm{Int32, Bool, Int16}()
srcMap = BlockMap(n, n, serialComm)
desMap = BlockMap(n, n, serialComm)

function basicTest(impor)
    if isa(impor, Import)
        data = impor.importData
    else
        # basic exports are about the same anyways
        data = impor.exportData
    end
    @test srcMap == data.source
    @test desMap == data.target
    @test n == data.numSameIDs
    @test isa(data.distributor, Distributor{Int32, Bool, Int16})
    @test [] == data.permuteToLIDs
    @test [] == data.permuteFromLIDs
    @test [] == data.remoteLIDs
    @test [] == data.exportLIDs
    @test [] == data.exportPIDs
    @test true == data.isLocallyComplete
end

# basic import
basicTest(Import(srcMap, desMap))
basicTest(Import(srcMap, desMap, nothing))


# basic export
basicTest(Export(srcMap, desMap))
basicTest(Export(srcMap, desMap, nothing))
