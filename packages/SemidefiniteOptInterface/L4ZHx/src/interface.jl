"""
    coefficienttype(optimizer::AbstractSDOptimizer)

Returns the `coefficienttype` that should be used for `optimizer`.
"""
function coefficienttype end

"""
    getnumberofconstraints(optimizer::AbstractSDOptimizer)

Returns the number of constraints of the model.
"""
function getnumberofconstraints end

"""
    getnumberofblocks(optimizer::AbstractSDOptimizer)

Returns the number of blocks of the block matrix.
"""
function getnumberofblocks end

"""
    getblockdimension(optimizer::AbstractSDOptimizer, blk)

Returns the dimension of the block `blk`.
"""
function getblockdimension end

"""
    init!(optimizer::AbstractSDOptimizer, blkdims::Vector{Int}, nconstrs::Integer)

Initialize the optimizer with nconstrs constraints and blkdims blocks.
"""
function init! end

"""
    getconstraintconstant(optimizer::AbstractSDOptimizer, constr::Integer)

Sets the entry `constr` of `b` to `val`.
"""
function getconstraintconstant end

"""
    setconstraintconstant!(optimizer::AbstractSDOptimizer, val, constr::Integer)

Get the entry `constr` of `b`.
"""
function setconstraintconstant! end

"""
    getobjectivecoefficients(optimizer::AbstractSDOptimizer)

Return the list of entries `blk`, `i`, `j` of the objective matrix.
"""
function getobjectivecoefficients end

"""
    setobjectivecoefficient!(optimizer::AbstractSDOptimizer, val, blk::Integer, i::Integer, j::Integer)

Set the entry `i`, `j` of the block `blk` of the objective matrix to `val`.
"""
function setobjectivecoefficient! end

"""
    getconstraintcoefficients(optimizer::AbstractSDOptimizer, constr::Integer)

Return the list of entries `blk`, `i`, `j` of the matrix of the constraint `constr`.
"""
function getconstraintcoefficients end

"""
    setconstraintcoefficient!(optimizer::AbstractSDOptimizer, val, constr::Integer, blk::Integer, i::Integer, j::Integer)

Set the entry `i`, `j` of the block `blk` of the matrix of the constraint `constr` to `val`.
"""
function setconstraintcoefficient! end

"""
    getX(optimizer::AbstractSDOptimizer)

Returns the solution X as a block matrix.
"""
function getX end

"""
    gety(optimizer::AbstractSDOptimizer)

Returns the solution y.
"""
function gety end

"""
    getZ(optimizer::AbstractSDOptimizer)

Returns the solution Z.
"""
function getZ end

"""
    getprimalobjectivevalue(optimizer::AbstractSDOptimizer)

Returns the primal objective value.
"""
function getprimalobjectivevalue end

"""
    getdualobjectivevalue(optimizer::AbstractSDOptimizer)

Returns the dual objective value.
"""
function getdualobjectivevalue end
