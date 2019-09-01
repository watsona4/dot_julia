
"""
Initialise model variables.

# Arguments 
- `Sim::DataFrame`: The simulation DataFrame
- `Met_c::DataFrame`: The meteorology DataFrame
- `Parameters`: The parameters for the model
"""
function initialise!(Sim::DataFrame,Met_c::DataFrame,Parameters)
    Sim.LAI= 0.1
    Sim.LAIplot= 0.0
    #Leaf Area per Plant location, to convert per ha using density,cannot be zero at beginning,
    # otherwise, GPP does not start and nothing grows
    Sim.PAR_Trans= 0.0
    Sim.CM_RE= 0.0
    Sim.Rm= 0.0
    Sim.CM_SCR= 0.0
    Sim.Demand_Fruit= 0.0
    Sim.CM_Fruit= 0.0
    Sim.SM= 0.0
    Sim.Harvest_Maturity= 0.0
    Sim.CM_FRoot= 0.0
    Sim.CM_Shoot= 0.0
    Sim.CM_Leaf= 1.0
  
    Sim.DM_Leaf= 0.0
    Sim.DM_FRoot= 0.0
    Sim.DM_Shoot= 0.0
    Sim.DM_Fruit= 0.0
    Sim.DM_SCR= 0.0
    Sim.DM_Fruit_Cohort= 0.0
    Sim.DM_RE= 0.0
    Sim.Mact_SCR= 0.0
    Sim.Mnat_SCR= 0.0
    Sim.Mprun_Shoot= 0.0
    Sim.DegreeDays_Tcan= 0.0
    Sim.pbreak= 0.0
    Sim.Budinit= 0.0
    Sim.BudBreak= 0.0
    Sim.Bud_available= 0.0
    Sim.BudBreak_cohort= 0.0
    Sim.Alloc_Fruit_Cohort= 0.0
    Sim.NPP_Fruit_Cohort= 0.0
    Sim.CM_Fruit_Cohort= 0.0
    Sim.Maturation_duration= 0.0
    Sim.SC= 0.0
    Sim.Temp_cor_Bud= 1.0
  
  
    Sim.Tcan_Diurnal_Cof_deg= 0.0
    Sim.NPP_RE= 0.0
    Sim.lue= 0.0
    Sim.GPP= 0.0
    Sim.K_Dif= 0.0
    Sim.K_Dir= 0.0
    Sim.Consumption_RE= 0.0
    Sim.Supply= 0.0
    Sim.Carbon_Lack_Mortality= 0.0
    Sim.Alloc_Shoot= 0.0
    Sim.NPP_Shoot= 0.0
    Sim.Rg_Shoot= 0.0
    Sim.Mnat_Shoot= 0.0
    Sim.Mortality_Shoot= 0.0
    Sim.Rm_Shoot= 0.0
    Sim.lambdaSCRage= 0.0
    Sim.Alloc_SCR= 0.0
    Sim.NPP_SCR= 0.0
    Sim.Rg_SCR= 0.0
    Sim.Rm_SCR= 0.0
    Sim.Mortality_SCR= 0.0
    Sim.Harvest_Maturity_Pot= 0.0
    Sim.ratioNodestoLAI= 0.0
    Sim.Supply_Fruit= 0.0
    Sim.Alloc_Fruit= 0.0
    Sim.Overriped_Fruit= 0.0
    Sim.NPP_Fruit= 0.0
    Sim.Rg_Fruit= 0.0
    Sim.Harvest_Fruit= 0.0
    Sim.Rm_Fruit= 0.0
    Sim.Supply_Leaf= 0.0
    Sim.Alloc_Leaf= 0.0
    Sim.NPP_Leaf= 0.0
    Sim.Rg_Leaf= 0.0
    Sim.Mnat_Leaf= 0.0
    Sim.M_ALS= 0.0
    Sim.MnatALS_Leaf= 0.0
    Sim.Mprun_Leaf= 0.0
    Sim.Mortality_Leaf= 0.0
    Sim.Rm_Leaf= 0.0
    Sim.Demand_FRoot= 0.0
    Sim.Supply_FRoot= 0.0
    Sim.Alloc_FRoot= 0.0
    Sim.NPP_FRoot= 0.0
    Sim.Rg_FRoot= 0.0
    Sim.Mnat_FRoot= 0.0
    Sim.Mprun_FRoot= 0.0
    Sim.Mortality_FRoot= 0.0
    Sim.Rm_FRoot= 0.0
    Sim.Rg= 0.0
    Sim.Ra= 0.0
    Sim.NPP= 0.0
    Sim.Cbalance= 0.0
    Sim.BudInitPeriod= false
    Sim.Rn_tot= 0.0
    Sim.Date_harvest= 0

    Sim.Throughfall= 0.0
    Sim.IntercRevapor= 0.0
    Sim.ExcessRunoff= 0.0
    Sim.SuperficialRunoff= 0.0
    Sim.TotSuperficialRunoff= 0.0
    Sim.InfilCapa= 0.0
    Sim.Infiltration= 0.0
    Sim.Drain_1= 0.0
    Sim.Drain_2= 0.0
    Sim.Drain_3= 0.0
    Sim.EW_1= 0.0
    Sim.REW_1= 0.0
    Sim.EW_2= 0.0
    Sim.REW_2= 0.0
    Sim.EW_3= 0.0
    Sim.REW_3= 0.0
    Sim.EW_tot= 0.0
    Sim.REW_tot= 0.0
    Sim.E_Soil= 0.0
    Sim.LE_Plot= 0.0
    Sim.LE_Soil= 0.0
    Sim.H_Soil= 0.0
    Sim.Q_Soil= 0.0
    Sim.Rn_Soil= 0.0
    Sim.LE_Tree= 0.0
    Sim.H_tot= 0.0
    Sim.LE_tot= 0.0
    Sim.Diff_T= 0.0
    Sim.Tleaf_Coffee= 0.0
    Sim.WindSpeed_Coffee= 0.0
    Sim.TairCanopy= 0.0
    Sim.APAR_Dif= 0.0
    Sim.APAR= 0.0
    Sim.PAR_Soil= 0.0
    Sim.SoilWaterPot= 0.0
    Sim.LeafWaterPotential= 0.0
    Sim.AEu= 0.0
    Sim.IntercMax= 0.0
    Sim.T_Coffee= 0.0
    Sim.T_tot= 0.0
    Sim.RootWaterExtract_1= 0.0
    Sim.RootWaterExtract_2= 0.0
    Sim.RootWaterExtract_3= 0.0
    Sim.ETR= 0.0
    Sim.SWD= 0.0
    Sim.H_Coffee= 0.0
    Sim.Rn_Coffee= 0.0
    Sim.LE_Coffee= 0.0
    Sim.Rn_Soil_SW= 0.0  
    Sim.TSoil= 0.0
    Sim.W_1= 290.0
    Sim.W_2= 66.0
    Sim.W_3= 69.0
    Sim.W_tot= Sim.W_1+Sim.W_2+Sim.W_3
  
    Sim.CanopyHumect= 0.0
    Sim.WSurfaceRes= 0.0
  
    if Parameters.Tree_Species == "No_Shade"
        Tree_init_no_shade!(Sim)
    else
        Tree_init!(Sim,Met_c,Parameters)
    end
end


function Tree_init_no_shade!(Sim)
    # NB: if Tree_Species is NULL (i.e. no shade trees), then do not add
    # any trees related variables to the main table, except for the few ones
    # needed in-code (e.g. Tree Height for GBCANMS):
    # Shade tree layer computations (common for all species)
    # Should output at least APAR_Tree, LAI_Tree, T_Tree, Rn_Tree, H_Tree,
    # LE_Tree (sum of transpiration + leaf evap)
    # And via allometries: Height_Tree for canopy boundary layer conductance
    Sim.LAI_Tree= 0.0
    Sim.APAR_Tree= 0.0
    Sim.T_Tree= 0.0
    Sim.Rn_Tree= 0.0
    Sim.H_Tree= 0.0
    Sim.LE_Tree= 0.0
    Sim.Height_Tree= 0.0
    Sim.TairCanopy_Tree= 0.0
    Sim.PAR_Trans_Tree= 0.0
end



function Tree_init!(Sim,Met_c,Parameters)
    # Initialisation of Shade tree variables:
    Sim.CM_Leaf_Tree= 0.01
    Sim.CM_Stem_Tree= 0.01
    Sim.CM_Branch_Tree= 0.01
    Sim.CM_FRoot_Tree= 0.01
    Sim.CM_CR_Tree= 0.01
    Sim.CM_RE_Tree= 0.15
  
    Sim.LAI_Tree= Sim.CM_Leaf_Tree .* (Parameters.SLA_Tree ./ 1000.0) ./ Parameters.CC_Leaf_Tree
  
    Sim.Trunk_H_Tree= 0.0
    Sim.Crown_H_Tree= 0.0
    Sim.Height_Tree= 0.0
    Sim.Height_Tree[1]= 0.001 # because G_bulk doesn't allow heights of 0

    Sim.LA_Tree= 0.0
    Sim.DM_Leaf_Tree= 0.0
    Sim.DM_Branch_Tree= 0.0
    Sim.DM_Stem_Tree= 0.0
    Sim.DM_CR_Tree= 0.0
    Sim.DM_FRoot_Tree= 0.0
    Sim.DM_Stem_FGM_Tree= 0.0
    Sim.DM_RE_Tree= 0.0
    Sim.Mprun_Branch_Tree= 0.0
    Sim.Mprun_FRoot_Tree= 0.0
    Sim.Mprun_Leaf_Tree= 0.0
    Sim.Mact_Stem_Tree= 0.0
    Sim.Mact_CR_Tree= 0.0
    Sim.Rm_Tree= 0.0
    Sim.DBH_Tree= 0.0
    Sim.Crown_H_Tree= 0.0
    Sim.CrownProj_Tree= 0.0
    Sim.LAD_Tree= 0.0
    Sim.K_Dif_Tree= 0.0
    Sim.K_Dir_Tree= 0.0
    Sim.APAR_Dif_Tree= 0.0
    Sim.APAR_Dir_Tree= 0.0
    Sim.APAR_Tree= 0.0
    Sim.Transmittance_Tree= 0.0
    Sim.PAR_Trans_Tree= 0.0
    Sim.lue_Tree= 0.0
    Sim.T_Tree= 0.0
    Sim.H_Tree= 0.0
    Sim.Tleaf_Tree= 0.0
    Sim.GPP_Tree= 0.0
    Sim.Rm_Leaf_Tree= 0.0
    Sim.Rm_CR_Tree= 0.0
    Sim.Rm_Branch_Tree= 0.0
    Sim.Rm_Stem_Tree= 0.0
    Sim.Rm_FRoot_Tree= 0.0
    Sim.Supply_Total_Tree= 0.0
    Sim.Alloc_Stem_Tree= 0.0
    Sim.NPP_Stem_Tree= 0.0
    Sim.Rg_Stem_Tree= 0.0
    Sim.Alloc_CR_Tree= 0.0
    Sim.NPP_CR_Tree= 0.0
    Sim.Rg_CR_Tree= 0.0
    Sim.Alloc_Branch_Tree= 0.0
    Sim.NPP_Branch_Tree= 0.0
    Sim.Rg_Branch_Tree= 0.0
    Sim.Mact_Branch_Tree= 0.0
    Sim.Alloc_Leaf_Tree= 0.0
    Sim.NPP_Leaf_Tree= 0.0
    Sim.Rg_Leaf_Tree= 0.0
    Sim.Mact_Leaf_Tree= 0.0
    Sim.Alloc_FRoot_Tree= 0.0
    Sim.NPP_FRoot_Tree= 0.0
    Sim.Rg_FRoot_Tree= 0.0
    Sim.Mact_FRoot_Tree= 0.0
    Sim.Alloc_RE_Tree= 0.0
    Sim.Rg_RE_Tree= 0.0
    Sim.M_Rm_Stem_Tree= 0.0
    Sim.M_Rm_CR_Tree= 0.0
    Sim.M_Rm_Branch_Tree= 0.0
    Sim.M_Rm_Leaf_Tree= 0.0
    Sim.M_Rm_FRoot_Tree= 0.0
    Sim.M_Rm_RE_Tree= 0.0
    Sim.Mortality_Leaf_Tree= 0.0
    Sim.Mortality_Branch_Tree= 0.0
    Sim.Mortality_Stem_Tree= 0.0
    Sim.Mortality_CR_Tree= 0.0
    Sim.Mortality_FRoot_Tree= 0.0
    Sim.Rg_Tree= 0.0
    Sim.Ra_Tree= 0.0
    Sim.DeltaCM__Tree= 0.0
    Sim.NPP_Tree= 0.0
    Sim.Cbalance_Tree= 0.0
    Sim.CrownRad_Tree= 0.0
    Sim.NPP_RE_Tree= 0.0
    Sim.Consumption_RE_Tree= 0.0
    Sim.MThinning_Stem_Tree= 0.0
    Sim.MThinning_CR_Tree= 0.0
    Sim.MThinning_Branch_Tree= 0.0
    Sim.MThinning_Leaf_Tree= 0.0
    Sim.MThinning_FRoot_Tree= 0.0
    Sim.Rn_Tree= 0.0
    Sim.H_Tree= 0.0
    Sim.Rn_tot= 0.0
    Sim.Rn_Tree= 0.0
    
    # Pre-computation of some variables / parameters:
    Sim.Stocking_Tree= Parameters.StockingTree_treeha1 / 10000.0
     
    Sim.TimetoFall_Tree= false
    Sim.TimetoFall_Tree[findall(x -> x in Parameters.Fall_Period_Tree, Met_c.DOY)] .= true
    Sim.TimetoFall_Tree[Sim.Plot_Age .< 1] .= false
      
    Sim.TimetoThin_Tree= false
    Sim.TimetoThin_Tree[intersect(findall(x -> x in Parameters.Thin_Age_Tree, Sim.Plot_Age),
                                  findall(x -> x in Parameters.date_Thin_Tree, Met_c.DOY))] .= true  
    Sim.TimetoPrun_Tree= false
    Sim.TimetoPrun_Tree[intersect(findall(x -> x in Parameters.Pruning_Age_Tree, Sim.Plot_Age),
                                  findall(x -> x in Parameters.D_pruning_Tree, Met_c.DOY))] .= true    
    Sim.TairCanopy_Tree= 0.0
end
  