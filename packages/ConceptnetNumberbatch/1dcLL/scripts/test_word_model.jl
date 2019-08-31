using Pkg
Pkg.activate(".")
using ConceptnetNumberbatch
using Serialization

# Load a serialized version of ConceptNetEnglish
fid = open("./_conceptnet_/numberbatch-en-17.06.txt.bin")
cptnet = deserialize(fid)
close(fid)

## get similar words from NN q-gram model
dictionary = collect(keys(cptnet))
@time modelstuff = ConceptnetNumberbatch.build_nn_model(dictionary, ngram_size=2)
open("./_conceptnet_/model.bin", "w") do fid
    serialize(fid, modelstuff)
end
#modelstuff = open(deserialize, "./_conceptnet_/model.bin", "r")
targets = ["phrasis", "appled", "fdellity", "moanster"]
found = ConceptnetNumberbatch.get_similar_words(targets[1], modelstuff...)
for target in targets
    @time found = ConceptnetNumberbatch.get_similar_words(target, modelstuff...)
    println("$target => $(found[1])")
end
