# This file includes code that was formerly a part of Julia.
# License is MIT: LICENSE.md

using MurmurHash3

@static VERSION < v"0.7.0-DEV" ? (using Base.Test) : (using Test)

_memhash(siz, ptr, seed) =
    ccall(Base.memhash, UInt, (Ptr{UInt8}, Csize_t, UInt32), ptr, siz, seed % UInt32)

p1 = SubString("--hello--",3,7)
p2 = "hello"

mmhash(str::String) = mmhash128_a(sizeof(str), pointer(str), 0%UInt32)
@static if sizeof(Int) == 8
    mmhashc(str::AbstractString) = mmhash128_c(str, 0%UInt32)
else
    mmhashc(str::AbstractString) = (s = string(str); mmhash128_c(sizeof(s), pointer(s), 0%UInt32))
end
memhash(str) = _memhash(sizeof(str), pointer(str), 0%UInt32)

@testset "MurmurHash3" begin
    @test mmhashc(p1) == mmhash(p2)
    @test last(mmhashc(p1)) == memhash(p1)
    @test last(mmhashc(p2)) == memhash(p2)
    @test last(mmhash(p2))  == memhash(p1)
end
