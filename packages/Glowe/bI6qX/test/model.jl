# test various model functions
bigdata = joinpath(dirname(@__FILE__), "..", "data", "big.txt")

TMPDIR = "./tmp"
mkpath(TMPDIR)

CORPUS = bigdata
VOCAB_FILE = joinpath(TMPDIR, "vocab.txt")
COOCCURRENCE_FILE = joinpath(TMPDIR, "cooccurrence.bin")
COOCCURRENCE_SHUF_FILE = joinpath(TMPDIR, "cooccurrence.shuf.bin")
SAVE_FILE = joinpath(TMPDIR, "vectors")
VERBOSE = 0
MEMORY = 4.0
VOCAB_MIN_COUNT = 5
VECTOR_SIZE = 50
MAX_ITER = 2
WINDOW_SIZE = 5
BINARY= 0
NUM_THREADS = 1
X_MAX = 10.0
HEADER = 1

# Create and load model
vocab_count(CORPUS, VOCAB_FILE, min_count=VOCAB_MIN_COUNT, verbose=VERBOSE)
cooccur(CORPUS, VOCAB_FILE, COOCCURRENCE_FILE,
        memory=MEMORY, verbose=VERBOSE, window_size=WINDOW_SIZE)
shuffle(COOCCURRENCE_FILE, COOCCURRENCE_SHUF_FILE,
memory=MEMORY, verbose=VERBOSE)
glove(COOCCURRENCE_SHUF_FILE, VOCAB_FILE, SAVE_FILE,
      threads=NUM_THREADS, x_max=X_MAX, iter=MAX_ITER,
      vector_size=VECTOR_SIZE, binary=BINARY,
      write_header=HEADER, verbose=VERBOSE)
model_file = joinpath(SAVE_FILE) * ifelse(BINARY==1, ".bin", ".txt")
model = wordvectors(model_file, Float32, header=true, kind= :text)

# word vectors
println(model)

len_vecs, num_words = size(model)
wordvecs = model.vectors
@test size(wordvecs) == (len_vecs, num_words)

words = vocabulary(model)
word1 = words[rand(1:end)]
word2 = words[rand(1:end)]
word3 = words[rand(1:end)]

@test in_vocabulary(model, word1)

n = rand(1:100)

indxs, mes = cosine(model, word1, n)
@test words[indxs] == cosine_similar_words(model, word1, n)
w4_indx = indxs[rand(1:end)]
loc = findall(in(w4_indx), indxs)
word4 = words[w4_indx]
@test index(model, word4) == w4_indx

s = similarity(model, word1, word4)
@test mes[loc[1]] ≈ s

inx, mes = analogy(model, [word1, word2], [word3], n)
@test words[inx] == analogy_words(model, [word1, word2], [word3], n)

rm(TMPDIR, recursive=true, force=true)

println("model passed test...")
