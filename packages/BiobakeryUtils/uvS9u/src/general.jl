
"""
Given a file path or paths to abundance tables (eg humann2 or metaphlan2),
create abundance table. Table is presumed to have samples in columns and
features in rows. First column is taken as feature IDs.
"""
function import_abundance_table(file::AbstractString; delim::Char='\t')
    @info "Importing abundance table" file
    df = CSV.File(file, delim=delim) |> DataFrame
    rename!(df, names(df)[1] => :col1)
    return df
end


function import_abundance_tables(files::Array{<:AbstractString, 1}; delim::Char='\t')
    @info "Importing abundance tables"
    fulltable = DataFrame(col1=String[])
    for t in files
        df = import_abundance_table(t, delim=delim)
        fulltable = join(fulltable, df, on=:col1, kind=:outer)
    end

    # replace all missing values (from joins) with 0.
    fulltable = map(c -> eltype(c) <: Union{<:Number, Missing} ? collect(Missings.replace(c, 0)) : c, eachcol(fulltable))
    return fulltable
end


function clean_abundance_tables(files::Array{String, 1};
                        delim::Char='\t',
                        col1::Symbol=:taxon,
                        suffix::String="_taxonomic_profile")
    @info "Cleaning"
    t = import_abundance_tables(files, delim=delim)

    rename!(t, :col1 => col1)
    rename!(n-> Symbol(replace(String(n), suffix => "")), t)

    return t
end


function rm_strat!(df::DataFrame; col::Union{Int, Symbol}=1)
    filter!(x->!occursin(r"\|", x[1]), df)
end


"""
Given a dataframe with a column that has a pvalue column, perform
Benjamini Hochberch correction to generate q value column with given Q.
"""
function qvalue!(df::DataFrame, q::Float64=0.2; pcol::Symbol=:p_value, qcol::Symbol=:q_value)
    ranks = invperm(sortperm(map(x->x,df[pcol])))
    m = length(ranks)
    df[qcol] = [i / m * q for i in eachindex(df[pcol])]
end



function permanova(dm::DistanceMatrix, metadata::AbstractVector, nperm::Int=999; filter=fill(true, length(metadata)))
    length(dm.samples) != length(metadata) && error("Metadata does not match the size of distance matrix")

    r_dm = dm.dm[filter, filter]
    metadata = metadata[filter]
    @rput r_dm
    @rput metadata

    R"""
    library(vegan)

    p <- adonis(r_dm ~ metadata,
            method = "bray", permutations = $nperm)
    """

    @rget p

    return p[:aov_tab]
end



#==============
PanPhlAn Utils
==============#

function panphlan_calcs(df::DataFrame)
    abun = abundancetable(df)
    dm = getdm(df, Jaccard())
    rowdm = getrowdm(df, Jaccard())
    col_clust = hclust(dm.dm, :single)
    row_clust = hclust(rowdm.dm, :single)
    optimalorder!(col_clust, dm.dm)
    optimalorder!(row_clust, rowdm.dm)

    pco = pcoa(dm)

    return abun, dm, col_clust, row_clust, pco
end
