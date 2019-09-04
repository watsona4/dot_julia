type RacosCommon
    parameter
    objective
    # solution set
    # random sampled solutions construct self._data
    data
    # self._positive_data are best-positive_size solutions set
    positive_data
    # self._negative_data are the other solutions
    negative_data
    # best solution
    best_solution

    function RacosCommon()
        new(Nullable(), Nullable(), [], [], [], Nullable())
    end
end

# clear RacosCommon
function rc_clear!(rc::RacosCommon)
    rc.parameter = Nullable()
    rc.objective = Nullable()
    rc.data = []
    rc.positive_data = []
    rc.negative_data = []
    rc.best_solution = Nullable()
end

# construct self._data, self._positive_data, self._negative_data
function init_attribute!(rc::RacosCommon)
    # check if the initial solutions have been set
    data_temp = rc.parameter.init_sample
    if !isnull(data_temp)
        for i = 1:length(data_temp)
            push!(rc.data, obj_eval(rc.objective, data_temp[i]))
        end
        selection!(rc)
        return
    end
    # otherwise generate random solutions
    iteration_num = rc.parameter.train_size
    i = 0
    while i < iteration_num
        # distinct_flag: True means sample is distinct(can be use),
        # False means sample is distinct, you should sample again.
        x, distinct_flag = distinct_sample_from_set(rc, rc.objective.dim, rc.data,
          data_num=iteration_num)
        # panic stop
        if isnull(x)
            break
        end
        if distinct_flag
            obj_eval(rc.objective, x)
            push!(rc.data, x)
            i += 1
        end
    end
    selection!(rc)
    return
end

# sort self._data
# choose first-train_size solutions as the new self._data
# choose first-positive_size solutions as self._positive_data
# choose [positive_size, train_size) (Include the begin, not include the end) solutions as self._negative_data
function selection!(rc::RacosCommon)
    # print(length(rc.data))
    sort!(rc.data, by = x->x.value)
    rc.positive_data = rc.data[1:rc.parameter.positive_size]
    rc.negative_data = rc.data[(rc.parameter.positive_size+1):rc.parameter.train_size]
    rc.best_solution = rc.positive_data[1]
end

# distinct sample form dim, return a solution
function distinct_sample(rc::RacosCommon, dim; check_distinct=true, data_num=0)
    objective = rc.objective
    sol = obj_construct_solution(objective, dim_rand_sample(dim))
    times = 1
    distinct_flag = true
    if check_distinct == true
        while is_distinct(rc.positive_data, sol) == false ||
            is_distinct(rc.negative_data, sol) == false
            sol = obj_construct_solution(objective, dim_rand_sample(dim))
            times += 1
            if times % 10 == 0
                limited, number = dim_limited_space(dim)
                if limited == true
                    if number <= data_num
                        zoolog("racos_common.py: WARNING -- sample space has been fully enumerated. Stop early")
                        return Nullable(), Nullable()
                    end
                end
                if times > 100
                    distinct_flag = false
                    break
                end
            end
        end
    end
    return sol, distinct_flag
end

function distinct_sample_from_set(rc::RacosCommon, dim, set; check_distinct=true, data_num=0)
    objective = rc.objective
    sol = obj_construct_solution(objective, dim_rand_sample(dim))
    times = 1
    distinct_flag = true
    if check_distinct == true
        while is_distinct(set, sol) == false
            sol = obj_construct_solution(objective, dim_rand_sample(dim))
            times += 1
            if times % 10 == 0
                limited, number = dim_limited_space(dim)
                if limited == true
                    if number <= data_num
                        zoolog("racos_common.py: WARNING -- sample space has been fully enumerated. Stop early")
                        return Nullable(), Nullable()
                    end
                end
                if times > 100
                    distinct_flag = false
                    break
                end
            end
        end
    end
    return sol, distinct_flag
end

# distinct sample from a classifier, return a solution
# if check_distinct is False, you don't need to sample distinctly
function distinct_sample_classifier(rc::RacosCommon, classifier; check_distinct=true, data_num=0)
    objective = rc.objective
    x = rand_sample(classifier)
    sol = obj_construct_solution(rc.objective, x)
    times = 1
    distinct_flag = true
    if check_distinct == true
        while is_distinct(rc.positive_data, sol) == false || is_distinct(rc.negative_data, sol) == false
            x = rand_sample(classifier)
            sol = obj_construct_solution(rc.objective, x)
            times += 1
            if times % 10 == 0
                space = classifier.solution_space
                limited, number = dim_limited_space(space)
                if limited == true
                    if number <= data_num
                        zoolog("racos_common: WARNING -- sample space has been fully enumerated. Stop early")
                        return Nullable(), Nullable()
                    end
                end
                if times > 100
                    distinct_flag = false
                    break
                end
            end
        end
    end
    return sol, distinct_flag
end

# Check if x is distinct from each solution in seta
# return False if there exists a solution the same as x,
# otherwise return True
function is_distinct(seta, x)
    for sol in seta
        if sol_equal(x, sol)
            return false
        end
    end
    return true
end

# for dubugging
function print_positive_data(rc::RacosCommon)
    zoolog("------print positive_data------")
    zoolog("the size of positive data is $(length(rc.positive_data))")
    for x in rc.positive_data
        sol_print(x)
    end
end

function print_negative_data(rc::RacosCommon)
    zoolog("------print negative_data------")
    zoolog("the size of negative_data is $(length(rc.negative_data))")
    for x in rc.negative_data
        sol_print(x)
    end
end

function print_data(rc::RacosCommon)
    zoolog("------print data------")
    zoolog("the size of data is $(length(rc.data))")
    for x in rc.data
        sol_print(x)
    end
end
