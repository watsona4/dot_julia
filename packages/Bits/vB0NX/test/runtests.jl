using Bits, Test
using Bits: NOTFOUND

x ≜ y = typeof(x) == typeof(y) && x == y

@testset "bitsize" begin
    for T in (Base.BitInteger_types..., Float16, Float32, Float64)
        @test bitsize(T) === sizeof(T) * 8
        @test bitsize(zero(T)) === bitsize(one(T)) === bitsize(T)
    end
    @test bitsize(BigInt) === Bits.INF
    @test bitsize(Bool) === 1
    @test bitsize(Float64) === 64
    @test bitsize(Float32) === 32
    @test bitsize(Float16) === 16
    @test_throws MethodError bitsize(BigFloat)
    @test bitsize(BigFloat(1, 256)) == 321
    @test bitsize(BigFloat(1, 100)) == 165
end

@testset "bit functions" begin
    @testset "weight" begin
        for T = (Base.BitInteger_types..., BigInt)
            @test weight(T(123)) === 6
            T == BigInt && continue
            @test weight(typemax(T)) === bitsize(T) - (T <: Signed)
            @test weight(typemin(T)) === Int(T <: Signed)
        end
        @test weight(big(-1)) === weight(big(-999)) === Bits.INF
    end

    @testset "bit & tstbit" begin
        val(::typeof(bit), x) = x
        val(::typeof(tstbit), x) = x % Bool
        for _bit = (bit, tstbit)
            for T = (Base.BitInteger_types..., BigInt)
                T0, T1 = T(0), T(1)
                @test _bit(T(0), rand(1:bitsize(T))) ≜ val(_bit, T0)
                @test _bit(T(1), 1) ≜ val(_bit, T1)
                @test _bit(T(1), 2) ≜ val(_bit, T0)
                @test _bit(T(5), 1) ≜ val(_bit, T1)
                @test _bit(T(5), 2) ≜ val(_bit, T0)
                @test _bit(T(5), 3) ≜ val(_bit, T1)
                @test _bit(T(5), 4) ≜ val(_bit, T0)
            end
            @test _bit( 1.0, 64) ≜ val(_bit, 0)
            @test _bit(-1.0, 64) ≜ val(_bit, 1)
            @test _bit( Float32(1.0), 32) ≜ val(_bit, Int32(0))
            @test _bit(-Float32(1.0), 32) ≜ val(_bit, Int32(1))
            x = BigFloat(-1.0, 128)
            for i=1:128+65
                @test _bit(x, i) == val(_bit, big(i ∈ [128, 129, 128+65]))
            end
        end
    end

    @testset "mask" begin
        for T = Base.BitInteger_types
            i = rand(0:min(999, bitsize(T)))
            @test mask(T, i) ≜ Bits.mask_2(T, i)
            @test mask(T) ≜ -1 % T
        end
        i = rand(0:bitsize(Bits.Word))
        @test mask(Bits.Word, i) === mask(i)
        @test mask(Bits.Word) === mask()
        @test mask(0) == 0
        @test mask(1) == 1
        @test mask(Sys.WORD_SIZE) === mask() === 0xffffffffffffffff
        @test mask(UInt64, 64) == mask(64)
        @test mask(UInt64, 63) == 0x7fffffffffffffff
        @test mask(BigInt, 0) ≜ big(0)
        @test mask(BigInt, 1) ≜ big(1)
        @test mask(BigInt, 1024) ≜ big(2)^1024 - 1

        # 2-arg mask
        for T = (Base.BitInteger_types..., BigInt)
            j, i = minmax(rand(0:min(999, bitsize(T)), 2)...)
            m = mask(T, j, i)
            @test m ≜ Bits.mask_2(T, j, i)
            if T === Bits.Word
                @test m === mask(j, i)
            end
            @test count_ones(m) == i-j
            @test m >>> j ≜ mask(T, i-j)
            @test mask(T, j, -1) ≜ ~mask(T, j)
        end
        @test mask(UInt64, 2, 4) === 0x000000000000000c
    end

    @testset "masked" begin
        for T = (Base.BitInteger_types..., BigInt)
            j, i = minmax(rand(0:min(999, bitsize(T)), 2)...)
            @test masked(mask(T), j) ≜ mask(T, j)
            @test masked(mask(T), j, i) ≜ mask(T, j, i)
            @test masked(mask(T, i), i) ≜ mask(T, i)
            @test masked(mask(T, i), j, i) ≜ mask(T, j, i)
            T == BigInt && continue
            x = rand(T)
            @test masked(x, j) ≜ x & mask(T, j)
            @test masked(x, j, i) ≜ x & mask(T, j, i)
        end
        @test masked(0b11110011, 1, 5) ≜ 0b00010010
        @test masked(-1.0, 52, 63) === 1.0
    end

    @testset "low0, low1, scan0, scan1" begin
        for T = (Base.BitInteger_types..., BigInt)
            x = T(0b01011010)
            @test low1(x, 0) == NOTFOUND
            @test low1(x)    == 2
            @test low1(x, 1) == 2
            @test low1(x, 2) == 4
            @test low1(x, 3) == 5
            @test low1(x, 4) == 7
            for i = 5:min(128, bitsize(T))+1
                @test low1(x, i) == NOTFOUND
            end
            @test low0(x, 0) == NOTFOUND
            @test low0(x)    == 1
            @test low0(x, 1) == 1
            @test low0(x, 2) == 3
            @test low0(x, 3) == 6
            @test low0(x, 4) == 8
            for i = 5:min(128, bitsize(T))
                @test low0(x, i) == (i+4 <= bitsize(T) ? i+4 : NOTFOUND)
            end

            @test scan1(x, 0) == NOTFOUND
            @test scan1(x, 1) == 2
            @test scan1(x)    == 2
            @test scan1(x, 2) == 2
            @test scan1(x, 3) == 4
            @test scan1(x, 4) == 4
            @test scan1(x, 5) == 5
            @test scan1(x, 6) == 7
            @test scan1(x, 7) == 7
            for i = 8:min(128, bitsize(T))+1
                @test scan1(x, i) == NOTFOUND
            end
            @test scan0(x, 0) == NOTFOUND
            @test scan0(x, 1) == 1
            @test scan0(x)    == 1
            @test scan0(x, 2) == 3
            @test scan0(x, 3) == 3
            @test scan0(x, 4) == 6
            @test scan0(x, 5) == 6
            @test scan0(x, 6) == 6
            @test scan0(x, 7) == 8
            @test scan0(x, 8) == 8
            for i = 9:min(128, bitsize(T))
                @test scan0(x, i) == i
            end
            T === BigInt && continue
            @test scan0(x, bitsize(T)+1) == NOTFOUND
        end
    end
end

@testset "bits" begin
    for T in Base.BitInteger_types
        v = bits(one(T))
        @test length(v) == bitsize(T)
        @test v[1] === true
        @test count(v) == 1
        v = bits(zero(T))
        @test length(v) == bitsize(T)
        @test v[1] === false
        @test count(v) == 0
    end
    v = bits(7)
    @test v[1] === v[2] === v[3] === true
    @test count(v) == 3
    for T = (Int64, UInt64)
        v = bits(T(2)^63)
        @test v[64] === true
        @test count(v) == 1
    end
    @test bits(Float64(-16))[53:end] == [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1]
    @test count(bits(Float64(-16))) == 4

    @testset "array indexing" begin
        v = bits(1234)[1:8]
        @test v == [0, 1, 0, 0, 1, 0, 1, 1]
        @test v isa Bits.BitVector1Mask
        v = bits(1.2)[10:17]
        @test v == [1, 0, 0, 1, 1, 0, 0, 1]
        @test v isa Bits.BitVector1Mask{Int64}
        @test all(bits(123)[[1, 2, 4, 5, 6, 7]])
        @test count(bits(123)) == 6
        # test optimization for v[i:j]
        for T = (Base.BitInteger_types..., BigInt)
            i, j = minmax(rand(1:min(999, bitsize(T)), 2)...)
            v = bits(rand(T == BigInt ? (big(-999):big(999)) : T))
            @test v[i:j] == v[i:1:j]
        end
    end
end
