function BarycentricCoordinates(simplex1::AbstractArray{Float64, 2},
								simplex2::AbstractArray{Float64, 2},
                                    orientation1::Float64, orientation2::Float64,
                                    tolerance::Float64)
    n = size(simplex1, 1)

    numof1in2 = 0
    numof2in1 = 0

    convexexp1in2 = zeros(Float64, n+1, n+1)
    convexexp2in1 = zeros(Float64, n+1, n+1)

    ordered_vertices1 = collect(1:n+1)
    ordered_vertices2 = collect(1:n+1)


    ########################################
    # Simplex 1 with respect to simplex 2
    ########################################

    # Will contain the indices of the vertices of simplex1 that are contained in simplex2
    contained_vertices = zeros(Int, n + 1)

    for column1 = 1:n+1
        # Initialize convex expansion coefficient
        beta_min = 0.0

        for row2 = 1:n+1
            #tmp = copy(simplex2)
			tmp = similar(simplex2)
			tmp[:, :] = simplex2[:, :]
            tmp[:, row2] = simplex1[:, column1]

            beta = det([ones(1, n + 1); tmp]) / orientation2

            # If beta is close enough to zero, then the coefficient is set to zero
            if abs(beta) <= tolerance
                beta = 0.0
            end

            # If beta is close enough to one, then the coefficient is set to 1
            if abs(beta - 1) <= tolerance
                beta = 1.0
            end

            convexexp1in2[row2, column1] = beta

            if beta < beta_min
                beta_min = beta
            end
        end

        if beta_min >= 0
            numof1in2 += 1
            contained_vertices[numof1in2] = column1
        end
    end


    if numof1in2 > 0
        ordered_vertices1[1:numof1in2] = contained_vertices[1:numof1in2]

        if numof1in2 < n + 1
            ordered_vertices1[numof1in2+1:end] = complementary(ordered_vertices1[1:numof1in2], n + 1)
        end
    end

    ########################################
    # Simplex 2 with respect to simplex 1
    ########################################
    # Will contain the indices of the vertices of simplex1 that are contained in simplex2
    contained_vertices = zeros(Int, 1, n+1)

    for column2 = 1:n+1
        # Initialize convex expansion coefficient
        beta_min = 0

        for row1 = 1:n+1
            #tmp = copy(simplex1)
            tmp = similar(simplex1)
            tmp[:, :] = simplex1[:, :]
            tmp[:, row1] = simplex2[:, column2]

            beta = det([ones(1, n + 1); tmp]) / orientation1

            # If beta is close enough to zero, then the coefficient is set to zero
            if abs(beta) <= tolerance
                beta = 0
            end

            # If beta is close enough to one, then the coefficient is set to 1
            if abs(beta - 1) <= tolerance
                beta = 1
            end

            convexexp2in1[row1, column2] = beta

            if beta < beta_min
                beta_min = beta
            end
        end

        if beta_min >= 0
            numof2in1 = numof2in1 + 1
            contained_vertices[numof2in1] = column2
        end
    end


    if numof2in1 > 0
        ordered_vertices2[1:numof2in1] = contained_vertices[1:numof2in1]

        if numof2in1 < n + 1
            ordered_vertices2[numof2in1+1:end] = complementary(ordered_vertices2[1:numof2in1], n + 1)
        end
    end

    return convexexp1in2, convexexp2in1, ordered_vertices1, ordered_vertices2, numof1in2, numof2in1

end
