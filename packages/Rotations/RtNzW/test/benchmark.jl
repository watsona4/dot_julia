module BenchMarkRotations

using Rotations
using StaticArrays

#=
# benchmark the rotate implementation vs converting to a rotation matrix and multiply
# N.B. - these timing seem pretty eratic and dont make sense to me...
function benchmark_rotations(n::Int=1_000_000)

    # use Quaternions to create random rotations
    Qv = [Rotations.nquatrand()::Quaternion{Float64} for i in 1:n]

    X = Vec{3,Float64}(randn(3))
    Xo = Vector{Vec{3,Float64}}(n)

    # test the current implementation of rotate
    function current_test!(Xo, rfv, X)
        for (i, rf) in enumerate(rfv)
            Xo[i] = rotate(rf, X)
        end
    end

    # test the Rotation matrix conversion
    function rot_test!(Xo, rfv, X)
        for (i, rf) in enumerate(rfv)
            Xo[i] = RotMatrix(rf) * X
        end
    end
    function rot_test!(Xo, Rv::Vector{RotMatrix}, X) # to test time variablity (I can't stop RotMatrix(R::RotMatrix) from constructing a new matrix)
        for (i, R) in enumerate(Rv)
            Xo[i] = R * X
        end
    end

    # bench mark the current implentation vs conversion to a rotation matrix
    for rT in Rotations.RotTypeList

        # build this format
        Rv = [rT(Qv[i]) for i in 1:n]
        if !isa(Rv, Vector{typeof(Rv[1])})  # check type inference worked
            convert(Vector{typeof(Rv[1])}, Rv)
        end

        println("Rotate by $(rT) (converting to a RotMatrix)")
        rot_test!(Xo, Rv[1:1], X)
        @time rot_test!(Xo, Rv, X)

        println("Rotate by $(rT) (implementation of rotate)")
        current_test!(Xo, Rv[1:1], X)
        @time current_test!(Xo, Rv, X)
        println(" ")

    end
end
=#

#########################################
# A bench mark for mutable vs immutable
#########################################

function rotate_mutable(R, X, n)
    Xb, Xo = zeros(3), zeros(3)
    for i = 1:n
        A_mul_B!(Xb, R, Xo)
        Xo .= Xb
    end
    return Xo
end

function rotate_immutable(R, X, n)
    Xo = X
    for i = 1:n
        Xo = R * Xo
    end
    return Xo
end

function benchmark_mutable(n::Int=1_000_000)
    # Initialise
    X_immute = SVector(1.0, 0.0, 0.0)
    R_immute = rand(RotMatrix)

    R_mute = Array(R_immute)
    X_mute = [1.0, 0.0, 0.0]

    # and test
    rotate_mutable(R_mute, X_mute, 1)
    println("Rotating using mutables (Base.Matrix and Base.Vector):")
    @time Xo = rotate_mutable(R_mute, X_mute, n)

    rotate_immutable(R_immute, X_immute, 1)
    println("Rotating using immutables (Rotations.RotMatrix and StaticArrays.SVector):")
    @time Xo = rotate_immutable(R_immute, X_immute, n)
end

export rotate_mutable, rotate_immutable, benchmark_mutable

end
# BenchMarkRotations.benchmark_rotations()
