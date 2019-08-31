# License is MIT: LICENSE.md

using ModuleInterfaceTools

@api test CharSetEncodings

@testset "CharSet" begin
    for CS in charset_types
        @test CS <: CharSet
        nam = sprint(show, CS)
        @test endswith(nam, "CharSet") || startswith(nam, "CharSet{:")
    end
end

@testset "Encoding" begin
    for E in encoding_types
        @test E <: Encoding
    end
end

@testset "Character Set Encodings" begin
    for CS in cse_types
        @test CS <: CSE
        @test charset(CS)  <: CharSet
        @test encoding(CS) <: Encoding
    end
end

@testset "show charsets" begin
    for CS in charset_types
    end
end
