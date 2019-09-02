
##################################################
## Deflation
## when a Q[k] matrix become a "D" matrix, we deflate. This is checked by the sine term being basically 0.
function check_deflation(state::FactorizationType{T,St,P, Tw}, tol = eps(T)) where {T,St,P,Tw}
    for k in state.ctrs.stop_index:-1:state.ctrs.start_index
        if abs(vals(state.Q[k])[2]) <= tol
            deflate(state, k)
            return
        end
    end
end

# deflate a term
# turn on `show_status` to view sequence
function deflate(state::FactorizationType{T,Val{:DoubleShift},P, Tw}, k) where {T,P,Tw}

    # make a D matrix for Q. C could be +/- 1
    c,s = vals(state.Q[k])
    c = c/norm(c)
    state.Q[k] = RealRotator(c, zero(T), state.Q[k].i)

    # shift zero counter
    state.ctrs.zero_index = k      # points to a matrix Q[k] either RealRotator(-1, 0) or RealRotator(1, 0)
    state.ctrs.start_index = k + 1

    # reset counter
    state.ctrs.it_count = 1
end


# deflate a term
# deflation for ComplexReal is different, as
# we replace Qi with I and move diagonal part into D
function deflate(state::FactorizationType{T,Val{:SingleShift},P, Val{:NotTwisted}}, k) where {T, P}

    # when we deflate here we want to leave Q[k] = I and

    # move Dk matrix over to merge with D
    # Qi       Qi            Qi           Qi
    #   Qj   ->   I Dj  -->    I Dj   -->   I Dj
    #     Qk        QK           Qk Dj        Qk Dj    fuse Dj's with D
    #       QL        QL           QL           Ql Dj


    # then the Dk's are collected into D

    alpha, s = vals(state.Q[k])
    state.Q[k] = Rotator(one(Complex{T}), zero(T), idx(state.Q[k]))

    cascade(state.Q, state.D, alpha, k, state.ctrs.stop_index)

    # shift zero counter
    state.ctrs.zero_index = k      # points to a matrix Q[k] either RealRotator(-1, 0) or RealRotator(1, 0)
    state.ctrs.start_index = k + 1

    # reset counter
    state.ctrs.it_count = 1
end


##################################################
