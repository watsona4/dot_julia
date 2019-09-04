# Package StatsBase, Distributions, JuMP, Gurobi are needed!
function BernsteinEstimate_MIQO(Y,m,a,b,k,e,T)
     n = size(Y,1)
     M = Model(with_optimizer(Gurobi.Optimizer, TimeLimit = T, MIPGap = e))
     #M = Model(solver = GurobiSolver(TimeLimit = T, MIPGap = e))

     @variable(M, w[1:m]>=0)
     @variable(M, z[1:m-1], Bin)
     @variable(M, σ_plus[1:m-2], Bin)
     @variable(M, σ_minus[1:m-2], Bin)
     @variable(M, α[1:m-2,1:2], Bin)

    # Uncomment this line for doing a warmstart
    #setvalue(w, BernsteinEstimate_MD(Y,m,a,b,0)')

    @constraint(M, sum(w)==1);
    # A big constant
    K = 1
    # k-modality constraint
    if k>=1
        for j=1:m-1
            @constraint(M, w[j]<=w[j+1]+K*z[j]);
            @constraint(M, w[j]>=w[j+1]-K*(1-z[j]));
        end
        for j=1:m-2
            @constraint(M, z[j+1]-z[j]==σ_plus[j]-σ_minus[j]);
            @constraint(M, σ_plus[j]<=K*α[j,1]);
            @constraint(M, σ_minus[j]<=K*α[j,2]);
            @constraint(M, α[j,1]+α[j,2]==1);
        end
        @constraint(M, sum(σ_plus)<=k);
        @constraint(M, sum(σ_minus)<=k);
    end
    
    ϵ = 3/(8*n)
    Ecdf = ecdf(vec(Y))

    B = zeros(n,m)
    f = zeros(n,1)
    for i = 1:n 
        f[i] = Ecdf(Y[i])
    end

    diag_L = (1 ./((Ecdf(Y).+ϵ).*(1+ϵ.-Ecdf(Y)))).^0.5 
    L = diagm(0 => diag_L)

    for i=1:n
        for j=1:m
            B[i,j] = betacdf(j, m-j+1, (Y[i]-a)/(b-a))
        end
    end

    #svd approximation - for numerical stability
    Q1 =(L*B)';
    Q = Q1*Q1';

    SVD_Q1 = svd(Q1)
    ids = SVD_Q1.S.>10e-3;
    vals = SVD_Q1.S[ids];
    uu = SVD_Q1.U[:,ids];

    Qhat = uu*diagm(0 => vals.^2)*uu'
    Qhat = (Qhat + Qhat')/2 + 0.001*Matrix{Float64}(I,m,m);

    V = (L*f)'*(L*B)

    c1 = sum(diag(V))
    c2 = sum(diag(Qhat))
 
    @objective(M, Min, -2*sum(V[i]*w[i] for i=1:m) + sum(Qhat[i,j]*w[i]*w[j] for i=1:m for j=1:m) )
    
    optimize!(M)
    
    return JuMP.value.(w)

end

