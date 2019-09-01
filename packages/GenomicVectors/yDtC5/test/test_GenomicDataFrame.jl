module TestGenomicPositions

using GenomicVectors
using Test
using DataFrames

@testset begin

    genomeinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])
    chrs = ["chr2","chr1","chr2","chrX"]
    pos = Int64[3e4,4.2e3,1.9e5,1e4]
    gp = GenomicPositions(pos,chrs,genomeinfo)
    dt = DataFrame(a=1:4,b=5:8)
    gt = GenomicDataFrame(gp,dt)
    @test isa(gt,GenomicDataFrame)
    @test size(gt) == (4,2)
    gt = gt[1:2,1:2]
    @test isa(gt,GenomicDataFrame)
    @test size(gt) == (2,2)
    @test table(gt) == GenomicVectors._table(gt)
    @test rowindex(gt) == GenomicVectors._rowindex(gt)
    @test table(gt) == DataFrame(a=1:2,b=5:6)
    @test rowindex(gt) == GenomicPositions(pos[1:2],chrs[1:2],genomeinfo)
    gt = GenomicDataFrame(gp,dt)
    @test convert(Vector,gt[:b]) == convert(Vector,gt[2])
    gt[2] = [4,3,2,1]
    @test convert(Vector,gt[2]) == [4,3,2,1]
    gt[2:3,[2]] = [7,6]
    @test convert(Vector,gt[2]) == [4,7,6,1]

    ## Interfaces
    @test starts(gt) == starts(gp)
    @test ends(gt) == ends(gp)
    @test strands(gt) == strands(gp)
    @test chr_info(gt) == chr_info(gp)
    @test genostarts(gt) == genostarts(gp)
    @test genoends(gt) == genoends(gp)

    ## Searches
    chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])
    gr1 = GenomicRanges( [30123,40456,40000],[30130,40500,40100],chrinfo )
    gr2 = GenomicRanges( [100,30123,40000],[200,30130,40200],chrinfo )
    dt = DataFrame(a=1:3,b=6:8)
    gr = GenomicDataFrame(gr1,dt)
    @test indexin(gr,gr2,true) == [2,nothing,nothing]
    @test findin(gr,gr2,true) == [1]
    @test in(gr,gr2,true) == BitArray([ true, false, false ])
    @test indexin(gr,gr2,false) == [2,nothing,3]
    #@test findin(gr,gr2,false) == [1,3]
    @test in(gr,gr2,false) == BitArray([ true, false, true ])
    dt3 = DataFrame(a=1:3,q=3:-1:1)
    gr3 = GenomicDataFrame(gr2,dt3)
    @test indexin(gr,gr3,false) == [2,0,3]
    #@test findin(gr,gr3,false) == [1,3]
    @test in(gr,gr3,false) == BitArray([ true, false, true ])

    ## Table ops
    chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])
    gr1 = GenomicRanges( [30123,40456,40000],[30130,40500,40100],chrinfo )
    gr2 = GenomicRanges( [100,30123,40000],[200,30130,40200],chrinfo )
    dt1 = DataFrame(a=1:3,b=6:8)
    dt2 = DataFrame(a=4:6,c=9:11)
    gt1 = GenomicDataFrame(gr1,dt1)
    gt2 = GenomicDataFrame(gr2,dt2)
    out = join(gt1, gt2, exact = false)
    @test names(out) == [:a,:b,:a_1,:c]
    @test out[:a] == [1,3]
    out = join(gt1, gt2, exact = true)
    @test names(out) == [:a,:b,:a_1,:c]
    @test out[:a] == [1]
    out = join(gt1, gt2, kind = :semi, exact = false)
    @test names(out) == [:a,:b]
    @test out[:a] == [1,3]
    out = join(gt1, gt2, kind = :anti, exact = false)
    @test names(out) == [:a,:b]
    @test out[:a] == [2]


end # testset

end # module
