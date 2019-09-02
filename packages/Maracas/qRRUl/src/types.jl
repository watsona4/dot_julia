using Distributed

mutable struct ResultsCount
    passes::Int
    fails::Int
    errors::Int
    broken::Int
end
"""
    MaracasTestSet
"""
abstract type MaracasTestSet <: AbstractTestSet end

macro MaracasTestSet(type_name)
    base_type = Meta.parse("""
        mutable struct $type_name <: MaracasTestSet
            description::AbstractString
            results::Vector
            count::ResultsCount
            max_depth::Int
            $type_name(desc, results, count, max_depth)=new(format_title($type_name, desc), results, count, max_depth)
        end
    """)
    constructor = Meta.parse("""
        $type_name(desc) = $type_name(desc, [], ResultsCount(0, 0, 0, 0), 0)
    """)
    esc(quote
        $base_type
        $constructor
    end)
end
