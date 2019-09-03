using  Test
using SimplePosets, SimplePosetAlgorithms

P = BooleanLattice(5)
C = max_chain(P)
@test length(C) == 6
@test height(P) == 6

A = max_antichain(P)
@test length(A) == 10
@test width(P) == 10

R = realizer(P,5)
Q = realize_poset(R)
@test P==Q

P = StandardExample(4)
@test dimension(P) == 4
