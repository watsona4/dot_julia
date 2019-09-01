using MixedSubdivisions
const MS = MixedSubdivisions
import MultivariatePolynomials
const MP = MultivariatePolynomials
import PolynomialTestSystems: equations, cyclic, ipp2, cyclooctane
using Test

@testset "MixedSubdivisions" begin
	@testset "Basic" begin
	    A₁ = [0 0 1 1; 0 2 0 1]
	    A₂ = [0 0 1 2; 0 1 1 0]

	    A = MS.cayley(A₁, A₂)

	    @test A == [0  0  1  1  0  0  1  2
	                0  2  0  1  0  1  1  0
	                1  1  1  1  0  0  0  0
	                0  0  0  0  1  1  1  1]

	    @test_throws ErrorException MS.cayley([1 0; 0 1], [1 0; 0 0; 0 2])

	    w₁ = [0, 0, 0, -2]
	    w₂ = [0, -3, -4, -8]
	    w = [w₁; w₂]

	    v₁ = [0, 0, 0, -1]
	    v₂ = copy(w₂)
	    v = [v₁; v₂]


	    mixed_cell_indices = [(2, 3), (1, 3)]
	    indexing = MS.CayleyIndexing(size.((A₁, A₂), 2))
	    ord = MS.DotOrdering(Int32.(w))
	    cell = MS.MixedCellTable(mixed_cell_indices, A, indexing)
	    @test cell.volume == 3
	    @test cell.circuit_table == [1 2; 3 0; 0 0; 1 -1; 0 3; 1 2; 0 0; -2 -1]
	    ineq = MS.first_violated_inequality(cell, v, ord)
	    @test ineq.config_index == 1
	    @test ineq.col_index == 4

	    @test MS.exchange_column(cell, MS.exchange_first, ineq) == MS.MixedCellTable([(4, 3), (1, 3)], A, indexing)
	    @test MS.exchange_column(cell, MS.exchange_second, ineq) == MS.MixedCellTable([(2, 4), (1, 3)], A, indexing)

	    ind_back = MS.reverse_index(ineq, cell, MS.exchange_second)
	    cell2 = MS.exchange_column(cell, MS.exchange_second, ineq)
	    @test cell2.volume == 2
	    @test cell == MS.exchange_column(cell2, MS.exchange_second, ind_back)

	    ind_back = MS.reverse_index(ineq, cell, MS.exchange_first)
	    cell2 = MS.exchange_column(cell, MS.exchange_first, ineq)
	    @test cell2.volume == 1
	    @test cell == MS.exchange_column(cell2, MS.exchange_first, ind_back)
	end

	@testset "Mixed Volume" begin
		@test mixed_volume(equations(cyclic(5))) == 70
		@test mixed_volume(equations(cyclic(7))) == 924
		@test mixed_volume(equations(cyclic(10))) == 35940
		@test mixed_volume(equations(cyclic(11))) == 184756
		@test mixed_volume(equations(ipp2())) == 288

		@test mixed_volume(equations(cyclic(5)), algorithm=:total_degree) == 70
		@test mixed_volume(equations(ipp2()), algorithm=:total_degree) == 288
	end

	@testset "Mixed Cells" begin
		A₁ = [0 0 1 1; 0 2 0 1]
		A₂ = [0 0 1 2; 0 1 1 0]

		A = [A₁, A₂]

		w₁ = [0, 0, 0, 2]
		w₂ = [0, 3, 4, 8]
		w = [w₁, w₂]

		v₁ = [0, 0, 0, 1]
		v₂ = copy(w₂)
		v = [v₁, v₂]

		cells_v = mixed_cells(A, v)
		@test length(cells_v) == 3
		@test sum(volume, cells_v) == 4
		@test sort(volume.(cells_v)) == [1, 1, 2]
		@test all(cells_v) do c
		    all(sort.(map(A_i -> A_i' * normal(c), A) .+ v)) do r
		        isapprox(r[1], r[2], atol=1e-12)
		    end
		end

		cells_w = mixed_cells(A, w)
		@test length(cells_w) == 2
		@test sum(volume, cells_w) == 4
		@test sort(volume.(cells_w)) == [1, 3]
		@test all(cells_w) do c
		    all(sort.(map(A_i -> A_i' * normal(c), A) .+ w)) do r
		        isapprox(r[1], r[2], atol=1e-12)
		    end
		end
	end

	@testset "Fine mixed cells" begin
		f = equations(cyclic(7))
		cells, lift = fine_mixed_cells(f)
		@test sum(c -> c.volume, cells) == 924
		@test lift isa Vector{Vector{Int32}}
	end

	@testset "Overflow error messages" begin
		f = equations(cyclooctane())
		@test_throws ArgumentError MS.mixed_volume(f)
		F = [f; randn(2, 18) * [MP.variables(f);1]]
		A = support(F)
		lifting = map(Ai -> MS.gaussian_lifting_sampler(size(Ai,2)), A)
		@test_throws OverflowError mixed_cells(A, lifting)
		@test fine_mixed_cells(F) === nothing
	end
end
