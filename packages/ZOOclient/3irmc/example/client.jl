using ZOOclient
# using PyPlot

# define a Dimension object
dim_size = 100
dim_regs = [[-1, 1] for i = 1:dim_size]
dim_tys = [true for i = 1:dim_size]
mydim = Dimension(dim_size, dim_regs, dim_tys)
# define an Objective object
obj = Objective(mydim)

# define a Parameter Object, the five parameters are indispensable.
# budget:  number of calls to the objective function
# evalueation_server_num: number of evaluation cores user requires
# control_server_ip_por4t: the ip:port of the control server
# objective_file: objective funtion is defined in this file
# func: name of the objective function
init_sample = construct_init_sample("/Users/liu/.julia/v0.6/ZOOclient/example/init.txt")
par = Parameter(budget=400, evaluation_server_num=2, control_server_ip_port="192.168.100.108:20000",
    objective_file="fx.py", func="ackley", output_file="log.txt", init_sample=init_sample, uncertain_bits=5)

# perform optimization
sol = zoo_min(obj, par)
# print the Solution object
sol_print(sol)
positive_data = take!(par.positive_data)
negative_data = take!(par.negative_data)
write_population("population.txt", positive_data, negative_data)
# visualize the optimization progress
# history = get_history_bestsofar(obj)
# plt[:plot](history)
# plt[:savefig]("figure.png")
