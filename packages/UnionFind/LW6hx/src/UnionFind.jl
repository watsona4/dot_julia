module UnionFind

import Base: union!
if VERSION < VersionNumber("1.0.0")
    import Base: find
end

export UnionFinder, CompressedFinder
export reset!, union!, find!, size!, find, groups

include("UnionFinder.jl")
include("CompressedFinder.jl")

end
