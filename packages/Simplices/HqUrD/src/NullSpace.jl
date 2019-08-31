function NullSpace(B, r)
    #This function returns the transformation of basis rendering the matrix B
    #into the form Bp=[eye(r) 0]

    #B is an array with dim1=n+2 rows and at least dim2=n+1 columns
    #r is the rank of B

    #P is the transformation matrix and is such that its last dim2-r columns span the null space of B
    #PermC is the permutation of columns throughout the process

    dim1, dim2 = size(B)
    P = Matrix(1.0I, dim2, dim2)
    PermC = 1:dim2

    Bp = copy(B)

    for a = 1:r
        temp = abs.(Bp[a:dim1, a:dim2])
        d1 = dim1 - a + 1
        d2 = dim2 - a + 1

        ind = argmax(reshape(temp, d1 * d2, 1))[1]
        column = ceil(Int64, ind / d1)
        row = a - 1 + ind - (column - 1) * d1
        column = a - 1 + column
        M = Bp[row, column]
        PerR = collect(1:dim1)
        PerR[a] = row
        PerR[row] = a
        PerC = collect(1:dim2)
        PerC[a] = column
        PerC[column] = a
        Bp = Bp[PerR, :]
        Bp = Bp[:, PerC]
        P = P[:, PerC]
        Bp[:, a] = Bp[:, a]/M
        P[:, a] = P[:, a]/M
        index = complementary(a, dim2)
        for i = index
            coef = Bp[a, i]
            Bp[:, i] = Bp[:, i] - coef * Bp[:, a]
            P[:, i] = P[:, i] - coef * P[:, a]
        end
        PerC
        PermC
        PermC = PermC[PerC]
    end
    # At this stage the columns in B corresponding to the indices PermC(1:r)
    # are linearly independent
    # In addition, since all the columns not chosen to be part of the first r
    # stack are simply changed as C -> C - a C' (and not permuted in any way), P is such that
    # Null(PermC,:) = [P';eye(dim2-r)]

    Null = P[:, (r + 1):dim2]

    return Null, PermC
end
