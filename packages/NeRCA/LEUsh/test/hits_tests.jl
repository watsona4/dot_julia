using NeRCA
using Test


hits = [Hit(1, 8, 100, 20, false),
        Hit(2, 9, 101, 21, true),
        Hit(3, 8, 112, 22, true),
        Hit(4, 8, 114, 23, false),
        Hit(5, 8, 134, 24, true),
        Hit(6, 8, 156, 25, false),
        Hit(7, 8, 133, 26, true),
        Hit(8, 8, 145, 26, false)]


# triggered()
thits = triggered(hits)
@test 4 == length(thits)
@test 9 == thits[1].dom_id


# nfoldhits()
twofoldhits = nfoldhits(hits, 10, 2)
@test 4 == length(twofoldhits)
threefoldhits = nfoldhits(hits, 15, 3)
@test 3 == length(threefoldhits)


# domhits()
dhits = domhits(hits)
@test 7 == length(dhits[8])
@test 20 == dhits[8][1].tot
@test dhits[8][6].triggered
