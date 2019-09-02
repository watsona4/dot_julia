export  vdm_jac, vdm_iter!, vdm_newton


#----------------------------------------------------------------------
function vdm_jac(w, Xi, L)
    n = size(Xi,1)
    r = size(Xi,2)
    J = fill(typeof(Xi[1])(0), length(L), r + r*n)

    for k in 1:r
        for i in 1:length(L)
            J[i,k] = 1.;
            for v in 1:n
                J[i,k]*= Xi[v,k]^((L[i].z)[v])
            end
            for l in 1:n
                J[i,r+(k-1)*n+l] = w[k];
                for v in 1:n
                    if v==l
                        if (L[i].z)[v] > 0
                            J[i,r+(k-1)*n+l] *= (L[i].z)[v]*Xi[v,k]^((L[i].z)[v]-1)
                        else
                            J[i,r+(k-1)*n+l] = 0.0
                        end
                    else
                        J[i,r+(k-1)*n+l] *= Xi[v,k]^((L[i].z)[v])
                    end
                end
            end
        end
    end
    J
end

#----------------------------------------------------------------------
function vdm_iter!(w, Xi, s0, L)
    f = fill(typeof(Xi[1])(0), length(L))
    mnt = moment(w,Xi)
    for i in 1:length(L)
        f[i] = mnt(L[i].z)-s0[L[i]]
    end
    print("|ε|=", norm(f))
    J = vdm_jac(w,Xi,L)
    dwXi = J\f
    delta = norm(dwXi)
    println("  δ=", delta)

    r = length(w)
    n = size(Xi,1)
    for i in 1:r
        w[i] -= dwXi[i]
    end
    for i in 1:r
        for j in 1:n
            Xi[j,i] -= dwXi[r+(i-1)*n+j]
        end
    end

    delta
end

#----------------------------------------------------------------------
function vdm_newton(w0, Xi0, s0, L;  args...)
    eps::Float64 = 1.e-5
    cmax::Int64  = 10
    for arg in args
        if arg[1]==:maxit
            cmax=arg[2]
        end
        if arg[1]==:eps
            eps=arg[2]
        end
    end

    w = copy(w0)
    Xi = copy(Xi0)
    c = 0; delta = 1.0
    while delta > eps && c< cmax
        delta = vdm_iter!(w,Xi,s0,L)
        c += 1;
    end
    w, Xi
end

#----------------------------------------------------------------------
