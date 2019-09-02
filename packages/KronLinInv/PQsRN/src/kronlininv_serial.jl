

#
# This file is a part of KronLinInv. License is MIT
# Copyright (c) 2019 Andrea Zunino
#

##======================================================================

@doc raw"""
    posteriormean_serial(klifac::KLIFactors,Gfwd::FwdOps,mprior::Array{Float64,1},
                  dobs::Array{Float64,1})

Computes the posterior mean model, purely serial version.

# Arguments
- `klifac`: a structure containing the required "factors" previously computed with 
    the function `calcfactors()`. It includes
    * `U1, U2, U3` ``\mathbf{U}_1``, ``\mathbf{U}_2``, ``\mathbf{U}_3``  of  ``F_{\sf{A}}``
    * `diaginvlambda` ``F_{\sf{B}}``
    * `iUCmGtiCd1, iUCmGtiCd2, iUCmGtiCd3` ``\mathbf{U}_1^{-1}
      \mathbf{C}_{\rm{M}}^{\rm{x}}
      (\mathbf{G}^{\rm{x}})^{\sf{T}}(\mathbf{C}_{\rm{D}}^{\rm{x}})^{-1} ``,
      `` \mathbf{U}_2^{-1} \mathbf{C}_{\rm{M}}^{\rm{y}}
      (\mathbf{G}^{\rm{y}})^{\sf{T}} (\mathbf{C}_{\rm{D}}^{\rm{y}})^{-1} ``,
      `` \mathbf{U}_3^{-1} \mathbf{C}_{\rm{M}}^{\rm{z}}
      (\mathbf{G}^{\rm{z}})^{\sf{T}} (\mathbf{C}_{\rm{D}}^{\rm{z}})^{-1} ``
      of  ``F_{\sf{D}} ``
- `FwdOps`: a structure containing the three forward matrices
    * `G1, G2, G3` `` \mathbf{G} = \mathbf{G_1} \otimes \mathbf{G_2} \otimes \mathbf{G_3} ``
- `mprior`: prior model (vector)
- `dobs`:  observed data (vector)

# Returns
- The posterior mean model (vector)
"""
function posteriormean_serial(klifac::KLIFactors,Gfwd::FwdOps,mprior::Array{Float64,1},
                       dobs::Array{Float64,1})

    ##--------------
    U1,U2,U3 = klifac.U1,klifac.U2,klifac.U3
    diaginvlambda = klifac.invlambda
    Z1,Z2,Z3 = klifac.iUCmGtiCd1,klifac.iUCmGtiCd2,klifac.iUCmGtiCd3
    G1,G2,G3 = Gfwd.G1,Gfwd.G2,Gfwd.G3

    ## sizes
    Ni = size(Z1,1)
    Nl = size(Z1,2)
    Nj = size(Z2,1)
    Nm = size(Z2,2)
    Nk = size(Z3,1)
    Nn = size(Z3,2)

    ## sizes
    # Nr12 = size(U1,2)*size(U2,2)*size(U3,2)
    # Nc1  = size(Z1,1)*size(Z2,1)*size(Z3,1)
    Na = size(mprior,1)
    Nb = size(dobs,1)

    ##-------------
    av = collect(1:Na)
    bv = collect(1:Nb)
    ## vectors containing all possible indices for 
    ##    row calculations of Kron prod AxBxC
    iv = div.( (av.-1), (Nk.*Nj) ) .+1 
    jv = div.( (av.-1 .-(iv.-1).*Nk.*Nj), Nk ) .+1 
    kv = av.-(jv.-1).*Nk.-(iv.-1).*Nk.*Nj 
    ## vectors containing all possible indices for
    ##    column calculations of Kron prod AxBxC
    lv =  div.( (bv .-1), (Nn.*Nm) ) .+ 1 
    mv =  div.( (bv.-1 .-(lv.-1).*Nn.*Nm), Nn ) .+ 1 
    nv =  bv.-(mv.-1).*Nn-(lv.-1).*Nn.*Nm 
    ##  Gs have different shape than Us !!
    
    ####===================================

    ####================================================
    ##     Serial version
    ####================================================
    postm  = Array{Float64}(undef,Na)
    ddiff  = Array{Float64}(undef,Nb)    
    Zh     = Array{Float64}(undef,Na)
    elUDZh = Array{Float64}(undef,Na)

    everynit = Na>20 ? div(Na,20) : 1
    
    startt = time()
    ## dobs - dcalc(mprior)
    @inbounds for b=1:Nb
        if (b%everynit==0) | (b==2)
            eta =  ( (time()-startt)/float(b-1) * (Na-b+1) ) /60.0
            reta = round(eta,digits=3)
            print("posteriormean(): loop 1/3, $b of $Nb; ETA: $reta min  \r")
            flush(stdout)
        end

        # !!---------------------------------------------------------------------------
        # ddiff(b) = dobs(b) - sum(mprior * G1(lv(b),iv) * G2(mv(b),jv) * G3(nv(b),kv))
        # !!---------------------------------------------------------------------------

        datp = 0.0
        @inbounds for j=1:Na
            elG = G1[lv[b],iv[j]] * G2[mv[b],jv[j]] * G3[nv[b],kv[j]]
            datp = datp +  mprior[j] * elG
        end        
        ddiff[b] = dobs[b] - datp
    end

    startt = time()
    #tmpzhi = Array{Float64,1}(undef,Nb)
    @inbounds for i=1:Na

        if (i%everynit==0) | (i==2)
            eta =  ( (time()-startt)/float(i-1) * (Na-i+1) ) /60.0
            reta = round(eta,digits=3)
            print("posteriormean(): loop 2/3, $i of $Na; ETA: $reta min  \r")
            flush(stdout)
        end                     
        
        ## compute Zh
        # tmpzhi .= ddiff .* (Z1[iv[i],lv] .* Z2[jv[i],mv] .* Z3[kv[i],nv])
        # Zh[i] =  sum(tmpzhi)

        Zh[i]=0.0
        @inbounds  for j=1:Nb
            tZZ = Z1[iv[i],lv[j]] * Z2[jv[i],mv[j]] * Z3[kv[i],nv[j]]
            Zh[i] = Zh[i] + tZZ * ddiff[j]
        end
    end
    
    startt = time()
    ### need to re-loop because full Zh is needed
    @inbounds for i=1:Na
        
        if (i%everynit==0) | (i==2)
            eta =  ( (time()-startt)/float(i+1) * (Na-i+1) ) /60.0
            reta = round(eta,digits=3)
            print("posteriormean(): loop 3/3, $i of $Na; ETA: $reta min   \r")
            flush(stdout)
        end
        
        ## UD times Zh
        elUDZh[i] = 0.0
        @inbounds for j=1:Na
            # element of row of UD
            elrowUD = U1[iv[i],iv[j]] * U2[jv[i],jv[j]] *
                U3[kv[i],kv[j]] * diaginvlambda[j]
            # element of final vector
            elUDZh[i] = elUDZh[i] + elrowUD * Zh[j]
        end

        ## element of the posterior mean
        postm[i] = mprior[i] + elUDZh[i] # sum(bigmatrow.*ddiff)
    end
    println()
    
    return postm
end

##============================================================================

@doc raw""" 
    blockpostcov_serial(klifac::KLIFactors,astart::Int64,aend::Int64,
                 bstart::Int64,bend::Int64 )

Computes a block of the posterior covariance, purely serial version. 

# Arguments
- `klifac`: a structure containing the required "factors" previously computed with 
    the function `calcfactors()`. It includes
    * U1,U2,U3 `` \mathbf{U}_1``, ``\mathbf{U}_2``, ``\mathbf{U}_3`` of ``F_{\sf{A}}``
    * diaginvlambda ``F_{\sf{B}}``
    * iUCm1, iUCm2, iUCm3  ``\mathbf{U}_1^{-1} \mathbf{C}_{\rm{M}}^{\rm{x}} ``,
      ``\mathbf{U}_2^{-1}  \mathbf{C}_{\rm{M}}^{\rm{y}}``,
      ``\mathbf{U}_2^{-1}  \mathbf{C}_{\rm{M}}^{\rm{z}}`` of  ``F_{\sf{C}} `` 
- `Gfwd`: a structure containing the three forward model matrices  G1,G2,G3, where 
     `` \mathbf{G} =  \mathbf{G_1} \otimes \mathbf{G_2} \otimes \mathbf{G_3} ``
- `astart, aend`: indices of the first and last rowa of the requested block
- `bstart, bend`: indices of the first and last columns of the requested block

# Returns
- The requested block of the posterior covariance.

"""
function blockpostcov_serial(klifac::KLIFactors,
                      astart::Int64,aend::Int64,
                      bstart::Int64,bend::Int64 )

    ##--------------
    U1,U2,U3 = klifac.U1,klifac.U2,klifac.U3
    diaginvlambda = klifac.invlambda
    iUCm1,iUCm2,iUCm3 = klifac.iUCm1,klifac.iUCm2,klifac.iUCm3
  
    ##-----------------
    Ni = size(U1,1)
    Nl = size(U1,2)
    Nj = size(U2,1)
    Nm = size(U2,2)
    Nk = size(U3,1)
    Nn = size(U3,2)
    Na = Ni*Nj*Nk
    Nb = Nl*Nm*Nn
    
    ## check limits of requested block
    if astart<1 || aend>Na || astart>aend || bstart<1 || bend>Na || bstart>bend
        error("blockpostcov(): Wrong size of the requested block array.")
    end 

    ## sizes----
    # Nr12 = size(U1,2)*size(U2,2)*size(U3,2)
    # Nc1  = size(Z1,1)*size(Z2,1)*size(Z3,1)

    ##-----------------
    av = collect(1:Na)
    ## vectors containing all possible indices for 
    ##    row calculations of Kron prod AxBxC
    iv =  div.( (av.-1), (Nk.*Nj) ) .+1 
    jv =  div.( (av.-1 .-(iv.-1).*Nk.*Nj), Nk ) .+ 1 
    kv =  av.-(jv.-1).*Nk.-(iv.-1).*Nk.*Nj 

    nci = aend-astart+1
    ncj = bend-bstart+1
    postC = Array{Float64}(undef,nci,ncj)

    ####================================================
    ##     Serial version
    ####================================================
    row2  = Array{Float64}(undef,Na)

    @inbounds for a=astart:aend
        if a%100==0
            print("blockpostcov():  $a of $(astart) to $(aend) \r")
            flush(stdout)
        end
        ## calculate one row of first two factors
        ## row of  Kron prod AxBxC times a diag matrix (fb)
        @inbounds for q=1:Na
            row2[q] = U1[iv[a],iv[q]] * U2[jv[a],jv[q]] * U3[kv[a],kv[q]] * diaginvlambda[q]
        end
        @inbounds for b=bstart:bend
            postC[a,b] = 0.0
            @inbounds for p=1:Na
                ## calculate one column of fc
                col1 = iUCm1[iv[p],iv[b]] * iUCm2[jv[p],jv[b]] * iUCm3[kv[p],kv[b]]
                ## calculate one element 
                postC[a,b] = postC[a,b] + row2[p] * col1
            end
        end
    end

    println()
    return postC
end
    
##==========================================================
