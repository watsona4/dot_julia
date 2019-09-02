# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module SeqTests

using Test, OEISUtils, SeqUtils
export SeqTest, is_oeis_installed

const ShowTest = false

# Directory of oeis local data.
srcdir = realpath(joinpath(dirname(@__FILE__)))
ROOTDIR = dirname(srcdir)
datadir = joinpath(ROOTDIR, "data")

"""
Returns the path where the oeis data is expected.
"""
oeis_path() = joinpath(datadir, "stripped")

"""
Indicates if the local copy of the OEIS data (the so-called 'stripped' file) is installed (in ../data).
"""
is_oeis_installed() = isfile(oeis_path())

"""
Indicates if the local copy of the OEIS data (the so-called 'stripped' file) is not installed and warns.
"""
function oeis_notinstalled()
    if !is_oeis_installed()
        @warn("OEIS data not installed! Download stripped.gz from oeis.org,")
        @warn("expand it and put it in the directory ../data.")
        return true
    end
    return false
end

function SeqTest(seqarray, kind, offset=0)
    if kind == 'V' return SeqVTest(seqarray, offset) end
    if kind == 'B' return SeqBTest(seqarray) end
    if kind == 'L' return SeqLTest(seqarray) end
    if kind == 'T' return SeqTTest(seqarray) end
    if kind == 'P' return SeqPTest(seqarray) end

    error("Test function not found!")
end

function SeqVTest(seq, offset=0)
    name = SeqName(seq)
    O = oeis_local(name, 10)
    S = ZArray(10, seq, offset)
    if ShowTest
        println("V --> ", name)
        println(O); println(S)
    end
    @test all(S[1:10] .== O[1:10])
end

function SeqBTest(seqarray)
    for seq in seqarray
        name = SeqName(seq)
        # the parameter is not 'length' but 'search bound'.
        O = oeis_local(name, 12)
        S = seq(300)
        if ShowTest
            println("B --> ", name);
            println(O); println(S)
        end
        @test all(S[0:11] .== O[0:11])
    end
end

function SeqLTest(seqarray)
    for seq in seqarray
        name = SeqName(seq)
        O = oeis_local(name, 12)
        S = seq(12)
        if ShowTest
            println("L --> ", name);
            println(O); println(S)
        end
        @test all(S .== O)
    end
end

function SeqTTest(seqarray)
    for seq in seqarray
        name = SeqName(seq)
        O = oeis_local(name, 21)
        S = seq(6)
        if ShowTest
            println("T --> ", name);
            println(O); println(S)
            # ShowAsΔ(O); ShowAsΔ(S)
        end
        @test all(S .== O)
    end
end

function SeqPTest(seqarray)
    for seq in seqarray
        name = SeqName(seq)
        O = oeis_local(name, 28)
        S = seq(7)
        if ShowTest
            println("P --> ", name);
            ShowAsΔ(O); ShowAsΔ(S)
        end
    end
end

end # module
