export ortho_latin, check_ortho

"""
`A,B = ortho_latin(n,quick=true)` returns a pair of orthogonal `n`-by-`n`
Latin squares. If `quick` is `true`, we first try to find the pair using
basic number theory. If that fails, or if `quick` is set to `false`,
integer programming is used.

`A,B = ortho_latin(n,r,s)` builds the Latin squares `latin(n,r)`
and `latin(n,s)` and, if they are orthogonal, returns them as the
answer. (Otherwise, throws an error.) See: `find_ortho_parameters`.
"""
function ortho_latin(n::Int, quick::Bool=true)
    if quick
        try
            r,s = find_ortho_parameters(n)
            return ortho_latin(n,r,s)
        catch
        end
    end
    println("No quick solution. Using integer programming.")

    return ortho_latin_IP(n)
end


function ortho_latin_IP(n::Int)
    MOD = Model(with_optimizer(SOLVER.Optimizer))
    # Z[i,j,k,l] is an indicator that there is a k in A[i,j] and
    # an l in B[i,j]
    @variable(MOD,Z[1:n,1:n,1:n,1:n], Bin)

    # one entry per cell constraint
    for i=1:n
        for j=1:n
            @constraint(MOD, sum(Z[i,j,k,l] for k=1:n for l=1:n) == 1)
        end
    end

    # Top row 11 22 33 ... nn
    for i=1:n
        @constraint(MOD, Z[1,i,i,i]==1)  # A[1,i] = B[1,i] = i
    end

    # orthogonality constraint
    for k=1:n
        for l=1:n
            @constraint(MOD, sum(Z[i,j,k,l] for i=1:n for j=1:n) == 1)
        end
    end

    # Row constraints

    for i=1:n
        for k=1:n
            @constraint(MOD, sum(Z[i,j,k,l] for j=1:n for l=1:n) == 1)
        end
    end

    for i=1:n
        for l=1:n
            @constraint(MOD, sum(Z[i,j,k,l] for j=1:n for k=1:n) == 1)
        end
    end

    # Col constraints
    for j=1:n
        for k=1:n
            @constraint(MOD, sum(Z[i,j,k,l] for i=1:n for l=1:n) == 1)
        end
    end

    for j=1:n
        for l=1:n
            @constraint(MOD, sum(Z[i,j,k,l] for i=1:n for k=1:n) == 1)
        end
    end

    optimize!(MOD)
    status = Int(termination_status(MOD))

    if status != 1
        error("No pair of orthogonal Latin squares of order $n can be found.")
    end

    ZZ = value.(Z)
    A = zeros(Int,n,n)
    B = zeros(Int,n,n)

    for i=1:n
        for j=1:n
            for k=1:n
                for l=1:n
                    if ZZ[i,j,k,l]>0
                        A[i,j] = k
                        B[i,j] = l
                    end
                end
            end
        end
    end

    return A,B
end





function ortho_latin(n::Int, r::Int, s::Int)
    A = latin(n,r)
    B = latin(n,s)
    @assert check_ortho(A,B) "Parameters n=$n, r=$r, and s=$s do not generate a pair of orthogonal Latin squares"
    return A,B
end

"""
`find_ortho_parameters(n)` tries to find parameters `r` and `s`
so that `ortho_latin(n,r,s)` will succeed. Returns `(r,s)` if
successful or throws an error if not.
"""
function find_ortho_parameters(n::Int)
    for r=1:n-1
        for s=1:n-1
            if gcd(n,r)==1 && gcd(n,s)==1 && gcd(n,r-s)==1
                return r,s
            end
        end
    end
    error("No parameters for n=$n found")
end


"""
`check_ortho(A,B)` checks that matrices `A` and `B` are a pair of
orthogonal Latin squares.
"""
function check_ortho(A::Matrix{Int},B::Matrix{Int})::Bool
    if size(A) != size(B)
        return false
    end
    if !check_latin(A) || !check_latin(B)
        return false
    end
    n,r = size(A)

    vals = unique((n+1)*A + B)
    return length(vals) == n*n
end
