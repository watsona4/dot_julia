"""
The collection of all ontology terms and their relations.
"""
struct Ontology
    header::Dict{String, Vector{String}}
    prefix::String
    terms::Dict{TermId, Term}
    typedefs::Dict{String, Typedef}
end

function load(fn, prefix::AbstractString)
    header, stanzas = parseOBO(fn)
    terms = getterms(stanzas)
    typedefs = gettypedefs(stanzas)
    Ontology(header, prefix, terms, typedefs)
end

function gettermbyname(ontology::Ontology, name)
    lname = lowercase(name)
    for term in allterms(ontology)
        (lowercase(term.name) == lname) && return term
    end
    throw(KeyError(name))
end

gettermid(ontology::Ontology, id::Integer) = @sprintf("%s:%07d", ontology.prefix, id)

# deprecate?
gettermbyid(ontology::Ontology, id::TermId) = ontology.terms[id]
gettermbyid(ontology::Ontology, id::Integer) = gettermbyid(ontology, gettermid(ontology, id))

allterms(ontology::Ontology) = values(ontology.terms)

Base.getindex(ontology::Ontology, term_id::TermId) = ontology.terms[term_id]

Base.getindex(ontology::Ontology, term_ids::Set{TermId}) =
    [ontology[t_id] for t_id in term_ids]

Base.length(ontology::Ontology) = length(ontology.terms)

parents(ontology::Ontology, term::Term, rel::Symbol = :is_a) = ontology[relationship(term, rel)]
children(ontology::Ontology, term::Term, rel::Symbol = :is_a) = ontology[rev_relationship(term, rel)]

const VecOrTuple{T} = Union{Vector{T}, Tuple{Vararg{T}}} where T

# return the set of all nodes of the ontology DAG that could be visited from `term`
# node when traveling along `rels` edges using `rev` direction
function transitive_closure(ontology::Ontology, term::Term,
                            rels::VecOrTuple{Symbol},
                            rev::Bool = false)
    # TODO: check if transitive & non-cyclical before doing so?
    res = Set{TermId}()
    frontier_ids = Set{TermId}((term.id,))
    while true
        new_ids = Set{TermId}()
        for f_id in frontier_ids, rel in rels
            f_term = ontology[f_id]
            f_rel_ids = rev ? rev_relationship(f_term, rel) : relationship(f_term, rel)
            union!(new_ids, f_rel_ids)
        end
        frontier_ids = setdiff!(new_ids, res)
        isempty(frontier_ids) && break # no new terms
        union!(res, frontier_ids)
    end
    return res
end

descendants(ontology::Ontology, term::Term, rels::VecOrTuple{Symbol}) = ontology[transitive_closure(ontology, term, rels, true)]
descendants(ontology::Ontology, term::Term, rel::Symbol = :is_a) = descendants(ontology, term, (rel,))
ancestors(ontology::Ontology, term::Term, rels::VecOrTuple{Symbol}) = ontology[transitive_closure(ontology, term, rels, false)]
ancestors(ontology::Ontology, term::Term, rel::Symbol = :is_a) = ancestors(ontology, term, (rel,))

function satisfies(ontology::Ontology, term1::Term, rel::Symbol, term2::Term)
    (term1 == term2) && return true # TODO: should check if relationship is is_reflexive
    (term2.id in relationship(term1, rel)) && return true

    # TODO: check if transitive & non-cyclical before doing so
    for p_id in relationship(term1, rel)
        p = ontology.terms[p_id]
        satisfies(ontology, p, rel, term2) && return true
    end

    return false
end

is_a(ontology::Ontology, term1::Term, term2::Term) = satisfies(ontology, term1, :is_a, term2)
