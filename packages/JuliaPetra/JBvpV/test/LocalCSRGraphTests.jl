
graph = LocalCSRGraph{UInt16, UInt32}()
@test Array{UInt16, 1}(undef, 0) == graph.entries
@test Array{UInt32, 1}(undef, 0) == graph.rowMap
@test 0 == numRows(graph)
@test_throws InvalidArgumentError maxEntry(graph)
@test_throws InvalidArgumentError minEntry(graph)


entries = UInt16[248, 230, 17, 26, 143, 101, 251, 13, 97, 380,
                    28, 16, 139, 9, 820, 637, 879, 156, 42, 339]
rowMap = UInt32[1, 3, 8, 9, 15, 18, 21]
graph = LocalCSRGraph(entries, rowMap)
@test entries === graph.entries
@test rowMap === graph.rowMap
@test 6 == numRows(graph)
@test 879 == maxEntry(graph)
@test 9 == minEntry(graph)
