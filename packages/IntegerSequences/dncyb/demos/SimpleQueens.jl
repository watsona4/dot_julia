module QueensAlwaysMakeProblems

# For some background see: https://wp.me/paipV7-E

function solve!(profile, level, size, start, cols, diag4, diag1)

    if level > 0
        for i in start:size
            save = cols & (1 << i) +
            diag1 & (1 << (i + level)) +
            diag4 & (1 << (32 + i - level))

            if save == 0

                cols  = xor(cols,  1 << i)
                diag1 = xor(diag1, 1 << (i + level))
                diag4 = xor(diag4, 1 << (32 + i - level))

                solve!(profile, level - 1, size, 0, cols, diag4, diag1)

                cols  = xor(cols,  1 << i)
                diag1 = xor(diag1, 1 << (i + level))
                diag4 = xor(diag4, 1 << (32 + i - level))

                profile[level + 1] += 1
            end
        end
    else
        for i in 0:size
            save = cols & (1<<i) + diag1 & (1<<i) + diag4 & (1<<(32+i))
            save == 0 && (profile[1] += 1)
        end
    end
end

function search(n::Int)

    profile = zeros(Int, n + 1)
    cols = diag4 = diag1 = Int(0)
    solve!(profile, n - 1, n - 1, 0, cols, diag4, diag1)
    return profile
end

function queens(n::Int)

    n == 0 && return [1]
    profile = search(n)
    profile[n+1] = 1  # add the root
    [profile[n-i+1] for i = 0:n]
end

function demo(up_to)

    for n in 0:up_to
        print("elapsed: ")
        @time profile = queens(n)
        println("size:      ", n)
        println("profile:   ", profile)
        println("nodes:     ", sum(profile))
        println("solutions: ", profile[n+1])
        println()
    end
end

demo(10)

end # module
