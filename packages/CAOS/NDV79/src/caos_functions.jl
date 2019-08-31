"""
    get_group_taxa_at_node(nodes::Array{Dict{String,Any}}, node_num::Int64)

Gets the sets of taxa for each group at a node.

# Arguments
- `nodes::Array{Dict{String,Any}}`: list of nodes.
- `node_num::Int64`: current node index.
"""
function get_group_taxa_at_node(nodes::Array{Dict{String,Any}}, node_num::Int64)

    #Initialize varibales
    last_group = Array{String}(undef, 0)
    groups = Array{Array{String}}(undef, 0)
    num_groups = nodes[node_num]["Groups"]

    # Iterate through each descendent
    for group in nodes[node_num]["Descendents"]

        # Add taxa taxa to group
        group_taxa = nodes[group]["Taxa"]
        push!(groups, group_taxa)
    end
    if length(groups) < num_groups
        for group in groups
            last_group = setdiff(nodes[node_num]["Taxa"], group)
        end
        if length(groups) == 0
            last_group = nodes[node_num]["Taxa"]
        end
        for idx in 1:num_groups-length(groups)
            if length(last_group) >= idx
                push!(groups, [last_group[idx]])
            end
        end
    end
    return groups
end

"""
    get_group_combos(group_taxa::Array{Array{String}})

Gets all the combinations of group vs non groups.

# Arguments
- `group_taxa::Array{Array{String}}`: list of taxa within a group.
"""
function get_group_combos(group_taxa::Array{Array{String}})
    combos = Array{Dict{String,Array{String}}}(undef, 0)
    for (idx, group) in enumerate(group_taxa)
        non_group = Array{String}(undef, 0)
        group = group
        non_group_groups = group_taxa[1:end .!= idx]
        for non_group_group in non_group_groups
            append!(non_group, non_group_group)
        end
        push!(combos, Dict("group" => group, "Non_group" => non_group))
    end
    return combos
end

"""
    get_sPu_and_sPr(nodes::Array{Dict{String,Any}}, node_num::Int64,
    taxa_labels::Dict{String,String}, character_labels::Dict{String,String})

Gets all the sPu and sPr for the entire character sequence at a specific node.

# Arguments
- `nodes::Array{Dict{String,Any}}`: list of nodes.
- `node_num::Int64`: current node index.
- `taxa_labels::Dict{String,String}`: a mapping of the taxa labels to the character labels.
- `character_labels::Dict{String,String}`: a mapping of the character labels to the corresponding sequences.
"""
function get_sPu_and_sPr(nodes::Array{Dict{String,Any}}, node_num::Int64, taxa_labels::Dict{String,String}, character_labels::Dict{String,String}; protein::Bool=false)

    # Initialize variables
    group_taxa = get_group_taxa_at_node(nodes, node_num)
    group_combos = get_group_combos(group_taxa)
    sPu = Array{Dict{String,Any}}(undef, 0)
    sPr = Array{Dict{String,Any}}(undef, 0)
    letter_transformations = Dict{Char,Vector{Char}}('A'=>['A'], 'T'=>['T'], 'C'=>['C'], 'G'=>['G'], 'U'=>['U'], 'R'=>['A','G'], 'Y'=>['C','T'], 'S'=>['G','C'], 'W'=>['A','T'], 'K'=>['G','T'], 'M'=>['A','C'], 'B'=>['C','G','T'], 'D'=>['A','G','T'], 'H'=>['A','C','T'], 'V'=>['A','C','G'], 'N'=>['A','T','C','G'], '-'=>['-'])

    # Iterate through all possible group combinations
    for (group_idx, group_combo) in enumerate(group_combos)
        group_taxa = group_combo["group"]
        non_group_taxa = group_combo["Non_group"]
        push!(sPu, Dict{String,Any}("Group_Taxa" => group_taxa, "sPu" => Dict{Int,Tuple{Char,Int}}(), "Num_Non_Group" => length(non_group_taxa)))
        push!(sPr, Dict{String,Any}("Group_Taxa" => group_taxa, "sPr" => Dict{Int,Array{Tuple{Char,Int}}}(), "Num_Non_Group" => length(non_group_taxa)))

        if length(group_taxa) > 0
            # Iterate through each letter in the character sequences
            for idx in 1:length(character_labels[taxa_labels[group_taxa[1]]])

                # Only continue if the non group does not contain any N's at the current index
                non_group_letters = unique([character_labels[taxa_labels[new_character]][idx] for new_character in non_group_taxa])
                if !(('N' in non_group_letters) | ('A' in non_group_letters && 'T' in non_group_letters && 'C' in non_group_letters && 'G' in non_group_letters))
                    # Iterate through each taxon in group
                    for (taxa_idx, taxa) in enumerate(group_taxa)

                        # Get the letter at the index
                        curr_letter = character_labels[taxa_labels[taxa]][idx]

                        # Get the transformation of the current letter
                        if protein
                            curr_letters = curr_letter
                        else
                            curr_letters = letter_transformations[curr_letter]
                        end

                        # Iterate through each letter
                        for letter in curr_letters
                            # If letter is not a gap and does not exist in sPu
                            valid = letter != '-' && !(haskey(sPu[group_idx]["sPu"], idx))

                            # If exists in sPr, check if new letter
                            if haskey(sPr[group_idx]["sPr"], idx)
                                used_sPr = [tup[1] for tup in sPr[group_idx]["sPr"][idx]]
                                valid = !(letter in used_sPr)
                            end
                            if valid
                                pure = true
                                match = false

                                # Iterate through the character of each member of the other groups, to check if candidate CA
                                for new_letter in non_group_letters

                                    if protein
                                        new_letters = new_letter
                                    else
                                        new_letters = letter_transformations[new_letter]
                                    end
                                    match = letter in new_letters
                                    if match
                                        break
                                    end
                                end

                                # If candidate CA, iterate through the character of each member of the same group to determine if pure or private
                                if !match
                                    occurances = 1
                                    for new_character in group_taxa[1:end .!=taxa_idx]
                                        new_letter = character_labels[taxa_labels[new_character]][idx]
                                        if protein
                                            new_letters = new_letter
                                        else
                                            new_letters = letter_transformations[new_letter]
                                        end
                                        match = letter in new_letters
                                        if match
                                            occurances += 1
                                        else
                                            pure = false
                                        end
                                    end

                                    # Add the single pure or private characteristic if found
                                    if pure
                                        sPu[group_idx]["sPu"][idx] = (letter, occurances)
                                    else
                                        if !haskey(sPr[group_idx]["sPr"], idx)
                                            sPr[group_idx]["sPr"][idx] = Array{Tuple{Char,Int}}(undef, 0)
                                        end
                                        push!(sPr[group_idx]["sPr"][idx], (letter, occurances))
                                    end
                                end
                            end
                        end

                    end
                end
            end
        end
    end
    return sPu, sPr
end

# Function to get all the cPu and cPr for the entire character sequence at a specific node ----- function currently not supported for nucleotide options
"""
    get_cPu_and_cPr(nodes::Array{Dict{String,Any}}, node_num::Int64, taxa_labels::Dict{String,String},
    character_labels::Dict{String,String}, sPu::Array{Dict{String,Any}}, sPr::Array{Dict{String,Any}})

Gets all the cPu and cPr for the entire character sequence at a specific node (does not support nucleotide options).

# Arguments
- `nodes::Array{Dict{String,Any}}`: list of nodes.
- `node_num::Int64`: current node index.
- `taxa_labels::Dict{String,String}`: a mapping of the taxa labels to the character labels.
- `character_labels::Dict{String,String}`: a mapping of the character labels to the corresponding sequences.
- `sPu::Array{Dict{String,Any}}`: list of simple pure rules.
- `sPr::Array{Dict{String,Any}}`: list of simple private rules.
"""
function get_cPu_and_cPr(nodes::Array{Dict{String,Any}}, node_num::Int64, taxa_labels::Dict{String,String}, character_labels::Dict{String,String}, sPu::Array{Dict{String,Any}}, sPr::Array{Dict{String,Any}})

    # Figure out which indices have already been matched to an sPu or sPr
    exclude = Vector{Int64}()
    for dict in sPu
        append!(exclude, [key for key in keys(dict["sPu"])])
    end
    for dict in sPr
        append!(exclude, [key for key in keys(dict["sPr"])])
    end
    all_idx = range(1, length=length(character_labels[taxa_labels["1"]]))
    curr_idx = setdiff(all_idx, exclude)

    # Initialize variables
    group_taxa = get_group_taxa_at_node(nodes, node_num)
    group_combos = get_group_combos(group_taxa)
    cPu = Array{Dict{String,Any}}(undef, 0)
    cPr = Array{Dict{String,Any}}(undef, 0)
    num_char = length(character_labels[taxa_labels["1"]])
    letter_transformations = Dict{Char,Vector{Char}}('A'=>['A'], 'T'=>['T'], 'C'=>['C'], 'G'=>['G'], 'U'=>['U'], 'R'=>['A','G'], 'Y'=>['C','T'], 'S'=>['G','C'], 'W'=>['A','T'], 'K'=>['G','T'], 'M'=>['A','C'], 'B'=>['C','G','T'], 'D'=>['A','G','T'], 'H'=>['A','C','T'], 'V'=>['A','C','G'], 'N'=>['A','T','C','G'], '-'=>['-'])

    # Iterate through all possible group combinations
    for (group_idx, group_combo) in enumerate(group_combos)
        group_taxa = group_combo["group"]
        non_group_taxa = group_combo["Non_group"]
        push!(cPu, Dict{String,Any}("Group_Taxa" => group_taxa, "cPu" => Dict{Tuple{Int,Int},Tuple{Tuple{Char,Char},Int}}(), "Num_Non_Group" => length(non_group_taxa)))
        push!(cPr, Dict{String,Any}("Group_Taxa" => group_taxa, "cPr" => Dict{Tuple{Int,Int},Array{Tuple{Tuple{Char,Char},Int}}}(), "Num_Non_Group" => length(non_group_taxa)))

        # Iterate through each letter in the character sequences
        for (iter_idx,idx1) in enumerate(curr_idx)

            # Iterate through each letter that occurs after the first letter to get all combinations
            for idx2 in curr_idx[iter_idx:end]

                # Iterate through each taxon in the group
                for (taxa_idx, taxa) in enumerate(group_taxa)

                    # Extract the two letters of interest
                    letter1 = character_labels[taxa_labels[taxa]][idx1]
                    letter2 = character_labels[taxa_labels[taxa]][idx2]

                    # If letter is not a gap and does not exist in sPu
                    valid = letter1 != '-' && letter2 != '-' && !(haskey(cPu[group_idx]["cPu"], (idx1,idx2)))

                    # If exists in sPr, check if new letter
                    if haskey(cPr[group_idx]["cPr"], (idx1,idx2))
                        used_cPr = [tup[1][1] for tup in cPr[group_idx]["cPr"][(idx1,idx2)]]
                        valid = !((letter1, letter2) in used_cPr)
                    end

                    # If the letter combination is valid, continue check for valid CA
                    if valid
                        pure = true
                        match = false

                        # Iterate through the character of each member of the other groups, to check if candidate CA
                        for new_character in non_group_taxa
                            new_letter1 = character_labels[taxa_labels[new_character]][idx1]
                            new_letter2 = character_labels[taxa_labels[new_character]][idx2]
                            match = (new_letter1 == letter1 && new_letter2 == letter2)
                            if match
                                break
                            end
                        end

                        # If candidate CA, iterate through the character of each member of the same group to determine if pure or private
                        if !match
                            occurances = 1
                            for new_character in group_taxa[1:end .!=taxa_idx]
                                new_letter1 = character_labels[taxa_labels[new_character]][idx1]
                                new_letter2 = character_labels[taxa_labels[new_character]][idx2]
                                match = (new_letter1 == letter1 && new_letter2 == letter2)
                                if match
                                    occurances += 1
                                else
                                    pure = false
                                end
                            end

                            # Add the complex pure or private characteristic if found
                            if pure
                                cPu[group_idx]["cPu"][(idx1,idx2)] = ((letter1,letter2), occurances)
                            else
                                if !haskey(cPr[group_idx]["cPr"], (idx1,idx2))
                                    cPr[group_idx]["cPr"][(idx1,idx2)] = Array{Tuple{Tuple{Char,Char},Int}}(undef, 0)
                                end
                                push!(cPr[group_idx]["cPr"][(idx1,idx2)], ((letter1,letter2), occurances))
                            end
                        end
                    end
                end
            end
        end
    end
    return cPu,cPr
end
