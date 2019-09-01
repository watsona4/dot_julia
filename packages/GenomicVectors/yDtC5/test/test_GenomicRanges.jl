module TestGenomicRanges

using GenomicVectors
using Test
using GenomicFeatures
using DataFrames
using RLEVectors

@testset begin

# Creating
chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])
chrs = ["chr1","chr2","chr2","chrX"]
s = [100, 200, 300, 400]
e = [120, 240, 350, 455]
gr = GenomicRanges(chrs,s,e,chrinfo)
@test isa(gr,GenomicRanges)
io = IOBuffer()
@test typeof(show(io,gr)) == Nothing # At least test that show does not give error

@test_throws ArgumentError GenomicRanges(chrs,s,e[1:2],chrinfo)
@test_throws ArgumentError GenomicRanges(chrs,s,e,['.','.'],chrinfo)

# Indexing
@test gr[2] == Interval("hg19", 300000 + 200, 300000 + 240, STRAND_NA, 2)
@test gr[2:3] == GenomicRanges(chrs[2:3], s[2:3], e[2:3], chrinfo)
gr[2] = Interval("hg19", 40123, 40456, STRAND_POS)
@test gr == GenomicRanges([100,40123,300300,500400],[120,40456,300350,500455],[STRAND_NA,STRAND_POS,STRAND_NA,STRAND_NA],chrinfo)
@test_throws ArgumentError gr[1] = Interval("hg19",1,310000,STRAND_NA)

# Creating with strand
gr = GenomicRanges(chrs,s,e,['.','.','.','.'],chrinfo)
@test isa(gr,GenomicRanges)
gr = GenomicRanges(chrs,s,e,[STRAND_NA,STRAND_NA,STRAND_NA,STRAND_NA,],chrinfo)
@test isa(gr,GenomicRanges)
gs = genopos(s,chrs,chrinfo)
ge = genopos(e,chrs,chrinfo)
gr = GenomicRanges(ge,gs,['.','.','.','.'],chrinfo)
@test isa(gr,GenomicRanges)
gr = GenomicRanges(gs,ge,[STRAND_NA,STRAND_NA,STRAND_NA,STRAND_NA,],chrinfo)
@test isa(gr,GenomicRanges)
gr2 = GenomicRanges(gs,ge,[STRAND_POS,STRAND_NEG,STRAND_NA,STRAND_POS,],chrinfo)
@test copy(gr2) == gr2

# Describing
chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])
chrs = ["chr1","chr2","chr2","chrX"]
s = [100, 200, 300, 400]
e =  [120, 240, 350, 455]
gs = genopos(s,chrs,chrinfo)
ge = genopos(e,chrs,chrinfo)
gr = GenomicRanges(chrs,s,e,chrinfo)
@test starts(gr) == s
@test ends(gr) == e
@test widths(gr) == [21,41,51,56]
@test genostarts(gr) == gs
@test GenomicVectors._genostarts(gr) == gs
@test GenomicVectors._genoends(gr) == ge
@test genoends(gr) == ge
@test strands(gr) == [STRAND_NA,STRAND_NA,STRAND_NA,STRAND_NA]
@test GenomicVectors._strands(gr) == [STRAND_NA,STRAND_NA,STRAND_NA,STRAND_NA]
@test chromosomes(gr) == [:chr1, :chr2, :chr2, :chrX]

# Sorting
chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])
chrs = ["chr1","chr2","chr2","chrX"]
s = [400, 300, 200, 150]
e = s .+ 20
strand = ['.','+','-','+']
gr = GenomicRanges(chrs,s,e,strand,chrinfo)
@test issorted(gr) == false
gr2 = sort(gr)
@test gr2 == GenomicRanges( ["chr1","chr2","chr2","chrX"], [400,200,300,150], [420,220,320,170], ['.','-','+','+'], chrinfo )
@test issorted(gr2) == true
sort!(gr)
@test gr == gr2
@test sort!(gr,rev=true) == GenomicRanges( ["chrX","chr2","chr2","chr1"], [150,300,200,400], [170,320,220,420], ['+','+','-','.'], chrinfo )
gr = GenomicRanges(chrs,s,e,chrinfo)
@test sortperm(gr) == [1,3,2,4]

# Conversions
chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])
chrs = ["chr1","chr2","chr2","chrX"]
s = [400, 300, 200, 150]
e = s .+ 20
gr = GenomicRanges(chrs,s,e,chrinfo)
@test convert(DataFrame,gr) == DataFrame([chrs,s,e,[STRAND_NA,STRAND_NA,STRAND_NA,STRAND_NA]],[:Chromosome,:Start,:End,:Strand])
@test convert(Vector{String},gr) == ["chr1:400-420","chr2:300-320","chr2:200-220","chrX:150-170"]
ic = IntervalCollection([
                        Interval("hg19",400,420,'?',1),
                        Interval("hg19",300200,300220,'?',3),
                        Interval("hg19",300300,300320,'?',2),
                        Interval("hg19",500150,500170,'?',4)
                        ])
@test convert(IntervalCollection,gr) == ic
@test [ metadata(el) for el in ic ] == [1,3,2,4] # Another test that meta right
@test convert(Vector,gr) == [ (400,420), (300300,300320), (300200,300220), (500150,500170) ]
@test convert(GenomicPositions,gr) == GenomicPositions(s,chrs,chrinfo)

# Altering
chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])
chrs = ["chr1","chr2","chr2","chrX"]
s = [100, 200, 300, 400]
e =  [120, 240, 350, 455]
gr = GenomicRanges(chrs,s,e,chrinfo)
gr2 = GenomicRanges(chrs,s.+5,e.+5,chrinfo)
@test slide(gr,5) == gr2
slide!(gr,5)
@test gr == gr2
@test_throws ArgumentError slide!(gr,90000000000000)

# Searching
chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])
gr1 = GenomicRanges( [30123,40456,40000],[30130,40500,40100],chrinfo )
gr2 = GenomicRanges( [100,30123,40000],[200,30130,40200],chrinfo )
@test indexin(gr1,gr2) == [2,nothing,nothing]
@test intersect(gr1,gr2) == gr1[ [1] ]
@test setdiff(gr1,gr2) == gr1[ [2,3] ]
@test in(gr1,gr2,true) == BitArray([ true, false, false ])
@test indexin(gr1,gr2,false) == [2,nothing,3]
@test intersect(gr1,gr2,false) == gr1[ [1,3] ]
@test setdiff(gr1,gr2,false) == gr1[ [2] ]
@test in(gr1,gr2,false) == BitArray([ true, false, true ])
@test in(gr2)(gr1) == [true, false, false]

# Array ops from delegate
chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])
chrs = ["chr1","chr2","chr2","chrX"]
s = [400, 300, 200, 150]
e = s .+ 20
d = [STRAND_NA,STRAND_NA,STRAND_NA,STRAND_NA]
gr = GenomicRanges(chrs,s,e,d,chrinfo)
gr2 = GenomicRanges(chrs[1:2],s[1:2],e[1:2],d[1:2],chrinfo)
gr3 = GenomicRanges(chrs[3:4],s[3:4],e[3:4],d[1:2],chrinfo)
@test size(gr) == (4,)
@test length(gr) == 4
@test lastindex(gr) == 4
@test issubset(gr2,gr) == true
@test issubset(gr2,gr3) == false
@test vcat(gr,gr) == GenomicRanges(vcat(chrs,chrs),vcat(s,s),vcat(e,e),vcat(d,d),chrinfo)
@test union(gr2,gr3) == gr
gr = GenomicRanges(chrs,s,e,chrinfo)
append!(gr2,gr3)
@test gr2 == gr
gr2 = GenomicRanges(chrs[1:2],s[1:2],e[1:2],chrinfo)
prepend!(gr2,gr3)
@test gr2 == gr[ [3,4,1,2] ]
@test typeof(gr) == typeof(similar(gr))
@test typeof(gr) == typeof(similar(gr,2))
@test length(similar(gr,2)) == 2

# resize!
x = GenomicRanges(chrs,s,e,chrinfo)
y = x
@test resize!(x,2) == y[1:2]

# Other
chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])
chrs = ["chr1","chr2","chr2","chrX"]
s = [400, 300, 200, 150]
e = s .+ 20
d = [STRAND_NA,STRAND_NA,STRAND_NA,STRAND_NA]
gr = GenomicRanges(chrs,s,e,d,chrinfo)
empty!(gr)
@test gr == GenomicRanges(Int64[],Int64[],Strand[],chrinfo)

# Range ops
chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[1e3,2e3,2e4])
chrs = ["chr1","chr1","chr1","chrX"]
s = [100, 200, 220, 500]
e = [150, 250, 300, 600]
d = [STRAND_NA,STRAND_NA,STRAND_NA,STRAND_NA]
gr = GenomicRanges(chrs,s,e,d,chrinfo)
out = collapse(gr)
@test genostarts(out) == [100,200,3500]
@test genoends(out) == [150,300,3600]
@test strands(out) == [STRAND_NA, STRAND_NA, STRAND_NA]

out = disjoin(gr)
@test genostarts(out) == [100,200,220,251,3500]
@test genoends(out) == [150,219,250,300,3600]
@test strands(out) == [STRAND_NA, STRAND_NA, STRAND_NA, STRAND_NA, STRAND_NA]

out = gaps(gr)
@test genostarts(out) == [151,301]
@test genoends(out) == [199,3499]
@test strands(out) == [STRAND_NA, STRAND_NA]

out = coverage(gr)
@test values(out) == [0,1,0,1,2,1,0,1,0]
@test ends(out) == [99,150,199,219,250,300,3499,3600,23000]

chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[1e3,2e3,2e4])
chrs = ["chr1","chr1","chr1","chr1","chr1","chr1","chr1"]
s = [100, 200, 300, 450, 700, 750, 800]
e = [500, 250, 400, 550, 775, 825, 850]
d = [STRAND_NA,STRAND_NA,STRAND_NA,STRAND_NA,STRAND_NA,STRAND_NA,STRAND_NA]
gr = GenomicRanges(chrs,s,e,d,chrinfo)
out = disjoin(gr)
@test genostarts(out) == [100,200,251,300,401,450,501,700,750,776,800,826]
@test genoends(out) == [199,250,299,400,449,500,550,749,775,799,825,850]
@test strands(out) == [STRAND_NA, STRAND_NA, STRAND_NA, STRAND_NA, STRAND_NA, STRAND_NA, STRAND_NA, STRAND_NA, STRAND_NA, STRAND_NA, STRAND_NA, STRAND_NA]

# overlap_table
chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])

chrs = ["chr1","chr1","chr1","chrX"]
s = [100, 200, 220, 500]
e = [150, 250, 300, 600]
d = [STRAND_NA,STRAND_NA,STRAND_NA,STRAND_NA]
x = GenomicRanges(chrs,s,e,d,chrinfo)

chrs = ["chr1","chr1","chr1","chr1","chr1","chr1","chr1"]
s = [100, 200, 300, 450, 700, 750, 800]
e = [500, 250, 400, 550, 775, 825, 850]
d = [STRAND_NA,STRAND_NA,STRAND_NA,STRAND_NA,STRAND_NA,STRAND_NA,STRAND_NA]
y = GenomicRanges(chrs,s,e,d,chrinfo)

out = overlap_table(x,y,true)
@test out == [2 2]
out = overlap_table(x,y,false)
@test out == [1 1; 2 1; 2 2; 3 1; 3 2; 3 3]

## Iterators
chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[10,10,10])
s = [2,4,6,15,7]
e = s .+ 2
gr = GenomicRanges(s,e,chrinfo)
rle = RLEVector([2,3,9,1,0], cumsum([6,6,6,6,6]))
@test collect(rle[gr]) == [ [2,2,2], [2,2,2], [2,3,3,], [9,9,9], [3,3,3] ]
@test map(mean, rle[gr]) == [2.0, 2.0, 2 .+ (2 / 3), 9.0, 3.0]

## Same genome
chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])
chrs = ["chr1","chr2","chr2","chrX"]
s = [100, 200, 300, 400]
e = [120, 240, 350, 455]
gr = GenomicRanges(chrs,s,e,chrinfo)

@test same_genome(gr,Interval("hg19",1,3,'.')) == true
@test same_genome(Interval("hg19",1,3,'.'),gr) == true
@test same_genome(Interval("hg18",1,3,'.'),gr) == false
@test same_genome(Interval("hg19",1,310000,'.'),gr) == false

end # testset

end # module
