n_scen = 10_000       # number of Monte Carlo scenarios
costs_fixed = 20      # fixed costs
s = 0.03              # risk free rate of interest
α = 0.99              # confidence level of economic capital
seed = 2              # random seed for repeatable calculations

insurance_input =
  DataFrame(
  id =          [:fire, :liab, :theft],
  name =        ["Fire", "Liability", "Theft"],
  premium =     [600.,  300.,  100.],
  loss_ratio =  [0.75,  0.75,  0.75],
  cost_ratio =  [0.05,  0.05,  0.05],
  var_coeff =   [0.50,  0.60,  0.70],
  re_ceded =    [0.25,  0.20,  0.20],
  re_costs =    [-0.06, -0.06, -0.06])
## add a column with an explicit counter: the lines of business
insurance_input[:ctr] = collect(1:nrow(insurance_input))

invest_input =
  DataFrame(
  id =    [:invest],
  name = ["Investment"],
  init = [1400.],
  cost_ratio = [0.005],
  mean = [0.05],
  sd =[0.02])
## add a column with an explicit counter: investments
invest_input[:ctr] = [nrow(insurance_input)+1]

tau_kendall = Real[1.0  0.3  0.2  0.0;
                   0.3  1.0  0.6  0.0;
                   0.2  0.6  1.0  0.0;
                   0.0  0.0  0.0  1.0]

hurdle = 0.1          # hurdle rate for EVA calculation
n_cloud = 100         # number of points in cloud diagrams
