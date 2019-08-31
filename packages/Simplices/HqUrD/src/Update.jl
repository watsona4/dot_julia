function Update(P, N)

    if P == 0
        Res = N
    elseif N == 0
        Res = P
    else
        Res = [P; N]
    end

    return Res
end
