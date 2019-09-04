type Solution
    x
    value
    attach::Nullable
    function Solution(; x=[], value=0, attach = Nullable())
        new(x, value, attach)
    end
end

function sol_equal(sol1, sol2)
    if sol1.value != 0 && sol2.value!=0
        if abs(sol1.value - sol2.value) > my_precision
            return false
        end
    end
    if length(sol1.x) != length(sol2.x)
        return false
    end
    for i = 1:length(sol1.x)
        if abs(sol1.x[i] - sol2.x[i]) > my_precision
            return false
        end
    end
    return true
end

# find minimum solution in iset
function find_min(iset)
    min = Inf
    min_index = 0
    res = Solution()
    i = 0
    for sol in iset
        i += 1
        if sol.value < min
            min = sol.value
            min_index = i
            res = sol
        end
    end
    return res, min_index
end

# find maximum solution in iset
function find_max(iset)
    max = -Inf
    max_index = 0
    res = Solution()
    i = 0
    for sol in iset
        i += 1
        if sol.value > max
            max = sol.value
            max_index = i
            res = sol
        end
    end
    return res, max_index
end

function sol_print(sol)
    zoolog("value: $(sol.value)")
    zoolog("x: $(sol.x)")
end

function sol_write(f, sol)
    write(f, "value=$(sol.value)\n")
    write(f, "x=$(sol.x)\n")
end

function write_population(filename, positive_data, negative_data)
	f = open(filename, "w")
	write(f, "########################################\n")
	write(f, "positive_data: \n")
	for sol in positive_data
		sol_write(f, sol)
	end
	write(f, "########################################\n")
	write(f, "negative_data: \n")
	for sol in negative_data
		sol_write(f, sol)
	end
	close(f)
end