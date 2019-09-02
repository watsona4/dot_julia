module PETScBinaryIO

export writepetsc, readpetsc

using SparseArrays

classids = Dict("Vec"=>1211214, "Mat"=>1211216, "IS"=>1211218)
ids_to_class = Dict(zip(values(classids), keys(classids)))

# PETSc IO for binary matrix IO. Format documentation here:
# http://www.mcs.anl.gov/petsc/petsc-current/docs/manualpages/Mat/MatLoad.html
#  int    MAT_FILE_CLASSID
#  int    number of rows
#  int    number of columns
#  int    total number of nonzeros
#  int    *number nonzeros in each row
#  int    *column indices of all nonzeros (starting index is zero)
#  PetscScalar *values of all nonzeros


function write_(io :: IO, mat :: SparseMatrixCSC, int_type, scalar_type)
    m = SparseMatrixCSC(transpose(mat))
    rows, cols = size(mat)
    write(io, hton(int_type(classids["Mat"]))) # MAT_FILE_CLASSID
    write(io, hton(int_type(rows))) # number of rows
    write(io, hton(int_type(cols))) # number of columns
    write(io, hton(int_type(nnz(mat)))) # number of nonzeros

    # write row lengths
    for i = 1:rows
        write(io, hton(int_type(length(nzrange(m, i)))))
    end

    # write column indices
    cols = rowvals(m)
    for i = 1:rows
        for j in nzrange(m, i)
            write(io, hton(int_type(cols[j] - 1))) # PETSc uses 0-indexed arrays
        end
    end

    # write nonzero values
    vals = nonzeros(m)
    for i = 1:rows
        for j in nzrange(m, i)
            write(io, hton(scalar_type(vals[j])))
        end
    end
end

function write_(io :: IO, vec :: Vector, int_type, scalar_type)
    if eltype(vec) <: Integer
        write(io, hton(int_type(classids["IS"])))
    else
        write(io, hton(int_type(classids["Vec"])))
    end
    write(io, hton(int_type(length(vec)))) # number of rows
    if eltype(vec) <: Integer
        write(io, hton.(int_type.(vec .- 1)))
    else
        write(io, hton.(scalar_type.(vec)))
    end
end

"""
### writepetsc(filename, mat :: Vector{Union{SparseMatrixCSC, Vector}}; int_type = nothing, scalar_type = nothing)

Write a sparse matrix or vector to `filename` in a format PETSc can understand.
`PETSC_DIR` and `PETSC_ARCH` will be used to determine the size of types
written. `int_type` and `scalar_type` can be used to manually specify which
types are desired.
"""
function writepetsc(filename :: AbstractString, objs; int_type = nothing, scalar_type = nothing)
    int_type, scalar_type = determine_type(int_type, scalar_type)
    open(filename, "w") do io
        for o in objs
            write_(io, o, int_type, scalar_type)
        end
    end
end

function writepetsc(filename :: AbstractString, mat :: SparseMatrixCSC; int_type = nothing, scalar_type = nothing)
    writepetsc(filename, [mat]; int_type=int_type, scalar_type=scalar_type)
end

function writepetsc(filename :: AbstractString, vec :: Vector{T}; int_type = nothing, scalar_type = nothing) where T <: Number
    writepetsc(filename, [vec]; int_type=int_type, scalar_type=scalar_type)
end

function read_prefix_vec(io, int_type, scalar_type)
    len = ntoh(read(io, int_type))
    read_vec(io, scalar_type, len)
end

function read_vec(io, ty, sz)
    ary = Array{ty}(undef, sz)
    read!(io, ary)
    ntoh.(ary)
end

function read_mat(io, int_type, scalar_type)
    rows = ntoh(read(io, int_type))
    cols = ntoh(read(io, int_type))
    nnz = ntoh(read(io, int_type))

    row_ptr = Array{int_type}(undef, rows+1)
    row_ptr[1] = 1

    # read row lengths
    row_ptr[2:end] = read_vec(io, int_type, rows)
    cumsum!(row_ptr, row_ptr)

    # write column indices
    colvals = read_vec(io, int_type, nnz) .+ int_type(1)

    # write nonzero values
    vals = read_vec(io, scalar_type, nnz)

    mat = SparseMatrixCSC(cols, rows, row_ptr, colvals, vals)
    SparseMatrixCSC(transpose(mat))
end

function read_single(io, int_type, scalar_type)
    class_id = ntoh(read(io, int_type))
    if !in(class_id, keys(ids_to_class))
        throw("Invalid PETSc binary file $class_id")
    end
    if ids_to_class[class_id] == "Vec"
        read_prefix_vec(io, int_type, scalar_type)
    elseif ids_to_class[class_id] == "Mat"
        read_mat(io, int_type, scalar_type)
    elseif ids_to_class[class_id] == "IS"
        read_prefix_vec(io, int_type, int_type) .+ 1
    else
        error("Invalid class id $class_id")
    end
end

"""
Tries to find and parse a petscvariables file.
"""
function parse_petsc_config()
    default_sizes = (Int32, Float64)
    isizemap = Dict(32 => Int32, 64 => Int64)
    ssizemap = Dict(32 => Float32, 64 => Float64)
    path = nothing
    if haskey(ENV, "PETSC_DIR")
        dir = ENV["PETSC_DIR"]
        path = joinpath(dir, "lib", "petsc", "conf", "petscvariables")
        if haskey(ENV, "PETSC_ARCH")
            arch = ENV["PETSC_ARCH"]
            path = joinpath(dir, arch, "lib", "petsc", "conf", "petscvariables")
        end
    end

    if path != nothing && isfile(path)
        isize = -1
        ssize = -1
        for line in eachline(path)
            if occursin("PETSC_SCALAR_SIZE", line)
                ssize = parse(Int, match(r"[0-9]+", line).match)
            end
            if occursin("PETSC_INDEX_SIZE", line)
                isize = parse(Int, match(r"[0-9]+", line).match)
            end
        end
        if !haskey(isizemap, isize) || !haskey(ssizemap, ssize)
            @warn "Could not determine PETSC_INDEX_SIZE and PETSC_SCALAR_SIZE from $path, defaulting to $default_sizes" maxlog=1
            return default_sizes
        end
        return (isizemap[isize], ssizemap[ssize])
    elseif path != nothing
        @warn "$path does not exist, defaulting to $default_sizes" maxlog=1
    end
    default_sizes
end

function determine_type(int_type, scalar_type)
    config_int_type, config_scalar_type = parse_petsc_config()
    if int_type == nothing
        int_type = config_int_type
    end
    if scalar_type == nothing
        scalar_type = config_scalar_type
    end
    int_type, scalar_type
end

"""
### readpetsc(filename; int_type = nothing, scalar_type = nothing)
           :: Vector{Union{SparseMatrixCSC, Vector}}

Read a sparse matrix in PETSc's binary format from `filename`. PETSC_DIR and
PETSC_ARCH will be used to determine the correct integer and float type to use.
`int_type` and `scalar_type` can be used to override these values.
"""
function readpetsc(filename; int_type = nothing, scalar_type = nothing) :: Vector{Union{SparseMatrixCSC, Vector}}
    int_type, scalar_type = determine_type(int_type, scalar_type)
    open(filename) do io
        items = []
        while !eof(io)
            push!(items, read_single(io, int_type, scalar_type))
        end
        items
    end
end

end
