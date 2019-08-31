using Test
using CUDAnative, CUDAdrv
using CUDAatomics

if CUDAnative.configured
    function kern_atomicadd( a, b )
        i = (blockIdx().x-1) * blockDim().x + threadIdx().x
        atomicadd(a,b[i], 2)
        return nothing
    end
    d_a = CuArray(zeros(Float32, 2))
    d_b = CuArray(Float32.(collect(1:1024)))
    @cuda threads=32 blocks=32 kern_atomicadd(d_a, d_b)
    @test abs(Array(d_a)[2] - sum(Array(d_b))) < 1.0f-7

    function kern_atomicsub( a, b )
        i = (blockIdx().x-1) * blockDim().x + threadIdx().x
        atomicsub(a,b[i])
        return nothing
    end
    d_a = CuArray(zeros(Int32, 1))
    d_b = CuArray(Int32.(collect(1:1024)))
    @cuda threads=32 blocks=32 kern_atomicsub(d_a, d_b)
    @test Array(d_a)[1] == -524800

    function kern_atomicmin( a, b )
        i = (blockIdx().x-1) * blockDim().x + threadIdx().x
        atomicmin(a,b[i])
        return nothing
    end
    d_a = CuArray(Array{Int32}([1025]))
    d_b = CuArray(Int32.(collect(1:1024)))
    @cuda threads=32 blocks=32 kern_atomicmin(d_a, d_b)
    @test Array(d_a)[1] == 1

    function kern_atomicmax( a, b )
        i = (blockIdx().x-1) * blockDim().x + threadIdx().x
        atomicmax(a,b[i])
        return nothing
    end
    d_a = CuArray(Array{Int32}([1]))
    d_b = CuArray(Int32.(collect(1:1024)))
    @cuda threads=32 blocks=32 kern_atomicmax(d_a, d_b)
    @test Array(d_a)[1] == 1024

    function kern_atomicinc( a, b )
        i = (blockIdx().x-1) * blockDim().x + threadIdx().x
        atomicinc(a,b[i])
        return nothing
    end
    d_a = CuArray(Array{UInt32}([UInt32(0)]))
    d_b = CuArray(repeat(Array{UInt32}([UInt32(1024)]), 1024))
    @cuda threads=32 blocks=32 kern_atomicinc(d_a, d_b)
    @test Array(d_a)[1] == 0x00000400

    function kern_atomicdec( a, b )
        i = (blockIdx().x-1) * blockDim().x + threadIdx().x
        atomicdec(a,b[i])
        return nothing
    end
    d_a = CuArray(Array{UInt32}([UInt32(1025)]))
    d_b = CuArray(repeat(Array{UInt32}([UInt32(1025)]), 1024))
    @cuda threads=32 blocks=32 kern_atomicdec(d_a, d_b)
    @test Array(d_a)[1] == 0x00000001

    function kern_atomicand( a, b )
        i = (blockIdx().x-1) * blockDim().x + threadIdx().x
        atomicand(a,b[i])
        return nothing
    end
    d_a = CuArray(Array{UInt32}([UInt32(1389)]))
    d_b = CuArray(repeat(Array{UInt32}([UInt32(1023)]), 1024))
    @cuda threads=32 blocks=32 kern_atomicand(d_a, d_b)
    @test Array(d_a)[1] == 0x0000016d

    function kern_atomicexch( a, b )
        i = (blockIdx().x-1) * blockDim().x + threadIdx().x
        atomicexch(a,b[i])
        return nothing
    end
    d_a = CuArray(zeros(Float32, 1))
    d_b = CuArray(Float32.(collect(1:1024)))
    @cuda threads=32 blocks=32 kern_atomicexch(d_a, d_b)
    @test findfirst( Array(d_b).==Array(d_a) ) < 1025

    function kern_atomiccas( a, b )
        i = (blockIdx().x-1) * blockDim().x + threadIdx().x
        atomiccas(a, i, b[i])
        return nothing
    end
    d_a = CuArray(Array{Int32}([17]))
    d_b = CuArray(Array{Int32}(collect(1025:2048)))
    @cuda threads=32 blocks=32 kern_atomiccas(d_a, d_b)
    @test findfirst(Array(d_b).==Array(d_a)) == 17
end
