## general data and market data =================================
seed = 2            ## seed for random generator
n_scen = 1_000_000  ## number of monte carlo scenarios
α = 0.99            ## confidence level for expected shortfall
coc_rate = 0.06     ## cost of capital rate for Mindestbetrag
spot = [0.00155, 0.00013, -0.00011]  ## spot rates as of 2012
stock_increase = 0.05   ## expected rel. increase of stock index

## risk factors =================================================

## CHF spot rates
x0_spot = [0.0, 0.0, 0.0]  ## as of 2012
h_spot = [0.01, 0.01, 0.01]
add_spot = [true, true, true]
index_spot = collect(1:3) # Arg. must always be of the form 1:T
## stock index
x0_stock = 1.0
h_stock = 0.1
add_stock = false
index_stock = [4]
## mortality
x0_mort = 1.0
h_mort = 0.1
add_mort = false
index_mort = [5]

## data provied by FINMA (for 2012) -----------------------------
## components link to index_spot, index_stock, index_mort

## standard deviations of risk factors
σ = [0.0060292643195745,         # spot_chf[1]
     0.00605990680656078,        # spot_chf[2]
     0.00633152336734695,        # spot_chf[3]
     0.150517788474455,          # stock
     0.05 ]                      # q

## correlations for risk factors
##       spot_chf[1] spot_chf[2] spot_chf[3] stock       mort
corr =  [1.000000000 0.721560179 0.545556472 0.402239567 0;
         0.721560179 1.000000000 0.953194547 0.433388849 0;
         0.545556472 0.953194547 1.000000000 0.413041139 0;
         0.402239567 0.433388849 0.413041139 1.000000000 0;
         0.000000000 0.000000000 0.000000000 0.000000000 1]

## stress scenarios

## data frame that describes the stresst scenarios to be added
## n:       number of scenarios
## name:    stress scenario name / description
## target:  true: include, false: do not include
## prob:    probability for this stress scenario occuring
## Δx:      effect of this scenario on risk factor
## Δrtk:    efect of this scenario on RTK (to be calculated)
stress =
  Stress(8,
         ["SZ01: Equity drop -60%",
          "SZ03: Stock mkt crash (87)",
          "SZ04: Nikkei crash (89/90)",
          "SZ05: European currency crisis (92)",
          "SZ06: US interest crisis (94)",
          "SZ07: Russian crisis/LTCM (98)",
          "SZ08: Stock mkt crash (00/01)",
          "SZ11: Financial crisis (08)"],
         [true, true, true, true, true, true, true, true],
         [0.001, 0.001, 0.001, 0.001, 0.001, 0.001, 0.001, 0.001],
         [ 0.00000  0.00000 0.00000 -0.6000 0;
          -0.00155 -0.00013 0.00000 -0.2323 0;
           0.01563  0.01098 0.01177 -0.2643 0;
          -0.00155 -0.00013 0.00000 -0.0580 0;
           0.01109  0.01406 0.01509 -0.1852 0;
          -0.00155 -0.00013 0.00000 -0.2841 0;
          -0.00155 -0.00013 0.00000 -0.3567 0;
          -0.00155 -0.00013 0.00000 -0.3881 0],
         zeros(Float64, 8))

## portfolio data  ==============================================
invest =
  DataFrame(maturity = [NaN, 1, 2, 3],
            index = [4, 1, 2, 3],
            kind = ["stock", "zerobond", "zerobond", "zerobond"],
            nominal = [300.0, 0.0, 300.0, 500.0])

n_ins = 10                         ## number insurance contracts
ins_sum = 100.0                    ## insured sum per contract
qx_flat = 0.02                     ## mortality probability
qx = [qx_flat, qx_flat, qx_flat]   ## mortality probabilities
B_PX  =[0.0, 0.0, n_ins * ins_sum] ## benefit profile (survival)
T = length(B_PX)                   ## Time until run off
