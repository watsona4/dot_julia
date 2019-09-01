#Code to extract genes from NCBI database using their API 
#API found here: https://api.ncbi.nlm.nih.gov/variation/v0/

#takes "rs" out of snpids/rsids if they start with "rs###"
function getSNPID(snpid::String)
    id = ""
    try
        id = match(r"(?<=rs)\w+", snpid).match
    catch
        id = snpid   
    end
    return id 
end

#checks if gene information is present, if not, return no gene found
function genecheck(info::LazyJSON.Object{Nothing,String})
    locus = ""
    try 
        locus = info["primary_snapshot_data"]["allele_annotations"][1]["assembly_annotation"][1]["genes"][1]["locus"]
    catch
        locus = "No gene listed"
    end
    return locus
end

#checks to make sure the HTTP has valid information
function httpcheck(snpid::AbstractString)   
    http = HTTP.Messages.Response()
    try
        http = HTTP.get("https://api.ncbi.nlm.nih.gov/variation/v0/beta/refsnp/" * snpid)
    catch
        http = HTTP.Messages.Response()
    end
    return http
end


"""
    getgenes(data::DataFrame; idvar::AbstractString)

# Position arguments

- `data::DataFrame`: A DataFrame containing a column with the Ref SNP IDs. By default, assumes that the variable name is "snpid". The variable name can be specified using the `idvar` keyword.

# Keyword arguments

- `idvar::AbstractString`: the variable name in the dataframe that specifies the Ref SNP ID (rsid).


    getgenes(snps::AbstractArray)

# Position arguments

- `snps::AbstractArray`: Ref SNP IDs (rsid) to get loci names for. 

# Output

Returns an array of gene loci associated to the Ref SNP IDs.

"""
function getgenes(snpids::AbstractArray)
    snpids = getSNPID.(snpids)
    loci = Vector{String}(undef, 0)
    for snpid in snpids
        http = httpcheck(snpid)
        if isempty(http.body)
            locus = "snpid not in database"
        else 
            str = String(http.body)
            info = LazyJSON.parse(str)
            locus = genecheck(info)
        end
        push!(loci, locus)
    end
    return loci
end

function getgenes(df::DataFrame; idvar::AbstractString = "snpid")
    rsidsym = Meta.parse(idvar)
    if !(rsidsym in names(df))
        throw(ArgumentError(idvar * " is not in the dataframe. Please rename 
        the column of rsids to `snpid` or specify the correct name using the `idvar` argument"))
    end
    getgenes(df[rsidsym])
end

function getgenes(snpid::Union{String, Int64})
    if typeof(snpid) == Int64
        snpid = string(snpid)
    end
    snpid = getSNPID(snpid)
    locus = ""
    http = httpcheck(snpid)
    if isempty(http.body)
        locus = "snpid not in database"
    else 
        str = String(http.body)
        info = LazyJSON.parse(str)
        locus = genecheck(info)
    end
    return locus
end


#gets additional gene information
function getinfo(info)
    snp_id = info["refsnp_id"]
    annotations = info["primary_snapshot_data"]["allele_annotations"]
    geneinfo = Dict()
    for a in annotations
        assembly_annotations = a["assembly_annotation"]
        for aa in assembly_annotations
            seq_id = aa["seq_id"]
            annotation_release = aa["annotation_release"]
            genes = aa["genes"]
                for g in genes
                    gene_name = g["name"]
                    gene_id = string(g["id"])
                    gene_locus = g["locus"]
                    gene_is_pseudo = string(Int(g["is_pseudo"] == "true"))
                    gene_orientation = string(Int(g["orientation"] == "minus"))
                    geneinfo = Dict("seq_id" => seq_id, "annotation_release" => annotation_release,
                    "gene_name" => gene_name, "gene_id" => gene_id, "gene_locus" => gene_locus,
                    "gene_is_pseudo" => gene_is_pseudo, "gene_orientation" => gene_orientation)
                end
        end 
    end
    return geneinfo
end

"""
    getgeneinfo(snpid::AbstractString)

# Position arguments

- `snp::AbstractString`: Ref SNP ID (rsid) to get gene information for. 

# Output

Returns a dictionary of gene information associated with the Ref SNP ID. Entries are `seq_id`, `annotation_release`, `gene_name`, `gene_id`, `gene_locus`, `gene_is_pseudo`, and `gene_orientation`.

"""
function getgeneinfo(snpid::AbstractString)
    geneinfo = Dict()
    rsid = getSNPID(snpid);
    http = httpcheck(rsid);
    if isempty(http.body)
        throw(ArgumentError("Ref SNP ID (rsid) not in database"))
    end 
    str = String(http.body)
    info = LazyJSON.parse(str)
    geneinfo = getinfo(info)
    if isempty(geneinfo)
        geneinfo = Dict("Empty" => "No gene info listed for ref SNP ID")
    end
    return geneinfo
end
