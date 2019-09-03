module ResizableArraysTests

using Test
using ResizableArrays
using ResizableArrays: checkdimension, checkdimensions, _same_elements
using Base: unsafe_convert, elsize

# FIXME: used @generated
slice(A::AbstractArray{<:Any,2}, I) = A[:,I]
slice(A::AbstractArray{<:Any,3}, I) = A[:,:,I]
slice(A::AbstractArray{<:Any,4}, I) = A[:,:,:,I]
slice(A::AbstractArray{<:Any,5}, I) = A[:,:,:,:,I]

sum_v1(iter::AbstractArray) = (s = zero(eltype(iter));
                               for x in iter; s += x; end;
                               return s)
sum_v2(iter::AbstractArray) = (s = zero(eltype(iter));
                               @inbounds for x in iter; s += x; end;
                               return s)
sum_v3(iter::AbstractArray) = (s = zero(eltype(iter));
                               @inbounds @simd for x in iter; s += x; end;
                               return s)

@testset "Basic methods" begin
    @testset "Utilities" begin
        @test checkdimension(Bool, π) == false
        @test checkdimensions(Bool, ()) == true
        @test checkdimensions(Bool, (1,)) == true
        @test checkdimensions(Bool, (1,2,0)) == true
        @test checkdimensions(Bool, (1,-2,0)) == false
        @test_throws ErrorException checkdimensions((1,-2,0))
        @test isgrowable(π) == false
        @test isgrowable((1,2,3)) == false
        @test isgrowable([1,2,3]) == true
        for T in (Int16, Float32, Tuple{Float64,Float64})
            @test elsize(ResizableArray{T,3,Vector{T}}) == sizeof(T)
        end

        # Make sure all variants of _same_elements are tested.
        A = randn(3,4)
        indexstyles = (IndexLinear(), IndexCartesian())
        for indexstyle1 in indexstyles, indexstyle2 in indexstyles
            @test _same_elements(indexstyle1, A, indexstyle2, A, length(A))
        end

    end
    @testset "Dimensions: $dims" for dims in ((), (3,), (2,3), (2,3,4))
        altdims = map(UInt, dims) # used later
        N = length(dims)
        if N > 0
            A = rand(dims...)
            T = eltype(A)
        else
            T = Float64
            A = Array{T}(undef, dims)
            A[1] = rand(dims...)
        end
        B = ResizableArray{T}(undef, size(A))
        @test isgrowable(B) == (N > 0)
        @test IndexStyle(typeof(B)) == IndexLinear()
        @test eltype(B) == eltype(A)
        @test elsize(B) == elsize(A)
        @test sizeof(B) == sizeof(A)
        @test ndims(B) == ndims(A) == N
        @test size(B) == size(A)
        @test all(d -> size(B,d) == size(A,d), 1:(N+2))
        @test axes(B) == axes(A)
        @test Base.axes1(B) == axes(B,1)
        @test length(B) == length(A) == prod(dims)
        @test maxlength(B) == length(B)
        @test all(d -> axes(B,d) == axes(A,d), 1:(N+2))
        @test unsafe_convert(Ptr{T}, B) == unsafe_convert(Ptr{T}, parent(B))
        @test pointer(B) == pointer(parent(B))
        @test pointer(B, 2) == pointer(parent(B), 2)
        copyto!(B, A)
        @test all(i -> A[i] == B[i], 1:length(A))
        @test all(i -> A[i] == B[i], CartesianIndices(A))
        @test all(i -> A[i] == parent(B)[i], 1:length(A))
        @test A == B
        for i in eachindex(B)
            B[i] = rand()
        end
        copyto!(A, B)
        @test A == B
        if N > 0
            # Extend array B.
            tmpdims = collect(size(B))
            tmpdims[end] += 1
            resize!(B, tmpdims...)
            for i in length(A)+1:length(B); B[i] = 0; end
            @test maxlength(B) == length(B) == prod(tmpdims)
            @test A != B
            @test B != A
            @test all(i -> B[i] == A[i], 1:length(A))
            C = view(B, axes(A)...)
            @test C != B && B != C
            @test C == A && A == C
            # Shrink array B.
            oldmaxlen = maxlength(B)
            resize!(B, dims)
            @test B == A
            @test C == B && B == C
            @test maxlength(B) == oldmaxlen
            # Use copy to make a fresh resizable copy
            C = copy(ResizableArray, B)
            @test C == B
            @test pointer(C) != pointer(B)
            @test maxlength(C) == length(C)
            C = copy(ResizableArray{T}, B)
            @test C == B
            @test pointer(C) != pointer(B)
            @test maxlength(C) == length(C)
            C = copy(ResizableArray{T,N}, B)
            @test C == B
            @test pointer(C) != pointer(B)
            @test maxlength(C) == length(C)
            shrink!(B)
            @test B == A
            @test maxlength(B) == length(B)
        end

        # Check errors.
        @test_throws BoundsError B[0]
        @test_throws BoundsError B[length(B) + 1]
        @test_throws ErrorException resize!(B, (dims..., 5))
        @test_throws DimensionMismatch ResizableArray{T,N+1}(A)
        @test_throws DimensionMismatch copy(ResizableArray{T,N+1}, A)
        @test_throws ErrorException ResizableArray{T,N,Vector{Char}}(A)
        @test_throws ErrorException copy(ResizableArray{T,N,Vector{Char}}, A)

        # Make a copy of A using a resizable array.
        C = copyto!(similar(ResizableArray{T}, axes(A)), A)
        @test C == A

        # Check equality for a different list of dimensions.
        C = rand(7)
        @test (B == C) == false
        @test (C == B) == false
        @test (B == ResizableArray(C)) == false
        @test (ResizableArray(C) == B) == false

        # Check various constructors and custom buffer
        # (do not splat dimensions if N=0).
        buf = Vector{T}(undef, length(A))
        for arg in (undef, buf), sz in (dims, altdims)
            if isa(arg, Vector)
                # No parameters.
                C = copyto!(ResizableArray(arg, sz), A)
                @test eltype(C) == eltype(A) && C == A
                if N > 0
                    C = copyto!(ResizableArray(arg, sz...), A)
                    @test eltype(C) == eltype(A) && C == A
                end
            end
            # Parameter {T}.
            C = copyto!(ResizableArray{T}(arg, sz), A)
            @test eltype(C) == eltype(A) && C == A
            if N > 0
                C = copyto!(ResizableArray{T}(arg, sz...), A)
                @test eltype(C) == eltype(A) && C == A
            end
            # Parameters {T,N}.
            C = copyto!(ResizableArray{T,N}(arg, sz), A)
            if N > 0
                @test eltype(C) == eltype(A) && C == A
                C = copyto!(ResizableArray{T,N}(arg, sz...), A)
            end
        end

        # Use constructor to convert array.
        C = ResizableArray{T,N}()
        resize!(C, dims)
        copyto!(C, A)
        @test eltype(C) == eltype(A) && C == A

        # Use constructor to convert ordinary array.
        C = ResizableArray(A)
        @test eltype(C) == eltype(A) && C == A
        C = ResizableArray{T}(A)
        @test eltype(C) == eltype(A) && C == A
        C = ResizableArray{T,N}(A)
        @test eltype(C) == eltype(A) && C == A

        # Use convert to convert ordinary array.
        C = convert(ResizableArray, A)
        @test eltype(C) == eltype(A) && C == A
        C = convert(ResizableArray{T}, A)
        @test eltype(C) == eltype(A) && C == A
        C = convert(ResizableArray{T,N}, A)
        @test eltype(C) == eltype(A) && C == A

        # Use convert to convert resizable array, result should be identical.
        for pass in 1:4
            C = (pass == 1 ? convert(ResizableArray,             B) :
                 pass == 2 ? convert(ResizableArray{T},          B) :
                 pass == 3 ? convert(ResizableArray{T,N},        B) :
                 pass == 4 ? convert(ResizableArray{T,N,Vector}, B) : nothing)
            @test eltype(C) == eltype(B)
            @test C == B
            @test pointer(C) == pointer(B)
        end
        # Use convert to convert resizable array, result should be different.
        B = ResizableArray{Int16,N}(undef, dims)
        for i in 1:length(B); B[i] = i; end
        for pass in 1:3
            C = (pass == 1 ? convert(ResizableArray{Int32},   B)        :
                 pass == 2 ? convert(ResizableArray{Int32,N}, B)        :
                 pass == 3 ? convert(ResizableArray{Int32,N,Vector}, B) :
                 nothing)
            @test eltype(C) == Int32
            @test elsize(C) == sizeof(eltype(C))
            @test sizeof(C) == elsize(C)*length(C)
            @test C == B
            @test pointer(C) != pointer(B)
        end
    end
end

@testset "Queue methods" begin
    T = Float32
    @testset "Dimensions: $dims" for dims in ((3,), (2,3), (2,3,4))
        N = length(dims)
        m = 5
        altdims = map(UInt16, dims) # used later
        extdims = (dims..., m)
        extaltdims = (altdims..., Int16(m))
        A = rand(T, dims..., m)
        B = rand(T, dims)
        C = rand(T, dims)
        R = ResizableArray(A)
        append!(R, B)
        @test slice(R, 1:m) == A
        @test slice(R, m+1) == B
        prepend!(R, C)
        @test slice(R, 1) == C
        @test slice(R, 2:m+1) == A
        @test slice(R, m+2) == B
        @test length(extdims) == length(extaltdims) == N+1
        for hint in (prod(extdims), extdims, extaltdims)
            R = sizehint!(ResizableArray{T}(undef, dims..., 0), hint...)
            for k in 1:m
                if isodd(k)
                    append!(R, B)
                else
                    prepend!(R, C)
                end
            end
            @test slice(R, 1) == C
            @test slice(R, m) == B
        end
    end
end

@testset "Iterations" begin
    T = Float64
    @testset "Dimensions: $dims" for dims in ((3,), (2,3), (2,3,4))
        N = length(dims)
        A = rand(T, dims)
        B = ResizableArray(A)
        val = sum(A)
        @test val ≈ sum(B)
        @test val ≈ sum_v1(B)
        @test val ≈ sum_v2(B)
        @test val ≈ sum_v3(B)
    end
end

end # module
