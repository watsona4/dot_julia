
default = LocalCSRMatrix{Float32, UInt32}()
@test 0 == numRows(default)
@test 0 == numCols(default)
@test_throws BoundsError getRowView(default, 1)
@test_throws BoundsError getRowView(default, 5)


rawVals = Float32[5, 8, 6, 2, 1, 6]
rawCols =  UInt32[2, 4, 5, 2, 3, 1]
mat = LocalCSRMatrix(4, 5, rawVals, UInt32[1, 2, 4, 6, 7], rawCols)
@test isa(mat, LocalCSRMatrix{Float32, UInt32})
@test 4 == numRows(mat)
@test 5 == numCols(mat)
@test Float32[5] == vals(getRowView(mat, 1))
@test  UInt32[2] == cols(getRowView(mat, 1))
@test Float32[8, 6] == vals(getRowView(mat, 2))
@test  UInt32[4, 5] == cols(getRowView(mat, 2))
@test Float32[2, 1] == vals(getRowView(mat, 3))
@test  UInt32[2, 3] == cols(getRowView(mat, 3))
@test Float32[6] == vals(getRowView(mat, 4))
@test  UInt32[1] == cols(getRowView(mat, 4))