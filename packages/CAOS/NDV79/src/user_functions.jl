# Only for simple rules
"""
    generate_caos_rules(tree_file_path::String, output_directory::String)

Takes a Nexus file and generates all the CAOS rules for the tree.

# Arguments
- `tree_file_path::String`: path to the Nexus file.
- `output_directory::String`: path to the output directory.
"""
function generate_caos_rules(tree_file_path::String, output_directory::String; protein::Bool=false)

    # Create directory
    try
        mkdir("$output_directory")
    catch
    end

    # Parse the tree and prepare data for CA's
    nodes, taxa_labels, character_labels, _ = parse_tree(tree_file_path)

    # Initialize variables for constructing tree
    sPu, sPr = get_sPu_and_sPr(nodes, 1, taxa_labels, character_labels; protein=protein)
    cPu = Array{Dict{String,Any}}(undef, 0)
    cPr = Array{Dict{String,Any}}(undef, 0)
    #cPu,cPr = get_cPu_and_cPr(nodes,1,taxa_labels,character_labels,sPu,sPr)

    # Get CA's for tree
    tree = Node([])
    add_nodes!(tree,sPu,sPr,cPu,cPr,taxa_labels,character_labels,nodes,1,complex=false, protein=protein)

    # Save tree to json
    tree_data = JSON.json(tree)
    open("$output_directory/caos_rules.json", "w") do f
        write(f, tree_data)
    end

    # Change blanks to N's for the database
    character_labels_no_gaps = remove_blanks(character_labels)

    # Create fasta file from dictionary of character labels
    writefasta("$output_directory/char_labels.fasta", character_labels_no_gaps)

    # Create the blast database
    if protein
        run(`makeblastdb -in $output_directory/char_labels.fasta -dbtype prot`)
    else
    run(`makeblastdb -in $output_directory/char_labels.fasta -dbtype nucl`)
    end

    # Save character and taxa labels
    character_data = JSON.json(character_labels)
    open("$output_directory/character_labels.json", "w") do f
        write(f, character_data)
    end
    taxa_data = JSON.json(taxa_labels)
    open("$output_directory/taxa_labels.json", "w") do f
        write(f, taxa_data)
    end

    return tree, character_labels, taxa_labels

end

"""
    classify_new_sequence(tree::Node, character_labels::Dict{String,String}, taxa_labels::Dict{String,String},
    sequence_file_path::String, output_directory::String ; all_CA_weights::Dict{Int64,
    Dict{String,Int64}}=Dict(1=>Dict("sPu"=>1,"sPr"=>1,"cPu"=>1,"cPr"=>1)), occurrence_weighting::Bool=false,
    tiebreaker::Vector{Dict{String,Int64}}=[Dict{String,Int64}()], combo_classification::Bool=false)

Takes a tree (Node) and a sequence, and classifies the new sequence using the CAOS tree.

# Arguments
- `tree::Node`: the tree represented as a Node.
- `character_labels::Dict{String,String}`: a mapping of the character labels to the corresponding sequences.
- `taxa_labels::Dict{String,String}`: a mapping of the taxa labels to the character labels.
- `sequence_file_path::String`: a file path to the sequence to classify.
- `output_directory::String`: path to the output directory.
- `all_CA_weights::Dict{Int64,Dict{String,Int64}}=Dict(1=>Dict("sPu"=>1,"sPr"=>1,"cPu"=>1,"cPr"=>1))`: CA weights to be used.
- `occurrence_weighting::Bool=false`: whether to use occurence weighting in classification.
- `tiebreaker::Vector{Dict{String,Int64}}=[Dict{String,Int64}()]`: tiebreaker to be used in classification.
- `combo_classification::Bool=false`: whether to use a combo of Blast and CAOS for classification.
"""
function classify_new_sequence(tree::Node, character_labels::Dict{String,String}, taxa_labels::Dict{String,String},
    sequence_file_path::String, output_directory::String ; all_CA_weights::Dict{Int64,Dict{String,Int64}}=Dict(1=>Dict("sPu"=>1,"sPr"=>1,"cPu"=>1,"cPr"=>1)),
    occurrence_weighting::Bool=false, tiebreaker::Vector{Dict{String,Int64}}=[Dict{String,Int64}()], combo_classification::Bool=false, protein::Bool=false)

    # Create directory
    try
        mkdir("$output_directory")
    catch
    end

    character_labels_no_gaps = remove_blanks(character_labels, change_to_N=false)

    # Get the new sequence after imputing blanks
    new_seq = add_blanks("$sequence_file_path", "$output_directory/char_labels.fasta", character_labels, character_labels_no_gaps, protein=protein)
    classification = classify_sequence(new_seq, tree, all_CA_weights[1], all_CA_weights, occurrence_weighting, 1,
                                       tiebreaker, combo_classification=combo_classification, protein=protein)

    return classification

end

# Function to read a tree from file and convert it to a node object
"""
    load_tree(directory::String)

Loads a CAOS tree from file.

# Arguments
- `directory::String`: path to directory where tree exists.
"""
function load_tree(directory::String)

    # Load tree from json
    open("$directory/caos_rules.json", "r") do f
        global loaded_tree
        loaded_tree=JSON.parse(f)  # parse and transform data
    end

    open("$directory/character_labels.json", "r") do f
        global character_labels
        character_labels=convert(Dict{String,String}, JSON.parse(f))  # parse and transform data
    end

    open("$directory/taxa_labels.json", "r") do f
        global taxa_labels
        taxa_labels=convert(Dict{String,String}, JSON.parse(f))  # parse and transform data
    end

    tree_load = Node([])

    # Get tree back into proper format
    tree = convert_to_struct(loaded_tree, tree_load)

    return tree, character_labels, taxa_labels

end
