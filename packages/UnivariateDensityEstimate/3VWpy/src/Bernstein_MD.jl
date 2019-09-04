function active_set_unimodal_regression(y::Vector{Float64}, weights::Vector{Float64})
    min_index = -1
    min_err = 10e8
    opt_w = zeros(size(y, 1),1)
    W = zeros(size(y, 1)+1,size(y, 1))
    err_left = zeros(size(y,1)+1,1)
    err_right = zeros(size(y,1)+1,1)
        
    active_set = Array(ActiveState, size(y, 1))  
    
    for k in 1 : size(active_set, 1)
            active_set[k] = ActiveState(weights[k] * y[k], weights[k], k, k)
    end
    
    current = 0
    for i = 1:size(y, 1)
        if i==1
            current += 1
        else
            if below(active_set[current], active_set[current+1])
                current += 1
            else
                merged = merge_state(active_set[current], active_set[current+1])
                splice!(active_set, current:current+1, [merged])
                while current > 1 && !below(active_set[current-1], active_set[current]) 
                    current -= 1
                    merged = merge_state(active_set[current], active_set[current+1])
                    splice!(active_set, current:current+1, [merged])
                end
            end 
        end
        for as in active_set
            if as.lower > i
                break
            else
                W[i+1,as.lower:as.upper] = as.weighted_label / as.weight
            end
        end  
        err_left[i+1] = sum((W[i+1,1:i]-y[1:i] ).^2)
    end
    
    active_set = Array(ActiveState, size(y, 1))  
    
    for k in 1 : size(active_set, 1)
        active_set[k] = ActiveState(weights[size(y, 1) - k + 1] * y[size(y, 1) - k + 1], weights[size(y, 1) - k + 1], k, k)
    end
    
    current = 0
    for i = 1:size(y, 1)
        if i==1
            current += 1
        else
            if below(active_set[current], active_set[current+1])
                current += 1
            else
                merged = merge_state(active_set[current], active_set[current+1])
                splice!(active_set, current:current+1, [merged])
                while current > 1 && !below(active_set[current-1], active_set[current]) 
                    current -= 1
                    merged = merge_state(active_set[current], active_set[current+1])
                    splice!(active_set, current:current+1, [merged])
                end
            end 
        end
        for as in active_set
            if as.lower > i
                break
            else
                W[size(y, 1) - i + 1, size(y, 1) - as.upper + 1:size(y, 1) - as.lower + 1] = as.weighted_label / as.weight
            end
        end  
        err_right[size(y, 1) - i + 1] =
        sum((W[size(y, 1) - i + 1, size(y, 1) - i + 1: size(y, 1)]-y[size(y, 1) - i + 1: size(y, 1)] ).^2)
        
        if err_right[size(y, 1) - i + 1] + err_left[size(y, 1) - i + 1] < min_err
            min_err = err_right[size(y, 1) - i + 1] + err_left[size(y, 1) - i + 1]
            min_index = size(y, 1) - i + 1
            opt_w = W[size(y, 1) - i + 1, :]'
        end
    end
    
    return min_err, opt_w
end

active_set_unimodal_regression(y::Vector{Float64}) = active_set_unimodal_regression(y, vec(ones(size(y, 1) )))


function BernsteinEstimate_MD(Y,m,a,b,k,e,T,MaxIter,obj,flag,Reg)
# Y are data samples
# m is the number of Bernstein bases
# (a,b) is the interval of estimate
# k is the maximum number of modality we tolerate, k=0 means we have no modality constraint 
# e is the tolerance
# T is the maximum timelimit (in seconds)
# MaxIter is the number of max iteration
# obj = "Log" or "Quad"
# flag =  "Acc" means the accelerated version and "NonAcc" otherwise
n = size(Y,1)
left_endpoint = a
right_endpoint = b
Iter = MaxIter
epsilon = e
Initial_time = Dates.now()
Stepsize = []
Qhat = []
V = []
gradient_hat = []
    
err = zeros(MaxIter,1)

#Lipshitz_constant = 10*m
    


if obj == "Log"
    Bf = zeros(n,m)
    for i = 1:n
        for j = 1:m
            Bf[i,j] = betapdf(j, m-j+1, (Y[i]-a)/(b-a))
        end
    end
    Lipshitz_constant = n*m/100
    
    Stepsize = 1/Lipshitz_constant 
       
elseif obj == "Quad"
    ϵ = 3/(8*n)
    Ecdf = ecdf(Y)

    B = zeros(n,m)
    f = zeros(n,1)
    for i = 1:n 
        f[i] = Ecdf(vec(Y[i]))
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
    Stepsize = 1/maximum(abs.(Qhat))
end
    

obj_seq = vec(ones(MaxIter,1)) * Inf
#time_seq = vec(zeros(MaxIter,1))
w_current = vec(ones(1,m)/m)
w_hat = []

for t=1:MaxIter
    #tic();
    w_hat = w_current
    
    if obj == "Log"
        denom = zeros(n,1)
        for i = 1:n
            denom[i] = 1 ./ (LinearAlgebra.dot(vec(w_hat), vec(Bf[i,:])))
        end
        gradient_hat = - Bf' * denom - Reg * w_hat
            
            
    elseif obj == "Quad"
         #gradient_hat = 2*BF'*L*BF*w_hat-2*BF'*L*f
         gradient_hat = 2 * Qhat * w_hat - 2 * V'
            
            
        elseif obj
    
    end
    
    gradient_hat = vec(gradient_hat)    
    
    if k==0
    
    if flag == "NonAcc"
    
    # Non-accelerated version
                
    
    y = vec(zeros(m,1))            
    
                
    if obj == "Log"
                    
    while 1 > 0
                        
        temp = - Stepsize * gradient_hat
        temp_diff = temp .- maximum(temp)             
        y = w_hat .* exp.(temp_diff)  / sum(w_hat .* exp.(temp_diff))
    
        obj_what = 0
        for i=1:n
             obj_what = obj_what + log.(LinearAlgebra.dot(vec(Bf[i,:]), vec(w_hat)))
        end                
                    
        obj_temp = 0
        for i=1:n
             obj_temp = obj_temp + log.(LinearAlgebra.dot(vec(Bf[i,:]), vec(y)))
        end
      
        if -obj_temp < -obj_what + LinearAlgebra.dot(vec(gradient_hat),vec(y-w_hat))+0.5/Stepsize*sum(vec((y-w_hat).^2))
            #Stepsize = Stepsize * 1.1
            break
        else
            Stepsize = Stepsize / 1.1
        end
        
    end                 
    
    elseif obj == "Quad"
     
        temp = - Stepsize * gradient_hat
        temp_diff = temp .- maximum(temp)             
        y = w_hat .* exp.(temp_diff)  / sum(w_hat .* exp.(temp_diff))                
                    
    end
    
    w_current = vec(y)
                
    elseif flag == "Acc"
    
    # Accelerated version
    
    theta = 2/(t+2)
    
    if obj == "Log"
                
    while 1 > 0
                        
        temp = - Stepsize/theta * gradient_hat
        temp_diff = temp .- maximum(temp)              
        z = w_hat .* exp.(temp_diff)  / sum(w_hat .* exp.(temp_diff)) 
    
        obj_what = 0
        for i=1:n
             obj_what = obj_what + log.(LinearAlgebra.dot(vec(Bf[i,:]), vec(w_hat)))
        end                
                    
        obj_temp = 0
        for i=1:n
             obj_temp = obj_temp + log.(LinearAlgebra.dot(vec(Bf[i,:]), vec(z)))
        end
      
        if -obj_temp < -obj_what + LinearAlgebra.dot(vec(gradient_hat),vec(z-w_hat))+0.5/Stepsize*sum(vec((z-w_hat).^2))
            #Stepsize = Stepsize * 1.1
            break
        else
            Stepsize = Stepsize / 1.1
        end
        
    end                 
    
    elseif obj == "Quad"
     
        temp = - Stepsize * gradient_hat
        temp_diff = temp .- maximum(temp)             
        z = w_hat .* exp.(temp_diff)  / sum(w_hat .* exp.(temp_diff))                
                    
    end

    w_current = vec(theta*z+(1-theta)*w_hat )
    
    end
            
    
    
    end
            
    if k==1 
        temp, sol_y = active_set_unimodal_regression(log.(w_hat) .- Stepsize * gradient_hat)
        sol_y = exp.(vec(sol_y).-maximum(vec(sol_y)) )/sum(exp.(vec(sol_y).-maximum(vec(sol_y)) ))  
            
            

    
    # Non-accelerated version
                
    
    y = vec(zeros(m,1))            
    
                
    if obj == "Log"
                    
    while 1 > 0
               
        
        
        temp, sol_y = active_set_unimodal_regression(log.(w_hat) .- Stepsize * gradient_hat )
        sol_y = exp.(vec(sol_y).-maximum(vec(sol_y)) )/sum(exp.(vec(sol_y).-maximum(vec(sol_y)) ))  
        obj_what = 0
        for i=1:n
             obj_what = obj_what + log.(LinearAlgebra.dot(vec(Bf[i,:]), vec(w_hat)))
        end                
                    
        obj_temp = 0
        for i=1:n
             obj_temp = obj_temp + log.(LinearAlgebra.dot(vec(Bf[i,:]), vec(y)))
        end
      
        if obj_temp > obj_what 
            #Stepsize = Stepsize * 1.1
            break
        else
            Stepsize = Stepsize / 1.1
        end
        
    end                 
    
    elseif obj == "Quad"
     
    temp, sol_y = active_set_unimodal_regression(log.(w_hat) .- Stepsize * gradient_hat )
    sol_y = exp.(vec(sol_y).-maximum(vec(sol_y)) )/sum(exp.(vec(sol_y).-maximum(vec(sol_y)) ))  
    end
    
    w_current = vec(sol_y)
  
    end
        
    #=
    if k==2
        y = w_hat .* exp.(- Stepsize * gradient_hat)
    
        sol=zeros(m,1)
        sol=sol[:,1]
        err=10e8
        for j=1:m-1
            err_left, sol_left = active_set_unimodal_regression(log.(y[1:j]))
            err_right, sol_right = active_set_unimodal_regression(log.(y[j+1:m]))
            sol_left = exp.(sol_left)
            sol_right = exp.(sol_right)
            if err_left+err_right<err
                err = err_left+err_right
                sol = [sol_left;sol_right]
                sol = sol[:,1]      
        end
    end        
        w_current = vec(sol / sum(abs.(sol))) 
    end

    if k==3
        y = w_hat .* exp.(- Stepsize * gradient_hat)
        sol=zeros(m,1)
        sol=sol[:,1]
        err=10e8
        for j=1:m-2
            for l=j+1:m-1
                err_left, sol_left = active_set_unimodal_regression(log.(y[1:j]))
                err_mid, sol_mid = active_set_unimodal_regression(log.(y[j+1:l]))
                err_right, sol_right = active_set_unimodal_regression(log.(y[l+1:m]))
                sol_left = exp.(sol_left)
                sol_mid = exp.(sol_mid)
                sol_right = exp.(sol_right)
                if err_left+err_right<err
                    err = err_left+err_mid+err_right
                    sol = [sol_left;sol_mid;sol_right]
                    sol = sol[:,1]      
                end
            end
        end
    
        w_current = vec(sol / sum(abs.(sol)))             
    end
    =#
     
    if obj == "Log"    
    obj_seq[t] = 0      
    for i=1:n
        obj_seq[t] = obj_seq[t] + log.(LinearAlgebra.dot(vec(Bf[i,:]), vec(w_current)))
    end
    elseif obj == "Quad"
        obj_seq[t] = sum(w_current'*Qhat*w_current)-2*LinearAlgebra.dot(vec(V),vec(w_current))
    end
        
    #time_seq[t] = toq();
            
    if (sum(abs.(w_current-w_hat)) < epsilon)||((Dates.now()-Initial_time)>Millisecond(T*1000) )
        Iter = t+1;
        break
    end
end
          
    #println(Iter)
    return w_current, obj_seq
        
end

BernsteinEstimate_MD(Y::Array{Float64,1},m::Int64,a::Float64,b::Float64,k::Int64) = BernsteinEstimate_MD(Y,m,a,b,k,1e-4,10e10,3000,"Log","Acc",0)
