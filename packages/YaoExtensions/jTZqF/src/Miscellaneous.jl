export inverselines, singlet_block
export openbox

"""
    openbox(block::AbstractBlock) -> AbstractBlock

For a black box, like QFTBlock, you can get its white box (loyal simulation) using this function.
"""
function openbox end

"""
    inverselines(nbit::Int; n_reg::Int=nbit) -> ChainBlock

inverse first `n_reg` lines

TODO:
deprecate this function, it is not used.
"""
function inverselines(nbit::Int; n_reg::Int=nbit)
    c = chain(nbit)
    for i = 1:(n_reg ÷ 2)
        push!(c, swap(i,(n_reg-i+1)))
    end
    c
end

function singlet_block(nbit::Int, i::Int, j::Int)
    unit = chain(nbit)
    push!(unit, put(nbit, i=>chain(X, H)))
    push!(unit, control(nbit, -i, j=>X))
end

singlet_block() = singlet_block(2,1,2)

"""Identity block"""
eyeblock(nbits::Int) = put(nbits, 1=>I2)

Base.Matrix(ρ::DensityMatrix{1}) = dropdims(state(ρ), dims=3)
