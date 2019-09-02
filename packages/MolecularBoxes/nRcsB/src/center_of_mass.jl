
function center_of_mass(
    pos::Vector{T},
    box::MolecularBox{T,N,P};
    weights = ones(Float64,length(pos))
) where {T,N,P}
    if sum(P) != N
        error("Calculating the center of mass is currently only supported for"*
            "fully-periodic systems")
    end
    if length(pos)==1 ; return pos[1] ; end

    L = box.lengths
    
    length(weights) == length(pos) || error("Weights and positions mismatch")
    
    invtotweight = 1.0/sum(weights)
    i2pi = 0.5/pi
    
    a = zero(eltype(pos))
    b = zero(eltype(pos))

    for i in eachindex(pos)
        t = pos[i]./L*2pi 
        a -= cos.(t) * weights[i]
        b -= sin.(t) * weights[i]
    end
    a = a*invtotweight
    b = b*invtotweight

    tcom = atan.(b,a)+pi
    com = tcom.*i2pi.*L
end

