using BiobakeryUtils
using DataFrames
using Random
using Test
using Microbiome

@testset "Biobakery Utilities" begin
    abund = import_abundance_table("metaphlan_test.tsv")

    @test typeof(abund) <: DataFrame
    @test size(abund) == (42, 8)
    spec_long = taxfilter(abund, shortnames=false)
    @test size(spec_long) == (15, 8)
    phyl_short = taxfilter(abund, :phylum)
    @test size(phyl_short) == (2, 8)

    @test all(occursin.("|", spec_long[1]))
    rm_strat!(spec_long)
    @test !any(occursin.("|", spec_long[1]))

    @test !any(occursin.("|", phyl_short[1]))

    taxfilter!(abund, 2)
    @test abund == phyl_short

    # dm = getdm(abundancetable(rand(100,10)), BrayCurtis())
    # p = permanova(dm, repeat(["a", "b"], 5))
    # @test typeof(p) == DataFrame
    # @test size(p) == (3, 6)
end
