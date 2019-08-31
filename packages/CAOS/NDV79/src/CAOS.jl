module CAOS

using BioTools
using BioTools.BLAST
using BioSequences
using JSON
using FastaIO
using Tokenize

export generate_caos_rules,
       classify_new_sequence,
       parse_tree,
       load_tree,
       get_nodes,
       remove_from_tree!,
       remove_blanks,
       get_max_depth,
       find_sequence,
       get_sPu_and_sPr,
       get_cPu_and_cPr,
       get_group_taxa_at_node,
       get_group_combos,
       classification,
       get_neighbors,
       get_first_taxa_from_tree,
       get_descendents,
       downsample_taxa,
       get_adjusted_start,
       get_all_neighbors,
       add_nodes!,
       add_blanks,
       convert_to_struct,
       classify_sequence

include("caos_functions.jl")
include("tree_functions.jl")
include("utils.jl")
include("classification.jl")
include("gap_imputation.jl")
include("user_functions.jl")

end # module
