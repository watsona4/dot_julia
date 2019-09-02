
import LinearAlgebra

n = 2
nProc = numProc(comm)
Data = Float32

######Build matrix######
map = BlockMap(nProc*n, comm)

numMyElts = numMyElements(map)
numGlobalElts = numGlobalElements(map)
myGlobalElts = myGlobalElements(map)

numNz = Array{GID, 1}(undef, numMyElts)
for i = 1:numMyElts
    if myGlobalElts[i] == 1 || myGlobalElts[i] == numGlobalElts
        numNz[i] = 2
    else
        numNz[i] = 3
    end
end

const A = CSRMatrix{Data}(map, numNz, STATIC_PROFILE)

const values = Data[-1, -1]
two = Data[2]

for i = 1:numMyElts
    if myGlobalElts[i] == 1
        indices = GID[2]
    elseif myGlobalElts[i] == numGlobalElts
        indices = GID[numGlobalElts-2]
    else
        indices = GID[myGlobalElts[i]-1, myGlobalElts[i]+1]
    end

    insertGlobalValues(A, myGlobalElts[i], indices, values)
    insertGlobalValues(A, myGlobalElts[i], GID[myGlobalElts[i]], two)
end

fillComplete(A, map, map)


Y = DenseMultiVector(map, LinearAlgebra.diagm(0 => Data(1):n))
X = DenseMultiVector(map, fill(Data(2), n, n))

@test Y === apply!(Y, A, X, NO_TRANS, Float32(3), Float32(.5))

@test fill(2, n, n) == X.data #ensure X isn't mutated

exp = LinearAlgebra.diagm(0 => Data(1):n)*.5
for i in 1:n
    if i == 1 && pid == 1
        exp[1, :] .+= 6
    elseif i == n && pid == nProc
        exp[i, :] .+= 6
    #else
        #exp[i, :] .+= -6 +12-6
    end
end

@test exp == Y.data



X = DenseMultiVector(map, fill(Data(2), n, n))
Y = A*X

@test Y isa DenseMultiVector
@test numVectors(Y) == n
@test fill(2, n, n) == X.data #ensure X isn't mutated
exp = fill(Data(0), n, n)
for i in 1:n
    if i == 1 && pid == 1
        exp[1, :] .= 2
    elseif i == n && pid == nProc
        exp[i, :] .= 2
    #else
        #exp[i, :] .= -2 +4 -2
    end
end

@test exp == Y.data


Y = DenseMultiVector(map, fill(Data(2), n, n))
X = DenseMultiVector(map, fill(Data(2), n, n))

@test Y === mul!(Y, A, X)

@test fill(2, n, n) == X.data #ensure X isn't mutated

exp = fill(Data(0), n, n)
for i in 1:n
    if i == 1 && pid == 1
        exp[1, :] .+= 2
    elseif i == n && pid == nProc
        exp[i, :] .+= 2
    #else
        #exp[i, :] .+= -2 +4 -2
    end
end

@test exp == Y.data
