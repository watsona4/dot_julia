using Pkg
Pkg.activate(".")
using ConceptnetNumberbatch
using Serialization

local cptnet

# Load a serialized version of ConceptNetEnglish
fid = open("./_conceptnet_/numberbatch-en-17.06.txt.bin")
cptnet = deserialize(fid)
close(fid)



## Get an embedding matrix
phrase = "this is a phrase that containz some iwords"
ConceptnetNumberbatch.word_embeddings(cptnet, phrase, keep_size=false, search_mismatches=false)
@time embs=ConceptnetNumberbatch.word_embeddings(cptnet, phrase, keep_size=false, search_mismatches=false)
@time embs=ConceptnetNumberbatch.word_embeddings(cptnet, phrase, keep_size=false, search_mismatches=true)
println("Loaded $(size(embs, 2)) embedding vectors (out of $(length(split(phrase)))), $(size(embs,1)) elements each.")

