"""
    AndersonMooreAlg(h, qcols, neq)

Solve a linear perfect foresight model using the julia eig
function to find the invariant subspace associated with the big
roots.  This procedure will fail if the companion matrix is
defective and does not have a linearly independent set of
eigenvectors associated with the big roots.

  Input arguments:

    h         Structural coefficient matrix (neq,neq*(nlag+1+nlead)).
    neq       Number of equations.
    nlag      Number of lags.
    nlead     Number of leads.
    condn     Zero tolerance used as a condition number test
              by numericShift and reducedForm.
    upper     Inclusive upper bound for the modulus of roots
              allowed in the reduced form.
 
  Output arguments:
 
    b         Reduced form coefficient matrix (neq,neq*nlag).
    rts       Roots returned by eig.
    ia        Dimension of companion matrix (number of non-trivial
              elements in rts).
    nexact    Number of exact shiftRights.
    nnumeric  Number of numeric shiftRights.
    lgroots   Number of roots greater in modulus than upper.
    AMAcode   Return code: see function AMAerr.
"""
function AndersonMooreAlg(hh::Array{Float64,2}, neq::Int64, nlag::Int64, nlead::Int64, anEpsi::Float64, upper::Float64) 

    if(nlag < 1 || nlead < 1) 
        error("AMA_eig: model must have at least one lag and one lead.")
    end

    # Initialization.
    nexact   = 0
    nnumeric = 0
    lgroots  = 0
    iq       = 0
    AMAcode  = 0
    bb       = 0
    qrows    = neq * nlead
    qcols    = neq * (nlag + nlead)
    bcols    = neq * nlag
    qq       = zeros(qrows, qcols)
    rts      = zeros(qcols, 1)

    # Compute the auxiliary initial conditions and store them in q.

    (hh, qq, iq, nexact) = exactShift!(hh, qq, iq, qrows, qcols, neq)
    if (iq > qrows) 
        AMAcode = 61
        return bb, rts, ia, nexact, nnumeric, lgroots, AMAcode
    end

    (hh, qq, iq, nnumeric) = numericShift!(hh, qq, iq, qrows, qcols, neq, anEpsi)
    if (iq > qrows) 
        AMAcode = 62
        return bb, rts, ia, nexact, nnumeric, lgroots, AMAcode
    end

    #  Build the companion matrix.  Compute the stability conditions, and
    #  combine them with the auxiliary initial conditions in q.  

    (aa, ia, js) = buildA!(hh, qcols, neq)

    if (ia != 0)
        for element in aa
            if isnan(element) || isinf(element)
                display("A is NAN or INF")
                AMAcode = 63
                return bb, rts, ia, nexact, nnumeric, lgroots, AMAcode
            end
        end
        (ww, rts, lgroots) = eigenSys!(aa, upper, min(size(js, 1), qrows - iq + 1))


        qq = augmentQ!(qq, ww, js, iq, qrows)
    end

    test = nexact + nnumeric + lgroots
    if (test > qrows)
        AMAcode = 3
    elseif (test < qrows)
        AMAcode = 4
    end

    # If the right-hand block of q is invertible, compute the reduced form.

    if(AMAcode == 0)
        (nonsing,bb) = reducedForm(qq, qrows, qcols, bcols, neq, anEpsi)
        if ( nonsing && AMAcode==0)
            AMAcode =  1
        elseif (!nonsing && AMAcode==0)
            AMAcode =  5
        elseif (!nonsing && AMAcode==3)
            AMAcode = 35
        elseif (!nonsing && AMAcode==4)
            AMAcode = 45
        end
    end

    return bb, rts, ia, nexact, nnumeric, lgroots, AMAcode
 # (bbJulia,rtsJulia,iaJulia,nexJulia,nnumJulia,lgrtsJulia,AMAcodeJulia) = AMAalg(hh,neq,nlag,nlead,anEpsi,1+anEpsi)
end # AndersonMooreAlg
