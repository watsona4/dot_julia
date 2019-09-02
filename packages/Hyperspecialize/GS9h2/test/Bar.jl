module Bar

using Hyperspecialize

@concretize AlsoNotAType Set{Type}([Int64])
@concretize Float64 Set{Type}([UInt16])
@concretize NotAType Set{Type}([UInt64])
@concretize Float32 Set{Type}([UInt128])

end #module
