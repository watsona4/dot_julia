function checkAM(neq, nlag, nlead, h, b)


#   substitute the reduced form, b, into the structural 
#   equations, h, to confirm that the reduced form solves 
#   the model.



# Append negative identity matrix to b

b = hcat(b, -Matrix(I, neq, neq))

# Define indexes into the lagged part (minus)
# and the current and lead part (plus) of h

minus = 1:(neq * nlag)
plus  = (neq * nlag + 1):(neq * (nlag + 1 + nlead))
    
# Initialize q

q = zeros(neq * (nlead + 1), neq * (nlag + 1 + nlead))
    
# Stuff b into the upper left-hand block of q

(rb,cb) = size(b)
q[(1:rb), (1:cb)] = b[(1:rb), (1:cb)]

# Copy b into the (nlead) row blocks of q, shifting right
# by neq once more for each block (this produces a coefficient matrix that 
# solves for x(t), x(t+1), ..., x(t+nlead)) in terms of x(t-nlag),...,x(t-1).

for i in (1:nlead)
   rows = i * neq .+ (1:neq)
   q[rows,:] = shiftRight!( q[(rows .- neq), :], neq )
end
    
# Premultiply the left block of q by the negative inverse
# of the right block of q (use equation solver to avoid
# actually computing the inverse).

q[:,minus] =  -q[:,plus] \ q[:,minus]

# Define the solution error
    
error = h[:,minus] +  h[:,plus] * q[:,minus] 

# Take maximum absolute value of the vec of error (error(:))

err = maximum( abs.( error ) );

# space
print("Maximum absolute error: ")
println(err)

# Resize q, removing the additional neq columns and rows

rows = 1:(neq * nlead);
cols = 1:(neq * (nlag + nlead))
q = q[rows,cols];

    return q, err

end
