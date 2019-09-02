using Test
using LabelNumerals
using RomanNumerals


@testset "RomanNumeral test" begin
    # Constructor tests
    @test LabelNumeral(RomanNumeral, 46) == LabelNumeral(RomanNumeral, "XLVI")
    @test LabelNumeral(RomanNumeral, 1999) == LabelNumeral(RomanNumeral, "MCMXCIX")
    @test LabelNumeral(rn"XXXX") == LabelNumeral(rn"XL")
    @test LabelNumeral(RomanNumeral,1) == LabelNumeral(rn"I")
    @test LabelNumeral(rn"xx") == LabelNumeral(rn"XX")

    @test_throws Meta.ParseError LabelNumeral(RomanNumeral, "nope")
    @test_throws Meta.ParseError LabelNumeral(RomanNumeral, "XLX")

    # arithmetic tests
    @test LabelNumeral(rn"I") + LabelNumeral(rn"IX") == LabelNumeral(rn"X")
    @test LabelNumeral(rn"L") - LabelNumeral(RomanNumeral, 1) == LabelNumeral(rn"XLIX")
    @test LabelNumeral(rn"X") > LabelNumeral(rn"IX")
    @test LabelNumeral(rn"IX") <= LabelNumeral(rn"X")
    @test LabelNumeral(rn"IX") < LabelNumeral(rn"X")
    @test isless(LabelNumeral(rn"IX"), LabelNumeral(rn"X"))
    @test begin
        max(LabelNumeral(rn"C"), LabelNumeral(rn"X"), LabelNumeral(rn"M")) ==
            LabelNumeral(rn"M")
    end
    @test begin
        min(LabelNumeral(rn"M"), LabelNumeral(rn"X"), LabelNumeral(rn"C")) ==
            LabelNumeral(rn"X")
    end
    @test string(LabelNumeral(rn"X"; prefix="A-",caselower=true)) == "A-x"
end


@testset "Integer test" begin
    # Constructor tests
    @test LabelNumeral(Int, 46) == LabelNumeral(Int, "46")
    @test LabelNumeral(Int, 1999) == LabelNumeral(Int, "1999")
    @test LabelNumeral(1000) == LabelNumeral("1000")
    @test LabelNumeral(Int,1) == LabelNumeral("1")

    # arithmetic tests
    @test LabelNumeral(1) + LabelNumeral(9) == LabelNumeral(10)
    @test LabelNumeral(10) - LabelNumeral(1) == LabelNumeral(9)
    @test LabelNumeral(10) > LabelNumeral(9)
    @test LabelNumeral(9) <= LabelNumeral(10)
    @test LabelNumeral(9) < LabelNumeral(10)
    @test isless(LabelNumeral(9), LabelNumeral(10))
    @test begin
        max(LabelNumeral(100), LabelNumeral(10), LabelNumeral(1000)) ==
            LabelNumeral(1000)
    end
    @test begin
        min(LabelNumeral(1000), LabelNumeral(10), LabelNumeral(100)) ==
            LabelNumeral(10)
    end
    @test string(LabelNumeral(10; prefix="A-",caselower=true)) == "A-10"
end


@testset "AlphaNumeral test" begin
    # Constructor tests
    @test LabelNumeral(AlphaNumeral, 46) == LabelNumeral(AlphaNumeral, "TT")
    @test LabelNumeral(AlphaNumeral, 156) == LabelNumeral(AlphaNumeral, "ZZZZZZ")
    @test LabelNumeral(AlphaNumeral, 1) == LabelNumeral(AlphaNumeral, "A")
    @test hash(LabelNumeral(AlphaNumeral, "BBB")) ==
        hash(LabelNumeral(AlphaNumeral, "CCC") - LabelNumeral(AlphaNumeral,"A"))

    println(LabelNumeral(AlphaNumeral, "BBB"))

    @test convert(Bool, LabelNumeral(AlphaNumeral,100)) == true
    @test convert(BigInt, LabelNumeral(AlphaNumeral,100)) == BigInt(100)
    @test convert(Int, LabelNumeral(AlphaNumeral,100)) == 100
    @test convert(LabelNumeral{AlphaNumeral}, 100) == LabelNumeral(AlphaNumeral, 100)
    @test LabelNumeral(AlphaNumeral, 100) + 10 == 110

    @test_throws DomainError LabelNumeral(AlphaNumeral, "ABC")
    @test_throws DomainError LabelNumeral(AlphaNumeral, "157")
    @test_throws DomainError LabelNumeral(AlphaNumeral, "0")
    @test_throws DomainError LabelNumeral(AlphaNumeral, 157)
    @test_throws DomainError LabelNumeral(AlphaNumeral, 0)

    # arithmetic tests
    @test LabelNumeral(an"II") + LabelNumeral(an"A") == LabelNumeral(an"JJ")
    @test LabelNumeral(an"JJ") - LabelNumeral(an"A") == LabelNumeral(an"II")
    @test LabelNumeral(an"JJ") > LabelNumeral(an"II")
    @test LabelNumeral(an"Z") <= LabelNumeral(an"BB")
    @test LabelNumeral(an"Z") < LabelNumeral(an"BB")
    @test isless(LabelNumeral(an"Z"), LabelNumeral(an"BB"))
    @test begin
        max(LabelNumeral(an"I"), LabelNumeral(an"AA"), LabelNumeral(an"A")) ==
            LabelNumeral(an"AA")
    end
    @test begin
        min(LabelNumeral(an"I"), LabelNumeral(an"AA"), LabelNumeral(an"A")) ==
            LabelNumeral(an"A")
    end
    @test string(LabelNumeral(an"J"; prefix="A-",caselower=true)) == "A-j"
end

A2N = Dict(
    "One" => 1,
    "Two" => 2,
    "Three" => 3,
    "Four" => 4,
    "Five" => 5,
    "Six" => 6,
    "Seven" => 7,
    "Eight" => 8,
    "Nine" => 9,
    "Ten" => 10,
    "Eleven"=> 11,
    #"Twelve" => 12,
    "Thirteen" => 13,
    "Fourteen" => 14,
    "Fifteen" => 15,
    "Sixteen" => 16,
    "Seventeen" => 17,
    "Eighteen" => 18,
    "Nineteen" => 19,
    "Twenty" => 20
)

@testset "LookupNumeral test" begin
    registerLookupNumerals(A2N, 1, 20)
    # Constructor tests
    @test LabelNumeral(LookupNumeral, 10) == LabelNumeral(LookupNumeral, "Ten")
    @test LabelNumeral(LookupNumeral, 11) == LabelNumeral(LookupNumeral, "Eleven")
    @test LabelNumeral(LookupNumeral, 1) == LabelNumeral(LookupNumeral, "One")
    @test hash(LabelNumeral(LookupNumeral, "Ten")) ==
        hash(LabelNumeral(LookupNumeral, "Eleven") - LabelNumeral(LookupNumeral,"One"))

    println(LabelNumeral(LookupNumeral, "Ten"))

    @test convert(Bool, LabelNumeral(LookupNumeral,10)) == true
    @test convert(BigInt, LabelNumeral(LookupNumeral,11)) == BigInt(11)
    @test convert(Int, LabelNumeral(LookupNumeral,10)) == 10
    @test convert(LabelNumeral{LookupNumeral}, 10) == LabelNumeral(LookupNumeral, 10)
    @test LabelNumeral(LookupNumeral, 9) + 10 == 19

    @test_throws DomainError LabelNumeral(LookupNumeral, "ABC")
    @test_throws DomainError LabelNumeral(LookupNumeral, "157")
    @test_throws DomainError LabelNumeral(LookupNumeral, "0")
    @test_throws DomainError LabelNumeral(LookupNumeral, 157)
    @test_throws DomainError LabelNumeral(LookupNumeral, 0)
    @test_throws DomainError begin
        LabelNumeral(ln"Ten") + LabelNumeral(ln"Two")
    end

    # arithmetic tests
    @test LabelNumeral(ln"One") + LabelNumeral(ln"Two") == LabelNumeral(ln"Three")
    @test LabelNumeral(ln"Three") - LabelNumeral(ln"Two") == LabelNumeral(ln"One")
    @test LabelNumeral(ln"Four") > LabelNumeral(ln"One")
    @test LabelNumeral(ln"Ten") <= LabelNumeral(ln"Eleven")
    @test LabelNumeral(ln"Ten") < LabelNumeral(ln"Eleven")
    @test isless(LabelNumeral(ln"Ten"), LabelNumeral(ln"Eleven"))
    @test begin
        max(LabelNumeral(ln"One"), LabelNumeral(ln"Five"), LabelNumeral(ln"Ten")) ==
            LabelNumeral(ln"Ten")
    end
    @test begin
        min(LabelNumeral(ln"Ten"), LabelNumeral(ln"Five"), LabelNumeral(ln"One")) ==
            LabelNumeral(ln"One")
    end
    @test string(LabelNumeral(ln"Ten"; prefix="A-",caselower=true)) == "A-ten"
end

@testset "AlphaNumNumeral test" begin
    # Constructor tests
    @test LabelNumeral(AlphaNumNumeral, 46) == LabelNumeral(AlphaNumNumeral, "BU")
    @test LabelNumeral(AlphaNumNumeral, 156) == LabelNumeral(AlphaNumNumeral, "GA")
    @test LabelNumeral(AlphaNumNumeral, 1) == LabelNumeral(AlphaNumNumeral, "B")
    @test hash(LabelNumeral(AlphaNumNumeral, "BBB")) ==
        hash(LabelNumeral(AlphaNumNumeral, "BBB") - LabelNumeral(AlphaNumNumeral,"A"))

    println(LabelNumeral(AlphaNumNumeral, "BBB"))

    @test convert(Bool, LabelNumeral(AlphaNumNumeral,100)) == true
    @test convert(BigInt, LabelNumeral(AlphaNumNumeral,100)) == BigInt(100)
    @test convert(Int, LabelNumeral(AlphaNumNumeral,100)) == 100
    @test convert(LabelNumeral{AlphaNumNumeral}, 100) == LabelNumeral(AlphaNumNumeral, 100)
    @test LabelNumeral(AlphaNumNumeral, 100) + 10 == 110

    @test_throws DomainError LabelNumeral(AlphaNumNumeral, "A23BC")
    @test_throws DomainError LabelNumeral(AlphaNumNumeral, "157")
    @test_throws DomainError LabelNumeral(AlphaNumNumeral, "0")

    # arithmetic tests
    @test LabelNumeral(ann"II") + LabelNumeral(ann"A") == LabelNumeral(ann"II")
    @test LabelNumeral(ann"JJ") - LabelNumeral(ann"B") == LabelNumeral(ann"JI")
    @test LabelNumeral(ann"JJ") > LabelNumeral(ann"II")
    @test LabelNumeral(ann"Z") <= LabelNumeral(ann"BB")
    @test LabelNumeral(ann"Z") < LabelNumeral(ann"BB")
    @test isless(LabelNumeral(ann"Z"), LabelNumeral(ann"BB"))
    @test begin
        max(LabelNumeral(ann"I"), LabelNumeral(ann"Z"), LabelNumeral(ann"A")) ==
            LabelNumeral(ann"Z")
    end
    @test begin
        min(LabelNumeral(ann"I"), LabelNumeral(ann"Z"), LabelNumeral(ann"A")) ==
            LabelNumeral(ann"A")
    end
    @test string(LabelNumeral(ann"J"; prefix="A-",caselower=true)) == "A-j"
end

@testset "Search Label" begin
    @test length(findLabels("XXX"; pfxList=["X",""])) == 6
    @test length(findLabels("X-XX"; pfxList=["X-",""])) == 3
    @test length(findLabels("A10"; pfxList=["A",""])) == 1
end
