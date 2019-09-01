### Sample input
using DataFrames
ds = readtable("/Users/phaverty/.julia/v0.4/GenomicRanges/test/testData/HumanOmni2.5-4v1_B-H_MappingInformation.txt", header=true, eltypes = [UTF8String, UTF8String, Int, UTF8String, UTF8String, Int], separator='\t')
ds = ds[ ds[:,:NewChr] .!= "0", : ]
ds = ds[ ds[:,:NewChr] .!= "MT", : ]
ds = ds[ ds[:,:NewChr] .!= "XY", : ]
ds = ds[ ds[:,:NewMapInfo] .> 0, :]

sort!( ds, cols=[:NewChr,:NewMapInfo] )

info = GenomeInfo("hg19",["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","X","Y"], [249213967, 243068869, 197891568, 199986338, 180700260, 170919470, 159126310, 146301427, 142095050, 135499612, 134993190, 133779375, 115103529, 107287663, 102520751, 90170495, 81057996, 78015180, 59097752, 62947458, 48199982, 51224208, 155299100, 59883690])
pos = convert(Array{Int64}, ds[:,6])
chr = convert(Array{ASCIIString}, ds[:,5])

using JLD
save("/Users/phaverty/.julia/v0.4/GenomicRanges/test/testData/pinfo.jld", "pos", pos, "chr", chr, "info", info)
