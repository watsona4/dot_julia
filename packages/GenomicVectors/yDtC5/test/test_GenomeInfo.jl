module TestGenomeInfo

using GenomicVectors
using Test
using GenomicFeatures

@testset begin

    ## GenomeInfo
    chrs = ["chr1","chr2","chrX"]
    csyms = [Symbol(x) for x in chrs]
    x = GenomeInfo("hg19",chrs,Int64[3e5,2e5,1e4])
    @test length(x) == 3
    @test genome(x) === "hg19"
    @test chr_lengths(x) == Int64[3e5,2e5,1e4]
    @test chr_offsets(x) == Int64[0,3e5,5e5]
    @test chr_ends(x) == cumsum(Int64[3e5,2e5,1e4])
    @test chr_names(x) == csyms
    io = IOBuffer()
    @test typeof(show(io,x)) == Nothing # At least test that show does not give error
    @test x[:chr2] == 500000
    @test x["chr2"] == 500000
    @test x[2] == 500000

    ## same genome
    chrinfo1 = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])
    chrinfo2 = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])
    chrinfo3 = GenomeInfo("hg20",["chr14","chr2","chrX"],Int64[4e5,2e5,1e4])
    @test ==(chrinfo1, chrinfo2) == true
    @test ==(chrinfo1, chrinfo3) == false

end # testset

end # module
