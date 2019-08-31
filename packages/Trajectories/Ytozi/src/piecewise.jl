"""
    piecewise(X::Trajectory, [endtime]) -> tt, xx

If X is a jump process with piecewise constant paths and jumps in `X.tt`,
piecewise returns coordinates path for plotting purposes. The second argument
allows to choose the right endtime of the last interval.
"""
function piecewise(X::Trajectory, tend = X.t[end])
    t = [X.t[1]]
    n = length(X)
    append!(t, repeat(X.t[2:n], inner=2))
    push!(t, tend)
    t, repeat(X.x, inner=2)
end
