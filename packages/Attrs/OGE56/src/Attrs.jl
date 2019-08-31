module Attrs

export @literalattrs, @defattrs, Attr, getattr, setattr!, attrnames, literal_getattr, literal_setattr!

include("interface.jl")
include("macros.jl")

end # module
