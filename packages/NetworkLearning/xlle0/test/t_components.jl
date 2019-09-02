function t_components()

########################################
# Test adjacency-related functionality #
########################################

# Define adjacency data
A = [							# adjacency matrix		
 0.0  0.0  1.0  1.0  0.0;
 0.0  0.0  1.0  0.0  0.0;
 1.0  1.0  0.0  1.0  1.0;
 1.0  0.0  1.0  0.0  0.0;
 0.0  0.0  1.0  0.0  0.0;
]

Ai = Int.(A)
G = Graph(Ai)

Gw = SimpleWeightedGraph(A)
I = findall(!iszero, A)
rows, cols = getindex.(I, 1), getindex.(I, 2)




data = [(i,j) for (i,j) in zip(rows,cols)]		# edges of A
n = 5							# number of vertices
f(n::Int, T=Int) = (data::Vector{Tuple{Int,Int}})->begin
	m = zeros(T,n,n)
	for t in data
		m[t[1],t[2]] = one(T)
	end
	return m
end

# Test functionality
E_Adj = adjacency()
Test.@test E_Adj isa EmptyAdjacency
Test.@test adjacency(nothing) isa EmptyAdjacency

A_Adj = adjacency(Ai)
Test.@test A_Adj isa MatrixAdjacency
Test.@test A_Adj.am == A

G_Adj = adjacency(G)
Test.@test G_Adj isa GraphAdjacency
Test.@test G_Adj.ag == G

Gw_Adj = adjacency(Gw)
Test.@test Gw_Adj isa GraphAdjacency
Test.@test Gw_Adj.ag == Gw

C_Adj = adjacency(f(n), data)
Test.@test C_Adj isa ComputableAdjacency
Test.@test C_Adj.f == f(n)
Test.@test C_Adj.data == data 

C2_Adj = adjacency((f(n), data))
Test.@test C2_Adj isa ComputableAdjacency
Test.@test C2_Adj.f == f(n)
Test.@test C2_Adj.data == data 

P_Adj = adjacency(f(n))
Test.@test P_Adj isa PartialAdjacency
Test.@test P_Adj.f == f(n)
Test.@test adjacency(P_Adj, data).am == A

A_Adj2 = adjacency(A_Adj)
Test.@test A_Adj2 == A_Adj

Test.@test adjacency(strip_adjacency(A_Adj),A).am == A_Adj.am
Test.@test adjacency(strip_adjacency(G_Adj),A).ag == G_Adj.ag
Test.@test adjacency(strip_adjacency(C_Adj),data).am == A_Adj.am
Test.@test adjacency(strip_adjacency(P_Adj),data).am == A_Adj.am
Test.@test adjacency(strip_adjacency(E_Adj),A).am == A_Adj.am

Test.@test adjacency_graph(A_Adj) == G
Test.@test adjacency_graph(G_Adj) == G
Test.@test adjacency_graph(Gw_Adj) == Gw
Test.@test adjacency_graph(C_Adj) == G

Test.@test adjacency_matrix(A_Adj) == Ai
Test.@test adjacency_matrix(G_Adj) == Ai
Test.@test adjacency_matrix(Gw_Adj) == A
Test.@test adjacency_matrix(C_Adj) == A

r=1:1
As = sparse(A)
Test.@test adjacency_obs(A, r, ObsDim.Constant{1}()) == view(A,r,:)
Test.@test adjacency_obs(A, r, ObsDim.Constant{2}()) == view(A,:,r)
Test.@test adjacency_obs(As, r, ObsDim.Constant{1}()) == As[r,:]
Test.@test adjacency_obs(As, r, ObsDim.Constant{2}()) == As[:,r]


# Test show methods
buf = IOBuffer()
Test.@test try
	for Adj in [A_Adj, G_Adj, C_Adj, P_Adj, E_Adj]
		show(buf,Adj)
	end
	true
catch
	false
end

# Test update_adjacency
A = [0 1 0; 1 0 0; 0 0 0]
Adj_m = adjacency(A)
update_function_m!(X,x,y) = begin
	X[x,y] += 1
	X[y,x] += 1
	return X
end
f_update_m(x,y) = X->update_function_m!(X,x,y)
for i in 1:3
	update_adjacency!(Adj_m, f_update_m(1,3))
end
Test.@test adjacency_matrix(Adj_m) == [0 1 3; 1 0 0; 3 0  0]

Adj_g = adjacency(Graph(A))
f_update_g(x,y) = G->add_edge!(G,x,y)
update_adjacency!(Adj_g, f_update_g(1,3))
Test.@test Matrix(adjacency_matrix(Adj_g)) == [0 1 1; 1 0 0; 1 0  0]

# Test errors
for Adj in [P_Adj, E_Adj]
	Test.@test try
		update_adjacency(Adj)
		false
	catch
		true # must fail because of the eror
	end
	
	Test.@test try
		adjacency_graph(Adj)
		false
	catch
		true # must fail because of the eror
	end
	Test.@test try
		adjacency_matrix(Adj)
		false
	catch
		true # must fail because of the eror
	end
end



######################################################
# Test fit/transform methods for relational learners #
######################################################
LEARNER = [SimpleRN,
	   WeightedRN,
	   BayesRN,
	   ClassDistributionRN]
N = 5							# number of observations
C = 2; 							# number of classes
A = [							# adjacency matrix		
 0.0  0.0  1.0  1.0  0.0;
 0.0  0.0  1.0  0.0  0.0;
 1.0  1.0  0.0  1.0  1.0;
 1.0  0.0  1.0  0.0  0.0;
 0.0  0.0  1.0  0.0  0.0;
]
Ad = adjacency(A); 

X = [							# local model estimates (2 classes)
 1.0  1.0  1.0  0.0  0.0;
 0.5  1.0  0.0  1.5  0.0
]

y = [1, 1, 1, 2, 2]					# labels

result = [
 [0.5  1.0  0.5  1.0  1.0; 				# validation data for SimpleRN
  0.5  0.0  0.5  0.0  0.0]
, 
 [0.5  1.0  0.5   1.0   1.0;				# validation data for WeightedRN 
  0.75 0.0  0.75  0.25  0.0]
, 		
 [1.60199  1.51083  1.60199  1.51083  1.51083;		# validation data for BayesRN
  1.14384  1.28768  1.14384  1.28768  1.28768]
,
 [0.300463  0.600925  0.300463  0.416667  0.600925; 	# validation data for ClassDistributionRN
  0.800391  0.125     0.800391  0.125     0.125]   
]

Xo = zeros(size(X));					# ouput (same size as X)
Xon = zeros(size(X));					# normalized ouput (same size as X)

tol = 1e-5
for li in 1:length(LEARNER)
	rl = fit(LEARNER[li], Ad, X, y; priors=ones(length(unique(y))),normalize=false)
	rln = fit(LEARNER[li], Ad, X, y; priors=ones(length(unique(y))),normalize=true)
        transform!(Xo, rl, Ad, X, y);
        transform!(Xon, rln, Ad, X, y);
	Test.@test all(abs.(Xo - result[li]) .<= tol);	# external validation
	Test.@test Xon ≈ (Xo./sum(Xo, dims=1))		# normalization validation
end

# Test show methods
for li in 1:length(LEARNER)
	rl = fit(LEARNER[li], Ad, X', y; obsdim=ObsDim.Constant{1}())
	Test.@test try 
		show(IOBuffer(), rl)
		true
	catch
		false
	end
	rl = fit(LEARNER[li], Ad, X, y; obsdim=ObsDim.Constant{2}())
	Test.@test try 
		show(IOBuffer(), rl)
		true
	catch
		false
	end
end



###################################
# Tests for the utility functions #
###################################

# Test observation-related functions i.e. oppdim, intdim, matrix_prealloc
r_oppdim = [ObsDim.Constant{2}(), ObsDim.First(), ObsDim.Constant{2}(), ObsDim.Constant{1}()]
r_intdim = [1,2,1,2]

tv = [ObsDim.First(), ObsDim.Last(), ObsDim.Constant{1}(), ObsDim.Constant{2}()]
for (i,o) in enumerate(tv)
	Test.@test oppdim(o) == r_oppdim[i]
	Test.@test intdim(o) == r_intdim[i]
end

Test.@test matrix_prealloc(10,2,ObsDim.Constant{1}(),1) == ones(10,2)
Test.@test matrix_prealloc(10,2,ObsDim.Constant{2}(),1) == ones(2,10)
Test.@test matrix_prealloc(10,2,ObsDim.First(),1) == ones(10,2)
Test.@test matrix_prealloc(10,2,ObsDim.Last(),1) == ones(2,10)
Test.@test try 
	matrix_prealloc(10,2,ObsDim.Undefined(),1)
	false
catch
	true
end

# Test the rest ...
cited =  [1,1,2,2,3,3,4,6,5,6]
citing = [2,3,1,5,2,6,7,1,2,3]
useidx = [1,2,6]

# 1 and 2 cite each other (edge weight of 2), 1 cites 6 one time (edge weight of 1)
Test.@test NetworkLearning.generate_partial_adjacency(cited,citing,useidx) == [0.0 2 1; 2 0 0; 1 0 0]
 
Test.@test NetworkLearning.get_size_out([1.,2,3]) == 1
Test.@test NetworkLearning.get_size_out([1,2,3]) == 3
Test.@test try
	NetworkLearning.get_size_out(rand(2,1))
	false
catch
	true
end

Test.@test NetworkLearning.getpriors([1.,2,3]) == [1.0]
Test.@test NetworkLearning.getpriors([1,2,3]) == 1/3*ones(3) 
Test.@test try
	NetworkLearning.getpriors(rand(2,1))
	false
catch
	true
end

end
