const ColumnIndex = Union{Symbol,Integer}

## Note: DataFrame([Int, Float64, String], [:A, :B, :C], 0) is the recipe for a zero row DF

"""
# GenomicDataFrame

A DataFrame-like class with a GenomicVector as an index.

# Examples
```julia
    genomeinfo = GenomeInfo("hg19",["chr1","chr2","chrX"],Int64[3e5,2e5,1e4])
    chrs = ["chr2","chr1","chr2","chrX"]
    pos = Int64[3e4,4.2e3,1.9e5,1e4]
    gp = GenomicPositions(pos,chrs,genomeinfo)
    dt = DataFrame(a=1:4,b=5:8)
    gt = GenomicDataFrame(gp,dt)
    gt[1:2,1:2]
```
"""
struct GenomicDataFrame{T1 <: AbstractGenomicVector, T2 <: AbstractDataFrame}
    rowindex::T1
    table::T2
     function GenomicDataFrame{T1,T2}(rowindex,table) where {T1 <: AbstractGenomicVector,T2 <: AbstractDataFrame}
         nrow = size(table,1)
         if nrow != 0 && length(rowindex) != nrow
             throw(ArgumentError("GenomicDataFrame requires that `length(rowindex) == size(table,1)`"))
         end
         new(rowindex,table)
     end
end

GenomicDataFrame(gv,dt) = GenomicDataFrame{typeof(gv),typeof(dt)}(gv,dt)
rowindex(gt::GenomicDataFrame) = copy(gt.rowindex)
table(gt::GenomicDataFrame) = copy(gt.table)
_rowindex(gt::GenomicDataFrame) = gt.rowindex
_table(gt::GenomicDataFrame) = gt.table
for op in [:size, :nrow, :ncol, :index]
    @eval (DataFrames.$op)(x::GenomicDataFrame) = ($op)(_table(x))
end
Base.names(x::GenomicDataFrame) = names(_table(x))

function Base.show(io::IO, x::GenomicDataFrame)
    t = typeof(x)
    show(io, t)
    println("\n\nRow Index:")
    show(io,_rowindex(x))
    println("\n\nTable:")
    show(io,_table(x))
end

Base.getindex(gt::GenomicDataFrame,i,j) = GenomicDataFrame(rowindex(gt)[i], table(gt)[i,j])
Base.getindex(gt::GenomicDataFrame,j) = GenomicDataFrame(rowindex(gt), table(gt)[j])
Base.getindex(gt::GenomicDataFrame,j::ColumnIndex) = table(gt)[j]
Base.setindex!(gt::GenomicDataFrame,value,j) = setindex!(_table(gt),value,j)
Base.setindex!(gt::GenomicDataFrame,value,i,j) = setindex!(_table(gt),value,i,j)

## Getters that delegate to the AbstractDataFrame row index
for op in [:chr_info, :_strands, :_genostarts, :_genoends, :(RLEVectors.starts), :(RLEVectors.ends), :(RLEVectors.widths), :chromosomes, :genostarts, :genoends, :strands, :(RLEVectors.eachrange), :chrpos, :genopos, :chrindex, :reduce, :gaps, :coverage, :disjoin, :collapse]
    @eval ($op)(x::GenomicDataFrame) = ($op)(_rowindex(x))
end

## two-arg functions that delegate to the genome info if one is a GenomicDataFrame
for op in [:overlap_table, :(Base.indexin), :(Base.findall), :(Base.in)]
    @eval ($op)(x::GenomicDataFrame,y::AbstractGenomicVector,exact::Bool=true) = ($op)(_rowindex(x),y,exact)
    @eval ($op)(x::AbstractGenomicVector,y::GenomicDataFrame,exact::Bool=true) = ($op)(x,_rowindex(y),exact)
    @eval ($op)(x::GenomicDataFrame,y::GenomicDataFrame,exact::Bool=true) = ($op)(_rowindex(x),_rowindex(y),exact)
end

function Base.vcat(x::GenomicDataFrame,y::GenomicDataFrame)
    same_genome(x,y) || throw(ArgumentError("x and y must be from the same genome"))
    GenomicDataFrame( vcat(_rowindex(x),_rowindex(y)), vcat(_table(x),_table(y)) )
end

## Joins
"""
    Base.join(gt1::GenomicDataFrame, gt2::GenomicDataFrame, on::Union{Symbol, Vector{Symbol}} = Symbol[], kind::Symbol = :inner, exact::Bool=false)
    Base.join(gt1::GenomicDataFrame, t2::DataFrame, on::Union{Symbol, Vector{Symbol}} = Symbol[], kind::Symbol = :inner)
    Base.join(t1::DataFrame, gt2::GenomicDataFrame, on::Union{Symbol, Vector{Symbol}} = Symbol[], kind::Symbol = :inner)

join on `GenomicDataFrame` is like a regular `DataFrame` join except that with the default value of `on`, the row matching is done
using the row indices (ranges) from the two tables. Like other range comparison operations, the `exact` argument controls whether or not
a range match must be exact, or if an overlap is sufficient. When `exact == false` the `join` operation is not entirely symmetric: the
row indices (ranges) in the resulting GenomicDataFrame will be those from the 'left' GenomicDataFrame.

GenomicDataFrames and standard DataFrames can also be joined using columns in the table portion of the GenomicDataFrame.

Columns in the table portion of the returned object will be DataArrays in order to accomodate missing values.
"""
function Base.join(gt1::GenomicDataFrame, gt2::GenomicDataFrame; on::Union{Symbol, Vector{Symbol}} = Symbol[], kind::Symbol = :inner, exact::Bool=false)
    if typeof(on) == Vector{Symbol} && length(on) == 0
        # join GDFs on ranges
        inds = overlap_table(gt1, gt2, exact)
        if kind == :inner
            out = GenomicDataFrame(
                                   rowindex(gt1)[inds[:,1]],
                                   hcat(
                                        table(gt1)[inds[:,1],:],
                                        table(gt2)[inds[:,2],:]
                                        )
                                   )
        elseif kind == :left
            error("left-join of GenomicDataFrames by rowindex is not supported at this time.")
        elseif kind == :right
            error("right-join of GenomicDataFrames by rowindex is not supported at this time.")
        elseif kind == :outer
            error("outer-join of GenomicDataFrames by rowindex is not supported at this time.")
        elseif kind == :cross
            error("cross-join of GenomicDataFrames by rowindex is not supported at this time.")
        elseif kind == :semi
            out = GenomicDataFrame( rowindex(gt1)[inds[:,1]], table(gt1)[inds[:,1],:] )
        elseif kind == :anti
            xinds = setdiff(1:nrow(gt1), inds[:,1])
            out = GenomicDataFrame( rowindex(gt1)[xinds], table(gt1)[xinds,:] )
        end
    else
        # join DataFrames in the usual way
        out = join(table(gr1), table(gr2), on = on, kind = kind)
    end
    out
end
function Base.join(t1::GenomicDataFrame, t2::DataFrame; on::Union{Symbol, Vector{Symbol}} = Symbol[], kind::Symbol = :inner)

end
function Base.join(t1::DataFrame, t2::GenomicDataFrame; on::Union{Symbol, Vector{Symbol}} = Symbol[], kind::Symbol = :inner)
    out = join(table(t1), table(t2), on = on, kind = kind)
end
