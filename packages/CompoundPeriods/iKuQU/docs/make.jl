using Documenter, CompoundPeriods, Dates

makedocs(
    modules = [CompoundPeriods],
    sitename = "CompoundPeriods",
    pages  = Any[
        "Overview"                           => "index.md",
        "Canonical Compound Periods"         => "canonicalcompoundperiods.md",
        "Reverse Compound Periods"           => "reversecompoundperiods.md",
        "Well Behaved Temporal Composites"   => "wellbehavedtemporalcomposites.md",
        "Compound Period Comparisons"        => "compoundcompare.md",
        "Nanosecond Increments"              => "nanosecondincrements.md",
        "min, max, minmax"                   => "minmaxminmax.md",
        "Dates, Times"                       => "datestimes.md"
        ]
    )

deploydocs(
    repo = "github.com/JeffreySarnoff/CompoundPeriods.jl.git",
    target = "build"
)
