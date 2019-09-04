function pposs_mutation(s, n)
    s_temp = copy(s)
    threshold = 1.0 / n
    flipped = false
    for i = 1:n
        if rand(rng, Float64) <= threshold
            s_temp[i] = (s_temp[i] + 1) % 2
            flipped = true
        end
    end
    if !flipped
        mustflip = rand(rng, 1:n)
        s_temp[mustflip] = (s_temp[mustflip] + 1) % 2
    end
    return s_temp
end

function pposs_opt!(objective::Objective, parameter::Parameter)
    sample_set = RemoteChannel(()->Channel(parameter.evaluation_server_num))
    result_set = RemoteChannel(()->Channel(parameter.evaluation_server_num))
    asyn_result = RemoteChannel(()->Channel(1))
    history = RemoteChannel(()->Channel(1))
    population = []
    # require calculator server
    ip = parameter.control_server_ip
    port = parameter.control_server_port
    cs_send = connect(ip, port)
    println(cs_send, "client: require servers#")
    readline(cs_send)
    println(cs_send, string(parameter.evaluation_server_num, "#"))
    msg = readline(cs_send)

    servers_msg = readline(cs_send)
    if servers_msg == "No available evaluation server"
        zoolog("Error: no available evaluation server")
        return Solution()
    end
    servers = split(servers_msg, " ")
    println("get $(length(servers)) servers")
    parameter.ip_port = RemoteChannel(()->Channel(length(servers)))
    for server in servers
      put!(parameter.ip_port, server)
    end
    n = objective.dim.size
    sol = Solution(x=[0 for i = 1:n])
    ip_port = take!(parameter.ip_port)
    br = pposs_compute_fx(sol, ip_port, parameter)
    put!(parameter.ip_port, ip_port)

    push!(population, sol)

    pposs_init_sample_set!(sample_set, sol, parameter)
    println("Initialization succeeds")
    finish = SharedArray{Bool}(1)
    finish[1] = false
    @spawn pposs_updater!(population, sample_set, result_set, asyn_result, history, parameter, finish)
    br = false
    while true
        if finish[1] == true
            break
        end
        # println("$(finish[1])")
        ip_port = take!(parameter.ip_port)
        sol = take!(sample_set)
        @spawn begin
            try
                br = pposs_compute_fx(sol, ip_port, parameter)
                put!(parameter.ip_port, ip_port)
                put!(result_set, sol)
                # pposs_updater!(population, result_set, asyn_result, parameter, finish)
            catch e
                println("Exception")
                println(e)
                cs_exception = connect(ip, port)
                println(cs_exception, "client: restart#")
                readline(cs_send)
                println(cs_receive, string(servers_msg, "#"))
                return Solution()
            end
        end
    end
    result = take!(asyn_result)
    objective.history = take!(history)
    cs_receive = connect(ip, port)
    println(cs_receive, "client: return servers#")
    println(readline(cs_send))
    println(cs_receive, string(servers_msg, "#"))
    return result
end

function pposs_init_sample_set!(sample_set, sol, parameter)
    evaluation_server_num = parameter.evaluation_server_num
    data_temp = parameter.init_sample
    init_num = 0
    if !isnull(data_temp)
        init_num = length(data_temp)
        for i = 1:init_num
            put!(sample_set, data_temp[i])
        end
    end
    for i = 1:(evaluation_server_num - init_num)
        new_x = pposs_mutation(sol.x, length(sol.x))
        put!(sample_set, Solution(x=new_x))
    end
end

function pposs_updater!(population, sample_set, result_set, asyn_result, history, parameter, finish)
    t = 1
    pop_size = 1
    my_history = []
    budget = parameter.budget
    time_log1 = now()
    interval = 10
    time_sum = interval
    output_file = parameter.output_file
    best_sol = population[1]
    f = Nullable()
    if !isnull(output_file)
        f = open(output_file, "w")
    end
    br = false
    while(t <= budget)
        sol = take!(result_set)
        if sol.value[2] >= 0
            push!(my_history, sol.value[1])
        else
            push!(my_history, best_sol.value[1])
        end
        if sol.value[1] < best_sol.value[1] && sol.value[2] >= 0
            best_sol = sol
        end
        has_better = false
        for i in 1:pop_size
            if parameter.isolationfunc(sol.x) != parameter.isolationfunc(population[i].x)
                continue
            else
                if (population[i].value[1] < sol.value[1] && population[i].value[2] >= sol.value[2]) ||
                    (population[i].value[1] <= sol.value[1] && population[i].value[2] > sol.value[2])
                    has_better = true
                    break
                end
            end
        end
        if !has_better
            Q = []
            for i = 1:pop_size
                if sol.value[1] <= population[i].value[1] && sol.value[2] >= population[i].value[2]
                    continue
                else
                    push!(Q, population[i])
                end
            end
            push!(Q, sol)
            population = Q
            pop_size = length(population)
        end
        t += 1
        time_log2 = now()
        time_pass = Dates.value(time_log2 - time_log1) / 1000
        if time_pass >= time_sum
            time_sum = time_sum + interval
            zoolog("time: $(time_pass) update $(t): best_solution value = $(best_sol.value[1])")
            if parameter.show_x == true
                zoolog("best_solution x = $(best_sol.x)")
            end
            str = "$(floor(time_pass)) $(best_sol.value)\n"
            if parameter.show_x == true
                str = string(str, best_sol.x, "\n")
            end
            if !isnull(f)
                write(f, str)
            end
            if !isnull(parameter.time_limit) && time_pass > parameter.time_limit
                zoolog("Exceed time limit: $(parameter.time_limit)")
                br = true
            end
         end
         index = rand(rng, 1:pop_size)
         new_x = pposs_mutation(population[index].x, length(population[index].x))
         put!(sample_set, Solution(x=new_x))
     end
     min_value = population[1].value[1]
     result_index = 1
     for p = 1:pop_size
         fitness = population[p].value
         if fitness[2] >= 0 && fitness[1] < min_value
             min_value = fitness[1]
             result_index = p
         end
     end
     # zoolog("update finish")
     if !isnull(f)
         close(f)
     end
     put!(asyn_result, population[result_index])
     put!(history, my_history)
     finish[1] = true
     index = rand(rng, 1:pop_size)
     new_x = pposs_mutation(population[index].x, length(population[index].x))
     put!(sample_set, Solution(x=new_x))
     # println("$(finish[1])")
end

function pposs_compute_fx(sol::Solution, ip_port, parameter::Parameter)
    ip, port = get_ip_port(ip_port)
    client = connect(ip, port)

    # send calculate info
    println(client, "client: calculate#")
    msg = readline(client)

    br = false
    if check_exception(msg) == true
        br = true
    end
    println(client, "pposs#")
    msg = readline(client)
    if check_exception(msg) == true
        br = true
    end
    # send objective_file:func
    if br == false
        smsg = string(parameter.objective_file, ":", parameter.func, ":", parameter.constraint, "#")
        println(client, smsg)
        msg = readline(client)
        if check_exception(msg) == true
            br = true
        end
    end

    # send x
    if br == false
        str = list2str(sol.x)
        println(client, str)
        receive = split(readline(client), " ")
        if check_exception(receive) == true
            br = true
        end
    end
    if br == false
        value = [parse(Float64, receive[1]), parse(Float64, receive[2])]
        # zoolog("$(value)")
        sol.value = value
    end
    return br
end
