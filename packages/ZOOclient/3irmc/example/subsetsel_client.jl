using ZOOclient
using PyPlot


# define a Dimension object
dim_size = 60
dim_regs = [[0, 1] for i = 1:dim_size]
dim_tys = [false for i = 1:dim_size]
mydim = Dimension(dim_size, dim_regs, dim_tys)
# define an Objective object
obj = Objective(mydim)

# define a Parameter object
# budget:  number of calls to the objective function
# evalueation_server_num: number of evaluation cores user requires
# control_server_ip_port: the ip:port of the control server
# objective_file: objective funtion is defined in this file
# func: name of the objective function
# constraint: the name of the constraint function
par = Parameter(budget=500, evaluation_server_num=2, control_server_ip_port="192.168.0.103:20000",
    objective_file="sparse_mse.py", func="loss", constraint="constraint")

# perform optimization
sol = zoo_min(obj, par)
# print the Solution object
sol_print(sol)

# visualize the optimization progress
history = get_history_bestsofar(obj)
plt[:plot](history)
plt[:savefig]("figure.pdf")
