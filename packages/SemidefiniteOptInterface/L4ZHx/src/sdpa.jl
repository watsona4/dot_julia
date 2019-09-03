# SDPA file format reader-writer

# Redefine the following method to branch on the filename extension of `optimizer` supports more formats
MOI.write(optimizer::SOItoMOIBridge, filename::String) = MOI.write(optimizer.sdoptimizer, filename)
MOI.write(optimizer::AbstractSDOptimizer, filename::String) = writesdpa(optimizer, filename)
MOI.read!(optimizer::SOItoMOIBridge, filename::String) = MOI.read!(optimizer.sdoptimizer, filename)
MOI.read!(optimizer::AbstractSDOptimizer, filename::String) = readsdpa!(optimizer, filename)

function writesdpa(optimizer::AbstractSDOptimizer, filename::String)
    endswith(filename, ".sdpa") || error("Filename must end with .sdpa")
    open(filename, "w") do io
        nconstrs = getnumberofconstraints(optimizer)
        println(io, nconstrs)
        nblocks = getnumberofblocks(optimizer)
        println(io, nblocks)
        for blk in 1:nblocks
            print(io, getblockdimension(optimizer, blk))
            if blk != nblocks
                print(io, ' ')
            end
        end
        println(io)
        for c in 1:nconstrs
            print(io, getconstraintconstant(optimizer, c))
            if c != nconstrs
                print(io, ' ')
            end
        end
        println(io)
        for (val, blk, i, j) in getobjectivecoefficients(optimizer)
            println(io, "0 $blk $i $j $val")
        end
        for c in 1:nconstrs
            for (val, blk, i, j) in getconstraintcoefficients(optimizer, c)
                println(io, "$c $blk $i $j $val")
            end
        end
    end
end

nextline(io::IO) = chomp(readline(io))

function readsdpa!(optimizer::AbstractSDOptimizer, filename::String)
    endswith(filename, ".sdpa") || error("Filename '$filename' must end with .sdpa")
    open(filename, "r") do io
        line = nextline(io)
        while line[1] == '"' || line[1] == '*' # Comment
            line = nextline(io)
        end
        nconstrs = parse(Int, line)
        nblocks = parse(Int, nextline(io))
        blkdims = parse.(Int, split(nextline(io)))
        init!(optimizer, blkdims, nconstrs)
        T = coefficienttype(optimizer)
        constraint_constants = parse.(T, split(nextline(io)))
        for c in 1:nconstrs
            setconstraintconstant!(optimizer, constraint_constants[c], c)
        end
        while !eof(io)
            line = nextline(io)
            isempty(line) && break
            s = split(line)
            c = parse(Int, s[1])
            0 ≤ c ≤ nconstrs || error("Invalid constraint index $c in '$filename', it should be an integer between 0 and $nconstrs")
            blk = parse(Int, s[2])
            1 ≤ blk ≤ nblocks || error("Invalid block index $blk in '$filename', it should be an integer between 0 and $nblocks")
            i = parse(Int, s[3])
            j = parse(Int, s[4])
            val = parse(T, s[5])
            if iszero(c)
                setobjectivecoefficient!(optimizer, val, blk, i, j)
            else
                setconstraintcoefficient!(optimizer, val, c, blk, i, j)
            end
        end
    end
end
