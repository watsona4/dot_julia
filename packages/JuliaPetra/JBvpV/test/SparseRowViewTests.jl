rawVals = Float32[2, 5, 3, 4,  8,  6,  2,  4]
rawCols =   Int32[1, 5, 8, 9, 11, 16, 20, 24]

rowView = SparseRowView(rawVals, rawCols)
@test isa(rowView, SparseRowView{Float32, Int32})
@test 8 == nnz(rowView)
@test rawVals == vals(rowView)
@test rawCols == cols(rowView)

rowView = SparseRowView(rawVals, rawCols, 6)
@test isa(rowView, SparseRowView{Float32, Int32})
@test 6 == nnz(rowView)
@test rawVals[1:6] == vals(rowView)
@test rawCols[1:6] == cols(rowView)

rowView = SparseRowView(rawVals, rawCols, 5, 2)
@test isa(rowView, SparseRowView{Float32, Int32})
@test 5 == nnz(rowView)
@test rawVals[2:6] == vals(rowView)
@test rawCols[2:6] == cols(rowView)

rowView = SparseRowView(rawVals, rawCols, 3, 3, 2)
@test isa(rowView, SparseRowView{Float32, Int32})
@test 3 == nnz(rowView)
@test rawVals[3:2:7] == vals(rowView)
@test rawCols[3:2:7] == cols(rowView)

@test_throws InvalidArgumentError SparseRowView([1, 2, 3], [1])
@test_throws BoundsError SparseRowView(rawVals, rawCols, 20)
@test_throws BoundsError SparseRowView(rawVals, rawCols, 9)
@test_throws BoundsError SparseRowView(rawVals, rawCols, 5, 5)
@test_throws BoundsError SparseRowView(rawVals, rawCols, 4, 1, 3)
