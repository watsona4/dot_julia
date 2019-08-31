"""
    convert_to_struct(tree_dict::Dict{String,Any}, tree_obj::Node)

Takes a tree loaded from json and convert it back to a proper internal representation.

# Arguments
- `tree_dict::Dict{String,Any}`: tree as a dictionary after being read from json.
- `tree_obj::Node`: the tree (Node).
"""
function convert_to_struct(tree_dict::Dict{String,Any}, tree_obj::Node)

    # Iterate through each child of a node
    for (child_idx, child) in enumerate(tree_dict["children"])

        # Initialize child
        push!(tree_obj.children, Node([],label=child["taxa_label"]))

        # Add the CA's for the child
        for CA in child["CAs"]
            push!(tree_obj.children[child_idx].CAs, Rule((CA["idxs"]...,), ([ca[1] for ca in CA["char_attr"]]...,), CA["is_pure"], CA["num_group"], CA["num_non_group"], CA["occurances"]))
        end

        # Iterate through all of the child's descendents
        for (desc_idx, descendent) in enumerate(child["children"])

            # Initialize child's descendent
            push!(tree_obj.children[child_idx].children, Node([],label=descendent["taxa_label"]))

            # Add the CA's for the child's descendent
            for CA in descendent["CAs"]
                push!(tree_obj.children[child_idx].children[desc_idx].CAs, Rule((CA["idxs"]...,), ([ca[1] for ca in CA["char_attr"]]...,), CA["is_pure"], CA["num_group"], CA["num_non_group"], CA["occurances"]))
            end

            # Recur on the child's descendent to add the next layer to the tree
            convert_to_struct(descendent, tree_obj.children[child_idx].children[desc_idx])
        end
    end
    return tree_obj
end

"""
    get_next_hit(hitnames::Vector{String}, hit_idx::Int64)

Gets the next best hit returned from a blastn search.

# Arguments
- `hitnames::Vector{String}`: a list of all blastn hitnames.
- `hit_idx::Int64`: index of the current hit.
"""
function get_next_hit(hitnames::Vector{String}, hit_idx::Int64)

    # Initialize varibales
    new_hit = ""
    used_hits = Array{String,1}()
    new_idx = 0

    # Get all currently used hits
    for hit in hitnames[1:hit_idx]
        if !(hit in used_hits)
            push!(used_hits, hit)
        end
    end

    # Iterate through remaining hits to find the next new one
    for hit in hitnames[hit_idx+1:end]
        new_idx += 1
        if !(hit in used_hits)
            new_hit = hit
            break
        end
    end

    # Return the new hit and its index in the hitlist
    return new_hit,new_idx+hit_idx
end

"""
    add_blanks_to_back(subject::String, query::String, new_seq::String,
    subj_len::Int64, query_len::Int64, subj_non_blanks::Int64,
    hitnames::Vector{String}, hit_idx::Int64, character_labels::Dict{String,String})

Adds blanks to the back of a sequence from a blast match.

# Arguments
- `subject::String`: the subject the query is being matched to.
- `query::String`: the query that is having blanks added to it.
- `new_seq::String`: the new sequence (query with added blanks).
- `subj_len::Int64`: length of the subject.
- `query_len::Int64`: length of the query.
- `subj_non_blanks::Int64`: number of non blanks in the subject.
- `hitnames::Vector{String}`: list of blast hits.
- `hit_idx::Int64`: index of the current blast hit.
- `character_labels::Dict{String,String}`: a mapping of the character labels to the corresponding sequences.
"""
function add_blanks_to_back(subject::String, query::String, new_seq::String, subj_len::Int64, query_len::Int64, subj_non_blanks::Int64, hitnames::Vector{String}, hit_idx::Int64, character_labels::Dict{String,String})

    # If empty, return the sequence, and blanks to keep the same length as the subject
    if query == ""
        return new_seq * repeat("-", subj_len)

    # If empty, return the sequence
    elseif subj_len == 0
        return new_seq

    # If subject length equals query length, return the sequence with the rest of the query on the back
    elseif subj_len == query_len
        return new_seq * query

    # ******* We can probably remove this *******
    # If subject contains only blanks
    elseif subj_non_blanks == 0

        # Get the next best hit
        next_hit,hit_idx = get_next_hit(hitnames, hit_idx)

        # If no other hits, add rest of the subject (blanks) onto the sequence
        if next_hit == ""
            return new_seq * subject

        # Found a new hit
        else
            # Get the rest of the new subject
            new_subj = character_labels[next_hit][end-subj_len+1:end]

            # Finish the recursion on the new subject
            return add_blanks_to_back(new_subj, query, new_seq, subj_len, query_len, length(replace(new_subj, "-", "")), hitnames, hit_idx, character_labels)
        end
    end

    # Check if the current subject character is a blank
    if subject[1] == '-'

        # Recur on the rest of the subject and the entire query
        return add_blanks_to_back(subject[2:end], query, new_seq * '-', subj_len-1, query_len, subj_non_blanks, hitnames, hit_idx, character_labels)

    # Else recur on the rest of the subject and the rest of the query
    else
        return add_blanks_to_back(subject[2:end], query[2:end], new_seq * query[1], subj_len-1, query_len-1, subj_non_blanks-1, hitnames, hit_idx, character_labels)
    end
end

"""
    add_blanks_to_front(subject::String, query::String, new_seq::String,
    subj_len::Int64, query_len::Int64, subj_non_blanks::Int64,
    hitnames::Vector{String}, hit_idx::Int64, character_labels::Dict{String,String})

Adds blanks to the front of a sequence from a blast match.

# Arguments
- `subject::String`: the subject the query is being matched to.
- `query::String`: the query that is having blanks added to it.
- `new_seq::String`: the new sequence (query with added blanks).
- `subj_len::Int64`: length of the subject.
- `query_len::Int64`: length of the query.
- `subj_non_blanks::Int64`: number of non blanks in the subject.
- `hitnames::Vector{String}`: list of blast hits.
- `hit_idx::Int64`: index of the current blast hit.
- `character_labels::Dict{String,String}`: a mapping of the character labels to the corresponding sequences.
"""
function add_blanks_to_front(subject::String, query::String, new_seq::String, subj_len::Int64, query_len::Int64, subj_non_blanks::Int64, hitnames::Vector{String}, hit_idx::Int64, character_labels::Dict{String,String})

    # If empty, return the sequence, and blanks to keep the same length as the subject
    if query == ""
        return repeat("-", subj_len) * new_seq

    # If empty, return the sequence
    elseif subj_len == 0
        return new_seq

    # If subject length equals query length, return the sequence with the rest of the query on the front
    elseif subj_len == query_len
        return query * new_seq

    # ******* We can probably remove this *******
    # If subject contains only blanks
    elseif subj_non_blanks == 0

        # Get the next best hit
        next_hit,hit_idx = get_next_hit(hitnames, hit_idx)

        # If no other hits, add rest of the subject (blanks) onto the sequence
        if next_hit == ""
            return subject * new_seq

        # Found a new hit
        else
            # Get the rest of the new subject
            new_subj = character_labels[next_hit][1:subj_len]

            # Finish the recursion on the new subject
            return add_blanks_to_front(new_subj, query, new_seq, subj_len, query_len, length(replace(new_subj, "-", "")), hitnames, hit_idx, character_labels)
        end
    end

    # Check if the current subject character is a blank
    if subject[end] == '-'

        # Recur on the rest of the subject and the entire query
        return add_blanks_to_front(subject[1:end-1], query, '-' * new_seq, subj_len-1, query_len, subj_non_blanks, hitnames, hit_idx, character_labels)

    # Recur on the rest of the subject and the rest of the query
    else
        return add_blanks_to_front(subject[1:end-1], query[1:end-1], query[end] * new_seq, subj_len-1, query_len-1, subj_non_blanks-1, hitnames, hit_idx, character_labels)
    end
end

"""
    get_best_hit(results::Array{BioTools.BLAST.BLASTResult,1}, query::String,
    character_labels::Dict{String,String},  character_labels_no_gaps::Dict{String,String})

Gets the hit from blastn that has the most sequence coverage with no gaps compared to the query sequence.

# Arguments
- `results::Array{BioTools.BLAST.BLASTResult,1}`: blastn results.
- `query::String`: the query that is having blanks added to it.
- `character_labels::Dict{String,String}`: a mapping of the character labels to the corresponding sequences.
- `character_labels_no_gaps::Dict{String,String}`: character labels with gaps removed from sequences.
"""
function get_best_hit(results::Array{BioTools.BLAST.BLASTResult,1}, query::String, character_labels::Dict{String,String},  character_labels_no_gaps::Dict{String,String})

    # Initialize varibales
    error = Array{Int,1}(undef, 0)

    # Iterate through each result
    for result in results

        # Extract the subject from the result
        subject = character_labels[result.hitname]

        subject_no_gaps = character_labels_no_gaps[result.hitname]

        # Get the number of characters that would be lost if we used this results alignment
        try
            orig_subj_start = match(Regex(convert(String, result.hit)), subject_no_gaps).offset
            subj_start = get_adjusted_start(orig_subj_start, subject)
            query_start = match(Regex(convert(String, result.alignment.seq)), query).offset
            subject_front = subject[1:subj_start-1]
            query_front = query[1:query_start-1]
            subject_back = subject[subj_start:end]
            query_back = query[query_start:end]
            lost_characters = abs(length(replace(subject_front, "-" => "")) - length(query_front)) + abs(length(replace(subject_back, "-" => "")) - length(query_back))
            push!(error, lost_characters)
        catch
            push!(error, 1000000)
        end
    end

    # Return the reuslt which minimizes the number of characters lost from the new alignment
    return results[argmin(error)]
end

"""
    add_blanks(query_path::String, db_path::String, character_labels::Dict{String,String},
    character_labels_no_gaps::Dict{String,String} ; return_blast::Bool=false)

Adds blanks to an input sequence given a database.

# Arguments
- `query_path::String`: path to the query file.
- `db_path::String`: path to the blast database.
- `character_labels::Dict{String,String}`: a mapping of the character labels to the corresponding sequences.
- `character_labels_no_gaps::Dict{String,String}`: character labels with gaps removed from sequences.
- `return_blast::Bool=false`: whether to return blast results.
- `protein::Bool=false`: if protein sequence.
"""
function add_blanks(query_path::String, db_path::String, character_labels::Dict{String,String},
                    character_labels_no_gaps::Dict{String,String} ; return_blast::Bool=false,
                    protein::Bool=false)

    # Initialize
    best_result = 0
    orig_subj_start = 0

    # Read in the query sequence from file
    query = ""
    for line in readlines(query_path)
        if occursin(">", line)
            continue
        end
        query = query * line
    end

    # # Get the results from blastn
    if protein
         results = blastp(query_path, db_path, ["-task", "blastp", "-max_target_seqs", 10], db=true)
    else
        results = blastn(query_path, db_path, ["-task", "blastn", "-max_target_seqs", 10], db=true)
    end

    # Extract the best result
    try
        best_result = get_best_hit(results, query, character_labels, character_labels_no_gaps)
    catch
        if return_blast
            return "Error",["Error"]
        else
            return "Error"
        end
    end

    # Get all hitnames
    hitnames = [result.hitname for result in results]

    # Extract the subject as the top hit
    subject = character_labels[best_result.hitname]

    subject_no_gaps = character_labels_no_gaps[best_result.hitname]

    # Convert the best hit to a string and remove gaps that blast added
    best_hit = replace(convert(String, best_result.hit), "-" => "")

    # Get the starting position of the matched subject
    try
        orig_subj_start = match(Regex(best_hit), subject_no_gaps).offset
    catch
        if return_blast
            return "Error",["Error"]
        else
            return "Error"
        end
    end

    subj_start = get_adjusted_start(orig_subj_start, subject)

    # Convert the best hit to a string and remove gaps that blast added
    blast_alignment = replace(convert(String, best_result.alignment.seq), "-" => "")

    # Get the starting position of the query
    query_start = match(Regex(blast_alignment), query).offset

    # Get the fronts and backs of the subject and query
    subject_front = subject[1:subj_start-1]
    query_front = query[1:query_start-1]
    subject_back = subject[subj_start:end]
    query_back = query[query_start:end]

    # Return the query sequence with blanks added to the front and back
    new_seq = add_blanks_to_front(subject_front, query_front, "", subj_start-1, query_start-1, length(replace(subject_front, "-" => "")), hitnames, 1, character_labels) *
    add_blanks_to_back(subject_back, query_back, "", length(subject_back), length(query_back), length(replace(subject_back, "-" => "")), hitnames, 1, character_labels)

    if return_blast
        return new_seq, hitnames
    else
        return new_seq
    end
end
