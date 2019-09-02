module OBOParse

export
    # types
    Ontology, Term,

    # term
    isobsolete, is_a,

    # parser
    gettermbyid, gettermbyname,
    parents, children,
    descendants, ancestors, relationship

using Printf: @printf, @sprintf

include("term.jl")
include("typedef.jl")
include("parser.jl")
include("ontology.jl")

end # OBOParse module
