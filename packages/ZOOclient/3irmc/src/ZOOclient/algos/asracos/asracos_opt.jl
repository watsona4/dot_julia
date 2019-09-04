function asracos_opt!(objective::Objective, parameter::Parameter)
    asracos = ASRacos(parameter.evaluation_server_num)
    rc = asracos.rc
    rc.objective = objective
    rc.parameter = parameter
    ub = isnull(parameter.uncertain_bits)? 1 : parameter.uncertain_bits

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
    # close the socket
    close(cs_send)
    parameter.ip_port = RemoteChannel(()->Channel(length(servers)))
    for server in servers
        put!(parameter.ip_port, server)
    end

    asracos_init_attribute!(asracos, parameter)
    asracos_init_sample_set!(asracos, ub)
    println("Initialization succeeds")
    finish = SharedArray{Bool}(1)
    finish[1] = false
    # addprocs(1)
    @spawn asracos_updater!(asracos, parameter.budget, ub, finish)
    i = parameter.train_size
    br = false
    while true
        i += 1
        if finish[1] == true
            break
        end
        ip_port = take!(parameter.ip_port)
        sol = take!(asracos.sample_set)
        @spawn begin
            try
                br = compute_fx(sol, ip_port, parameter)
                put!(parameter.ip_port, ip_port)
                put!(asracos.result_set, sol)
            catch e
                println("Exception")
                println(e)
                cs_exception = connect(ip, port)
                println(cs_exception, "client: restart#")
                readline(cs_exception)
                println(cs_exception, string(servers_msg, "#"))
                close(cs_exception)
                return Solution()
            end
        end
    end
    # finish task
    result = take!(asracos.asyn_result)
    objective.history = take!(asracos.history)
    cs_receive = connect(ip, port)
    println(cs_receive, "client: return servers#")
    readline(cs_receive)
    println(cs_receive, string(servers_msg, "#"))
    close(cs_receive)
    return result
end

function compute_fx(sol::Solution, ip_port, parameter::Parameter)
    ip, port = get_ip_port(ip_port)
    client = connect(ip, port)

    # send calculate info
    println(client, "client: calculate#")
    msg = readline(client)
    br = false
    if check_exception(msg) == true
        br = true
    end

    println(client, "asracos#")
    msg = readline(client)
    if check_exception(msg) == true
        br = true
    end

    # send objective_file:func
    if br == false
        smsg = string(parameter.objective_file, ":", parameter.func, "#")
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
        receive = readline(client)
        if check_exception(receive) == true
            br = true
        end
    end
    if br == false
        value = parse(Float64, receive)
        sol.value = value
    end
    close(client)
    return br
end

function asracos_updater!(asracos::ASRacos, budget, ub, finish)
    rc = asracos.rc
    parameter = rc.parameter
    history = []
    t = parameter.train_size + 1
    strategy = parameter.replace_strategy
    time_log1 = now()
    interval = 10
    time_sum = interval
    output_file = parameter.output_file
    f = Nullable()
    if !isnull(output_file)
        f = open(output_file, "w")
    end
    br = false

    while(t <= budget)
        sol = take!(asracos.result_set)
        push!(history, sol.value)
        bad_ele = sracos_replace!(rc.positive_data, sol, "pos")
        sracos_replace!(rc.negative_data, bad_ele, "neg", strategy=strategy)
        rc.best_solution = rc.positive_data[1]
	    time_log2 = now()
        time_pass = Dates.value(time_log2 - time_log1) / 1000
        zoolog("Budget $(t): value=$(sol.value), best_solution_value=$(rc.best_solution.value)")
		str = "Budget $(t): time=$(floor(time_pass))s, value=$(sol.value), best_solution_value=$(rc.best_solution.value)\nbest_x=$(rc.best_solution.x)\n"
		if !isnull(f)
			write(f, str)
			flush(f)
		end
		if !isnull(parameter.time_limit) && time_pass > parameter.time_limit
			zoolog("Exceed time limit: $(parameter.time_limit)")
			br = true
		end
		 if rand(rng, Float64) < rc.parameter.probability
			 classifier = RacosClassification(rc.objective.dim, rc.positive_data,
			 rc.negative_data, ub=ub)
			 mixed_classification(classifier)
			 solution, distinct_flag = distinct_sample_classifier(rc, classifier, data_num=rc.parameter.train_size)
		 else
			 solution, distinct_flag = distinct_sample(rc, rc.objective.dim)
		 end
		 if distinct_flag == false
			 zoolog("ERROR: dimension limited")
			 break
		 end
		 if isnull(solution)
			 zoolog("ERROR: solution null")
			 break
		 end
		 put!(asracos.sample_set, solution)
		 t += 1
		 if br == true
			 break
		 end
     end
     finish[1] = true
     # zoolog("update finish")
     if !isnull(f)
         close(f)
     end
     put!(asracos.asyn_result, rc.best_solution)
     put!(asracos.history, history)
	 put!(parameter.positive_data, rc.positive_data)
	 put!(parameter.negative_data, rc.negative_data)
end

function asracos_sample(rc, ub)
    if rand(rng, Float64) < rc.parameter.probability
        classifier = RacosClassification(rc.objective.dim, rc.positive_data,
        rc.negative_data, ub=ub)
        zoolog("before classification")
        mixed_classification(classifier)
        zoolog("after classification")
        solution, distinct_flag = distinct_sample_classifier(rc, classifier, data_num=rc.parameter.train_size)
    else
        solution, distinct_flag = distinct_sample(rc, rc.objective.dim)
    end
    #painc stop
    if distinct_flag == false
        zoolog("ERROR: dimension limited")
    end
    if isnull(solution)
        zoolog("ERROR: solution null")
    end
    return solution
end

function asracos_init_attribute!(asracos::ASRacos, parameter::Parameter)
    f = open("init.txt", "w")
    rc = asracos.rc
    # otherwise generate random solutions
    iteration_num = rc.parameter.train_size
    data_temp = rc.parameter.init_sample
    init_num = 0
    remote_data = RemoteChannel(()->Channel(iteration_num))
    remote_result = RemoteChannel(()->Channel(iteration_num))
    if !isnull(data_temp)
        init_num = length(data_temp) < iteration_num? length(data_temp):iteration_num
        for i = 1:init_num
            # str = "initial sample: $(i), value=$(data_temp[i].value)\nx=$(sol.x)\n"
            put!(remote_data, data_temp[i])
        end
    end
    i = 1
    while i <= iteration_num - init_num
        # distinct_flag: True means sample is distinct(can be use),
        # False means sample is distinct, you should sample again.
        sol, distinct_flag = distinct_sample_from_set(rc, rc.objective.dim, rc.data,
            data_num=iteration_num)
        # panic stop
        if isnull(sol)
            break
        end
        if distinct_flag
            put!(remote_data, sol)
            i += 1
        end
    end
    fn = RemoteChannel(()->Channel(1))
    for i = 1:iteration_num
        d = take!(remote_data)
        if d.value != 0
            put!(remote_result, d)
            if i == iteration_num
                put!(fn, 1)
            end
            continue
        end
        ip_port = take!(parameter.ip_port)
        @spawn begin
            compute_fx(d, ip_port, parameter)
            put!(parameter.ip_port, ip_port)
            put!(remote_result, d)
            if i == iteration_num
                put!(fn, 1)
            end
        end

    end
    result = take!(fn)
    f = open("init.txt", "w")
    for i = 1:iteration_num
        d = take!(remote_result)
        push!(rc.data, d)
        str_print = "init sample: $(i), value=$(d.value)"
        str = "init sample: $(i), value=$(d.value)\n x=$(d.x)\n"
        zoolog(str_print)
        write(f, str)
        flush(f)
    end
    # zoolog("after taking result")
    close(f)
    selection!(rc)
    return
end

function construct_init_sample(init_file)
    f = open(init_file)
    lines = readlines(f)
    count = floor(Int, length(lines)/2)
    result = []
    for i in 1:count
        value_num = 2 * i - 1
        x_num = 2 * i
        value = eval(parse(split(lines[value_num], "=")[2]))
        x = eval(parse(split(lines[x_num], "=")[2]))
        sol = Solution(x=x, value=value)
        push!(result, sol)
    end
    return result
end

function check_exception(msg)
    if length(msg) < 9
        return false
    end
    res = msg[1:9]
    if res == "Exception"
        println(msg)
        return true
    end
    return false
end

function get_ip_port(ip_port)
    temp = split(ip_port, ":")
    ip = temp[1]
    port = parse(Int64, temp[2])
    return ip, port
end

function list2str(list)
    result = ""
    for i = 1:length(list)
        if i == 1
            result = string(list[i])
        else
            result = string(result, " ", string(list[i]))
        end
    end
    result = string(result, "#")
    result
end
