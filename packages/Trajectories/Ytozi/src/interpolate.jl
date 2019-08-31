
struct Linear
end
struct Left
end
struct Right
end

"""
    interpolate(method, X::Trajectory, s)

Interpolate trajectory `X` using `method in [Linear(), Left(), ...]`
at time `s`.
"""
function interpolate
end

function interpolate(::Linear, X::Trajectory, s)
    i = searchsorted(keys(X), s)
    t, x = Pair(X)
    n = length(X)
    f, l = first(i), last(i)
    if f <= 1
        return x[1]
    elseif l >= n
        return x[end]
    elseif f <= l
        return x[f]
    else
        λ = (t[f] - s)/(t[f]-t[l])
        return λ*x[l] + (1-λ)*x[f]
    end
end


function interpolate(::Left, X::Trajectory, s)
    i = searchsorted(keys(X), s)
    t, x = Pair(X)
    n = length(X)
    f, l = first(i), last(i)
    return x[l]
end

function interpolate(::Right, X::Trajectory, s)
    i = searchsorted(keys(X), s)
    t, x = Pair(X)
    n = length(X)
    f, l = first(i), last(i)
    return x[f]
end
