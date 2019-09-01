using DrawSimpleGraphs, SimpleGraphs
using Test
G =  Cycle(12)
DrawSimpleGraphs.draw(G)
@test 1==1
