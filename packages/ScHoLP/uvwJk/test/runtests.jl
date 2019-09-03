using Test
using ScHoLP
using Combinatorics
using LinearAlgebra
using SparseArrays

function test_projected_graph()
    data = example_dataset("example1")
    simplices, nverts = data.simplices, data.nverts
    B = basic_matrices(simplices, nverts)[3]
    
    @test size(B) == (9, 9)
    @test nnz(B - B') == 0
    @test sum(Diagonal(B)) == 0
    @test B[1, 2] == 2
    @test B[1, 3] == 2
    @test B[1, 4] == 1
    @test B[1, 5] == 1
    @test B[1, 6] == 2
    @test B[1, 7] == 1
    @test B[1, 8] == 1
    @test B[2, 3] == 1
    @test B[2, 4] == 1
    @test B[2, 6] == 2
    @test B[3, 4] == 1
    @test B[3, 5] == 1
    @test B[3, 9] == 1
    @test B[5, 8] == 1
    @test B[7, 8] == 1
    @test nnz(B) == 30
end

function test_basic_matrices()
    for dataset in ["example1", "example2", "email-Enron", "contact-high-school"]
        println("$dataset")
        data = example_dataset(dataset)
        simplices, nverts = data.simplices, data.nverts
        A, At, B = basic_matrices(simplices, nverts)
        @test nnz(A) == length(simplices)
        @test A' == At
        ms = maximum(simplices)
        @test size(B) == (ms, ms)
        @test size(A) == (ms, length(nverts))
        
        all_pairs = Set{NTuple{2, Int64}}()
        curr_ind = 1
        for nvert in nverts
            simp = simplices[curr_ind:(curr_ind + nvert - 1)]
            curr_ind += nvert
            for (i, j) in combinations(simp, 2)
                if i != j; push!(all_pairs, (i, j), (j, i)); end
            end
        end
        @test nnz(B) == length(all_pairs)
    end
end

function test_open_closed_triangles1()
    for dataset in ["example1", "example2", "email-Enron", "contact-high-school"]
        data = example_dataset(dataset)
        simplices, nverts = data.simplices, data.nverts
        
        # Using internal implementation
        num_open1, num_closed1 =
            num_open_closed_triangles(basic_matrices(simplices, nverts)...)

        # Naive implementation by looping over simplices
        closed_tris = Set{NTuple{3, Int64}}()
        I, J = Int64[], Int64[]
        curr_ind = 1
        for nvert in nverts
            simp = simplices[curr_ind:(curr_ind + nvert - 1)]
            curr_ind += nvert
            for (i, j, k) in combinations(simp, 3)
                push!(closed_tris, sorted_tuple(i, j, k))
            end
            for (i, j) in combinations(simp, 2)
                push!(I, i, j)
                push!(J, j, i)
            end
        end
        num_closed2 = length(closed_tris)
        @test num_closed1 == num_closed2
        
        n = maximum(simplices)
        A = sparse(I, J, ones(length(I)), n, n)
        total_triangles = 0
        for (i, j, k) in combinations(1:n, 3)
            if A[i, j] > 0 && A[i, k] > 0 && A[j, k] > 0
                total_triangles += 1
            end
        end
        num_open2 = total_triangles - num_closed2
        @test num_open1 == num_open2
    end
end

function test_open_closed_triangles2()
    function check(simplices::Vector{Int64}, nverts::Vector{Int64},
                   num_open::Int64, num_closed::Int64)
        num_open_check, num_closed_check =
            num_open_closed_triangles(basic_matrices(simplices, nverts)...)
        @test num_open == num_open_check
        @test num_closed == num_closed_check
    end
    simplices = Int64[]
    nverts    = Int64[]
    check(simplices, nverts, 0, 0)
    
    append!(simplices, [1, 2, 2, 5])
    append!(nverts,    [2,    2   ])
    check(simplices, nverts, 0, 0)
    
    append!(simplices, [1, 2, 2, 5])
    append!(nverts,    [2,    2   ])
    check(simplices, nverts, 0, 0)
    
    append!(simplices, [1, 5])
    append!(nverts,    [2])
    check(simplices, nverts, 1, 0)
    
    append!(simplices, [1, 2, 5])
    append!(nverts,    [3])
    check(simplices, nverts, 0, 1)

    append!(simplices, [1, 2, 5, 1, 2, 5])
    append!(nverts,    [3,       3])
    check(simplices, nverts, 0, 1)

    append!(simplices, [1, 8, 8, 2, 8, 5, 8])
    append!(nverts,    [2,    1, 2,    2   ])
    check(simplices, nverts, 3, 1)

    append!(simplices, [1, 2, 5, 8])
    append!(nverts,    [4         ])
    check(simplices, nverts, 0, 4)

    data = example_dataset("example1")
    simplices, nverts = data.simplices, data.nverts
    check(simplices, nverts, 1, 7)
end

function test_closure_counts1()
    simplices = [1, 2, 3, 1, 2, 3, 1, 2, 4, 2, 3, 4, 1, 3, 4, 8]
    nverts    = [3,       3,       3,       3,       3,       1]
    open_counts = open_types4(simplices, nverts)
    @test open_counts[(WEAK, WEAK, WEAK, STRONG)] == 1
    @test open_counts[(WEAK, WEAK, WEAK, WEAK)] == 0
    @test open_counts[(-3, -3, -3, STRONG)] == 1
    @test open_counts[(-3, -3, -3, WEAK)] == 3
    @test open_counts[(-3, -3, -3, OPEN)] == 0

    # none of the following close any open triangles
    new_simplices = [9, 11, 12, 11, 12, 14, 9, 11, 12]
    new_nverts    = [3,         3,          3]
    closed_counts = newly_closed_types4(simplices, nverts,
                                        new_simplices, new_nverts)
    for (_, val) in closed_counts; @test val == 0; end

    # Close the open tetrahedron
    new_simplices = [1, 2, 3, 4]
    new_nverts    = [4]
    closed_counts = newly_closed_types4(simplices, nverts,
                                        new_simplices, new_nverts)
    @test closed_counts[(WEAK, WEAK, WEAK, STRONG)] == 1
end

function test_equivalent_counters(counter1, counter2)
    sorted_keys(counts) = sort(collect(keys(counts)))
    skeys1 = sorted_keys(counter1)
    skeys2 = sorted_keys(counter2)
    @test skeys1 == skeys2
    for key in skeys1
        @test counter1[key] == counter2[key]
    end
end

function test_closure_counts2()
    for dataset in ["example1", "example2", "email-Enron"]
        println("$dataset...")        
        data = example_dataset("example1")
        simplices, nverts = data.simplices, data.nverts
        open_counts3 = open_types3(simplices, nverts)
        open_counts4 = open_types4(simplices, nverts)
        
        # Close all open simplices. Add an extra simplex which should not be
        # counted since it did not appear in the original data.
        maxsize = maximum(simplices)
        new_simplices = [collect(1:maxsize); collect((maxsize + 1):(maxsize + 5))]
        new_nverts = [maxsize, 5]
        
        closed_counts3 = newly_closed_types3(simplices, nverts,
                                             new_simplices, new_nverts)
        test_equivalent_counters(open_counts3, closed_counts3)
        closed_counts4 = newly_closed_types4(simplices, nverts,
                                             new_simplices, new_nverts)
        test_equivalent_counters(open_counts4, closed_counts4)
    end
end

function test_closure_counts3()
    # Naive 3 nested loops computation of open type counts.
    function open_types3_naive(simplices::Vector{Int64}, nverts::Vector{Int64})
        # Get set of closed triangles
        closed_tris = Set{NTuple{3, Int64}}()
        curr_ind = 1
        for nvert in nverts
            simp = simplices[curr_ind:(curr_ind + nvert - 1)]
            curr_ind += nvert
            for (i, j, k) in combinations(simp, 3)
                push!(closed_tris, sorted_tuple(i, j, k))
            end
        end

        # naive counting
        type_counts = initialize_type_counter3()
        A, At, B = basic_matrices(simplices, nverts)
        inds = findall(vec(sum(At, dims=1)) .> 0)
        n = length(inds)
        for (i, j, k) in combinations(inds, 3)
            if !((i, j, k) in closed_tris)
                push!(type_counts, simplex_key3(B[i, j], B[i, k], B[j, k]), 1)
            end
        end
        return type_counts
    end

    # Naive implementation of open counting open 4-node simplex types.
    function open_types4_naive(simplices::Vector{Int64}, nverts::Vector{Int64})
        # Get closed triangles and tetrahedra
        closed_tris_counts = triangle_counts(simplices, nverts)    
        closed_tetras = Set{NTuple{4, Int64}}()
        curr_ind = 1
        for nv in nverts
            simplex = simplices[curr_ind:(curr_ind + nv - 1)]
            curr_ind += nv
            for (i, j, k, l) in combinations(simplex, 4)
                push!(closed_tetras, sorted_tuple(i, j, k, l))
            end
        end

        # naive counting
        type_counts = initialize_type_counter4()
        A, At, B = basic_matrices(simplices, nverts)
        is_triangle(a::Int64, b::Int64, c::Int64) =
            all(v -> v > 0, [B[a, b], B[a, c], B[b, c]])
        inds = findall(vec(sum(At, dims=1)) .> 0)
        n = length(inds)
        for (i, j, k, l) in combinations(inds, 4)
            if (is_triangle(i, j, k) || is_triangle(i, j, l) ||
                is_triangle(i, k, l) || is_triangle(j, k, l)) && 
                !((i, j, k, l) in closed_tetras)
                num_edges = sum((B[i, j], B[i, k], B[i, l],
                                 B[j, k], B[j, l], B[k, l]) .> 0)
                wijk = closed_tris_counts[(i, j, k)]
                wijl = closed_tris_counts[(i, j, l)]
                wikl = closed_tris_counts[(i, k, l)]
                wjkl = closed_tris_counts[(j, k, l)]
                push!(type_counts, simplex_key4(wijk, wijl, wikl, wjkl, num_edges), 1)
            end
        end
        return type_counts
    end
    
    for dataset in ["example1", "example2", "email-Enron", "contact-primary-school"]
        println("$dataset...")
        data = example_dataset("example1")
        simplices, nverts = data.simplices, data.nverts
        test_equivalent_counters(open_types3_naive(simplices, nverts),
                                 open_types3(simplices, nverts))
        test_equivalent_counters(open_types4_naive(simplices, nverts),
                                 open_types4(simplices, nverts))        
    end
end

function test_simplicial_closure()
    println("test_projected_graph")
    test_projected_graph()
    
    println("basic_matrices")
    test_basic_matrices()
    
    println("open_closed_triangles (1/2)")
    test_open_closed_triangles1()
    println("open_closed_triangles (2/2)")
    test_open_closed_triangles2()
    
    println("closure_counts (1/3)")
    test_closure_counts1()
    println("closure_counts (2/3)")    
    test_closure_counts2()
    println("closure_counts (3/3)")    
    test_closure_counts3()
end

function test_new_closures()
    data = example_dataset("example1")
    simplices, nverts = data.simplices, data.nverts
    old_simplices, old_nverts = Int64[], Int64[]
    new_tris = new_closures(old_simplices, old_nverts, simplices, nverts)
    @test length(new_tris) == 0
    old_simplices = collect(1:9)
    old_nverts = ones(Int64, 9)
    new_tris = new_closures(old_simplices, old_nverts, simplices, nverts)    
    @test length(new_tris) == 7    
end

function test_enum_open_triangles()
    data = example_dataset("example1")
    simplices, nverts = data.simplices, data.nverts
    tris = enum_open_triangles(simplices, nverts)
    @test length(tris) == 1
    @test Set{Int64}(tris[1]) == Set{Int64}([1, 5, 8])
end

function test_common_neighbor_map()
    data = example_dataset("example1")
    simplices, nverts = data.simplices, data.nverts
    tris = enum_open_triangles(simplices, nverts)
    A, At, B = basic_matrices(simplices, nverts)
    common_nbrs = common_neighbors_map(B, tris)
    @test sort(collect(common_nbrs[(1, 5)])) == [3, 8]
    @test sort(collect(common_nbrs[(1, 8)])) == [5, 7]
    @test collect(common_nbrs[(5, 8)]) == [1]
end

function test_grad_and_curl()
    data = example_dataset("example1")
    simplices, nverts = data.simplices, data.nverts
    A, At, B = basic_matrices(simplices, nverts)
    grad, curl, edge_map = grad_and_curl(A, At, B)
    @test length(edge_map) == 15
    @test nnz(grad) == 15 * 2
    @test nnz(curl) == 7 * 3

    # test gradient map for edge (1, 3)
    edge_id = edge_map[(1, 3)]
    @test grad[edge_id, 3] == 1
    @test grad[edge_id, 1] == -1
    @test nnz(grad[edge_id, :]) == 2
    degrees = vec(sum(make_sparse_ones(B), dims=1))
    @test nnz(grad[:, 1]) == degrees[1]
    @test nnz(grad[:, 3]) == degrees[3]    

    # test curl map for triangle (1, 2, 4)
    edge_id1 = edge_map[(1, 2)]
    edge_id2 = edge_map[(2, 4)]
    edge_id3 = edge_map[(1, 4)]
    inds1 = findnz(curl[:, edge_id1])[1]
    inds2 = findnz(curl[:, edge_id2])[1]
    inds3 = findnz(curl[:, edge_id3])[1]
    @test length(inds1) == 3
    @test length(inds2) == 2
    @test length(inds3) == 2
    common = collect(intersect(inds1, inds2, inds3))
    @test length(common) == 1
    tri_ind = common[1]
    @test curl[tri_ind, edge_id1] == 1
    @test curl[tri_ind, edge_id2] == 1
    @test curl[tri_ind, edge_id3] == -1
    @test nnz(curl[tri_ind, :]) == 3
end

function test_score_functions()
    data = example_dataset("example1")
    simplices, nverts = data.simplices, data.nverts
    tris = enum_open_triangles(simplices, nverts)
    @test length(tris) == 1
    A, At, B = basic_matrices(simplices, nverts)
    @test arithmetic_mean(tris, B)[1] ≈ 1
    @test geometric_mean(tris, B)[1] ≈ 1

    degrees = vec(sum(make_sparse_ones(B), dims=1))
    @test pref_attach3(tris, degrees)[1] ≈ 63
    simp_degrees = vec(sum(At, dims=1))
    @test pref_attach3(tris, simp_degrees)[1] ≈ 20

    common_nbrs = common_neighbors_map(B, tris)
    @test common3(tris, common_nbrs)[1] ≈ 0
    @test jaccard3(tris, common_nbrs, degrees)[1] ≈ 0
    @test adamic_adar3(tris, common_nbrs, degrees)[1] ≈ 0

    function walk_test(func, weighted::Bool)
        scores1 = func(tris, B, weighted, true)[1]
        scores2 = func(tris, B, weighted, false)[1]
        @test scores1[1] ≈ scores2[1] atol=2e-3
    end
    walk_test(PKatz3, true)
    walk_test(PKatz3, false)
    walk_test(PPR3,   true)
    walk_test(PPR3,   false)    
end

function all_tests()
    println("test_simplicial_closure")
    test_simplicial_closure()

    println("test_new_closures")
    test_new_closures()

    println("test_enum_open_triangles")
    test_enum_open_triangles()

    println("test_common_neighbor_map")
    test_common_neighbor_map()

    println("test_grad_and_curl")
    test_grad_and_curl() 

    println("test_score_functions")
    test_score_functions()
end

all_tests()
