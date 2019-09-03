@doc """
toFunctionMXelements(as::Vector{Vector{Matrix{T}}}) where T <: Real

Return an array of discretized matrix-time function in the for of an array of matrices of discretised functions (as elements)

## Arguments
- `as::Vector{Vector{Matrix{T}}}`: Vector of discretised matrix function 
""" toFunctionMXelements
function toFunctionMXelements(as::AbstractVector{<:AbstractVector{<:AbstractArray{T}}},::ItoIsometryMethod{K}) where {T <: Real,K}
    idxs=CartesianIndices(as[1][1])
    return [[SVector{K}([
        aₜ[idx]
        for aₜ in aᵢ]) for idx in idxs] for aᵢ in as]
end
function toFunctionMXelements(as::AbstractVector{<:AbstractArray{T}},::ItoIsometryMethod{K}) where {T <: Real,K}
    idxs=CartesianIndices(as[1])
    return [SVector{K}([
        aₜ[idx]
        for aₜ in as]) for idx in idxs]
end

###############################################################################
############################### CovMX vs CovVec ###############################
###############################################################################

@doc """
MxToCovVec(mx::AbstractArray,SDmatrixSize::Int64)

Create covariance vector from covariance matrix
- `mx::AbstractArray`: covariance matrix to convert
- `SDmatrixSize::Int64`: size of the large mapping matrix
""" MxToCovVec
function MxToCovVec(mx::AbstractArray, SDmatrixSize::Int64)
#take raw excitation matrix and turn it into the semi discretized 2nd Moment vector
    mxdim = size(mx, 1);
    ri = reverse(0:SDmatrixSize)
    vdim = sum(ri)
    result = spzeros(vdim)
    idxs = idxTuples(mxdim)
    rstrt = 0;
    rstp = mxdim;
    strt = 0;
    stp = mxdim;
    for i in 1:mxdim
        result[rstrt + 1:rstp] = (x -> mx[x...]).(idxs[strt + 1:stp])
        strt = stp;
        stp += mxdim - i;
        rstrt = rstrt + ri[i]
        rstp = rstp + ri[i + 1]
    end
    return result
end

@doc """
    VecToCovMx(CovV::AbstractArray,dims::Int64)

Create covariance matrix from covariance vector
- `CovV::AbstractArray`: covariance vector to convert
- `dims::Int64`: size of the state space
""" VecToCovMx
function VecToCovMx(CovV::AbstractArray, SDmatrixSize::Int64)
  #Covariance vector to Covariance matrix
          dim = SDmatrixSize;  from = 1;  to = SDmatrixSize;  i = 0;
    result = diagm(i => vec(CovV[from:to]));
    while (dim > 0)
                    from += dim; dim -= 1; to = from + dim - 1; i += 1;
        result[:,:] .+= diagm(i => vec(CovV[from:to]));
    end
    return Symmetric(result)
end

function idxTuples(nN::Int64)
    idx = [[(i, i - j) for i in 1 + j:nN] for j in 0:nN - 1]
    idxrng = 1:length(idx)
    result = Array{Tuple{Int64,Int64},1}(undef, sum(idxrng))
    iIDX = prepend!(accumulate(+, reverse(idxrng)), 0)
    for i in 1:length(idx)
        result[iIDX[i] + 1:iIDX[i + 1]] .= idx[i]
    end
    return result
end

###############################################################################
############################ M2 Mapping Utilities #############################
###############################################################################
struct CovVecIdx
    sectionStarts::Vector{Int64} #Every diagonal's start-1 in the covariance vector
    function CovVecIdx(siz::Int64)
        resvec = Vector{Int64}(undef, siz + 1);
        resvec[1] = 0;
        for (i, n) in enumerate(siz:-1:1)
            resvec[i + 1] = resvec[i] + n;
        end
        new(resvec)
    end
    CovVecIdx(MX::AbstractArray) = CovVecIdx(size(MX, 1))
end

function (cvIdx::CovVecIdx)(i::Int64, j::Int64)
    cvIdx.sectionStarts[abs(i - j) + 1] + min(i, j)
end

# Squared process generator #######################################################
#
function calculate_noise_mxelems(rst::AbstractResult{d}) where d
    ns = zeros(Int64,rst.LDDEP.w);
    for stsubMXsᵢ in rst.stsubMXs
        ns[stsubMXsᵢ[1].nID] += d^2 * length(stsubMXsᵢ[1].MXfun)
    end
    ns
end
function calculate_noise_velems(rst::AbstractResult{d}) where d
    ns = zeros(Int64,rst.LDDEP.w);
    for stsubVᵢ in rst.stsubVs
        ns[stsubVᵢ[1].nID] += d
    end
    ns
end

function M2_Mapping_from_Sparse(SM::SparseMatrixCSC{TSMX,Int64},rst::AbstractResult) where TSMX<: Union{<:AbstractVector{T},<:T} where T <:Real
    idx = CovVecIdx(SM)
    (_Is, _Js, _Vs) = findnz(SM)
    elemnum = sum(eachindex(_Vs))
    Is = Vector{Int64}(undef, elemnum)
    Js = Vector{Int64}(undef, elemnum)
    Vs = Vector{T}(undef, elemnum)
    k = 1;
    for i in eachindex(_Is)
        for j in i:length(_Is)
            Is[k] = idx(_Is[i], _Is[j]) 
            Js[k] = idx(_Js[i], _Js[j]) 
            if Is[k] <= idx.sectionStarts[2] && Js[k] > idx.sectionStarts[2]
                Vs[k] = 2 * rst.itoisometrymethod(_Vs[i],_Vs[j])
            else
                Vs[k] = rst.itoisometrymethod(_Vs[i],_Vs[j])
            end
            k += 1
        end
    end
    sparse(Is, Js, Vs, idx.sectionStarts[end], idx.sectionStarts[end])
end

function M2_Mapping_from_Sparse(SM::SparseMatrixCSC{TSMX,Int64},idxs::AbstractVector{<:Integer},rst::AbstractResult) where TSMX<: Union{<:AbstractVector{T},<:T} where T <:Real
    M2_Mapping_from_Sparse(SM[idxs,idxs],rst)
end

function M1toM2_Mapping_Generator_from_Sparse(FM::SparseMatrixCSC{TSMX,Int64}, FV::SparseVector{TSV,Int64},rst::AbstractResult) where TSMX<: Union{<:AbstractVector{T},<:T} where TSV<: Union{<:AbstractVector{T},<:T} where T <:Real # Condition: FM and FV have the same dimension (FM ∈ Rⁿˣⁿ, FV ∈ Rⁿ)
    idx = CovVecIdx(FV)
    (_MIs, _MJs, _MVs) = findnz(FM)
    (_FIs, _FVs) = findnz(FV)
    elemnum = length(_MVs) * length(_FVs)
    Is = Vector{Int64}(undef, elemnum)
    Js = Vector{Int64}(undef, elemnum)
    Vs = Vector{T}(undef, elemnum)
    k = 1
    for i in eachindex(_MIs)
        for j in eachindex(_FIs)
            Is[k] = idx(_MIs[i], _FIs[j])
            Js[k] = _MJs[i]
            if _MIs[i] == _FIs[j]
                Vs[k] = 2 * rst.itoisometrymethod(_MVs[i],_FVs[j])
                # Vs[k] = 2 * _MVs[i] * _FVs[j]
            else
                Vs[k] = rst.itoisometrymethod(_MVs[i],_FVs[j])
                # Vs[k] = _MVs[i] * _FVs[j]
            end
            k += 1
        end
    end
    return sparse(Is, Js, Vs, idx.sectionStarts[end], idx.sectionStarts[2])
end

function M1toM2_Mapping_Generator_from_Sparse(FM::SparseMatrixCSC{TSMX,Int64}, FV::SparseVector{TSV,Int64},idxs::AbstractVector{<:Integer},rst::AbstractResult)  where TSMX<: Union{<:AbstractVector{T},<:T} where TSV<: Union{<:AbstractVector{T},<:T} where T <:Real # Condition: FM and FV have the same dimension (FM ∈ Rⁿˣⁿ, FV ∈ Rⁿ)
    M1toM2_Mapping_Generator_from_Sparse(FM[idxs,idxs], FV[idxs], rst)
end

function M2_Additive_from_Sparse(FV::SparseVector{TSMX,Int64},rst::AbstractResult) where TSMX<: Union{<:AbstractVector{T},<:T} where T <:Real
    idx = CovVecIdx(FV)
    (_Is, _Vs) = findnz(FV)
    elemnum = sum(1:length(_Vs))
    Is = Vector{Int64}(undef, elemnum)
    Vs = Vector{T}(undef, elemnum)
    k = 1
    for i in eachindex(_Is)
        for j in i:length(_Is)
            Is[k] = idx(_Is[i], _Is[j])
            Vs[k] = rst.itoisometrymethod(_Vs[i], _Vs[j])
            k += 1
        end
    end
    sparsevec(Is, Vs, idx.sectionStarts[end])
end
function M2_Additive_from_Sparse(FV::SparseVector{TSMX,Int64},idxs::AbstractVector{<:Integer},rst::AbstractResult) where TSMX<: Union{<:AbstractVector{T},<:T} where T <:Real
    M2_Additive_from_Sparse(FV[idxs],rst)
end

# Reduction of the 2nd moment mapping vectors on a time interval 
function reduce_additive(M2s::Vector{TM2}, M12s::Vector{TM12}, M1s::Vector{TM1}, V2s::Vector{TV2}, V1s::Vector{TV1}, V1st::TV1st) where {TM2<:AbstractMatrix, TM12<:AbstractMatrix, TM1<:AbstractMatrix, TV2<:AbstractVector, TV1<:AbstractVector, TV1st<:AbstractVector}
    mV1 = V1st;
    mV2 = M12s[1]*mV1 .+ V2s[1];
    
    # mV2 = V2s[1];
    for i in 2:length(V2s)
        mV1 .= M1s[i] * mV1 .+ V1s[i-1]
        mV2 .= M2s[i] * mV2 .+ M12s[i]*mV1 .+ V2s[i]
        
        # mV2 .= M2s[i] * mV2 .+ M12s[i]*mV1 .+ V2s[i]
        # mV1 .= M1s[i-1] * mV1 .+ V1s[i-1]
    end
    mV2
end
