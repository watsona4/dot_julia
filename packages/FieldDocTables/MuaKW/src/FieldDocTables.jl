module FieldDocTables

using DocStringExtensions, PrettyTables
import DocStringExtensions: Abbreviation, format

export FieldDocTable

struct FieldDocTable{L,T,TR,F} <: Abbreviation
    labels::L
    functions::T
    truncation::TR
    tableformat::F
    fenced::Bool
end

FieldDocTable(labels::L, functions::T; truncation=((100 for f in functions)...,), 
              tableformat=PrettyTableFormat(markdown), fenced=false) where {L,T} =
    FieldDocTable{L,T,typeof(truncation), typeof(tableformat)
                 }(labels, functions, truncation, tableformat, fenced)

FieldDocTable(nt::NamedTuple; kwargs...) = FieldDocTable(keys(nt), (nt...,); kwargs...)


function format(doctable::FieldDocTable, buf, doc)
    local docs = get(doc.data, :fields, Dict())
    local binding = doc.data[:binding]
    local object = Docs.resolve(binding)
    # On 0.7 fieldnames() on an abstract type throws an error. We then explicitly return
    # an empty vector to be consistent with the behaviour on v0.6.
    local fields = isabstracttype(object) ? Symbol[] : fieldnames(object)

    if !isempty(fields)

        # Fieldnames and passed in functions
        colnames = [:Field, doctable.labels...]
        funcdata = ([safestring.(f(object), doctable.truncation[i])...] for (i, f) in enumerate(doctable.functions))
        data = hcat([fields...], funcdata...)

        # Only add a fielddocs column if there are fielddocs
        fielddocs = []
        for field in fields
            if haskey(docs, field) && isa(docs[field], AbstractString)
                for line in split(docs[field], "\n")
                    fielddoc = isempty(line) ? "" : rstrip(line)
                end
            else
                fielddoc = ""
            end
            push!(fielddocs, fielddoc)
        end
        if any(d -> d != "", fielddocs)
            data = hcat(data, fielddocs)
            colnames = [colnames..., :Docs]
        end

        println(buf)
        doctable.fenced && println(buf, "```")
        pretty_table(buf, data, colnames, doctable.tableformat)
        doctable.fenced && println(buf, "```")
        println(buf)
    end
end

safestring(::Nothing, n) = "nothing"
safestring(s, n) = truncate_utf8(string(s), n)

# Is there simpler way to do this?
truncate_utf8(s, n) = begin
    eo = lastindex(s)
    neo = 0
    for i = 1:n
      if neo < eo
          neo = nextind(s, neo)
      else
          break
      end
    end
    SubString(s, 1, neo)
end

end # module
