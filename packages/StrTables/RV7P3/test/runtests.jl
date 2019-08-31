using StrTables

@static VERSION < v"0.7.0-DEV" ? (using Base.Test) : (using Test)
const _islinux = (@static VERSION < v"0.7.0-DEV" ? is_linux : Sys.islinux)

ST = StrTables

const testfile = joinpath(@__DIR__, "../test", "test.dat")

teststrs = sort(["AA", "AAAAA",
                 "JuliaLang", "Julia", "JuliaIO", "JuliaDB", "JuliaString",
                 "Scott", "Zulima", "David", "Alex", "Jules", "Gandalf",
                 "\U1f596 Spock Hands"])
stab     = StrTable(teststrs)
testbin  = [_codeunits(s) for s in stab]
btab     = PackedTable(testbin)

const strs = ("AA", "\U1f596 Spock Hands", "A", "Julia", "My name is Julia")
const as = ["AA", "AAAAA", "Alex"]
const js = ["Julia", "JuliaDB", "JuliaIO", "JuliaLang", "JuliaString"]

@testset "StrTables" begin
    @test length(stab) == length(teststrs)
    @test stab == teststrs
    @test stab[1] == strs[1]
    @test stab[end] == strs[2]
    @test ST.matchfirstrng(stab, strs[3]) == 1:3
    @test ST.matchfirstrng(stab, strs[4]) == 7:11
    @test ST.matchfirstrng(stab, SubString(strs[5], 12)) == 7:11
    @test ST.matchfirst(stab, strs[3]) == as
    @test ST.matchfirst(stab, strs[4]) == js
end

bstrs = [_codeunits(s) for s in strs]
bas   = [_codeunits(s) for s in as]
bjs   = [_codeunits(s) for s in js]

@testset "PackedTable" begin
    @test length(btab) == length(testbin)
    @test btab == testbin
    @test btab[1] == bstrs[1]
    @test btab[end] == bstrs[2]
    @test ST.matchfirstrng(btab, bstrs[3]) == 1:3
    @test ST.matchfirstrng(btab, bstrs[4]) == 7:11
    @test ST.matchfirst(btab, bstrs[3]) == bas
    @test ST.matchfirst(btab, bstrs[4]) == bjs
end

medstr = String(rand(Char, 300))
bigstr = repeat("abcdefgh", 8200)
testout = [stab, btab,
           0x1, 2%UInt16, 3%UInt32, 4%UInt64, 5%UInt128,
           6%Int8, 7%Int16, 8%Int32, 9%Int64, 10%Int128,
           Float32(9.87654321), 1.23456789,
           "Test case",
           "† \U1f596",
           SubString("My name is Spock", 12),
           medstr,
           bigstr]

@testset "Read/write values" begin
    io = IOBuffer(b"\x7f")
    @test_throws ErrorException ST.read_value(io)
    # Test may be incorrect, can also get OutOfMemory error
    #=
    @static if sizeof(Int) > 4
        @static if !_islinux()
            x = @static VERSION < v"0.7.0-DEV" ? IOBuffer(2^32) : IOBuffer(maxsize=2^32)
            x.size = 2^32
            @test_throws ErrorException ST.write_value(io, String(take!(x)))
        end
    end
    =#
end

@testset "Save/Load tables" begin
    ST.save(testfile, testout)
    @test ST.load(testfile) == testout
end
