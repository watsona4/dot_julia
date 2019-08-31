# This file includes code that was formerly a part of Julia.
# Further modifications and additions: Scott P. Jones
# License is MIT: LICENSE.md

using ModuleInterfaceTools

#ModuleInterfaceTools.debug[] = true

@api test ChrBase

for C in (ASCIIChr, LatinChr, UCS2Chr, UTF32Chr, Char)
@testset "$C" begin

    maxch = typemax(C)

    V6_COMPAT || @testset "Ranges" begin
        # This caused JuliaLang/JSON.jl#82
        rng = C('\x00'):C('\x7f')
        @test first(rng) === C('\x00')
        @test last(rng) === C('\x7f')
    end

    C != Char && @testset "Casefold character" begin
        for c = 0:UInt(maxch)
            is_valid(C, c) || continue
            ch = C(c)
            cj = Char(c)
            uj = uppercase(cj)
            if uj <= maxch
                uc = uppercase(ch)
                uc == uj || println(" $c: $maxch $uc $uj")
                @test uc == uj
            end
            @test lowercase(ch) == lowercase(cj)
        end
    end

    @testset "Edge conditions" begin
        for (val, pass) in (
            (0, true), (0xd7ff, true),
            (0xd800, false), (0xdfff, false),
            (0xe000, true), (0xffff, true),
            (0x10000, true), (0x10ffff, true),
            (0x110000, false))
            pass &= Char(val) <= maxch
            @test is_valid(C, val) == pass
        end
    end

    V6_COMPAT || @testset "Char in invalid string" for (val, pass) in (
            (String(b"\x00"), true),
            (String(b"\x7f"), true),
            (String(b"\x80"), false),
            (String(b"\xbf"), false),
            (String(b"\xc0"), false),
            (String(b"\xff"), false),
            (String(b"\xc0\x80"), false),
            (String(b"\xc1\x80"), false),
            (String(b"\xc2\x80"), Char(0x80) <= maxch),
            (String(b"\xc2\xc0"), false),
            (String(b"\xed\x9f\xbf"), Char(0xd7ff) <= maxch),
            (String(b"\xed\xa0\x80"), false),
            (String(b"\xed\xbf\xbf"), false),
            (String(b"\xee\x80\x80"), Char(0xe000) <= maxch),
            (String(b"\xef\xbf\xbf"), Char(0xffff) <= maxch),
            (String(b"\xf0\x80\x80\x80"), false),
            (String(b"\xf0\x90\x80\x80"), Char(0x10000) <= maxch),
            (String(b"\xf4\x8f\xbf\xbf"), Char(0x10ffff) <= maxch),
            (String(b"\xf4\x90\x80\x80"), false),
            (String(b"\xf5\x80\x80\x80"), false),
            (String(b"\ud800\udc00"), false),
            (String(b"\udbff\udfff"), false),
            (String(b"\ud800\u0100"), false),
            (String(b"\udc00\u0100"), false),
            (String(b"\udc00\ud800"), false))
            @test is_valid(C, val[1]) == pass
    end

    @testset "Invalid Chars" begin
        @test  is_valid(C, 'a')
        @test  is_valid(C, 'ÿ')    == ('ÿ' <= maxch)
        @test  is_valid(C, '柒')   == ('柒' <= maxch)
        @test  is_valid(C, 0xd7ff) == (Char(0xd7ff) <= maxch)
        @test  is_valid(C, 0xe000) == (Char(0xe000) <= maxch)
        @test !is_valid(C, Char(0xd800))
        @test !is_valid(C, Char(0xdfff))
    end
end
end
