# function IntersectionOfBoundaries(s₁::Array{Float64, 2}, s₂::Array{Float64, 2},
#                                     convexexp1in2::Array{Float64, 2},
#                                     convexexp2in1::Array{Float64, 2},
#                                     ordered_vertices1::RowVector{Int},
#                                     ordered_vertices2::RowVector{Int},
#                                     num1in2::Int,
#                                     num2in1::Int,
#                                     ncomm::Int,
#                                     tol::Float64)
#
#
# end

function IntersectionOfBoundaries_NoStorage(s₁,
                                    s₂,
                                    convexexp1in2::AbstractArray{Float64, 2},
                                    convexexp2in1::AbstractArray{Float64, 2},
                                    ordered_vertices1::AbstractVector{Int},
                                    ordered_vertices2::AbstractVector{Int},
                                    num1in2::Int,
                                    num2in1::Int,
                                    ncomm::Int,
                                    tol::Float64)

    n = size(s₁, 1)
    IntVert = zeros(Float64, 0)
    ConvexExpIntVert = zeros(Float64, 0)
    Z = zeros(Float64, 2*n+2, 1)

    Indices = 1:n+1

    for label1 = 2^num1in2+1:2^(n+1) - 2
        b1 = binary_while(label1, n)
        num_vert1 = sum(b1)

        if num_vert1 > 1
            for label2 = 2^num2in1+1:2^(n+1)-2
                b2 = binary_while(label2, n)

                num_vert2 = sum(b2)

                if num_vert2 > 1
                    no_common_vert = true
                    #b1[1:ncomm] + b2[1:ncomm]   contains, 0,1 or 2
                    #If there is any vertex shared by the boundaries, a 2 will appear somewhere
                    if ncomm > 0
                        no_common_vert = maximum(b1[1:ncomm] + b2[1:ncomm]) < 2
                    end

                    if num_vert1 + num_vert2 <= n+2 && no_common_vert

                        if num_vert1 >= num_vert2
                            r = num_vert1
                            s = num_vert2
                            TargetVertices = view(s₂, :, :)
                            ReferenceBoundary = view(ordered_vertices1, Indices[findall(x->x!=0, b1)])
                            TargetBoundary = view(ordered_vertices2, Indices[findall(x->x!=0, b2)])
                            beta = view(convexexp2in1, :, :)
                            Gamma = view(convexexp2in1, setdiff(1:n+1,ReferenceBoundary), TargetBoundary)
                            Rank = rank(Gamma)
                            Rank0 = rank([Gamma; ones(1, s)])
                            no_vanishing_column = minimum(maximum(abs.(Gamma), dims=1))
                            Switch = 0
                        else
                            s = num_vert1
                            r = num_vert2
                            TargetVertices = view(s₁,:,:)
                            ReferenceBoundary = view(ordered_vertices2, Indices[findall(x->x!=0, b2)])
                            TargetBoundary = view(ordered_vertices1, Indices[findall(x->x!=0, b1)])
                            beta = view(convexexp1in2, :, :)
                            Gamma = view(convexexp1in2, setdiff(1:n+1,ReferenceBoundary), TargetBoundary)
                            Rank= rank(Gamma)
                            Rank0 = rank([Gamma;ones(1,s)])
                            no_vanishing_column = minimum(maximum(abs.(Gamma), dims=1))
                            Switch = 1
                        end

                        if Rank0-Rank == 1 && Rank == s-1 && no_vanishing_column > 0
                            lambda = QR(Gamma, tol)
                            alpha = [1 .- ones(Int,1,r-1)*view(beta,ReferenceBoundary[2:r],TargetBoundary) ;
                                    view(beta,ReferenceBoundary[2:r],TargetBoundary)]*lambda
                            alpha[abs.(alpha) .<= tol] .= 0
                            if min(minimum(alpha), minimum(lambda)) > 0 && sum(findall(x->x!=0, alpha))[1] > 1
                                # Filtering out non minimal boundaries
                                NewPoint = view(TargetVertices,:,TargetBoundary)*lambda
                                append!(IntVert,NewPoint)
                                Z .= 0
                                if Switch == 0
                                    Z[ReferenceBoundary] .= view(alpha,:)
                                    Z[TargetBoundary .+ (n + 1)] .= view(lambda,:)
                                else
                                    Z[ReferenceBoundary .+ (n + 1)] .= view(alpha,:)
                                    Z[TargetBoundary] .= view(lambda,:)
                                end

                                append!(ConvexExpIntVert,Z)
                            end
                        end
                    end
                end
            end
        end
    end

    return copy(transpose(reshape(IntVert, n, div(length(IntVert), n)))),
        copy(transpose(reshape(ConvexExpIntVert, 2*n+2, div(length(ConvexExpIntVert), 2*n+2))))
end


function binarydecomp(m::Int, n::Int)
    binary = zeros(Int,n+1)
    binary[n+1] = floor(Int,m/2^n)

    @inbounds for i = 1:n
        m = m-binary[n+1-i+1]*2^(n-i+1)
        binary[n+1-i] = floor(Int, m/2^(n-i))
    end

    return binary
end


function binary_while(m::Int, n::Int)
    binary = zeros(Int, n + 1)
    first1 = 0
    if m > 0
        first1 = floor(Int, log2(m))
        binary[first1+1] = 1
        m = m - 2^first1
        while m > 0
            first1 = floor(Int, log2(m))
            binary[first1 + 1] = 1
            m = m - 2^first1
        end
    end

    return binary
end
