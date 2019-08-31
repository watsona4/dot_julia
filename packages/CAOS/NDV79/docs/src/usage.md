## Workflow

* First run the `generate_caos_rules` function on your tree in the required NEXUS format. This will create the necessary CAOS rules and files to use for classification.

* Once you have generated your CAOS rules, you can load them with the function `load_tree`.

* Lastly run the `classify_new_sequence` function on the sequence you wish to classify.

## NEXUS File Format

In order for the parser to correctly extract all relevant information from your phylogeneitc tree, your NEXUS file must be in the exact format described below (most NEXUS files will already be in this format, but if you are having issues with your file being read properly, here is how to format it):

* The tree must in Newick format
* The tree must be on a line with the words "TREE" and "="
* The character labels (names associated with each sequence of characters) should be directly after a line with the word "MATRIX" (this should be the only time the word "MATRIX" appears in the file)
* Each character label should be its own line, with the name followed by a number of space, and then the character sequence
* After your last character label, the following line should contain only a ";"
* Taxa labels (taxa numbers for the position in the newick formatted tree associated with each character sequence name) should appear directly after a line containing the word "TRANSLATE" (this should be the only occurrence of that word in the file)
* Each taxa label should be its own line, with the taxa number followed by the character sequence name (at least one space in between the two)
* The line with the last taxa label should end with a ";"

## Examples

Two example NEXUS files are provided in the `test/data` folder : `S10593.nex` and `E1E2L1.nex`

An example sequence file is provided in the `test/data` folder : `Example_Sequence.txt`

#### Functions

```julia
generate_caos_rules("test/data/S10593.nex", "test/data")
```
This will generate your CAOS rules for the tree in the `S10593.nex` NEXUS file and place all output files from rule generation in the `test/data` directory.

```julia
tree, character_labels, taxa_labels = load_tree("test/data")
```
This will load the internal representation of the tree and CAOS rules from the files output during rule generation in the `test/data` directory.

```julia
classification = classify_new_sequence(tree, character_labels, taxa_labels, "test/data/Example_Sequence.txt", "test/data")
```
This will return the classification result, either a string with the classification label or a Node object (under classifiction).
