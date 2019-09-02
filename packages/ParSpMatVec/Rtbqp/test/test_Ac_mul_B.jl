
using ParSpMatVec
using Test
using SparseArrays
using Printf
using LinearAlgebra

n = 50000
numProcs =4;
nvec = 5
A = sprand(n,n, 2.e-6);

x = rand(n,nvec);  x = x*10 .- 5;
y = rand(n,nvec);  y = y*10 .- 5;

println("Real")

alpha = 123.56
beta = 543.21
y2 = copy(y)
println("y = beta*y + alpha * A'*x")
BaseTime = @elapsed y2 = beta*y2 + alpha * A'*x; 

for k=0:numProcs
	y3 = copy(y)
	println("ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3,",k,")")
	PSMVtime = @elapsed ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3, k );
	@printf "Base=%1.4f\t ParSpMatVec=%1.4f\t speedup=%1.4f\n" BaseTime PSMVtime BaseTime/PSMVtime 
	@test norm(y3-y2) / norm(y) < 1.e-12
end
println()

# test error handling for nthreads
try 
	y3 = copy(y)
	ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3, -1);
catch E
	@test isa(E,ArgumentError)
end

# test error handling for sizes
try 
	y3 = copy(y)
	ParSpMatVec.Ac_mul_B!( alpha, A, x[1:10,:], beta, y3, 1);
catch E
	@test isa(E,DimensionMismatch)
end
try 
	y3 = copy(y)
	ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3[:,2], 1);
catch E
	@test isa(E,DimensionMismatch)
end

println("Complex Scalars, Real matrix")

alpha = 123.56 .+ 1im*randn()
beta = 543.21 .+ 1im*randn()
y = rand(n,nvec) + 1im* rand(n,nvec)
x  = rand(n,nvec) + 1im* rand(n,nvec)
println("y = beta*y + alpha * A'*x")

BaseTime = @elapsed y2 = beta*y + alpha * A'*x; 


for k=0:numProcs
	y3 = copy(y)
	println("ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3,",k,")")
	PSMVtime = @elapsed ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3, k ); 
	@printf "Base=%1.4f\t ParSpMatVec=%1.4f\t speedup=%1.4f\n" BaseTime PSMVtime BaseTime/PSMVtime 
	@test norm(y3-y2) / norm(y) < 1.e-12
end
try 
	y3 = copy(y)
	ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3, -1);
catch E
	@test isa(E,ArgumentError)
end
# test error handling for sizes
try 
	y3 = copy(y)
	ParSpMatVec.Ac_mul_B!( alpha, A, x[1:10,:], beta, y3, 1);
catch E
	@test isa(E,DimensionMismatch)
end
try 
	y3 = copy(y)
	ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3[:,2], 1);
catch E
	@test isa(E,DimensionMismatch)
end
println()
#-----------------------------------
# Complex

y2=0;
ii,jj,vv = findnz(A)

ai = ones(length(ii));
vv = vv + im*ai
A = sparse(ii,jj, vv, n,n)
ii=0; jj=0; vv=0; ai=0;

xi = rand(n,nvec);  xi = xi*10 .- 5;
x = x + im*xi
xi=0
yi = rand(n,nvec);  yi = yi*10 .- 5;
y = y + im*yi
yi=0

println("Complex")

alpha = complex(123.56, 333.444)
beta  = complex(543.21, 111.222)

y2 = copy(y)
println("y = beta*y + alpha * A'*x")
 
BaseTime = @elapsed y2 = beta*y2 + alpha * A'*x; 

for k=0:numProcs
	y3 = copy(y)
	println("ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3,",k,")")
	PSMVtime = @elapsed ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3, k ); 
	@printf "Base=%1.4f\t ParSpMatVec=%1.4f\t speedup=%1.4f\n" BaseTime PSMVtime BaseTime/PSMVtime 
	@test norm(y3-y2) / norm(y) < 1.e-12
end
try 
	y3 = copy(y)
	ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3, -1);
catch E
	@test isa(E,ArgumentError)
end
# test error handling for sizes
try 
	y3 = copy(y)
	ParSpMatVec.Ac_mul_B!( alpha, A, x[1:10,:], beta, y3, 1);
catch E
	@test isa(E,DimensionMismatch)
end
try 
	y3 = copy(y)
	ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3[:,2], 1);
catch E
	@test isa(E,DimensionMismatch)
end
println()


println("Complex short")
alpha = convert(ComplexF32, alpha)
beta  = convert(ComplexF32,beta);
A = convert(SparseMatrixCSC{ComplexF32,Int64},A);
x = convert(Array{ComplexF32},x);
y = convert(Array{ComplexF32},y);

y2 = copy(y)
println("y = beta*y + alpha * A'*x")

BaseTime = @elapsed y2 = beta*y2 + alpha * A'*x; 

for k=0:numProcs
	y3 = copy(y)
	println("ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3,",k,")")
	PSMVtime = @elapsed ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3, k ); 
	@printf "Base=%1.4f\t ParSpMatVec=%1.4f\t speedup=%1.4f\n" BaseTime PSMVtime BaseTime/PSMVtime 
	@test norm(y3-y2) / norm(y) < 1.e-4
end
try 
	y3 = copy(y)
	ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3, -1);
catch E
	@test isa(E,ArgumentError)
end
# test error handling for sizes
try 
	y3 = copy(y)
	ParSpMatVec.Ac_mul_B!( alpha, A, x[1:10,:], beta, y3, 1);
catch E
	@test isa(E,DimensionMismatch)
end
try 
	y3 = copy(y)
	ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3[:,2], 1);
catch E
	@test isa(E,DimensionMismatch)
end
println()

println("Complex short with a real matrix")
alpha = convert(ComplexF32, alpha)
beta  = convert(ComplexF32,beta);
A = convert(SparseMatrixCSC{Float32,Int64},real(A));
x = convert(Array{ComplexF32},x);
y = convert(Array{ComplexF32},y);

y2 = copy(y)
println("y = beta*y + alpha * A'*x")

BaseTime = @elapsed y2 = beta*y2 + alpha * A'*x; 


for k=0:numProcs
	y3 = copy(y)
	println("ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3,",k,")")
	PSMVtime = @elapsed ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3, k );  
	@printf "Base=%1.4f\t ParSpMatVec=%1.4f\t speedup=%1.4f\n" BaseTime PSMVtime BaseTime/PSMVtime 
	@test norm(y3-y2) / norm(y) < 1.e-5
end
try 
	y3 = copy(y)
	ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3, -1);
catch E
	@test isa(E,ArgumentError)
end
# test error handling for sizes
try 
	y3 = copy(y)
	ParSpMatVec.Ac_mul_B!( alpha, A, x[1:10,:], beta, y3, 1);
catch E
	@test isa(E,DimensionMismatch)
end
try 
	y3 = copy(y)
	ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3[:,2], 1);
catch E
	@test isa(E,DimensionMismatch)
end

println()
println("Complex single with a complex matrix but double target and source")
alpha = convert(ComplexF64, alpha)
beta  = convert(ComplexF64,beta);
A = convert(SparseMatrixCSC{ComplexF32,Int64},real(A) + 1im*A);
x = convert(Array{ComplexF64},x);
y = convert(Array{ComplexF64},y);

y2 = copy(y)
println("y = beta*y + alpha * A'*x")

BaseTime = @elapsed y2 = beta*y2 + alpha * A'*x; 


for k=0:numProcs
	y3 = copy(y)
	println("ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3,",k,")")
	PSMVtime = @elapsed ParSpMatVec.Ac_mul_B!( alpha, A, x, beta, y3, k ); 
	@printf "Base=%1.4f\t ParSpMatVec=%1.4f\t speedup=%1.4f\n" BaseTime PSMVtime BaseTime/PSMVtime 
	@test norm(y3-y2) / norm(y) < 1.e-5
	 norm(y3-y2) / norm(y) 
end
println()


