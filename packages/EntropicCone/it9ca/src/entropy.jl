export xlogx, hb, hxi, g_p

# Entropy log computation

function xlogx(p::Number)
    if p == 0
        0
    else
        p * log2(p)
    end
end

function xlogx(p)
    ret = zero(p)
    nonzero = p .!= 0
    ret[nonzero] = p[nonzero] .* log2(p[nonzero])
    return ret
end

function hb(t, p)
    return -xlogx(p) - xlogx(t-p)
end

function hb(p)
    return hb(1, p)
end

function hxi(p::Real)
    #return [hb(2*p) ones(length(p),1) hb(2*p)+1]
    PrimalEntropy([hb(2*p); 1; hb(2*p)+1; hb(1/2+p); 2*hb(1/2,p)-2*p; hb(1/2,p)+1/2; hb(2*p)+1; hb(p); hb(2*p)+2*p; hb(1/2,p)+1/2; hb(2*p)+1; hb(1/2,p)+1/2; hb(2*p)+1; hb(2*p)+1; hb(2*p)+1], 1)
    #PrimalEntropy([hb(2*p); ones(length(p),1); hb(2*p)+1; hb(1/2+p); 2*hb(1/2,p)-2*p; hb(1/2,p)+1/2; hb(2*p)+1; hb(p); hb(2*p)+2*p; hb(1/2,p)+1/2; hb(2*p)+1; hb(1/2,p)+1/2; hb(2*p)+1; hb(2*p)+1; hb(2*p)+1], 1)
end

function g_p(p)
    hxi(p) + hb(p) * matusrentropy(1,14) + (1 + 2*p - hb(2*p)/2) * (matusrentropy(1,23) + matusrentropy(2,4))
end
