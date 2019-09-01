"""
Coffee crop model

Computes the coffee crop growth and yield. This function is called from [`dynacof`](@ref) and should not be called
by the user.

# Return

Nothing, modify the DataFrame of simulation `Sim` in place. See [`dynacof`](@ref) for more details.

"""
function coffee_model!(Sim,Parameters,Met_c,i)
      # CM is in gC m-2soil, so use C content to transform in dry mass
      Sim.LAI[i]= Sim.CM_Leaf[previous_i(i)]  *  Parameters.SLA  /  1000.0  /  Parameters.CC_Leaf
      Sim.LAIplot[i]= Sim.LAIplot[i] + Sim.LAI[i]
  
      # Light interception ------------------------------------------------------
  
      Sim.K_Dif[i]= Parameters.k_Dif
      Sim.K_Dir[i]= Parameters.k_Dir
  
      #APAR coffee
      Sim.PAR_Trans_Tree[i]= Met_c.PAR[i] - Sim.APAR_Tree[i] # PAR above coffee layer
      Sim.APAR_Dif[i]= max(0.0, (Sim.PAR_Trans_Tree[i] * Met_c.FDiff[i]) * (1.0 - exp(-Sim.K_Dif[i] * Sim.LAI[i])))
      APAR_Dir= max(0.0,(Sim.PAR_Trans_Tree[i] * (1.0 - Met_c.FDiff[i])) * (1.0 - exp(-Sim.K_Dir[i] * Sim.LAI[i])))
      # APAR_Dir is not part of Sim because it can be easily computed by Met_c.PARm2d1-Sim.APAR_Dif
      Sim.APAR[i]= APAR_Dir + Sim.APAR_Dif[i]
      Sim.PAR_Trans[i]= Sim.PAR_Trans_Tree[i] - Sim.APAR[i] # PAR above soil layer
  
      # soil (+canopy evap) water balance ---------------------------------------
  
        # Metamodel Coffee leaf water potential
      Sim.LeafWaterPotential[i]= Base.invokelatest(Parameters.LeafWaterPotential,Sim,Met_c,i)
      # Transpiration Coffee
      Sim.T_Coffee[i]= Base.invokelatest(Parameters.T_Coffee,Sim,Met_c,i)
      Sim.H_Coffee[i]= Base.invokelatest(Parameters.H_Coffee,Sim,Met_c,i)
  
      # Tcanopy Coffee : using bulk conductance if no trees, interlayer conductance if trees
      # Source: Van de Griend and Van Boxel 1989.
      if Sim.Height_Tree[i] > Parameters.Height_Coffee
  
        Sim.TairCanopy[i]= Sim.TairCanopy_Tree[i] + ((Sim.H_Coffee[i] + Sim.H_Soil[i]) * Parameters.MJ_to_W) / 
          (air_density(Sim.TairCanopy_Tree[i],Met_c.Pressure[i] / 10.0) *  Parameters.cp * 
             G_interlay(Wind= Met_c.WindSpeed[i], ZHT = Parameters.ZHT, LAI_top= Sim.LAI_Tree[i], LAI_bot= Sim.LAI[i],
                        Z_top= Sim.Height_Tree[i], extwind = Parameters.extwind))
        Sim.Tleaf_Coffee[i]= Sim.TairCanopy[i] + (Sim.H_Coffee[i] * Parameters.MJ_to_W) / 
          (air_density(Sim.TairCanopy[i],Met_c.Pressure[i] / 10.0) *  Parameters.cp * 
             Gb_h(Wind = Met_c.WindSpeed[i], wleaf= Parameters.wleaf, LAI_lay=Sim.LAI[i], LAI_abv=Sim.LAI_Tree[i],
                  ZHT = Parameters.ZHT, Z_top = Sim.Height_Tree[i], extwind= Parameters.extwind))
  
      else
  
        Sim.TairCanopy[i]= Met_c.Tair[i] + ((Sim.H_Coffee[i] + Sim.H_Soil[i]) * Parameters.MJ_to_W) / 
          (air_density(Met_c.Tair[i], Met_c.Pressure[i] / 10.0) *  Parameters.cp * 
             G_bulk(Wind = Met_c.WindSpeed[i], ZHT = Parameters.ZHT, Z_top = Parameters.Height_Coffee,
                    LAI = Sim.LAI[i], extwind = Parameters.extwind))
  
        Sim.Tleaf_Coffee[i]= Sim.TairCanopy[i]+(Sim.H_Coffee[i] * Parameters.MJ_to_W) / 
          (air_density(Sim.TairCanopy[i], Met_c.Pressure[i] / 10.0) *  Parameters.cp  * 
             Gb_h(Wind= Met_c.WindSpeed[i], wleaf= Parameters.wleaf, LAI_lay= Sim.LAI[i], LAI_abv= Sim.LAI_Tree[i],
                  ZHT= Parameters.ZHT, Z_top= Parameters.Height_Coffee, extwind= Parameters.extwind))
      end
      # NB: if no trees, TairCanopy_Tree= Tair
  
      # Recomputing soil temperature knowing TairCanopy
  
      Sim.TSoil[i]= Sim.TairCanopy[i]+(Sim.H_Soil[i] * Parameters.MJ_to_W) / 
        (air_density(Sim.TairCanopy[i], Met_c.Pressure[i] / 10.0) *  Parameters.cp * 
           G_soilcan(Wind= Met_c.WindSpeed[i], ZHT=Parameters.ZHT, Z_top= max(Sim.Height_Tree[i], Parameters.Height_Coffee),
                     LAI = Sim.LAI_Tree[i] + Sim.LAI[i], extwind= Parameters.extwind))
  
      Sim.DegreeDays_Tcan[i]= GDD(Sim.Tleaf_Coffee[i], Parameters.MinTT, Parameters.MaxTT)
      
      # Metamodel LUE coffee:
      Sim.lue[i]= Base.invokelatest(Parameters.lue,Sim,Met_c,i)
  
      #GPP Coffee
      Sim.GPP[i]= Sim.lue[i] * Sim.APAR[i]
  
      # Maintenance respiration -------------------------------------------------
  
      # Rm is computed at the beginning of the day on the drymass of the previous day.
      # This is considered as the highest priority for the plant (to maintain its dry mass)
  
      after_2= i <= 2 ? 0 : 1 # used to start respiration after two days so there are some dry mass.
      # Resprout (branches) wood:
      Sim.Rm_Shoot[i]=  after_2 * (Parameters.pa_Shoot * Sim.DM_Shoot[previous_i(i)] * Parameters.NC_Shoot * 
                        Parameters.MRN *  Parameters.Q10_Shoot^((Sim.TairCanopy[i] - Parameters.TMR) / 10.0))
  
      # Stump and Coarse roots (perennial wood):
      Sim.Rm_SCR[i]= after_2 *  (Parameters.pa_SCR * Sim.DM_SCR[previous_i(i)] *  Parameters.NC_SCR * Parameters.MRN * 
           Parameters.Q10_SCR^((Sim.TairCanopy[i] - Parameters.TMR) / 10.0))
  
      # Fruits:
      Sim.Rm_Fruit[i]= after_2 * (Parameters.pa_Fruit * Sim.DM_Fruit[previous_i(i)] *  Parameters.NC_Fruit * Parameters.MRN * 
           Parameters.Q10_Fruit^((Sim.TairCanopy[i] - Parameters.TMR) / 10.0))
  
      # Leaves:
      Sim.Rm_Leaf[i]= after_2 * (Parameters.pa_Leaf * Sim.DM_Leaf[previous_i(i)] * Parameters.NC_Leaf * Parameters.MRN * 
           Parameters.Q10_Leaf^((Sim.TairCanopy[i] - Parameters.TMR) / 10.0))
  
      # Fine roots:
      Sim.Rm_FRoot[i]= after_2 * (Parameters.pa_FRoot * Sim.DM_FRoot[previous_i(i)] * Parameters.NC_FRoot * Parameters.MRN * 
           Parameters.Q10_FRoot^((Sim.TairCanopy[i] - Parameters.TMR) / 10.0))
  
      # Total plant maintenance respiration
      Sim.Rm[i]= Sim.Rm_Fruit[i] + Sim.Rm_Leaf[i] + Sim.Rm_Shoot[i] + Sim.Rm_SCR[i] + Sim.Rm_FRoot[i]
  
  
      # Coffee Allocation -------------------------------------------------------
  
      # Potential use of reserves:
      Sim.Consumption_RE[i]= Parameters.kres * Sim.CM_RE[previous_i(i)]
  
      # Supply function
      Sim.Supply[i]= max(Sim.GPP[i] - Sim.Rm[i] + Sim.Consumption_RE[i], 0.0)
  
      # If the respiration is greater than the GPP + reserves use, then take this carbon
      # from mortality of each compartments' biomass equally (not for fruits or reserves):
      Sim.Carbon_Lack_Mortality[i]= -min(0.0, Sim.GPP[i] - Sim.Rm[i] + Sim.Consumption_RE[i])
  
      # 1-Resprout wood ---------------------------------------------------------
      # Allocation priority 1, see Charbonnier 2012.
      Sim.Alloc_Shoot[i]= Parameters.lambda_Shoot * Sim.Supply[i]
      Sim.NPP_Shoot[i]= Sim.Alloc_Shoot[i] / Parameters.epsilon_Shoot
      Sim.Rg_Shoot[i]= Sim.Alloc_Shoot[i] - Sim.NPP_Shoot[i]
      Sim.Mnat_Shoot[i]= Sim.CM_Shoot[previous_i(i)] / Parameters.lifespan_Shoot
      # Pruning
      if (Sim.Plot_Age[i] >= Parameters.MeanAgePruning) & (Met_c.DOY[i] == Parameters.D_pruning)
        Sim.Mprun_Shoot[i]= Sim.CM_Shoot[previous_i(i)] * Parameters.WoodPruningRate
      end
  
      Sim.Mortality_Shoot[i]= min((Sim.Mnat_Shoot[i] + Sim.Mprun_Shoot[i]), Sim.CM_Shoot[previous_i(i)])
  
      # 2-Stump and coarse roots (perennial wood) ------------------------------
      Sim.Alloc_SCR[i]= Parameters.lambda_SCR * Sim.Supply[i]
      Sim.NPP_SCR[i]= Sim.Alloc_SCR[i] / Parameters.epsilon_SCR
      Sim.Rg_SCR[i]= Sim.Alloc_SCR[i] - Sim.NPP_SCR[i]
      Sim.Mnat_SCR[i]= Sim.CM_SCR[previous_i(i)] / Parameters.lifespan_SCR
      Sim.Mortality_SCR[i]= Sim.Mnat_SCR[i]
  
      # Ratio of number of new nodes per LAI unit as affected by canopy air temperature
      # according to Drinnan & Menzel, 1995
      # Source "0 Effect T on yield and vegetative growth.xlsx", sheet
      # "Std20dComposWinterNodeperBr"
      # NB: computed at the end of the vegetatitve growth only to have Tcan of the
      # whole period already computed
      # NB2 : This is the total number of productive nodes on the coffee plant, i.e. the
      # number of green wood nodes that potentially carry flower buds. Green wood mass (and
      # so number of nodes) are related to leaf area (new leaves appear on nodes) :
      # GUTIERREZ et al. (1998)
      if Met_c.DOY[i] == Parameters.DVG2
        T_VG= Sim.Tleaf_Coffee[(Met_c.year .== Met_c.year[i]) .& (Met_c.DOY .>= Parameters.DVG1) .& (Met_c.DOY .<= Parameters.DVG2)]
        T_VG= sum(T_VG)/length(T_VG)
        Sim.ratioNodestoLAI[Met_c.year .>= Met_c.year[i]] .= Parameters.RNL_base * CN(T_VG)
      end
  
      # Flower Buds + Flower + Fruits -------------------------------------------
  
      # (1) Buds induction
      # Buds start appearing for the very first time from 5500 dd. After that,
      # they appear every "Parameters.F_Tffb" degree days until flowering starts
      if Sim.BudInitPeriod[i]
        Sim.Budinit[i]= (Parameters.a_bud+Parameters.b_bud * (Sim.PAR_Trans_Tree[i] / Parameters.FPAR)) *
                         Sim.LAI[i-1] * Sim.ratioNodestoLAI[i-1] * Sim.DegreeDays_Tcan[i]
        # NB: Number of nodes= Sim.LAI[i-1] * Sim.ratioNodestoLAI[i-1]
        Sim.Bud_available[i]= Sim.Budinit[i]
      end
      # NB: number of fruits ~1200  /  year  /  coffee tree, source : Castro-Tanzi et al. (2014)
      # Sim%>%group_by(Plot_Age)%>%summarise(N_Flowers= sum(BudBreak))
  
      # (2) Cumulative degree days experienced by each bud cohort :
      dd_i= cumsum(Sim.DegreeDays_Tcan[i:-1:previous_i(i,1000)])
      
      # (3) Find the window where buds are under dormancy (find the dormant cohorts)
      # Bud develops during F_buds1 (840) degree days after initiation, so they cannot
      # be dormant less than F_buds1 before i. But they can stay under dormancy until
      # F_buds2 dd maximum, so they cannot be older than F_buds2 dd before i.
      
      OldestDormancy= i - (maximum(findall(dd_i .< Parameters.F_buds2)) - 1)
      YoungestDormancy= i - (maximum(findall(dd_i .< Parameters.F_buds1)) - 1)
      # Idem above (reduce the days computed, F_buds2 is ~300 days and F_buds1 ~80-100 days)
  
      # (4) Test if the condition of minimum required rain for budbreak is met, and if
      # not, which cohort first met the condition (starting from younger to older cohorts):
      CumRain= cumsum(Met_c.Rain[YoungestDormancy:-1:OldestDormancy])
      # (5) Compute the period were all cohorts have encountered all conditions to break
      # dormancy :
      DormancyBreakPeriod= OldestDormancy:(YoungestDormancy - sum(CumRain .< Parameters.F_rain))
  
      # (6) Temperature effect on bud phenology
      Sim.Temp_cor_Bud[i]= Base.invokelatest(Parameters.Bud_T_correction)(Sim.Tleaf_Coffee[i])
      
      # (7) Bud dormancy break, Source, Drinnan 1992 and Rodriguez et al., 2011 eq. 13
      Sim.pbreak[i]= 1.0 / (1.0 + exp(Parameters.a_p + Parameters.b_p * Sim.LeafWaterPotential[i]))
      # (8) Compute the number of buds that effectively break dormancy in each cohort:
      Sim.BudBreak_cohort[DormancyBreakPeriod] .=
          map(min, Sim.Bud_available[DormancyBreakPeriod], 
                   Sim.Budinit[DormancyBreakPeriod] .* Sim.pbreak[i] .* Sim.Temp_cor_Bud[DormancyBreakPeriod])
      # NB 1: cannot exceed the number of buds of each cohort
      # NB 2: using Budinit and not Bud_available because pbreak is fitted on total bud cohort
  
      # (9) Remove buds that did break dormancy from the pool of dormant buds
      Sim.Bud_available[DormancyBreakPeriod]= Sim.Bud_available[DormancyBreakPeriod] .- Sim.BudBreak_cohort[DormancyBreakPeriod]
  
      # (10) Sum the buds that break dormancy from each cohort to compute the total number
      # of buds that break dormancy on day i :
      Sim.BudBreak[i]= min(sum(Sim.BudBreak_cohort[DormancyBreakPeriod]),Parameters.Max_Bud_Break)
      # Rodriguez et al. state that the maximum number of buds that may break dormancy
      # during each dormancy-terminating episode was set to 12 (see Table 1).
  
      # Fruits :
      FruitingPeriod= i .- findall(dd_i .< Parameters.F_over) .+ 1
      # NB : Fruits that are older than the FruitingPeriod are overripped
  
      # Demand from each fruits cohort present on the coffee tree (not overriped),
      # same as Demand_Fruit but keeping each value :
      demand_distribution= logistic_deriv.(dd_i[1:length(FruitingPeriod)], Parameters.u_log, Parameters.s_log) .*
                           [0.0 ; Base.diff(dd_i[1:length(FruitingPeriod)])]
      # NB: we use diff because the values are not evenly distributed (it is not grided, e.g. not 1 by 1 increment)
      demand_distribution[demand_distribution .== Inf] .= 0.0
      Demand_Fruit_Cohort_Period = Sim.BudBreak[FruitingPeriod] .* Parameters.DE_opt .* demand_distribution
      # Total C demand of the fruits :
      Sim.Demand_Fruit[i]= sum(Demand_Fruit_Cohort_Period)
      # C supply to Fruits (i.e. what is left from Supply after removing the consumption
      # by previous compartments and Rm):
      Sim.Supply_Fruit[i]= Sim.Supply[i] - Sim.Alloc_Shoot[i] - Sim.Alloc_SCR[i]
  
      # Total C allocation to all fruits on day i :
      Sim.Alloc_Fruit[i]= min(Sim.Demand_Fruit[i], Sim.Supply_Fruit[i])
      # Allocation to each cohort, relative to each cohort demand :
      if Sim.Demand_Fruit[i] > 0.0
        Rel_DE= Demand_Fruit_Cohort_Period ./ Sim.Demand_Fruit[i]
      else
        Rel_DE= 0.0
      end
      Sim.Alloc_Fruit_Cohort[FruitingPeriod] .= Sim.Alloc_Fruit[i] .* Rel_DE
      Sim.NPP_Fruit_Cohort[FruitingPeriod] .= Sim.Alloc_Fruit_Cohort[FruitingPeriod] ./ Parameters.epsilon_Fruit
      Sim.CM_Fruit_Cohort[FruitingPeriod] .= Sim.CM_Fruit_Cohort[FruitingPeriod] .+ Sim.NPP_Fruit_Cohort[FruitingPeriod]
      Sim.DM_Fruit_Cohort[FruitingPeriod] .= Sim.CM_Fruit_Cohort[FruitingPeriod] ./ Parameters.CC_Fruit
      # Overriped fruits that fall onto the ground (= to mass of the cohort that overripe) :
      Sim.Overriped_Fruit[i]= Sim.CM_Fruit_Cohort[max(minimum(FruitingPeriod) - 1, 1)]
      # Sim.Overriped_Fruit[i]= Sim.CM_Fruit_Cohort[minimum(FruitingPeriod)-1.0] * Parameters.epsilon_Fruit
      # Duration of the maturation of each cohort born in the ith day (in days):
      Sim.Maturation_duration[FruitingPeriod] .= 1:length(FruitingPeriod)
      # Sucrose content of each cohort:
      Sim.SC[FruitingPeriod] .= Sucrose_cont_perc.(Sim.Maturation_duration[FruitingPeriod], Parameters.S_a, Parameters.S_b,
                                                   Parameters.S_x0, Parameters.S_y0)
      # Sucrose mass of each cohort
      Sim.SM[FruitingPeriod] .= Sim.DM_Fruit_Cohort[FruitingPeriod] .* Sim.SC[FruitingPeriod]
      # Harvest maturity:
      Sim.Harvest_Maturity_Pot[i]= sum(Sim.SM[FruitingPeriod]) / sum(Sim.DM_Fruit_Cohort[FruitingPeriod] .* ((Parameters.S_y0 .+ Parameters.S_a) ./ 100.0))
      # NB : here harvest maturity is computed as the average maturity of the cohorts, because
      # all cohorts present in the Coffea are within the 'FruitingPeriod' window.
      # It could be computed as the percentage of cohorts that are fully mature (Pezzopane
      # et al. 2012 say at 221 days after flowering)
      # Optimal sucrose concentration around 8.8% of the dry mass
  
      Sim.NPP_Fruit[i]= Sim.Alloc_Fruit[i] / Parameters.epsilon_Fruit
      Sim.Rg_Fruit[i]= Sim.Alloc_Fruit[i] - Sim.NPP_Fruit[i]
  
      # Harvest. Made one day only for now (TODO: make it a period of harvest)
  
      if Parameters.harvest == "quantity"
        is_harvest= (Sim.Plot_Age[i] >= Parameters.ageMaturity) & 
                    all(Sim.NPP_Fruit[previous_i.(i,0:10)] .< Sim.Overriped_Fruit[previous_i.(i,0:10)]) &
                    (Sim.CM_Fruit[previous_i(i)] > Parameters.Min_Fruit_CM)
        # Made as soon as the fruit dry mass is decreasing for 10 consecutive days.
        # This condition is met when fruit overriping is more important than fruit NPP
        # for 10 days.
        # This option is the best one when fruit maturation is not well known or when the
        # harvest is made throughout several days or weeks with the assumption that fruits
        # are harvested when mature.
      else
        is_harvest= (Sim.Plot_Age[i]>=Parameters.ageMaturity) &
                    (mean(Sim.Harvest_Maturity_Pot[previous_i.(i,0:9)]) < mean(Sim.Harvest_Maturity_Pot[previous_i.(i,10:19)]))
        # Made as soon as the overall fruit maturation is optimal (all fruits are mature)
      end
  
      if is_harvest
        # Save the date of harvest:
        Sim.Date_harvest[i]= Met_c.DOY[i]
        Sim.Harvest_Fruit[i]= Sim.CM_Fruit[i-1] + Sim.NPP_Fruit[i] - Sim.Overriped_Fruit[i]
        Sim.Harvest_Maturity[i]= Sim.Harvest_Maturity_Pot[i]
        Sim.CM_Fruit[i-1]= 0.0
        Sim.NPP_Fruit[i]= 0.0
        Sim.Overriped_Fruit[i]= 0.0
        Sim.CM_Fruit_Cohort .= zeros(nrow(Sim))
        # RV: could harvest mature fruits only (To do).
      else
        Sim.Harvest_Fruit[i]= 0.0
      end
  
      # Leaves ------------------------------------------------------------------
  
      Sim.Supply_Leaf[i]= Parameters.lambda_Leaf_remain * (Sim.Supply[i] - Sim.Alloc_Fruit[i] - Sim.Alloc_Shoot[i] - Sim.Alloc_SCR[i])
  
      Sim.Alloc_Leaf[i]= min(Parameters.DELM * (Parameters.Stocking_Coffee / 10000.0) * ((Parameters.LAI_max - Sim.LAI[i]) /
                              (Sim.LAI[i] + Parameters.LAI_max)), 
                             Sim.Supply_Leaf[i])
  
      Sim.NPP_Leaf[i]= Sim.Alloc_Leaf[i] / Parameters.epsilon_Leaf
      Sim.Rg_Leaf[i]= Sim.Alloc_Leaf[i] - Sim.NPP_Leaf[i]
      Sim.Mnat_Leaf[i]= Sim.CM_Leaf[previous_i(i)] / Parameters.lifespan_Leaf
      Sim.NPP_RE[i]= Sim.NPP_RE[i] + (Sim.Supply_Leaf[i] - Sim.Alloc_Leaf[i])
  
      Sim.M_ALS[i]= after_2 * max(0.0, Sim.CM_Leaf[previous_i(i)] * Sim.ALS[i])
  
      if (Sim.Plot_Age[i]>= Parameters.MeanAgePruning) & (Met_c.DOY[i] == Parameters.D_pruning)
        Sim.Mprun_Leaf[i]= Sim.CM_Leaf[previous_i(i)] * Parameters.LeafPruningRate
      else
        Sim.Mprun_Leaf[i]= 0.0
      end
  
      Sim.Mortality_Leaf[i]= Sim.Mnat_Leaf[i] + Sim.Mprun_Leaf[i] + Sim.M_ALS[i]
  
      # Fine Roots --------------------------------------------------------------
  
      Sim.Supply_FRoot[i]= Parameters.lambda_FRoot_remain * (Sim.Supply[i] - Sim.Alloc_Fruit[i] - Sim.Alloc_Shoot[i] - Sim.Alloc_SCR[i])
      Sim.Alloc_FRoot[i]=max(0.0, min(Sim.Alloc_Leaf[i], Sim.Supply_FRoot[i]))
      Sim.NPP_FRoot[i]= Sim.Alloc_FRoot[i] / Parameters.epsilon_FRoot
      Sim.Rg_FRoot[i]= Sim.Alloc_FRoot[i] - Sim.NPP_FRoot[i]
      Sim.NPP_RE[i]= Sim.NPP_RE[i] + (Sim.Supply_FRoot[i] - Sim.Alloc_FRoot[i])
      Sim.Mnat_FRoot[i]= Sim.CM_FRoot[previous_i(i)] / Parameters.lifespan_FRoot
      Sim.Mprun_FRoot[i]= Parameters.m_FRoot * Sim.Mprun_Leaf[i]
      Sim.Mortality_FRoot[i]= Sim.Mnat_FRoot[i] + Sim.Mprun_FRoot[i]
  
      # Biomass -----------------------------------------------------------------
  
      CM_tot= Sim.CM_Leaf[previous_i(i)] + Sim.CM_Shoot[previous_i(i)] + Sim.CM_SCR[previous_i(i)] + Sim.CM_FRoot[previous_i(i)]
  
      Sim.CM_Leaf[i]= Sim.CM_Leaf[previous_i(i)] + Sim.NPP_Leaf[i] - Sim.Mortality_Leaf[i] - 
                      Sim.Carbon_Lack_Mortality[i] * Sim.CM_Leaf[previous_i(i)] / CM_tot
      Sim.CM_Shoot[i]= Sim.CM_Shoot[previous_i(i)] + Sim.NPP_Shoot[i]-Sim.Mortality_Shoot[i] -
                       Sim.Carbon_Lack_Mortality[i] * Sim.CM_Shoot[previous_i(i)] / CM_tot
      Sim.CM_Fruit[i]= Sim.CM_Fruit[previous_i(i)]+ Sim.NPP_Fruit[i] - Sim.Overriped_Fruit[i]
      Sim.CM_SCR[i]= Sim.CM_SCR[previous_i(i)] + Sim.NPP_SCR[i] - Sim.Mortality_SCR[i] -
                     Sim.Carbon_Lack_Mortality[i] * Sim.CM_SCR[previous_i(i)] / CM_tot
      Sim.CM_FRoot[i]= Sim.CM_FRoot[previous_i(i)] + Sim.NPP_FRoot[i] - Sim.Mortality_FRoot[i] -
                       Sim.Carbon_Lack_Mortality[i] * Sim.CM_FRoot[previous_i(i)] / CM_tot
      Sim.CM_RE[i]= Sim.CM_RE[previous_i(i)] + Sim.NPP_RE[i] - Sim.Consumption_RE[i]
  
      Sim.DM_Leaf[i]= Sim.CM_Leaf[i] / Parameters.CC_Leaf
      Sim.DM_Shoot[i]= Sim.CM_Shoot[i] / Parameters.CC_Shoot
      Sim.DM_Fruit[i]= Sim.CM_Fruit[i] / Parameters.CC_Fruit
      Sim.DM_SCR[i]= Sim.CM_SCR[i] / Parameters.CC_SCR
      Sim.DM_FRoot[i]= Sim.CM_FRoot[i] / Parameters.CC_FRoots
      Sim.DM_RE[i]=Sim.CM_RE[i] / Parameters.CC_SCR
  
      # Total Respiration and NPP -----------------------------------------------
  
      Sim.Rg[i]= Sim.Rg_Fruit[i] + Sim.Rg_Leaf[i] + Sim.Rg_Shoot[i]+Sim.Rg_SCR[i] + Sim.Rg_FRoot[i]
      Sim.Ra[i]=Sim.Rm[i] + Sim.Rg[i]
      Sim.NPP[i]= Sim.NPP_Shoot[i] + Sim.NPP_SCR[i] + Sim.NPP_Fruit[i] + Sim.NPP_Leaf[i] + Sim.NPP_FRoot[i]  
end