using StrFs, Test

randstr(pieces::AbstractVector, K) = string((rand(pieces) for _ in 1:K)...)
randstr(pieces::String, K) = randstr(collect(pieces), K)

@testset "literal and show" begin
    @test strf"λ the ultimate" ≡ StrF("λ the ultimate")
    str = strf"λ the ultimate"
    @test repr(str) == "\"λ the ultimate\""
end

@testset "conversions" begin
    for _ in 1:100
        str = randstr("aα∃", rand(3:5))
        len = sizeof(str)
        for _ in 1:100
            # to string and back
            S = len + rand(0:2)
            strf = StrF{S}(str)
            @test sizeof(strf) == len
            @test length(strf) == length(str)
            str2 = String(strf)
            @test str2 == str

            # to other strfs types
            ssame = StrF{S}(strf)
            slong = StrF{S + 1}(strf)
            @test ssame ≡ strf
            @test slong.bytes[1:(len+1)] == vcat(codeunits(str), [0x00])
            @test_throws InexactError StrF{len-1}(strf)

            # io
            io = IOBuffer()
            write(io, strf)
            seekstart(io)
            @test strf == read(io, StrF{len})
        end
    end
end

@testset "promotion" begin
    p1 = [strf"a", strf"bb", "ccc"]
    @test p1 isa Vector{String}
    p2 = [strf"a", strf"bb"]
    @test p2 isa Vector{StrF{2}}
end

"Convert to StrF, padding size with `Δs`."
function StrFmultilen(str, Δs)
    S = sizeof(str)
    Any[StrF{S + Δ}(str) for Δ in Δs]
end

@testset "concatenation, comparisons, and hashing" begin
    for _ in 1:1000
        str = randstr("abcηβπ", rand(2:8))
        stra = str * "a"
        strλ = str * "λ"
        fstr = StrFmultilen(str, 0:2)
        fstra = StrFmultilen(stra, 0:2)
        fstrλ = StrFmultilen(strλ, 0:2)
        @test all(str .== fstr)
        @test all(fstr .== permutedims(fstr))
        @test all(fstr .== permutedims(fstr))
        @test all(str .< fstra)
        @test all(fstr .< permutedims(fstra))
        @test all(fstra .< permutedims(fstrλ))
        @test all(hash(str) .== hash.(fstr))
    end
end

@testset "shortening conversions" begin
    str = StrF{6}("foo")
    str3 = StrF{3}(str)
    str4 = StrF{4}(str)
    str5 = StrF{5}(str)
    @test str == str3 == str4 == str5
    @test_throws InexactError StrF{2}(str)
end

@testset "zero length strings" begin
    s0 = StrF{0}("")
    s = StrF("")
    @test length(s) == length(s0) == 0
    @test s == s0 == StrF{1}("")
end

@testset "iteration" begin
    for s in ["abc", "ηβπ", "∇κ≠0 ↔ ∃ζ>0"]
        @test collect(StrF(s)) == collect(s)
    end
    for _ in 1:1000
        s = randstr("aα∃bc", rand(3:5))
        @test collect(StrF(s)) == collect(s)
    end
    S = StrF{9}
    @test eltype(S) ≡ eltype(String)
    @test Base.IteratorSize(S) ≡ Base.IteratorSize(String)
    @test Base.IteratorEltype(S) ≡ Base.IteratorEltype(S)
end
