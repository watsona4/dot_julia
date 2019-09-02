function FMM_mainMVP_pre!(output, beta, scatteringMatrices, φs::Vector{Float64}, ids::Vector{Int}, P, mFMM, pre_agg, translated_sum)
    #@simd does not have a positive effect in 0.6.0
    #calculate matrix-vector product - devectorized with pre-preconditioning

    @inbounds begin
    mul!(output, mFMM.Znear, beta)
    G = length(mFMM.groups)
    fill!(pre_agg,0.0)
    #first preagg all
    for ig2 = 1:G
        for is = 1:mFMM.groups[ig2].size
            indices = (mFMM.groups[ig2].point_ids[is]-1)*(2*P+1)
            for ii = 1:2*P+1
                for iq = 1:mFMM.Q
                    pre_agg[iq,ig2] += mFMM.Agg[ig2][iq,(is-1)*(2*P+1) + ii]*beta[indices + ii]
                end
            end
        end
    end

    for ig1 = 1:G
        #translate plane waves from ig2 to ig1
        fill!(translated_sum,0.0)
        for ig2 = 1:G
            if isempty(mFMM.Trans[(ig1-1)*G + ig2])
                continue
            else
                for iQ = 1:mFMM.Q
                    translated_sum[iQ] -= mFMM.Trans[(ig1-1)*G + ig2][iQ]*pre_agg[iQ,ig2]
                end
                #minus sign because the real equation is (I-ST)x=b
            end
        end
        #disaggregate from ig1 center to ig1's scatterers, producing -Tx
        for is = 1:mFMM.groups[ig1].size
            for ip = 1:2*P+1
                disagged = 0.0im
                for iq = 1:mFMM.Q
                    disagged += conj(mFMM.Agg[ig1][iq,(is-1)*(2*P+1) + ip])*translated_sum[iq]
                end
                output[(mFMM.groups[ig1].point_ids[is]-1)*(2*P+1) + ip] += disagged
            end
        end
    end
    #multiply by S to produce -S
    #temp can be moved outward, but for now this preallocation prevents most
    #dynamic mem alloc by this MVP
    temp = Array{Complex{Float64}}(undef, 2*P+1)
    for ic = 1:length(ids)
        rng = (ic-1)*(2*P+1) .+ (1:2*P+1)
        #copy values to avoid dynamic allocation - copyto!(temp,1:2*P+1,output,rng) doesn't work because output is a subarray
        for ip = 1:2*P+1
            temp[ip] = output[(ic-1)*(2*P+1) + ip]
        end
        v = view(output,rng)
        if φs[ic] == 0.0
            mul!(v, scatteringMatrices[ids[ic]], temp)
        else
            #rotate without matrix
            rotateMultipole!(temp,-φs[ic],P)
            mul!(v, scatteringMatrices[ids[ic]], temp)
            rotateMultipole!(v,φs[ic],P)
        end
    end
    #add identity matrix (Ix)
    output .+= beta
    end #inbounds
    return output
end

function FMM_mainMVP_transpose!(output, beta, scatteringMatrices, φs::Vector{Float64}, ids::Vector{Int}, P, mFMM, pre_agg, translated_sum)
    #calculate matrix^T-vector product - devectorized with pre-preconditioning

    @inbounds begin
    #here we first multiply by Xᵀ

    #Xβ storage can be moved outward, but for now this preallocation prevents most
    #dynamic mem alloc by this MVP
    Xβ = Array{Complex{Float64}}(undef, length(beta))
    temp = Array{Complex{Float64}}(undef, 2*P+1)
    for ic = 1:length(ids)
        rng = (ic-1)*(2*P+1) .+ (1:2*P+1)
        v = view(Xβ, rng)
        if φs[ic] == 0.0
            mul!(v, transpose(scatteringMatrices[ids[ic]]), view(beta, rng))
        else
            #rotate without matrix - transposed
            rotateMultipole!(temp, view(beta, rng), φs[ic], P)
            mul!(v, transpose(scatteringMatrices[ids[ic]]), temp)
            rotateMultipole!(v, -φs[ic], P)
        end
    end

    mul!(output, transpose(mFMM.Znear), Xβ)
    G = length(mFMM.groups)
    fill!(pre_agg,0.0)
    #first preagg all
    for ig2 = 1:G
        for is = 1:mFMM.groups[ig2].size
            indices = (mFMM.groups[ig2].point_ids[is]-1)*(2*P+1)
            for ii = 1:2*P+1
                for iq = 1:mFMM.Q
                    pre_agg[iq,ig2] += conj(mFMM.Agg[ig2][iq,(is-1)*(2*P+1) + ii])*Xβ[indices + ii]
                end
            end
        end
    end

    for ig1 = 1:G
        #translate plane waves from ig2 to ig1
        fill!(translated_sum,0.0)
        for ig2 = 1:G
            if isempty(mFMM.Trans[(ig2-1)*G + ig1]) #transposed
                continue
            else
                for iQ = 1:mFMM.Q
                    translated_sum[iQ] -= mFMM.Trans[(ig2-1)*G + ig1][iQ]*pre_agg[iQ,ig2] #transposed
                end
                #minus sign because the real equation is (I-TᵀXᵀ)β=b
            end
        end
        #disaggregate from ig1 center to ig1's scatterers
        for is = 1:mFMM.groups[ig1].size
            for ip = 1:2*P+1
                disagged = 0.0im
                for iq = 1:mFMM.Q
                    disagged += mFMM.Agg[ig1][iq,(is-1)*(2*P+1) + ip]*translated_sum[iq]
                end
                output[(mFMM.groups[ig1].point_ids[is]-1)*(2*P+1) + ip] += disagged
            end
        end
    end

    #add identity matrix (Iβ)
    output .+= beta
    end #inbounds
    return output
end
