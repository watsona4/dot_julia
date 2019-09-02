# The OBO Flat File parser
"""
Represents one entry in the OBO file, e.g.
```
[Term]
id: GO:0000002
namespace: biological_process
def: BBB
name: two
```
is stored as `Stanza` with `Typ` = "Term", `id` = "GO:0000002" and
`tagvalues = Dict("id" => "GO:0000002", "namespace" => ["biological_process"], "def" => ["BBB"], "name" => "two")`.
"""
struct Stanza
    Typ::String # Official ones are: "Term", "Typedef" and "Instance"
    id::String
    tagvalues::TagDict
end

struct OBOParseException <: Exception
    msg::String
end

function find_first_nonescaped(s, ch)
    i = findfirst(isequal(ch), s)
    while i !== nothing
        numescapes = 0
        @inbounds for j in i-1:-1:1
            (s[j] == '\\') || break
            numescapes += 1
        end
        iseven(numescapes) && return i # this is not escaped
        i = findnext(isequal(ch), s, i+1)
    end
    return i
end

function removecomments(line)
    i = find_first_nonescaped(line, '!')
    return i !== nothing ? line[1:i-1] : line
end

const id_tag = "id"

function parseOBO(stream::IO)
    # first set of tag values is a header
    header, nextstanza = parsetagvalues(stream)
    stanzas = Stanza[]
    while nextstanza != ""
        prevstanza = nextstanza
        vals, nextstanza = parsetagvalues(stream)
        haskey(vals, id_tag) || throw(OBOParseException("Stanza is missing ID tag"))
        id = vals[id_tag][1]
        push!(stanzas, Stanza(prevstanza, id, vals))
    end

    return header, stanzas
end


parseOBO(filepath::AbstractString) = open(parseOBO, filepath, "r")

const r_stanza = r"^\[(.*)\]$"

# returns tagvalues of the current Stanza and the type of the next one
function parsetagvalues(s)
    vals = TagDict()

    for line in eachline(s)
        line = strip(removecomments(line))
        m = match(r_stanza, line)
        (m !== nothing) && return vals, m.captures[1]

        isempty(line) && continue

        tag, value, ok = tagvalue(line)
        ok || throw(OBOParseException("cannot find a tag (position: $(position(s))), empty: $(isempty(line)), line: `$(line)`"))
        push!(get!(()->Vector{String}(), vals, tag), value)
    end

    return vals, ""
end


function tagvalue(line)
    # TODO: what an ad hoc parser!
    i = findfirst(": ", line)
    if i === nothing
        # empty tag value
        if endswith(line, ":")
            return line, "", true
        else
            # empty strings are dummy
            return "", "", false
        end
    end

    j = findfirst(" !", line)
    tag = line[1:first(i)-1]
    value = j === nothing ? line[first(i)+2:end] : line[first(i)+2:first(j)-1]

    return tag, value, true
end

function getuniqueval(st::Stanza, tagname, def::String="")
    if haskey(st.tagvalues, tagname)
        arr = st.tagvalues[tagname]
        (length(arr) > 1) && throw(OBOParseException("Expect unique tag named $tagname"))
        return arr[1]
    else
        return def
    end
end

function getterms(arr::Vector{Stanza})
    result = Dict{String, Term}()

    for st in arr
        st.Typ == "Term" || continue

        term_obsolete = getuniqueval(st, "is_obsolete") == "true"
        term_name = getuniqueval(st, "name")
        term_def_and_refs = getuniqueval(st, "def")
        term_def_matches = match(r"^\"([^\"]+)\"(?:\s\[(.+)\])?$", term_def_and_refs)
        if term_def_matches !== nothing
             term_def = term_def_matches[1]
             term_refs = RefDict(begin
                    Pair(split(ref, r"(?<!\\):")...)
                end for ref in split(term_def_matches[2], ", "))
         else # plain format
             term_def = term_def_and_refs
             term_refs = RefDict()
         end

        term_namespace = getuniqueval(st, "namespace")
        if haskey(result, st.id)
            # term was automatically created, re-create it with the correct properties,
            # but preserve the existing relationships
            term = result[st.id] = Term(result[st.id], term_name, term_obsolete, term_namespace, term_def, term_refs)
        else # brand new term
            term = result[st.id] = Term(st.id, term_name, term_obsolete, term_namespace, term_def, term_refs)
        end

        for otherid in get(st.tagvalues, "is_a", String[])
            otherterm = get!(() -> Term(otherid), result, otherid)
            push!(relationship(term, :is_a), otherid)
            push!(rev_relationship(otherterm, :is_a), st.id)
        end

        for rel in get(st.tagvalues, "relationship", String[])
            rel = strip(rel)
            tmp = split(rel)
            length(tmp) == 2 || throw(OBOParseException("Failed to parse relationship field: $rel"))

            rel_type = Symbol(tmp[1])
            rel_id = tmp[2]
            otherterm = get!(() -> Term(rel_id), result, rel_id)

            push!(relationship(term, rel_type), rel_id)
            push!(rev_relationship(otherterm, rel_type), st.id)
        end

        if isobsolete(term) && length(relationship(term, :is_a)) > 0
            throw(OBOParseException("Obsolete term $term contains is_a relationship"))
        end

        append!(term.synonyms, get(st.tagvalues, "synonym", String[]))
        for (k, v) in st.tagvalues
            append!(get!(() -> Vector{String}(), term.tagvalues, k), v)
        end

    end
    result
end

function gettypedefs(arr::Vector{Stanza})
    result = Dict{String, Typedef}()
    result
end
