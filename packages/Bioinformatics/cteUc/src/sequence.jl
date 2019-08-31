import Base.==

"""Structure for sequence data."""
struct Sequence
    seq::String
    type::String
    Sequence(seq, type) =
        all(base -> base in alphabets[type], uppercase(seq)) ?
        new(uppercase(seq), type) : error("String is not a valid $type string!")
end

==(s1::Sequence, s2::Sequence) = (s1.seq == s2.seq) && (s1.type == s2.type)

Base.getindex(s::Sequence, i::Int64) = getindex(s.seq, i)
Base.getindex(s::Sequence, r::UnitRange{Int64}) = getindex(s.seq, r)
Base.length(s::Sequence) = length(s.seq)
Base.replace(s::Sequence, p::Pair{Char,Char}) = replace(s.seq, p)
Base.reverse(s::Sequence) = reverse(s.seq)

"""
    function transcription(dna_seq::Sequence)

Transcribe DNA to RNA.
"""
function transcription(dna_seq::Sequence)
    if dna_seq.type != "DNA"
        error("Only DNA sequences can be transcribed.")
    end
    return Sequence(replace(dna_seq, 'T' => 'U'), "RNA")
end

"""
    function reverse_complement(s::Sequence)

Reverse complement of given DNA/RNA sequence.
"""
function reverse_complement(s::Sequence)
    if (s.type == "AA")
        error("Amino acid sequence doesn't have reverse complement")
    end
    len = length(s)
    rev = reverse(s)
    reverse_complement = Char['N' for i in 1:len]
    for i in 1:len
        reverse_complement[i] = complements[s.type][rev[i]]
    end
    return Sequence(string(reverse_complement...), s.type)
end

"""
    function kmers(s::Sequence, k::Int64 = 2)

Find all k-mers of given sequence.
"""
function kmers(s::Sequence, k::Int64 = 2)
    len = length(s)
    kmer_arr = String[]
    for i in 1:(len-k+1)
        kmer = s[i:(i+k-1)]
        push!(kmer_arr, kmer)
    end
    return kmer_arr
end

"""
    function kmers_frequency(s::Sequence, k::Int64 = 2)

Calculate frequencies of k-mers of given sequence.
"""
function kmers_frequency(s::Sequence, k::Int64 = 2)
    kmers_arr = kmers(s, k)
    unique_kmers = unique(kmers_arr)
    kmers_dict = Dict{String,Int64}([(kmer, count(x -> x == kmer, kmers_arr)) for kmer in unique_kmers])
    return kmers_dict
end

"""
    function translation(s::Sequence, start_pos::Int64 = 1)

Translate given DNA sequence to Amino Acid sequence.
"""
function translation(s::Sequence, start_pos::Int64 = 1)
    if (s.type == "AA")
        error("Amino acid sequence cannot be translated.")
    end
    len = length(s)
    translated_seq = Char[]
    for i in start_pos:3:(len - 2)
        cod = s[i:i+2]
        push!(translated_seq, codons[cod])
    end
    return Sequence(string(translated_seq...), "AA")
end

"""
    function reading_frames(s::Sequence)

Find all reading frames of given sequence.
"""
function reading_frames(s::Sequence)
    if (s.type == "AA")
        error("Amino acid sequence cannot be translated.")
    end
    reading_frames = Dict{String,Sequence}()
    rc = reverse_complement(s)
    for i in 1:3
        reading_frames["5'3' Frame $i"] = translation(s, i)
        reading_frames["3'5' Frame $i"] = translation(rc, i)
    end
    return reading_frames
end

"""
    function possible_proteins(s::Sequence)

Find possible proteins of given sequence.
"""
function possible_proteins(s::Sequence)
    if (s.type == "AA")
        error("Amino acid sequence cannot be translated.")
    end
    regex = r"M[ACDEFGHIKLMNPQRSTVWY]+(?=-|$)"
    rfs = reading_frames(s)
    possible_proteins = Dict{String,Sequence}()
    for k in keys(rfs)
        m = match(regex, rfs[k].seq)
        if m != nothing
            possible_proteins[k] = Sequence(m.match, "AA")
        end
    end
    return possible_proteins
end
