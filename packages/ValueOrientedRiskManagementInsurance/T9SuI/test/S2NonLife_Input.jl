## general data and market data #################################

α = 0.995  ## confidence level

lob_names = [:motor_liab, :motor_other, :mat,
             :fire, :liability, :credit,
             :legal, :assist, :misc,
             :re_np_cas, :re_np_mat, :re_np_prop]
lob_ids = 1:12


## risk free interest curve:
rf = [0.03, 0.031, 0.0315, 0.032, 0.032, 0.032]

## data for premium risk and reserve risk
df_lobs_prem_risk = DataFrame(
  id =                lob_ids,
  abbrev =            lob_names,
  prem_gross_vc =     [0.10,         0.08,           0.15,
                       0.08,         0.14,           0.12,
                       0.07,         0.09,           0.13,
                       0.17,         0.17,           0.17],
  re_np_prem =        [0.8,          1.0,            1.0,
                       0.8,          0.8,            1.0,
                       1.0,          1.0,            1.0,
                       1.0,          1.0,            1.0],
  res_net_vc =        [0.09,         0.8,            0.11,
                       0.10,         0.11,           0.19,
                       0.12,         0.20,           0.20,
                       0.20,         0.20,           0.20]
  )

## correlation matrix for premium risk and reserve risk
corr_lob =
  [1.00 0.50 0.50 0.25 0.50 0.25 0.50 0.25 0.50 0.25 0.25 0.25;
   0.50 1.00 0.25 0.25 0.25 0.25 0.50 0.50 0.50 0.25 0.25 0.25;
   0.50 0.25 1.00 0.25 0.25 0.25 0.25 0.50 0.50 0.25 0.50 0.25;
   0.25 0.25 0.25 1.00 0.25 0.25 0.25 0.50 0.50 0.25 0.50 0.50;
   0.50 0.25 0.25 0.25 1.00 0.50 0.50 0.25 0.50 0.50 0.25 0.25;
   0.25 0.25 0.25 0.25 0.50 1.00 0.50 0.25 0.50 0.50 0.25 0.25;
   0.50 0.50 0.25 0.25 0.50 0.50 1.00 0.25 0.50 0.50 0.25 0.25;
   0.25 0.50 0.50 0.50 0.25 0.25 0.25 1.00 0.50 0.25 0.25 0.50;
   0.50 0.50 0.50 0.50 0.50 0.50 0.50 0.50 1.00 0.25 0.50 0.25;
   0.25 0.25 0.25 0.25 0.50 0.50 0.50 0.25 0.25 1.00 0.25 0.25;
   0.25 0.25 0.50 0.50 0.25 0.25 0.25 0.25 0.50 0.25 1.00 0.25;
   0.25 0.25 0.25 0.50 0.25 0.25 0.25 0.50 0.25 0.25 0.25 1.00]

## correlation between premium and reserve risk
corr_prem_res = [1.0 0.5; 0.5 1.0]

## data for catastrophe liability risk
df_cat_liability =
  DataFrame(index = collect(1:6),
            description =
              [:l_malpractice,
               :l_employer,
               :l_director_officer,
               :l_personal,
               :l_other,
               :l_nprob_re],
            f_liab = [1.0, 1.6, 1.6, 0.0, 1.0, 2.1])
## correlations for types of catastrophe liability risk
corr_liab =
  [1.00 0.00 0.50 0.00 0.25 0.50;
   0.00 1.00 0.00 0.00 0.25 0.50;
   0.50 0.00 1.00 0.00 0.25 0.50;
   0.00 0.00 0.00 1.00 0.00 0.00;
   0.25 0.25 0.25 0.00 1.00 0.50;
   0.50 0.50 0.50 0.00 0.50 1.00]

## correlations for premium-reserve-risk, lapse-risk, cat-risk
corr_scr = [1.00 0.00 0.25;
            0.00 1.00 0.00;
            0.25 0.00 1.00]

## company data #################################################

## theft -> misc (we classify theft insurance as miscellaneous)
select_lob_names = [:fire, :liability, :misc]

df_lobs = DataFrame(
  name = select_lob_names,              # lobs of X-AG
  index = findall( (in)(select_lob_names), lob_names), # ids of lobs
  prem_gross_w_py = [500., 250.,  50.], # gross written prem. PY
  prem_gross_w_cy = [600., 300., 100.], # gross written prem. CY
  upr_py = [50., 20., 5.],              # unearned prem. res. PY
  upr_cy = [70., 40., 12.],             # unearned prem. res. CY
  upr_ny = [ 75., 45., 15.],            # unearned prem. res. NY
  re_prop_q_py = [0.25, 0.20, 0.20],    # prop. reins. ceded PY
  re_prop_q_cy = [0.25, 0.20, 0.20],    # prop. reins. ceded CY
  re_prop_q_ny = [0.25, 0.20, 0.20],    # prop. reins. ceded NY
  re_np = [true, false, false],         # has non-prop. reins.
  res_undisc_py = [200., 150., 20.],    # undisc. res. PY (EoY)
  )

β_raw = DataFrame(
  fire =      [1.0, 0.6, 0.1, 0.0, 0.0, 0.0],
  liability = [1.0, 0.9, 0.6, 0.2, 0.1, 0.0],
  misc =      [1.0, 0.4, 0.0, 0.0, 0.0, 0.0]
  )

## for fire catastrophe risk: total insured sum within the
## the circle of rations 200m that has the largest total
## insured sum.
cat_fire_is = [20, 30, 10]

## 50% employer's liability, 10% D&O, 40% personal liability
cat_liability_mix = [0.0, 0.5, 0.1, 0.4, 0.0, 0.0]
