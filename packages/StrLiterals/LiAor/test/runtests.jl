# License is MIT: LICENSE.md

using ModuleInterfaceTools

@api test StrLiterals

@static if V6_COMPAT
    eval_parse(s) = eval(parse(s))
else
    eval_parse(s) = Core.eval(@__MODULE__, Meta.parse(s))
end

const ErrorType = @static V6_COMPAT ? ParseError : LoadError

ts(io) = String(take!(io))

@testset "Unicode constants" begin
    @test f"\u{3}"     == "\x03"
    @test f"\u{f60}"   == "\u0f60"
    @test f"\u{2a7d}"  == "\u2a7d"
    @test f"\u{1f595}" == "\U0001f595"
end
@testset "Interpolation" begin
    scott = 123
    @test f"\(scott)" == "123"
end
@testset "\$ not interpolation" begin
    @test f"I have $10, $spj$" == "I have \$10, \$spj\$"
end
@testset "Valid quoted characters" begin
    @test f"\$" == "\$"
    @test f"\"" == "\""
    @test f"\'" == "\'"
    @test f"\\" == "\\"
    @test f"\0" == "\0"
    @test f"\a" == "\a"
    @test f"\b" == "\b"
    @test f"\e" == "\e"
    @test f"\f" == "\f"
    @test f"\n" == "\n"
    @test f"\r" == "\r"
    @test f"\t" == "\t"
    @test f"\v" == "\v"
end
@testset "Invalid quoted characters" begin
    for ch in "cdghijklmopqsuwxy"
        @test_throws ErrorType eval_parse("f\"\\$ch\"")
    end
    for ch in 'A':'Z'
        @test_throws ErrorType eval_parse("f\"\\$ch\"")
    end
end

@testset "Legacy mode only sequences" begin
    # Check for ones allowed in legacy mode
    for s in ("f\"\\x\"", "f\"\\x7f\"", "f\"\\u\"", "f\"\\U\"", "f\"\\U{123}\"")
        @test_throws ErrorType eval_parse(s)
    end
end

@testset "Legacy mode Hex constants" begin
    @test F"\x3"     == "\x03"
    @test F"\x7f"    == "\x7f"
    @test_throws ErrorType eval_parse("F\"\\x\"")
    @test_throws ErrorType eval_parse("F\"\\x!\"")
end

@testset "Legacy mode Unicode constants" begin
    @test F"\u3"     == "\x03"
    @test F"\uf60"   == "\u0f60"
    @test F"\u2a7d"  == "\u2a7d"
    @test F"\U1f595" == "\U0001f595"
    @test F"\u{1f595}" == "\U0001f595"
    @test_throws ErrorType eval_parse("F\"\\U\"")
    @test_throws ErrorType eval_parse("F\"\\U!\"")
    @test_throws ErrorType eval_parse("F\"\\U{123}\"")
end

@testset "Legacy mode valid quoted characters" begin
    @test f"\$" == "\$"
    @test f"\"" == "\""
    @test f"\'" == "\'"
    @test f"\\" == "\\"
    @test f"\0" == "\0"
    @test f"\a" == "\a"
    @test f"\b" == "\b"
    @test f"\e" == "\e"
    @test f"\f" == "\f"
    @test f"\n" == "\n"
    @test f"\r" == "\r"
    @test f"\t" == "\t"
    @test f"\v" == "\v"
end

@testset "Legacy mode \$ interpolation" begin
    scott = 123
    @test F"$scott" == "123"
    @test F"$(scott+1)" == "124"
end

@testset "Quoted \$ in Legacy mode" begin
    @test F"I have \$10, \$spj\$" == "I have \$10, \$spj\$"
end

@testset "Print macro support" begin
    io = IOBuffer()
    scott = 123
    pr"\(io)This is a test with \(scott)"
    @test ts(io) == "This is a test with 123"
end

@testset "escape, unescape" begin
    @test s_escape_string(f"' \" \\ \u{7f} \u{20ac} \u{1f596} \u{e0000}") ==
        "' \\\" \\\\ \\u{7f} € 🖖 \\u{e0000}"
    @test s_unescape_string(f"' \\\" \\\\ \\u{7f} € 🖖 \\u{e0000}") ==
        "' \" \\ \x7f € 🖖 \Ue0000"
    io = IOBuffer()
    s_print_escaped(io, f"' \" \\ \u{7f} \u{20ac} \u{1f596} \u{e0000}", "")
    @test ts(io) == f"' \" \\\\ \\u{7f} € 🖖 \\u{e0000}"
    io = IOBuffer()
    s_print_unescaped(io, f"' \" \\\\ \\u{7f} € 🖖 \\u{e0000}")
    @test ts(io) == "' \" \\ \x7f € 🖖 \Ue0000"
end
