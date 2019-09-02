
#a few light tests to catch basic issues

commObj = SerialComm{UInt32, UInt8, UInt16}()
map = BlockMap(20, commObj)

function basicTests(graph)
    @test !isLocallyIndexed(graph)
    @test isGloballyIndexed(graph)
    @test isFillActive(graph)
    @test !isFillComplete(graph)
    @test !hasColMap(graph)
    @test 0 == getNumEntriesInGlobalRow(graph, 1)
end

graph = CSRGraph(map, UInt16(15), STATIC_PROFILE, Dict{Symbol, Any}())
@test JuliaPetra.checkInternalState(graph)
@test map == getMap(graph)
@test STATIC_PROFILE == getProfileType(graph)
basicTests(graph)

graph = CSRGraph(map, UInt16(15), STATIC_PROFILE, Dict{Symbol, Any}(:debug=>true))
@test JuliaPetra.checkInternalState(graph)
@test map == getMap(graph)
@test STATIC_PROFILE == getProfileType(graph)
basicTests(graph)
insertGlobalIndices(graph, 1, [2, 3])
@test 2 == getNumEntriesInGlobalRow(graph, 1)

graph2 = CSRGraph(map, UInt16(15), DYNAMIC_PROFILE, Dict{Symbol, Any}(:debug=>true))
@test JuliaPetra.checkInternalState(graph)
@test map == getMap(graph2)
@test DYNAMIC_PROFILE == getProfileType(graph2)
basicTests(graph2)
@test 0 == getNumEntriesInGlobalRow(graph2, 1)

impor = Import(map, map)
doImport(graph, graph2, impor, REPLACE)
@test 2 == getNumEntriesInGlobalRow(graph2, 1)


commObj = SerialComm{UInt8, Int8, UInt16}()
map = BlockMap(20, commObj)

@test_throws InvalidArgumentError CSRGraph(map, UInt16(15), STATIC_PROFILE, Dict{Symbol, Any}())


#TODO ensure result of CSRGraph(rowMap, colMap, localGraph, plist) is fill complete
#TODO ensure CSRGraph(rowMap, colMap, rowOffsets, entries, plist) sets up local graph correctly (same length and content in local graph as was given to constructor)
