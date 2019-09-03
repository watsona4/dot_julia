function getemptymaze(dimx, dimy)
    maze = ones(Int64, dimx, dimy)
    maze[1,:] .= maze[end,:] .= 0
    maze[:, 1] .= maze[:, end] .= 0
    maze
end

function setwall!(maze, startpos, endpos)
    dimx, dimy = startpos - endpos
    if dimx == 0
        maze[startpos[1], startpos[2]:endpos[2]] .= 0
    else
        maze[startpos[1]:endpos[1], startpos[2]] .= 0
    end
end

function indto2d(maze, pos)
    dimx = size(maze, 1)
    [rem(pos, dimx), div(pos, dimx) + 1]
end
function posto1d(maze, pos)
    dimx = size(maze, 1)
    (pos[2] - 1) * dimx + pos[1]
end

function checkpos(maze, pos)
    count = 0
    for dx in -1:1
        for dy in -1:1
            count += maze[(pos + [dx, dy])...] == 0
        end
    end
    count
end

function addrandomwall!(maze)
    startpos = rand(findall(x -> x != 0, maze[:]))
    startpos = indto2d(maze, startpos)
    starttouch = checkpos(maze, startpos) 
    if starttouch > 0
        return 0
    end
    endx, endy = startpos
    if rand(0:1) == 0 # horizontal
        while checkpos(maze, [endx, startpos[2]]) == 0
            endx += 1
        end
        if maze[endx + 1, startpos[2]] == 1 &&
            maze[endx + 1, startpos[2] + 1] == 
            maze[endx + 1, startpos[2] - 1] == 0
            endx -= 1
        end
    else
        while checkpos(maze, [startpos[1], endy]) == 0
            endy += 1
        end
        if maze[startpos[1], endy + 1] == 1 &&
            maze[startpos[1] + 1, endy + 1] == 
            maze[startpos[1] - 1, endy + 1] == 0
            endx -= 1
        end
    end
    setwall!(maze, startpos, [endx, endy])
    return 1
end

function mazetomdp(maze, ngoalstates = 1, goalrewards = 1, 
                   stepcost = 0, stochastic = false, neighbourstateweight = .05)
    na = 4
    nzpos = findall(x -> x != 0, maze[:])
    mapping = cumsum(maze[:])
    ns = length(nzpos)
    T = Array{SparseVector}(undef, na, ns)
    goals = sort(sample(1:ns, ngoalstates, replace = false))
    R = -ones(na, ns) * stepcost
    isterminal = zeros(Int64, ns); isterminal[goals] .= 1
    isinitial = collect(1:ns); deleteat!(isinitial, goals)
    for s in 1:ns
        for (aind, a) in enumerate(([0, 1], [1, 0], [0, -1], [-1, 0]))
            pos = indto2d(maze, nzpos[s])
            nextpos = maze[(pos + a)...] == 0 ? pos : pos + a
            if stochastic && !(mapping[posto1d(maze, nextpos)] in goals)
                positions = []
                push!(positions, nextpos)
                weights = [1.]
                for dir in ([0, 1], [1, 0], [0, -1], [-1, 0])
                    if maze[(nextpos + dir)...] != 0
                        push!(positions, nextpos + dir)
                        push!(weights, neighbourstateweight)
                    end
                end
                states = map(p -> mapping[posto1d(maze, p)], positions)
                weights /= sum(weights)
                T[aind, s] = sparsevec(states, weights, ns)
            else
                nexts = mapping[posto1d(maze, nextpos)]
                T[aind, s] = sparsevec([nexts], [1.], ns)
                if nexts in goals
                    R[aind, s] = typeof(goalrewards) <: Number ? goalrewards : 
                                goalrewards[findfirst(x -> x == nexts, goals)]
                end
            end
        end
    end
    MDP(DiscreteSpace(ns, 1), 
        DiscreteSpace(na, 1), 
        rand(1:ns), T, R, isinitial, isterminal), 
    goals, nzpos
end

function breaksomewalls(m; f = 1/50, 
                        n = div(length(findall(x -> x == 0, m[2:end-1, 2:end-1][:])), 1/f))
    nx, ny = size(m)
    zeros = findall(x -> x == 0, m[:])
    i = 1
    while i < n
        candidate = rand(zeros)
        if candidate > nx && candidate < nx * (ny - 1) &&
            candidate % nx != 0 && candidate % nx != 1
            m[candidate] = 1
            i += 1
        end
    end
end

"""
    struct DiscreteMaze
        mdp::MDP
        maze::Array{Int64, 2}
        goals::Array{Int64, 1}
        nzpos::Array{Int64, 1}
"""
struct DiscreteMaze
    mdp::MDP
    maze::Array{Int64, 2}
    goals::Array{Int64, 1}
    nzpos::Array{Int64, 1}
end
"""
    DiscreteMaze(; nx = 40, ny = 40, nwalls = div(nx*ny, 10), ngoals = 1,
                   goalrewards = 1, stepcost = 0, stochastic = false, 
                   neighbourstateweight = .05)

Returns a `DiscreteMaze` of width `nx` and height `ny` with `nwalls` walls and
`ngoals` goal locations with reward `goalreward` (a list of different rewards
for the different goal states or constant reward for all goals), cost of moving 
`stepcost` (reward = -`stepcost`); if `stochastic = true` the actions lead with
a certain probability to a neighbouring state, where `neighbourstateweight`
controls this probability.
"""
function DiscreteMaze(; nx = 40, ny = 40, 
                   nwalls = div(nx*ny, 10), 
                   stepcost = 0., stochastic = false, ngoals = 1,
                   neighbourstateweight = .05, goalrewards = 1)
    m = getemptymaze(nx, ny)
    [addrandomwall!(m) for _ in 1:nwalls]
    breaksomewalls(m)
    mdp, goals, nzpos = mazetomdp(m, ngoals, goalrewards, stepcost,
                                  stochastic, neighbourstateweight)
    DiscreteMaze(mdp, m, goals, nzpos)
end

interact!(env::DiscreteMaze, a) = interact!(env.mdp, a)
reset!(env::DiscreteMaze) = reset!(env.mdp)
getstate(env::DiscreteMaze) = getstate(env.mdp)
actionspace(env::DiscreteMaze) = actionspace(env.mdp)

function plotenv(env::DiscreteMaze)
    goals = env.goals
    nzpos = env.nzpos
    m = deepcopy(env.maze)
    m[nzpos[goals]] .= 3
    m[nzpos[env.mdp.state]] = 2
    imshow(m, colormap = 21, size = (400, 400))
end
