# The GenomicVectors API

```@contents
```

## Types
```@docs
AbstractGenomicVector
GenomeInfo
GenomicPositions
GenomicRanges
GenomicDataFrame
```

## Interfaces and Accessing position info
```@docs
chromosomes
```

## Modifying positions
Several functions are offered for altering locations or creating related locations.
```@docs
slide
collapse
disjoin
gaps
coverage
```

## Querying positions
As in Bioconductor, location query operations discriminate between exact and overlapping matches. In
addition to exact versus overlapping coordinates, exact matching includes strand, while overlap matching
does not. In `GenomicVectors.jl`, the standard set operations use exact matching and custom overlap functions are defined for `AbstractGenomicVector`.

```@docs
findoverlaps
```

## A round trip to R
```julia
using RCall
chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])
chrs = ["chr1","chr2","chr2","chrX"]
s = [100, 200, 300, 400]
e = [120, 240, 350, 455]
x = GenomicRanges(chrs,s,e,chrinfo)
y = RObject(x)
@rput y
R"z = y + 2L"
@rget z
```

## Summarize genomic data by ranges

It is often useful to summarize data along the genome by region. For example, one
might wish to summarize DNA copy number by gene or the number of point mutations per
transcript.

Subsetting a vector with an AbstractGenomicVector returns an iterator over sections
of the vector indexed by the genostarts and genoends of the AbstractGenomicVector.
To make this a safe operation, the vector must span the full length of the genome
specified by the chr_info of the AbstractGenomicVector. This is particularly useful
when the vector is an RLEVector.

```julia
chrinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[10,10,10])
s = [2,4,6,15,7]
e = s + 2
gr = GenomicRanges(s,e,chrinfo)
rle = RLEVector([2,3,9,1,0],cumsum([6,6,6,6,6]))
collect(rle[gr])
map(mean, rle[gr])

# Working with BAM files

One can create GenomicRanges from a BAM file. Additionally, coverage can be calculated
directly from a BAM file.

```julia
bam_path = joinpath(Pkg.dir("GenomicVectors"),"BAM", bam_file)
reader = open(BAM.Reader, bam_path)
gr = GenomicRanges("hg19", reader)
c1 = coverage(gr)
reader = open(BAM.Reader, bam_path)
c2 = coverage(reader)
c1 == c2
```


```
