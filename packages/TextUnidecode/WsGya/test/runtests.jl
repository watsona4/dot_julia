using TextUnidecode
using Test

@testset "TextUnidecode.jl" begin
    @test unidecode("u") == "u"
    @test unidecode("uua") == "uua"
    @test unidecode(string(Char(0x10000))) == ""
    @test unidecode("ü") == "u"
    @test unidecode("ø") == "o"
    @test unidecode("😜") == ""
    @test unidecode("Ｈ") == "H"
    @test unidecode("南无阿弥陀佛") == "Nan Wu A Mi Tuo Fo"
    @test unidecode("˿") == ""
    SubString("bla", 1, 2)
    @test unidecode(SubString("bla", 1, 2)) == "bl"
    # Check for no crashes
    for i in 0:0xffff
        unidecode(string(Char(i)))
    end
end
