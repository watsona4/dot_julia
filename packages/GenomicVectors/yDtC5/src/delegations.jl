### Functions that delegate simple tasks to the underlying data

## Basic vector operations

### Operations that take and return GenomicVectors
for op in [:similar, :copy, :unique]
    @eval (Base.$op)(x::GenomicPositions) = GenomicPositions(($op)(_genostarts(x)), chr_info(x))
    @eval (Base.$op)(x::GenomicRanges) = GenomicRanges(($op)(_genostarts(x)), ($op)(_genoends(x)), ($op)(_strands(x)), chr_info(x))
end

### Operations that take a GenomicVector and a Integer and return a GenomicVector
for op in [:similar, :resize!]
    @eval (Base.$op)(x::GenomicPositions, n::Integer) = GenomicPositions(($op)(_genostarts(x),n), chr_info(x))
    @eval (Base.$op)(x::GenomicRanges, n::Integer) = GenomicRanges(($op)(_genostarts(x),n), ($op)(_genoends(x),n), ($op)(_strands(x),n), chr_info(x))
end

### Operations that operate directly on the internal genopos, not mutating
for op in [:size, :length, :lastindex]
    @eval (Base.$op)(x::GenomicPositions) = ($op)(x.genopos)
    @eval (Base.$op)(x::GenomicRanges) = ($op)(x.starts)
end

### Operations that work on two GenomicPositions and return something else
for op in [:issubset,:indexin,:findall] # max, min, etc. would go here if I decide that they make sense
    @eval begin
        function (Base.$op)(x::GenomicPositions, y::GenomicPositions, exact::Bool=true)
            same_genome(x, y) || throw(ArgumentError("Both GenomicPositions must be from the same genome."))
            ($op)(x.genopos, y.genopos)
        end
    end
end

### Operations that work on two GenomicPositions and return a single one
for op in [:vcat, :union, :intersect, :setdiff, :symdiff]
    @eval begin
        function (Base.$op)(x::GenomicPositions, y::GenomicPositions)
            same_genome(x, y) || throw(ArgumentError("Both GenomicPositions must be from the same genome."))
            GenomicPositions( ($op)(x.genopos, y.genopos), chr_info(x) )
        end
    end
end

### Operations that work on two GenomicPositions and mutate the first one
for op in [:append!, :prepend!]
    @eval begin
        function (Base.$op)(x::GenomicPositions, y::GenomicPositions)
            same_genome(x, y) || throw(ArgumentError("Both GenomicPositions must be from the same genome."))
            ($op)(x.genopos, y.genopos)
            x
        end
        function (Base.$op)(x::GenomicRanges, y::GenomicRanges)
            same_genome(x, y) || throw(ArgumentError("Both GenomicRanges must be from the same genome."))
            ($op)(x.starts, y.starts)
            ($op)(x.ends, y.ends)
            ($op)(x.strands, y.strands)
            x
        end
    end
end

### Do I want to put these in any of the above?
### maximum, maximum!, minimum, minimum!, extrema, findmax, findmin, maxabs, maxabs!, minabs, minabs!, sum, count, foreach, map, etc.
### filter(function, x::GenomicPositions, filter!(function, x::GenomicPositions)
### push!, pop!
### splice!, deleteat!, insert!, popfirst!, pushfirst!, pop!, push!, intersect!, setdiff!
