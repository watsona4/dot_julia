# Module written by Ed Scheinerman, ers@jhu.edu
# distributed under terms of the MIT license

module ShowSet

import Base: string, show, AbstractSet

function string(A::AbstractSet)
    elements = collect(A)
    try
        sort!(elements)
    catch
    end
    return "{" * join(elements,",") * "}"
end

show(io::IO, A::Set)    = print(io,string(A))
show(io::IO, A::BitSet) = print(io,string(A))

end # module ShowsSet
