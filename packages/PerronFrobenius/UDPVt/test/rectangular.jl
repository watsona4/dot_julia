
@testset "Transfer operator from rectangular binning" begin
    @testset "Grid approach" begin
        @testset "Independent realization $i" for i=1:3
            points_2D = rand(2, 200)
            points_3D = rand(3, 400)
            points_4D = rand(4, 500)

            E_2D = invariantize(embed(points_2D))
            E_3D = invariantize(embed(points_3D))
            E_4D = invariantize(embed(points_4D))

            points_2D = E_2D.points
            points_3D = E_3D.points
            points_4D = E_4D.points

            # The binning scheme
            ϵ = 3

            @testset "From precomputed bin visits" begin
                @testset "2D" begin
                    bins_visited_by_orbit = assign_bin_labels(E_2D, ϵ)
                    bininfo = organize_bin_labels(bins_visited_by_orbit)
                    TO = transferoperator_binvisits(bininfo)
                    @test typeof(TO) <: RectangularBinningTransferOperator

                    # Last row might sum to zero, because the last point does not need to
                    # be contained in the last bin. However, the remaining row sums must
                    # be one.
                    if !is_markov(TO)
                        @warn "There were all-zero columns in the transfer matrix"
                        @warn "Removing first column and last row"
                        if is_markov(TO.transfermatrix[1:(end-1), 2:end])
                            info("That made the transfer matrix Markov")
                        else
                            @warn "That did NOT make the transfer matrix Markov"
                            #@save "from_binvisits_2D.jld2" TO, E_2D, bininfo
                        end
                        @test is_markov(TO.transfermatrix[1:(end-1), 2:end])
                    end
                end

                @testset "3D" begin
                    bins_visited_by_orbit = assign_bin_labels(E_3D, ϵ)
                    bininfo = organize_bin_labels(bins_visited_by_orbit)
                    TO = transferoperator_binvisits(bininfo)
                    @test typeof(TO) <: RectangularBinningTransferOperator

                    # Last row might sum to zero, because the last point does not need to
            		# be contained in the last bin. However, the remaining row sums must
            		# be one.
                    if !is_markov(TO)
                        @warn "There were all-zero columns in the transfer matrix"
                        @warn "Removing first column and last row"
                        if is_markov(TO.transfermatrix[1:(end-1), 2:end])
                            info("That made the transfer matrix Markov")
                        else
                            @warn "That did NOT make the transfer matrix Markov"
                            #@save "from_binvisits_3D.jld2" TO, E_3D, bininfo
                        end
                        @test is_markov(TO.transfermatrix[1:(end-1), 2:end])
                    end
                end

                @testset "4D" begin
                    bins_visited_by_orbit = assign_bin_labels(E_4D, ϵ)
                    bininfo = organize_bin_labels(bins_visited_by_orbit)
                    TO = transferoperator_binvisits(bininfo)
                    @test typeof(TO) <: RectangularBinningTransferOperator

                    # Last row might sum to zero, because the last point does not need to
            		# be contained in the last bin. However, the remaining row sums must
            		# be one.
                    if !is_markov(TO)
                        @warn "There were all-zero columns in the transfer matrix"
                        @warn "Removing first column and last row"
                        if is_markov(TO.transfermatrix[1:(end-1), 2:end])
                            info("That made the transfer matrix Markov")
                        else
                            @warn "That did NOT make the transfer matrix Markov"
                            #@save "from_binvisits_4D.jld2" TO, E_4D, bininfo
                        end
                        @test is_markov(TO.transfermatrix[1:(end-1), 2:end])
                    end
                end

            end

            @testset "From embedding" begin
                @testset "2D" begin
                    TO = transferoperator_grid(E_2D, ϵ)
                    @test typeof(TO) <: RectangularBinningTransferOperator
                    if !is_markov(TO)
                        @warn "There were all-zero columns in the transfer matrix"
                        @warn "Removing first column and last row"
                        if is_markov(TO.transfermatrix[1:(end-1), 2:end])
                            info("That made the transfer matrix Markov")
                        else
                            @warn "That did NOT make the transfer matrix Markov"
                            #@save "from_embedding_2D.jld2" TO, E_2D
                        end
                        @test is_markov(TO.transfermatrix[1:(end-1), 2:end])
                    end
                end

                @testset "3D" begin
                    TO = transferoperator_grid(E_3D, ϵ)
                    @test typeof(TO) <: RectangularBinningTransferOperator
                    if !is_markov(TO)
                        @warn "There were all-zero columns in the transfer matrix"
                        @warn "Removing first column and last row"
                        if is_markov(TO.transfermatrix[1:(end-1), 2:end])
                            info("That made the transfer matrix Markov")
                        else
                            @warn "That did NOT make the transfer matrix Markov"
                            #@save "from_embedding_3D.jld2" TO, E_3D
                        end
                        @test is_markov(TO.transfermatrix[1:(end-1), 2:end])
                    end
                end

                @testset "4D" begin
                    TO = transferoperator_grid(E_4D, ϵ)
                    @test typeof(TO) <: RectangularBinningTransferOperator
                    if !is_markov(TO)
                        @warn "There were all-zero columns in the transfer matrix"
                        @warn "Removing first column and last row"
                        if is_markov(TO.transfermatrix[1:(end-1), 2:end])
                            info("That made the transfer matrix Markov")
                        else
                            @warn "That did NOT make the transfer matrix Markov"
                            #@save "from_embedding_4D.jld2" TO, E_4D
                        end
                        @test is_markov(TO.transfermatrix[1:(end-1), 2:end])
                    end
                end
            end

            @testset "From points" begin
                @testset "2D" begin
                    TO = transferoperator_grid(points_2D, ϵ)

                    @test typeof(TO) <: RectangularBinningTransferOperator

                    if !is_markov(TO)
                        @warn "There were all-zero columns in the transfer matrix"
                        @warn "Removing first column and last row"
                        if is_markov(TO.transfermatrix[1:(end-1), 2:end])
                            info("That made the transfer matrix Markov")
                        else
                            @warn "That did NOT make the transfer matrix Markov"
                            #@save "from_points_2D.jld2" TO, points_2D
                        end
                        @test is_markov(TO.transfermatrix[1:(end-1), 2:end])
                    end
                end

                @testset "3D" begin
                    TO = transferoperator_grid(points_3D, ϵ)

                    @test typeof(TO) <: RectangularBinningTransferOperator

                    if !is_markov(TO)
                        @warn "There were all-zero columns in the transfer matrix"
                        @warn "Removing first column and last row"
                        if is_markov(TO.transfermatrix[1:(end-1), 2:end])
                            info("That made the transfer matrix Markov")
                        else
                            @warn "That did NOT make the transfer matrix Markov"
                            #@save "from_points_3D.jld2" TO, points_3D
                        end
                        @test is_markov(TO.transfermatrix[1:(end-1), 2:end])
                    end
                end

                @testset "4D" begin
                    TO = transferoperator_grid(points_4D, ϵ)
                    @test typeof(TO) <: RectangularBinningTransferOperator
                    if !is_markov(TO)
                        @warn "There were all-zero columns in the transfer matrix"
                        @warn "Removing first column and last row"
                        if is_markov(TO.transfermatrix[1:(end-1), 2:end])
                            info("That made the transfer matrix Markov")
                        else
                            @warn "That did NOT make the transfer matrix Markov"
                            #@save "from_points_4D.jld2" TO, points_4D
                        end
                        @test is_markov(TO.transfermatrix[1:(end-1), 2:end])
                    end
                end
            end
        end
    end
end
