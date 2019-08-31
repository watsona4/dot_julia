function SharedVertices(convexexp1in2::AbstractArray{Float64, 2},
                        ordered_vertices1::Vector{Int},
                        ordered_vertices2::Vector{Int},
                        numof1in2::Int,
                        numof2in1::Int)

    reordered_vertices1 = copy(ordered_vertices1)
    reordered_vertices2 = copy(ordered_vertices2)
    Ncomm = 0
    M = numof1in2 * numof2in1

    if M > 0 # The simplices might share some vertex
        contained1in2 = collect(1:numof1in2)
        contained2in1 = collect(1:numof2in1)

        referenceexpansion = Matrix(1.0I, size(convexexp1in2, 1), size(convexexp1in2, 2))

        exp1 = convexexp1in2[:, reordered_vertices1[1:numof1in2]]
        exp2 = referenceexpansion[:, reordered_vertices2[1:numof2in1]]

        num1 = numof1in2
        num2 = numof2in1

        # Create matrices to compare the expansions
        exp1Xones_num2 = kron(exp1, ones(1, num2))
        ones_num1Xexp2 = kron(ones(1, num1), exp2)

        temp = maximum(abs.(exp1Xones_num2 - ones_num1Xexp2), dims = 1)
        x = transpose(heaviside0(-temp)) .* collect(1:M)
        coincidences = (LinearIndices(x))[findall(x->x!=0, x)]
        coincidences = coincidences
        Ncomm = length(coincidences)

        if Ncomm > 0
            # Indices in 1:numof1in2 corresponding to the vertices in simplex1 that are shared
            internal_indices_sharedvert_in_1 = ceil.(Int64, coincidences ./ num2)
            # Indices in 1:numof2in1 corresponding to the vertices in simplex2 that are shared
            internal_indices_sharedvert_in_2 = round.(Int64, coincidences .- num2 * (internal_indices_sharedvert_in_1 .- 1))

            # Common vertices in 1
            common_indices_in1 = contained1in2[internal_indices_sharedvert_in_1]
            Temp1 = reordered_vertices1[common_indices_in1]
            if Ncomm < numof1in2
                indices_not_common_in1 = complementary(common_indices_in1, numof1in2)
                Temp1 = [reordered_vertices1[common_indices_in1]; reordered_vertices1[indices_not_common_in1]]
            end
            reordered_vertices1[1:numof1in2] = Temp1

            # Common vertices in 2
            common_indices_in2 = contained2in1[internal_indices_sharedvert_in_2]
            Temp2 = reordered_vertices2[common_indices_in2]
            if Ncomm < numof2in1
                indices_not_common_in2 = complementary(common_indices_in2, numof2in1)
                Temp2 = [reordered_vertices2[common_indices_in2]; reordered_vertices2[indices_not_common_in2]]
            end
            reordered_vertices2[1:numof2in1] = Temp2

        end
    end

    return Ncomm, reordered_vertices1, reordered_vertices2
end
