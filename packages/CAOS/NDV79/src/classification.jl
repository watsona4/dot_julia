"""
    CA_matches(sequence::String, CAs::Vector{Rule}, CA_weights::Dict{String,Int64}, occurrence_weighting::Bool)

Counts the number of CA's matched by a sequence (only support for simple rules).

# Arguments
- `sequence::String`: sequence to count matches.
- `CAs::Vector{Rule}`: list of all CA's.
- `CA_weights::Dict{String,Int64}`: weights to use for CA counts.
- `occurrence_weighting::Bool`: whether to use occurrence weighting during counting.
"""
function CA_matches(sequence::String, CAs::Vector{Rule}, CA_weights::Dict{String,Int64}, occurrence_weighting::Bool ; protein::Bool=false)

    letter_transformations = Dict{Char,Vector{Char}}('A'=>['A'],
                                                     'T'=>['T'],
                                                     'C'=>['C'],
                                                     'G'=>['G'],
                                                     'U'=>['U'],
                                                     'R'=>['A','G'],
                                                     'Y'=>['C','T'],
                                                     'S'=>['G','C'],
                                                     'W'=>['A','T'],
                                                     'K'=>['G','T'],
                                                     'M'=>['A','C'],
                                                     'B'=>['C','G','T'],
                                                     'D'=>['A','G','T'],
                                                     'H'=>['A','C','T'],
                                                     'V'=>['A','C','G'],
                                                     'N'=>['A','T','C','G'],
                                                     '-'=>['-'])

    used_idxs = Array{Int,1}()

    # Initialize CAOS score
    total_score = 0

    # Iterate through each rule
    for rule in CAs

        # Initialize variables
        is_match = true
        score = 1

        # Check if the sequence follows the rule
        for (iter,idx) in enumerate(rule.idxs)

            if idx in used_idxs
                is_match = false
                break
            end

            if haskey(letter_transformations, sequence[idx]) && !protein
                seq_letters = letter_transformations[sequence[idx]]
            else
                seq_letters = sequence[idx]
            end

            if !(rule.char_attr[iter] in seq_letters)
                is_match = false
                break
            end
        end

        # Keep track of score
        if is_match

            push!(used_idxs, (rule.idxs)[1])

            # Add value of pure/private rule
            if rule.is_pure
                if length(rule.char_attr) == 1
                    score *= CA_weights["sPu"]
                else
                    score *= CA_weights["cPu"]
                end
            else
                if length(rule.char_attr) == 1
                    score *= CA_weights["sPr"]
                    if occurrence_weighting
                        score *= rule.occurances/rule.num_group
                    end
                else
                    score *= CA_weights["cPr"]
                    if occurrence_weighting
                        score *= rule.occurances/rule.num_group
                    end
                end
            end

            # Add to total score
            total_score += score
        end
    end

    # Return CAOS score
    return Int(round(total_score))
end

"""
    classify_sequence(sequence::String, tree::Node, CA_weights::Dict{String,Int64},
    all_CA_weights::Dict{Int64,Dict{String,Int64}}, occurrence_weighting::Bool,
    depth::Int64, tiebreaker::Vector{Dict{String,Int64}} ; blast_results=["Fake Label"], combo_classification::Bool=false, protein::Bool=false)

Classifies an input sequence given a phylogentic tree.

# Arguments
- `sequence::String`: sequence to count matches.
- `tree::Node`: the tree represented as a Node.
- `CA_weights::Dict{String,Int64}`: weights to use for CA counts.
- `all_CA_weights::Dict{Int64,Dict{String,Int64}}`: all sets of weights to use for CA counts.
- `occurrence_weighting::Bool`: whether to use occurrence weighting during counting.
- `depth::Int64`: current depth of the tree.
- `tiebreaker::Vector{Dict{String,Int64}}`: tiebreaking procedures to use.
- `blast_results=["Fake Label"]`: list of blast results.
- `combo_classification::Bool=false`: whether to use both Blast and CAOS for classification.
"""
function classify_sequence(sequence::String, tree::Node, CA_weights::Dict{String,Int64}, all_CA_weights::Dict{Int64,Dict{String,Int64}}, occurrence_weighting::Bool, depth::Int64, tiebreaker::Vector{Dict{String,Int64}} ; blast_results=["Fake Label"], combo_classification::Bool=false, protein::Bool=false)

    if haskey(all_CA_weights, depth)
        CA_weights = all_CA_weights[depth]
    end

    # If at a terminal node, return the taxa label
    if length(tree.children) == 0
        return tree.taxa_label

    # Get the CA score for each child
    else


        if false && combo_classification && (length(blast_results) >= 10)
            for child in tree.children
                descendents = get_descendents(child)
                all_blast = true
                for blast_result in blast_results[1:10]
                    if !(blast_result in descendents)
                        all_blast = false
                        break
                    end
                end
                if all_bast
                    return classify_sequence(sequence,child,CA_weights,all_CA_weights,occurrence_weighting,depth+1,tiebreaker, blast_results=blast_results, combo_classification=combo_classification, protein=protein)
                end
            end
        end


        child_CA_score = Array{Int,1}()
        for child in tree.children
            push!(child_CA_score, CA_matches(sequence, child.CAs, CA_weights, occurrence_weighting, protein=protein))
        end

        max_child_idx = argmax(child_CA_score)

        # Select the child with highest CA score and descend in that direction
        if length(max_child_idx) == 1
            return classify_sequence(sequence,tree.children[max_child_idx[1]],CA_weights,all_CA_weights,occurrence_weighting,depth+1,tiebreaker, blast_results=blast_results, combo_classification=combo_classification, protein=protein)

        # If there is a tie, return either use the tiebreaker or return the tree
        elseif tiebreaker[1] == Dict{String,Int64}()
            if combo_classification && (length(blast_results) >= 5)
                for child in tree.children
                    descendents = get_descendents(child)
                    top_blasts = true
                    for blast_result in blast_results[1:5]
                        if !(blast_result in descendents)
                            top_blasts = false
                            break
                        end
                    end
                    if top_blasts
                        return classify_sequence(sequence,child,CA_weights,all_CA_weights,occurrence_weighting,depth+1,tiebreaker, blast_results=blast_results, combo_classification=combo_classification, protein=protein)
                    end
                end
            end
            return tree
        else
            return classify_sequence(sequence,tree,tiebreaker[1],Dict{Int,Dict{String,Int64}}(),occurrence_weighting,depth,tiebreaker[2:end], blast_results=blast_results, combo_classification=combo_classification, protein=protein)
        end
    end
end
