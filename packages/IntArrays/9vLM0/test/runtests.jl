using IntArrays
using Test
using Random

Random.seed!(12345)

const Ts = (UInt8, UInt16, UInt32, UInt64)

@testset "conversion" begin
    @testset "IntVector" begin
        data = [0x00, 0x01, 0x02]
        ivec = IntArray{2}(data)
        @test typeof(ivec) == IntArray{2,UInt8,1}
        @test typeof(ivec) == IntVector{2,UInt8}

        ivec = convert(IntVector{2}, data)
        @test typeof(ivec) == IntArray{2,UInt8,1}
        @test typeof(ivec) == IntVector{2,UInt8}
    end
    @testset "IntMatrix" begin
        data = [0x00 0x01; 0x02 0x03; 0x04 0x05]
        imat = IntArray{3}(data)
        @test typeof(imat) == IntArray{3,UInt8,2}
        @test typeof(imat) == IntMatrix{3,UInt8}

        imat = convert(IntMatrix{3}, data)
        @test typeof(imat) == IntArray{3,UInt8,2}
        @test typeof(imat) == IntMatrix{3,UInt8}
    end
    @testset "three-dimensional array" begin
        data = rand(0x00:0x03, 2, 3, 4)
        iarr = IntArray{2}(data)
        @test typeof(iarr) == IntArray{2,UInt8,3}
    end
end

@testset "construction" begin
    @testset "IntVector" begin
        ivec = IntArray{9,UInt16}(10)
        @test typeof(ivec) == IntArray{9,UInt16,1}
        @test size(ivec) == (10,)
        @test length(ivec) == 10
    end
    @testset "IntMatrix" begin
        imat = IntMatrix{3,UInt8}(2, 3)
        @test typeof(imat) == IntArray{3,UInt8,2}
        @test size(imat) == (2, 3)
    end
    @testset "invalid width" begin
        @test_throws Exception IntArray{9,UInt8,1}(4)
        @test_throws Exception IntArray{20,UInt16,1}(4)
        @test_throws Exception IntArray{50,UInt32,1}(4)
    end
    @testset "mmap" begin
        @test typeof(IntArray{2,UInt8}(10, true)) == IntArray{2,UInt8,1}
    end
end

@testset "similar" begin
    @testset "IntVector" begin
        data = rand(0x00:0x02, 10)
        ivec = IntVector{2}(data)
        @test similar(ivec) !== ivec
        @test size(similar(ivec)) == (10,)
        @test typeof(similar(ivec)) == IntVector{2,UInt8}
        @test size(similar(ivec, UInt16)) == (10,)
        @test typeof(similar(ivec, UInt16)) == IntVector{2,UInt16}
        @test size(similar(ivec, UInt16, (20,))) == (20,)
        @test typeof(similar(ivec, UInt16, (20,))) == IntVector{2,UInt16}
    end
end

@testset "getindex" begin
    @testset "IntVector" begin
        data = [0x00, 0x01, 0x02, 0x03, 0x04]
        ivec = IntArray{3}(data)
        @test_throws BoundsError ivec[0]
        @test ivec[1] == 0x00
        @test ivec[2] == 0x01
        @test ivec[3] == 0x02
        @test ivec[4] == 0x03
        @test ivec[5] == 0x04
        @test_throws BoundsError ivec[6]
    end
    @testset "IntMatrix" begin
        # 2x3
        data = [0x00 0x01 0x02; 0x03 0x04 0x05]
        imat = IntArray{4}(data)
        # linear indexing
        @test_throws BoundsError imat[0]
        @test imat[1] == 0x00
        @test imat[2] == 0x03
        @test imat[3] == 0x01
        @test imat[4] == 0x04
        @test imat[5] == 0x02
        @test imat[6] == 0x05
        @test_throws BoundsError imat[7]
        # tuples
        @test_throws BoundsError imat[0,1]
        @test imat[1,1] == 0x00
        @test imat[1,2] == 0x01
        @test imat[1,3] == 0x02
        @test imat[2,1] == 0x03
        @test imat[2,2] == 0x04
        @test imat[2,3] == 0x05
        @test_throws BoundsError imat[1,4]
        @test_throws BoundsError imat[2,4]
        @test_throws BoundsError imat[3,1]
    end
end

@testset "setindex!" begin
    @testset "IntVector" begin
        data = [0x00, 0x01, 0x02]
        ivec = IntArray{2}(data)
        @test_throws BoundsError ivec[0] = 0x00
        ivec[1] = 0x01
        @test ivec[1] == 0x01
        ivec[2] = 0x02
        @test ivec[2] == 0x02
        ivec[3] = 0x03
        @test ivec[3] == 0x03
        @test_throws BoundsError ivec[4] = 0x01
    end
    @testset "IntMatrix" begin
        data = [0x00 0x00 0x00; 0x00 0x00 0x00]
        imat = IntArray{2}(data)
        # linear
        @test_throws BoundsError imat[0] = 0x00
        imat[2] = 0x01
        @test imat[2] == 0x01
        imat[2] = 0x00
        @test imat[2] == 0x00
        @test_throws BoundsError imat[7] = 0x00
        # tuple
        imat[1,1] = 0x01
        @test imat[1,1] == 0x01
        imat[1,3] = 0x03
        @test imat[1,3] == 0x03
        @test_throws BoundsError imat[1,4] = 0x00
        @test_throws BoundsError imat[3,1] = 0x01
    end
end

@testset "comparison" begin
    a = IntVector{2}([0x00, 0x01, 0x02, 0x03])
    b = IntVector{2}([0x00, 0x01, 0x02, 0x03])
    c = IntVector{4}([0x00, 0x01, 0x02, 0x03])
    d = IntVector{2}([0x00, 0x02, 0x02, 0x03])
    e = IntMatrix{2}([0x00  0x02; 0x01  0x03])
    @test a == b
    @test a == c
    @test a != d
    @test a != e
end

@testset "sizeof" begin
    @testset "smaller bits" begin
        n = 100
        data = rand(0x00:0x01, n)
        @test sizeof(IntVector{1}(data)) < sizeof(data)
        @test sizeof(IntVector{2}(data)) < sizeof(data)
        @test sizeof(IntVector{3}(data)) < sizeof(data)
        @test sizeof(IntVector{4}(data)) < sizeof(data)
    end
end

@testset "copy" begin
    @testset "same length" begin
        data = rand(0x00:0x03, 10)
        ivec = IntVector{2,UInt8}(data)
        @test copy(ivec) == ivec
        @test typeof(copy(ivec)) == typeof(ivec)
        @test size(copy(ivec)) == size(ivec)
        ivec′ = IntVector{2,UInt8}(10)
        @test copy!(ivec′, ivec) === ivec′
        @test ivec′ == ivec
    end
    @testset "larger" begin
        data = rand(0x00:0x03, 10)
        ivec = IntVector{2,UInt8}(data)
        ivec′ = IntVector{2,UInt8}(20)
        copy!(ivec′, ivec)
        @test ivec′[1:10] == ivec
    end
    @testset "smaller" begin
        data = rand(0x00:0x03, 10)
        ivec = IntVector{2,UInt8}(data)
        ivec′ = IntVector{2,UInt8}(5)
        @test_throws BoundsError copy!(ivec′, ivec)
    end
end

@testset "fill!" begin
    @testset "IntVector" begin
        n = 100
        data = rand(0x00:0x03, n)
        for x in 0x00:0x03
            ivec = IntVector{2}(data)
            @test fill!(ivec, x) === ivec
            @test ivec == ones(UInt8, n) * x
        end
    end
    @testset "IntMatrix" begin
        m, n = 10, 11
        data = rand(0x00:0x03, (m, n))
        for x in 0x00:0x03
            #imat = IntMatrix{2}(m, n)
            #@test fill!(imat, x) === imat == true
            #@test imat == ones(UInt8, (m, n)) * x
        end
    end
end

@testset "reverse" begin
    ivec = IntVector{2,UInt8}()
    @test reverse!(ivec) === ivec
    @test isempty(ivec)

    ivec = IntVector{2}([0x00])
    @test reverse!(ivec) === ivec
    @test ivec == [0x00]

    ivec = IntVector{2}([0x00, 0x01])
    @test reverse!(ivec) === ivec
    @test ivec == [0x01, 0x00]

    ivec = IntVector{2}([0x00, 0x01, 0x02])
    @test reverse!(ivec) === ivec
    @test ivec == [0x02, 0x01, 0x00]

    ivec = IntVector{2}([0x00, 0x01, 0x02, 0x03])
    @test reverse!(ivec) === ivec
    @test ivec == [0x03, 0x02, 0x01, 0x00]
end

@testset "push!/pop!" begin
    ivec = IntVector{4,UInt8}()
    @test length(ivec) == 0
    @test push!(ivec, 3) === ivec
    @test length(ivec) == 1
    @test ivec[end] == 3
    @test pop!(ivec) == 3
    @test length(ivec) == 0
end

@testset "append!" begin
    ivec = IntVector{4}([0x00])
    @test append!(ivec, [0x01, 0x02]) === ivec
    @test ivec == [0x00, 0x01, 0x02]
    append!(ivec, [3, 4])
    @test ivec == [0x00, 0x01, 0x02, 0x03, 0x04]
end

@testset "radixsort" begin
    data = UInt8[]
    ivec = IntVector{1}(data)
    @test issorted(radixsort(ivec))

    data = [0x00]
    ivec = IntVector{2}(data)
    @test issorted(radixsort(ivec))

    data = [0x01, 0x00]
    ivec = IntVector{2}(data)
    @test issorted(radixsort(ivec))

    n = 101
    data = rand(0x00:0x01, n)
    ivec = IntVector{1}(data)
    @test issorted(radixsort(ivec))
    @test radixsort!(ivec) === ivec
    @test issorted(ivec)
    data = rand(0x00:0x03, n)
    ivec = IntVector{2}(data)
    @test issorted(radixsort(ivec))
    @test radixsort!(ivec) === ivec
    @test issorted(ivec)
    data = rand(0x00:0x07, n)
    ivec = IntVector{3}(data)
    @test issorted(radixsort(ivec))
    @test radixsort!(ivec) === ivec
    @test issorted(ivec)
end

# thorough and time-consuming tests for each combination of width and element type

@testset "conversion" begin
    @testset "empty" begin
        for T in Ts, w in 1:sizeof(T)*8
            data = Vector{T}(undef, 0)
            @test typeof(IntArray{w}(data)) == IntArray{w,T,1}
            @test length(IntArray{w}(data)) == 0

            data = Matrix{T}(undef, 0, 0)
            @test typeof(IntArray{w}(data)) == IntArray{w,T,2}
            @test size(IntArray{w}(data)) == (0, 0)
        end
    end
    @testset "small" begin
        for T in Ts, w in 1:sizeof(T)*8
            data = T[0x00, 0x01]
            @test typeof(IntArray{w}(data)) == IntArray{w,T,1}
            @test length(IntArray{w}(data)) == 2

            data = T[0x00 0x01 0x00; 0x01 0x00 0x01]
            @test typeof(IntArray{w}(data)) == IntArray{w,T,2}
            @test size(IntArray{w}(data)) == (2, 3)
        end
    end
    @testset "large" begin
        n = 1000
        for T in Ts, w in 1:sizeof(T)*8
            data = rand(T, n)
            @test typeof(IntArray{w}(data)) == IntArray{w,T,1}
            @test length(IntArray{w}(data)) == n
        end
    end
end

@testset "random run" begin
    @testset "IntVector" begin
        n = 123
        for T in Ts, w in 1:sizeof(T)*8
            data = rand(T(0):T(2)^w-T(1), n)
            ivec = IntVector{w,T}(data)
            for i in 1:n
                @test ivec[i] == data[i]
            end

            # random update
            for _ in 1:100
                i = rand(1:n)
                x::T = rand(T) % w
                data[i] = x
                ivec[i] = x
                @test ivec[i] == data[i]
            end
            for i in 1:n
                @test ivec[i] == data[i]
            end
            @test_throws BoundsError ivec[0]
            @test_throws BoundsError ivec[n+1]

            # sort
            sort!(data)
            radixsort!(ivec)
            for i in 1:n
                @test ivec[i] == data[i]
            end

            # random push!/pop!
            for _ in 1:100
                if rand() < 0.5
                    x::T = rand(T) % w
                    push!(ivec, x)
                    push!(data, x)
                else
                    pop!(ivec)
                    pop!(data)
                end
                @test length(ivec) == length(data)
                @test ivec[end] == data[end]
            end
            while !isempty(ivec)
                x = pop!(ivec)
                y = pop!(data)
                @test x == y
            end
            @test isempty(ivec)
        end
    end
    @testset "IntMatrix" begin
        m, n = 11, 28
        for T in Ts, w in 1:sizeof(T)*8
            data = rand(T(0):T(2)^w-T(1), (m, n))
            imat = IntMatrix{w,T}(data)
            for i in 1:m, j in 1:n
                @test imat[i,j] == data[i,j]
            end

            # random update
            for _ in 1:100
                i = rand(1:m)
                j = rand(1:n)
                x::T = rand(T) % w
                data[i,j] = x
                imat[i,j] = x
                @test imat[i,j] == data[i,j]
            end
            for i in 1:m, j in 1:n
                @test imat[i,j] == data[i,j]
            end
        end
    end
end
