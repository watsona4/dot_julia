const TermId = String
const TagDict = Dict{String, Vector{String}}
const RefDict = Dict{String, String}
const RelDict = Dict{Symbol, Set{TermId}}

"""
Ontology term.

The `Term` object is a node in the direct acyclic ontology graph.
Its outgoing and incoming edges represent the relations with the other nodes and
could be retrieved by
```julia
relationship(term, sym)
```
and
```julia
rev_relationship(term, sym)
```
respectively, where `sym` is the relationship annotation (e.g. `:part_of`, `:is_a`, `:regulates`).
"""
struct Term
    id::TermId
    name::String

    obsolete::Bool
    namespace::String
    def::String
    refs::RefDict
    synonyms::Vector{String}
    tagvalues::TagDict

    relationships::RelDict
    rev_relationships::RelDict # reverse relationships

    Term(id::AbstractString, name::AbstractString="", obsolete::Bool=false,
         namespace::AbstractString="", def::AbstractString="",
         refs::RefDict=RefDict()) =
        new(id, name, obsolete, namespace, def, refs, String[],
            TagDict(), RelDict(), RelDict())
    Term(term::Term, name::AbstractString=term.name, obsolete::Bool=term.obsolete,
         namespace::AbstractString=term.namespace, def::AbstractString=term.def,
         refs::RefDict=term.refs) =
        new(term.id, name, obsolete, namespace, def, refs, term.synonyms,
            term.tagvalues, term.relationships, term.rev_relationships)
end


Base.isless(term1::Term, term2::Term) = isless(term1.id, term2.id)

function Base.show(io::IO, term::Term)
    if get(io, :compact, false)
        @printf io "Term(\"%s\", \"%s\")" term.id term.name
    else
        print(io, term.id)
    end
end

isobsolete(term::Term) = term.obsolete

relationship(term::Term, sym::Symbol) = get!(() -> Set{TermId}(), term.relationships, sym)
rev_relationship(term::Term, sym::Symbol) = get!(() -> Set{TermId}(), term.rev_relationships, sym)
