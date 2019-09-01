export FlexMatrix, row_keys, col_keys, delete_row!, delete_col!


struct FlexMatrix{R<:Any,C<:Any,T<:Number}
    data::Dict{Tuple{R,C},T}
    function FlexMatrix{T}(rows,cols) where T<:Number
        R = eltype(rows)
        C = eltype(cols)
        RC = Tuple{R,C}
        d = Dict{RC,T}()
        for r in rows
            for c in cols
                d[r,c] = zero(T)
            end
        end
        new{R,C,T}(d)
    end
end


"""
`FlexMatrix{T}(rows,cols)` creates a new `FlexMatrix` with
rows indexed by `rows`, columns indexed by `cols` and
all zero entries of type `T` (which is `Number` if omitted).

`FlexMatrix(v::FlexVector)` converts `v` into a one-column
`FlexMatrix` whose sole column index is `Int(1)`
"""
FlexMatrix(rows,cols) = FlexMatrix{Number}(rows,cols)
FlexMatrix() = FlexMatrix(Int[],Int[])
function FlexMatrix(v::FlexVector)
    VT = valtype(v)
    IT = valtype(v)
    A = FlexMatrix{VT}(keys(v),1)
    for k in keys(v)
        A[k,1] = v[k]
    end
    return A
end

function FlexOnes(T::Type,rows,cols)
    M = FlexMatrix{T}(rows,cols)
    for r in rows
        for c in cols
            M.data[r,c] = one(T)
        end
    end
    return M
end

FlexOnes(rows,cols) = FlexOnes(Float64,rows,cols)

size(A::FlexMatrix) = (length(row_keys(A)), length(col_keys(A)))

function FlexConvert(A::Matrix{T}) where T
    r,c = size(A)
    M = FlexMatrix{T}(1:r, 1:c)
    for i=1:r
        for j=1:c
            M.data[i,j]=A[i,j]
        end
    end
    return M
end

keys(M::FlexMatrix) = keys(M.data)
values(M::FlexMatrix) = values(M.data)
valtype(M::FlexMatrix) = valtype(M.data)

"""
`row_keys(M::FlexMatrix)` returns a list of the keys to the
rows of `M`.
"""
function row_keys(M::FlexMatrix)
    firsts = unique( [ k[1] for k in keys(M) ] )
    try
        sort!(firsts)
    catch
    end
    return firsts
end

"""
`col_keys(M::FlexMatrix)` returns a list of the keys to the
columns of `M`.
"""
function col_keys(M::FlexMatrix)
    seconds = unique( [ k[2] for k in keys(M) ] )
    try
        sort!(seconds)
    catch
    end
    return seconds
end

function getindex(A::FlexMatrix{R,C,T}, i, j) where {R,C,T}
    if haskey(A.data,(i,j))
        return A.data[i,j]
    end
    return zero(T)
end

setindex!(A::FlexMatrix,x,i,j) = setindex!(A.data,x,i,j)

function (==)(A::FlexMatrix,B::FlexMatrix)
    row_A = row_keys(A)
    row_B = row_keys(B)

    if Set(row_A) != Set(row_B)
        return false
    end

    col_A = col_keys(A)
    col_B = col_keys(B)

    if Set(col_A) != Set(col_B)
        return false
    end

    for i in row_A
        for j in col_A
            if A[i,j] != B[i,j]
                return false
            end
        end
    end
    return true
end


function Matrix(A::FlexMatrix)
    rows = collect(row_keys(A))
    cols = collect(col_keys(A))
    try
        sort!(rows)
    catch
    end
    try
        sort!(cols)
    catch
    end
    r = length(rows)
    c = length(cols)

    R = Array{valtype(A),2}(undef,r,c)
    for i=1:r
        for j=1:c
            R[i,j] = A[rows[i],cols[j]]
        end
    end
    return R
end


function show(io::IO, A::FlexMatrix{R,C,T}) where {R,C,T}
    rows = row_keys(A)
    cols = col_keys(A)

    println(io,"FlexMatrix{($R,$C),$T}:")
    for r in rows
        for c in cols
            println("  $((r,c)) ==> $(A[r,c])")
        end
    end
    nothing
end

## Arithmetic

function _mush(A::FlexMatrix,B::FlexMatrix)
    rows = union(Set(row_keys(A)), Set(row_keys(B)))
    cols = union(Set(col_keys(A)), Set(col_keys(B)))
    TR = eltype(rows)
    TC = eltype(cols)

    TA = valtype(A)
    TB = valtype(B)
    TX = typeof(one(TA)+one(TB))

    M = FlexMatrix{TX}(rows,cols)
    return M
end

function (+)(A::FlexMatrix,B::FlexMatrix)
    M = _mush(A,B)
    for k in keys(M)
        M[k...] = A[k...]+B[k...]
    end
    return M
end

function (-)(A::FlexMatrix,B::FlexMatrix)
    M = _mush(A,B)
    for k in keys(M)
        M[k...] = A[k...]-B[k...]
    end
    return M
end


function (*)(s::Number, A::FlexMatrix)
    if length(A.data)==0
        return A
    end
    x = s*first(A.data)[2]
    rows = row_keys(A)
    cols = col_keys(A)
    sA = FlexMatrix{typeof(x)}(rows,cols)

    for ij = keys(A)
        sA[ij...] = s * A[ij...]
    end
    return sA
end


function (*)(A::FlexMatrix, B::FlexMatrix)
    rowsA = row_keys(A)
    colsB = col_keys(B)

    TA = valtype(A)
    TB = valtype(B)
    TX = typeof(one(TA)+one(TB))

    M = FlexMatrix{TX}(rowsA,colsB)

    common = union( Set(col_keys(A)), Set(row_keys(B)) )

    for i in rowsA
        for j in colsB
            M[i,j] = sum( A[i,k]*B[k,j] for k in common )
        end
    end

    return M
end

(-)(A::FlexMatrix) = -1 * A

function (*)(A::FlexMatrix, v::FlexVector)
    klist = row_keys(A)
    TA = valtype(A)
    Tv = valtype(v)
    Tw = typeof(one(TA)+one(Tv))
    w = FlexVector{Tw}(klist)

    sum_keys = union( Set(col_keys(A)), Set(keys(v)) )

    for k in klist
        w[k] = sum( A[k,j]*v[j] for j in sum_keys )
    end
    return w
end


"""
`delete_row!(A,r)` deletes row `r` from the `FlexMatrix` `A`.
"""
function delete_row!(A::FlexMatrix, r)
    for k in keys(A.data)
        if k[1] == r
            delete!(A.data,k)
        end
    end
end


"""
`delete_col!(A,c)` deletes row `c` from the `FlexMatrix` `A`.
"""
function delete_col!(A::FlexMatrix, c)
    for k in keys(A.data)
        if k[2] == c
            delete!(A.data,k)
        end
    end
end

function LinearAlgebra.adjoint(A::FlexMatrix)
    R = row_keys(A)
    C = col_keys(A)
    T = valtype(A)
    B = FlexMatrix{T}(C,R)
    for k in keys(A)
        i,j = k
        B[j,i] = A[i,j]'
    end
    return B
end
