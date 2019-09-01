# Release Notes

## Version 0.0.1: Initial Public Release
This is the first public release of GenomicVectors.jl, which brings the features of
BioConductor's GenomicRanges to Julia.

## Version 0.0.2: changes to indexing a GenomicRanges
This release changes how indexing a GenomicRanges at a single position works. From the docs:

Indexing a GenomicRanges with an array produces a new GenomicRanges. Getting/setting by a
scalar gives/takes a three-tuple of the (start,end,strand) in genome location units. In the
near future, this will likely switch to using Bio.Intervals.Interval. The each function
produces an iterator of (start,end) two-tuples in genome location units. This is use for many
internal functions, like sorting. This is intentionally similar to RLEVectors.each.

This release also has simplified sorting code, fixes for a few edge cases and 100 percent
test coverage (well, not counting the precompiles).

## Version 0.0.3: Update to scalar indexing, behaves like Vector{Interval}
This version changes the value received or returned by setindex and getindex on a GenomicRanges.
We now use the Interval type from Bio.jl to represent a single range. However, we still maintain
our genome-level coordinates and use the name of the genome (e.g. hg19) in the Interval seqname
slot. Using Interval simplifies some code, but more importantly gives the single range some
meaning and guaranteed behavior. In effect, GenomicRanges now behaves as if it were
Vector{Interval}, but the internal representation is different. Additionally, the metadata slot
of the Interval returned by getindex contains the index of that Interval in the GenomicRanges.
This is useful for recovering the original ordering when a round trip is made converting to
IntervalCollection and back.

The each method on GenomicRanges still returns an iterator of (start,end) tuples, in units of
genomic position, which is useful for sorting and some other internal operations.

## Version 0.1.0: Introducing `GenomicDataFrame`
A GenomicDataFrame is a [DataFrame](https://github.com/JuliaData/DataFrames.jl) with one of the concrete AbstractGenomicVector subtypes as a row index. It is similar, in spirit, to Bioconductor's GenomicRanges, but a GenomicDataFrame isa DataFrame, while Bioconductor's GenomicRanges is always a vector of ranges that may, or may not, also have an associated DataFrame of metadata. GenomicDataFrame is experimental and is not yet fully-featured.

This version includes more range overlap features including discrimination between exact- and overlap-matches using an `exact` argument to `findoverlaps`, `in`, etc..

There are a number of internal changes including faster `genopos`, `chrpos`, `chromosomes`, etc. functions and a re-organization of the range search functions as methods on `AbstractGenomicVector`.

The names of range-related functions have changed. The `each` function for iterating over tuples of (genostart, genoend) pairs is now called `eachrange` mirroring the change in `RLEVectors`. Range searching functions are built on the `findoverlaps` kernel function. Rather than using separate vocabularies for exact- and overlap-matches, the usual search functions (`indexin`, `findin`, `in`, etc.) gain an `exact` argument.

This version is fully compatible with julia 0.6. (There are a few deprecation warnings about the new "where" syntax that will eventually be fixed by Compat.jl).
