# test various training parameters
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
VECTOR_SIZE = 13
MAX_ITER = 2
WINDOW_SIZE = 3
BINARY_OPTS = [0,1]
NUM_THREADS = 1
X_MAX = 10.0
HEADER_OPTS = [0,1]
TYPES = [Float32, Float64]

vocab_count(CORPUS, VOCAB_FILE, min_count=VOCAB_MIN_COUNT, verbose=VERBOSE)
cooccur(CORPUS, VOCAB_FILE, COOCCURRENCE_FILE,
        memory=MEMORY, verbose=VERBOSE, window_size=WINDOW_SIZE)
shuffle(COOCCURRENCE_FILE, COOCCURRENCE_SHUF_FILE,
        memory=MEMORY, verbose=VERBOSE)
for BINARY in BINARY_OPTS
    for HEADER in HEADER_OPTS
        glove(COOCCURRENCE_SHUF_FILE, VOCAB_FILE, SAVE_FILE,
              threads=NUM_THREADS, x_max=X_MAX, iter=MAX_ITER,
              vector_size=VECTOR_SIZE, binary=BINARY,
              write_header=HEADER, verbose=VERBOSE)
        model_file = joinpath(SAVE_FILE) * ifelse(BINARY==1, ".bin", ".txt")
        for T in TYPES
            if BINARY == 0
                model = wordvectors(model_file,
                                    T,
                                    kind=:text)
            else
                model = wordvectors(model_file,
                                    T,
                                    kind=:binary,
                                    vocabulary=VOCAB_FILE)
            end
            len_vecs, num_words = size(model)
            @test model.vectors isa Matrix{T}
            @test len_vecs == VECTOR_SIZE
        end
    end
end

rm(TMPDIR, recursive=true, force=true)

println("training passed test...")

