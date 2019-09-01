using Test, GetGene, DataFrames

snps = ["rs113980419", "rs17367504", 
"rs113980419", "rs2392929", "rs11014171",
"78067132", "1465537", "Affx-4150211"]

loci = ["C1orf167", "MTHFR", "C1orf167", 
"No gene listed", "CACNB2", "No gene listed",
"No gene listed", "snpid not in database"]

genedict = Dict("annotation_release" => "Homo sapiens Annotation Release 109",
"gene_name"          => "solute carrier family 39 member 8",
"gene_locus"         => "SLC39A8",
"gene_id"            => "64116",
"seq_id"             => "NC_000004.12",
"gene_is_pseudo"     => "0",
"gene_orientation"   => "1")

emptydict = Dict("Empty" => "No gene info listed for ref SNP ID")

df = DataFrame(rsid = snps)

@testset "snpid match" begin
    @test getgenes(snps) == loci
    @test getgenes(df; idvar = "rsid") == loci
    @test getgenes(2270993) == "PTPRJ"
end

@testset "Argument Error" begin
    @test_throws ArgumentError getgenes(df)
    @test_throws ArgumentError getgeneinfo("Affx-4150211")
end

@testset "get gene info" begin
    @test getgeneinfo("rs13107325") == genedict
    @test getgeneinfo("rs1173771") == emptydict
end


