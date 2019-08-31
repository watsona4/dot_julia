using Pkg; Pkg.activate(".");
using StringDistances
using ConceptnetNumberbatch
using BenchmarkTools
using Random
using Languages
using Serialization

fid = open("./_conceptnet_/numberbatch-en-17.06.txt.bin")
cptnet = deserialize(fid)
close(fid)
words = (key for key in keys(cptnet[Languages.English()]) if isascii(key))

target="sstring"
for dist in [Jaro(), Levenshtein(), DamerauLevenshtein(), Cosine(), QGram(2), QGram(3)]
    _, idx = findmin(map(x->evaluate(dist, target, x), words))
    println("---------------")
    @time _, idx = findmin(map(x->evaluate(dist, target, x), words))
    println("[$dist], best match: $(collect(words)[idx])")
end

