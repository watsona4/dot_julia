
#TODO write MPI tests

#TODO ensure result of CSRMatrix(rowMap, colMap, localMatrix, plist) is fill complete

#TODO make testing version of checkInternalState to run during testing

using TypeStability


#### Type Stability Tests ####
method_sigs = [(CSRMatrix{D, G, P, L}, L)
                for (D, G, P, L) in Base.Iterators.product(
                    [Float64, ComplexF32], #Data
                    [UInt64, Int64, UInt32], #GID
                    [UInt8, Int8, UInt32], #PID
                    [UInt32, Int32]) #LID
                ]
report = check_function(JuliaPetra.getLocalRowViewPtr, method_sigs, RegexDict((r"rowValues", Union{Vector, SubArray})))
stability_warn(JuliaPetra.getLocalRowViewPtr, report)
@test is_stable(report)


method_sigs = [(DenseMultiVector{D, G, P, L}, CSRMatrix{D, G, P, L},
                DenseMultiVector{D, G, P, L}, TransposeMode, D, D)
                for (D, G, P, L) in Base.Iterators.product(
                    [Float64, ComplexF32], #Data
                    [UInt64, Int64, UInt32], #GID
                    [UInt8, Int8, UInt32], #PID
                    [UInt32, Int32]) #LID
            ]
report = check_function(localApply, method_sigs, RegexDict((r"(?:#temp#)?@_[0-9]+", Union{Nothing, Tuple{UInt32, UInt32}, Tuple{Int32, Int32}})))
stability_warn(localApply, report)
@test is_stable(report)


#### Serial Tests####s

n = 8
m = 6

Data = Float32
GID = UInt16
PID = Bool
LID = UInt8

commObj = SerialComm{GID, PID, LID}()
rowMap = BlockMap(n, n, commObj)


mat = CSRMatrix{Data}(rowMap, m, STATIC_PROFILE)
@test isa(mat, CSRMatrix{Data, GID, PID, LID})

mat = CSRMatrix{Data}(rowMap, m, STATIC_PROFILE, Dict{Symbol, Any}())
@test isa(mat, CSRMatrix{Data, GID, PID, LID})
@test STATIC_PROFILE == getProfileType(mat)
@test isFillActive(mat)
@test !isFillComplete(mat)
@test isGloballyIndexed(mat)
@test !isLocallyIndexed(mat)
@test rowMap == getRowMap(mat)
@test !hasColMap(mat)
@test n == getGlobalNumRows(mat)
@test n == getLocalNumRows(mat)


@test 0 == getNumEntriesInLocalRow(mat, 2)
@test 0 == getNumEntriesInGlobalRow(mat, 2)
@test 0 == getLocalNumEntries(mat)
@test 0 == getGlobalNumEntries(mat)
@test 0 == getGlobalNumDiags(mat)
@test 0 == getLocalNumDiags(mat)
@test 0 == getGlobalMaxNumRowEntries(mat)
@test 0 == getLocalMaxNumRowEntries(mat)
insertGlobalValues(mat, 2, GID[1, 3, 4], Data[2.5, 6.21, 77])
@test 3 == getNumEntriesInLocalRow(mat, 2)
@test 3 == getNumEntriesInGlobalRow(mat, 2)
@test 3 == getLocalNumEntries(mat)
@test 0 == getLocalNumDiags(mat)
rowInfo = JuliaPetra.getRowInfo(mat.myGraph, LID(2))
@test 3 == rowInfo.numEntries
JuliaPetra.recycleRowInfo(rowInfo)
#skipped many of the global methods because those require re-generating and may not be up to date

row = getGlobalRowCopy(mat, 2)
@test isa(row, Tuple{<: AbstractArray{GID, 1}, <: AbstractArray{Data, 1}})
@test GID[1, 3, 4] == row[1]
@test Data[2.5, 6.21, 77] == row[2]

row = getGlobalRowView(mat, 2)
@test isa(row, Tuple{<: AbstractArray{GID, 1}, <: AbstractArray{Data, 1}})
@test GID[1, 3, 4] == row[1]
@test Data[2.5, 6.21, 77] == row[2]

fillComplete(mat)

row = getLocalRowCopy(mat, 2)
@test isa(row, Tuple{<: AbstractArray{LID, 1}, <: AbstractArray{Data, 1}})
@test LID[1, 2, 3] == row[1]
@test Data[2.5, 6.21, 77] == row[2]

row = getLocalRowView(mat, 2)
@test isa(row, Tuple{<: AbstractArray{LID, 1}, <: AbstractArray{Data, 1}})
@test LID[1, 2, 3] == row[1]
@test Data[2.5, 6.21, 77] == row[2]

#=

getGlobalNumCols(mat::CSRMatrix) = -1#TODO figure out
getLocalNumCols(mat::CSRMatrix) = numCols(mat.localMatrix)
=#

map = BlockMap(2, 2, commObj)

mat = CSRMatrix{Data}(map, 2, STATIC_PROFILE)
insertGlobalValues(mat, 1, GID[1, 2], Data[2, 3])
insertGlobalValues(mat, 2, GID[1, 2], Data[5, 7])
fillComplete(mat)

@test [1, 2, 1, 2] == (mat.myGraph.localIndices1D)
@test (LID[1, 2], Data[2, 3]) == getLocalRowCopy(mat, 1)
@test (LID[1, 2], Data[5, 7]) == getLocalRowCopy(mat, 2)
@test (LID[1, 2], Data[2, 3]) == getLocalRowView(mat, 1)
@test (LID[1, 2], Data[5, 7]) == getLocalRowView(mat, 2)



Y = DenseMultiVector(map, Data[1 0; 0 2])
X = DenseMultiVector(map, Data[2 2; 2 2])


@test Y === apply!(Y, mat, X, NO_TRANS, Data(3), Data(.5))

@test Data[2 2; 2 2] == X.data #ensure X isn't mutated
@test Data[30.5 30; 72 73] == Y.data


Y = DenseMultiVector(map, Data[1 0; 0 2])
X = DenseMultiVector(map, Data[2 2; 2 2]) #ensure bugs in the previous test don't affect this test

@test Y === apply!(Y, mat, X, TRANS, Float32(3), Float32(.5))

@test Data[2 2; 2 2] == X.data #ensure X isn't mutated
@test [42.5 42; 60 61] == Y.data


# Julia's LA API

X = DenseMultiVector(map, Data[2 2; 2 2])

Y = mat * X
@test Data[2 2; 2 2] == X.data
@test Y isa DenseMultiVector
@test getMap(Y) === getMap(X)
@test Data[10 10;24 24] == Y.data

Y = DenseMultiVector(map, Data[1 0; 0 2])
Y = mul!(Y, mat, X)
@test Data[2 2; 2 2] == X.data
@test Data[10 10;24 24] == Y.data
