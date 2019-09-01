function No_Shade(Sim,Parameters,Met_c,i)

end


function Shade_Tree(Sim,Parameters,Met_c,i)
    # Shade tree layer computations (common for all species)
    # Should output at least APAR_Tree, LAI_Tree, T_Tree, Rn_Tree, H_Tree,
    # LE_Tree (sum of transpiration + leaf evap)
    # And via allometries: Height_Tree for canopy boundary layer conductance
  
    # Metamodel for kdif and kdir
    Base.invokelatest(Parameters.k, Sim,Met_c,i)
  
    Sim.APAR_Dif_Tree[i]= (Met_c.PAR[i] * Met_c.FDiff[i]) * (1-exp(- Sim.K_Dif_Tree[i] * Sim.LAI_Tree[previous_i(i)]))
    Sim.APAR_Dir_Tree[i]= (Met_c.PAR[i]*(1-Met_c.FDiff[i]))*(1-exp(-Sim.K_Dir_Tree[i]*Sim.LAI_Tree[previous_i(i)]))
  
    Sim.APAR_Tree[i]= max(0.0,Sim.APAR_Dir_Tree[i]+Sim.APAR_Dif_Tree[i])
  
    Sim.Transmittance_Tree[i]= 1.0 - (Sim.APAR_Tree[i]/Met_c.PAR[i])
    if abs(Sim.Transmittance_Tree[i])==Inf
        Sim.Transmittance_Tree[i]= 1.0
    end
  
    # Calling the metamodels for LUE, Transpiration and sensible heat flux :
    Base.invokelatest(Parameters.metamodels_tree,Sim,Met_c,i)
    # Computing the air temperature in the shade tree layer:
    Sim.TairCanopy_Tree[i]=
      Met_c.Tair[i] + (Sim.H_Tree[i] * Parameters.MJ_to_W) /
      (air_density(Met_c.Tair[i],Met_c.Pressure[i] / 10.0) * Parameters.cp *
         G_bulk(Wind= Met_c.WindSpeed[i], ZHT= Parameters.ZHT,
                LAI= Sim.LAI_Tree[previous_i(i)],
                extwind= Parameters.extwind,
                Z_top= Sim.Height_Tree[previous_i(i)]))
    # NB : using WindSpeed because wind extinction is already computed in G_bulk (until top of canopy).
  
    Sim.Tleaf_Tree[i]=
      Sim.TairCanopy_Tree[i] + (Sim.H_Tree[i]*Parameters.MJ_to_W) /
      
      (air_density(Met_c.Tair[i],Met_c.Pressure[i] / 10.0) * Parameters.cp *
         Gb_h(Wind = Met_c.WindSpeed[i], wleaf= Parameters.wleaf_Tree,
              LAI_lay= Sim.LAI_Tree[previous_i(i)],
              LAI_abv= 0,ZHT = Parameters.ZHT,
              Z_top = Sim.Height_Tree[previous_i(i)],
              extwind= Parameters.extwind))
              
    Sim.GPP_Tree[i]= Sim.lue_Tree[i] * Sim.APAR_Tree[i]
  
    # Tree Thinning threshold when Transmittance <=Parameters.ThinThresh:
    if Sim.Transmittance_Tree[i] < Parameters.ThinThresh
        Sim.TimetoThin_Tree[i]= true
    end
  
    # Maintenance respiration -------------------------------------------------
  
    # Rm is computed at the beginning of the day on the drymass of the previous day.
    Sim.Rm_Leaf_Tree[i]=
      Parameters.pa_Leaf_Tree * Sim.DM_Leaf_Tree[previous_i(i)] *
      Parameters.MRN_Tree * Parameters.NC_Leaf_Tree * Parameters.Q10Leaf_Tree^((Sim.TairCanopy_Tree[i]-Parameters.TMR)/10.0)
  
    Sim.Rm_CR_Tree[i]=
      Parameters.pa_CR_Tree * Sim.DM_CR_Tree[previous_i(i)] * Parameters.MRN_Tree * Parameters.NC_CR_Tree *
      Parameters.Q10CR_Tree^((Sim.TairCanopy_Tree[i] - Parameters.TMR) / 10.0)
  
    Sim.Rm_Branch_Tree[i]=
      Parameters.pa_Branch_Tree[Sim.Plot_Age[i],2] * Sim.DM_Branch_Tree[previous_i(i)] * Parameters.MRN_Tree * 
      Parameters.NC_Branch_Tree * Parameters.Q10Branch_Tree^((Sim.TairCanopy_Tree[i] - Parameters.TMR) / 10.0)
  
    Sim.Rm_Stem_Tree[i]=
      Parameters.pa_Stem_Tree[Sim.Plot_Age[i],2] * Sim.DM_Stem_Tree[previous_i(i)] * Parameters.MRN_Tree * 
      Parameters.NC_Stem_Tree * Parameters.Q10Stem_Tree^((Sim.TairCanopy_Tree[i] - Parameters.TMR) / 10.0)
  
    Sim.Rm_FRoot_Tree[i]=
      Parameters.pa_FRoot_Tree * Sim.DM_FRoot_Tree[previous_i(i)] * Parameters.MRN * Parameters.NC_FRoot_Tree *
      Parameters.Q10FRoot_Tree^((Sim.TairCanopy_Tree[i] - Parameters.TMR) / 10.0)
  
    Sim.Rm_Tree[i]= Sim.Rm_Leaf_Tree[i] + Sim.Rm_CR_Tree[i] + Sim.Rm_Branch_Tree[i] + Sim.Rm_Stem_Tree[i] + Sim.Rm_FRoot_Tree[i]
  
    # Shade Tree Allocation ---------------------------------------------------
  
    # Potential use of reserves:
    # Reserves are used only if GPP doesn't meet the condition:
    # maintenance respiration * kres_max_Tree.
    # Thus, if GPP is < to Rm*kres_max_Tree, the model take the needed C to meet the Rm,
    # but not more than there is C in the reserves. If the reserve mass are high enough
    # (>Res_max_Tree gC m-2), the model use it whatever the need.
    if Sim.GPP_Tree[i] < (Parameters.kres_max_Tree * Sim.Rm_Tree[i]) || Sim.CM_RE_Tree[previous_i(i)] > Parameters.Res_max_Tree
      Sim.Consumption_RE_Tree[i]= max(0.0, min(Sim.CM_RE_Tree[previous_i(i)], Parameters.kres_max_Tree * Sim.Rm_Tree[i]))
    end
  
    Sim.Supply_Total_Tree[i]= Sim.GPP_Tree[i] - Sim.Rm_Tree[i] + Sim.Consumption_RE_Tree[i]
    # If the supply is negative (Rm>GPP+RE), there is mortality. This mortality is shared between
    # the organs according to their potential carbon allocation (it is a deficit in carbon
    # allocation)
  
    if Sim.Supply_Total_Tree[i] < 0.0
      # Make it positive to cumulate in mortality:
      Sim.Supply_Total_Tree[i]= -Sim.Supply_Total_Tree[i]
      # Allocate carbon deficit to each organ:
      Sim.M_Rm_Stem_Tree[i]= Parameters.lambda_Stem_Tree * Sim.Supply_Total_Tree[i]
      Sim.M_Rm_CR_Tree[i]= Parameters.lambda_CR_Tree * Sim.Supply_Total_Tree[i]
      Sim.M_Rm_Branch_Tree[i]= Parameters.lambda_Branch_Tree * Sim.Supply_Total_Tree[i]
      Sim.M_Rm_Leaf_Tree[i]= 
            min(Parameters.DELM_Tree * Sim.Stocking_Tree[i] * ((Parameters.LAI_max_Tree - Sim.LAI_Tree[previous_i(i)]) /
                  (Sim.LAI_Tree[previous_i(i)] + Parameters.LAI_max_Tree)),
                Parameters.lambda_Leaf_Tree * Sim.Supply_Total_Tree[i])

      Sim.M_Rm_FRoot_Tree[i]= Parameters.lambda_FRoot_Tree * Sim.Supply_Total_Tree[i]
      Sim.M_Rm_RE_Tree[i]= Sim.Supply_Total_Tree[i] - 
           (Sim.M_Rm_FRoot_Tree[i] + Sim.M_Rm_Leaf_Tree[i] + Sim.M_Rm_Branch_Tree[i] + Sim.M_Rm_CR_Tree[i] + Sim.M_Rm_Stem_Tree[i])
  
      if Sim.M_Rm_RE_Tree[i] > (Sim.CM_RE_Tree[previous_i(i)] - Sim.Consumption_RE_Tree[i])
        # If reserves cannot provide the C deficit, take it from wood mortality:
        C_overdeficit_RE= Sim.M_Rm_RE_Tree[i] - (Sim.CM_RE_Tree[previous_i(i)] - Sim.Consumption_RE_Tree[i])
        Sim.M_Rm_CR_Tree[i]= Sim.M_Rm_CR_Tree[i] + C_overdeficit_RE * (Parameters.lambda_CR_Tree / Parameters.Wood_alloc)
        Sim.M_Rm_Branch_Tree[i]= Sim.M_Rm_Branch_Tree[i] + C_overdeficit_RE * (Parameters.lambda_Branch_Tree / Parameters.Wood_alloc)
        Sim.M_Rm_Stem_Tree[i]= Sim.M_Rm_Stem_Tree[i] + C_overdeficit_RE * (Parameters.lambda_Stem_Tree / Parameters.Wood_alloc)
        Sim.M_Rm_RE_Tree[i]= Sim.M_Rm_RE_Tree[i] - C_overdeficit_RE
      end
      # NB : M_Rm_RE_Tree is regarded as an extra reserve consumption as supply is not met.
      Sim.Supply_Total_Tree[i]= 0.0
    end
  
    # Allocation to each compartment :
    Sim.Alloc_Stem_Tree[i]= Parameters.lambda_Stem_Tree * Sim.Supply_Total_Tree[i]
    Sim.Alloc_CR_Tree[i]= Parameters.lambda_CR_Tree * Sim.Supply_Total_Tree[i]
    Sim.Alloc_Branch_Tree[i]= Parameters.lambda_Branch_Tree * Sim.Supply_Total_Tree[i]
    Sim.Alloc_Leaf_Tree[i]= 
        min(Parameters.DELM_Tree * Sim.Stocking_Tree[i] * ((Parameters.LAI_max_Tree - Sim.LAI_Tree[previous_i(i)]) /
               (Sim.LAI_Tree[previous_i(i)] + Parameters.LAI_max_Tree)),
          Parameters.lambda_Leaf_Tree * Sim.Supply_Total_Tree[i])
    Sim.Alloc_FRoot_Tree[i]= Parameters.lambda_FRoot_Tree * Sim.Supply_Total_Tree[i]
    # Allocation to reserves (Supply - all other allocations):
    Sim.Alloc_RE_Tree[i]= Sim.Supply_Total_Tree[i]- (Sim.Alloc_FRoot_Tree[i] + Sim.Alloc_Leaf_Tree[i] +
         Sim.Alloc_Branch_Tree[i] + Sim.Alloc_CR_Tree[i] + Sim.Alloc_Stem_Tree[i])
  
    # Stem:
    Sim.NPP_Stem_Tree[i]= Sim.Alloc_Stem_Tree[i] / Parameters.epsilon_Stem_Tree
    Sim.Rg_Stem_Tree[i]= Sim.Alloc_Stem_Tree[i] - Sim.NPP_Stem_Tree[i]
    # Mortality: No mortality yet for this compartment.
    # If stem mortality has to be set, write it here.
  
    # Coarse Roots:
    Sim.NPP_CR_Tree[i]= Sim.Alloc_CR_Tree[i] / Parameters.epsilon_CR_Tree
    Sim.Rg_CR_Tree[i]= Sim.Alloc_CR_Tree[i] - Sim.NPP_CR_Tree[i]
    Sim.Mact_CR_Tree[i]= Sim.CM_CR_Tree[previous_i(i)] / Parameters.lifespan_CR_Tree
  
    # Branches:
    Sim.NPP_Branch_Tree[i]= Sim.Alloc_Branch_Tree[i] / Parameters.epsilon_Branch_Tree
    Sim.Rg_Branch_Tree[i]= Sim.Alloc_Branch_Tree[i] - Sim.NPP_Branch_Tree[i]
    Sim.Mact_Branch_Tree[i]= Sim.CM_Branch_Tree[previous_i(i)] / Parameters.lifespan_Branch_Tree
  
    # Leaves:
    Sim.NPP_Leaf_Tree[i]= Sim.Alloc_Leaf_Tree[i] / Parameters.epsilon_Leaf_Tree
    Sim.Rg_Leaf_Tree[i]= Sim.Alloc_Leaf_Tree[i] - Sim.Rg_Leaf_Tree[i]
  
    # Leaf Fall ---------------------------------------------------------------
  
    if Sim.TimetoFall_Tree[i]
      # Phenology (leaf mortality increases in this period) if Leaf_Fall_Tree is TRUE
      Sim.Mact_Leaf_Tree[i]=
        Sim.CM_Leaf_Tree[previous_i(i)] *
        Parameters.Leaf_fall_rate_Tree[findfirst(x -> any(map(y -> y==Met_c.DOY[i],collect(x))), Parameters.Fall_Period_Tree)]
    else
      # Or just natural litterfall assuming no diseases
      Sim.Mact_Leaf_Tree[i]= Sim.CM_Leaf_Tree[previous_i(i)] / Parameters.lifespan_Leaf_Tree
    end
  
    # Fine roots
    Sim.NPP_FRoot_Tree[i]= Sim.Alloc_FRoot_Tree[i] / Parameters.epsilon_FRoot_Tree
    Sim.Rg_FRoot_Tree[i]= Sim.Alloc_FRoot_Tree[i] - Sim.NPP_FRoot_Tree[i]
    Sim.Mact_FRoot_Tree[i]= Sim.CM_FRoot_Tree[previous_i(i)] / Parameters.lifespan_FRoot_Tree
  
    # Reserves:
    Sim.NPP_RE_Tree[i]= Sim.Alloc_RE_Tree[i] / Parameters.epsilon_RE_Tree
    # Cost of allocating to reserves
    Sim.Rg_RE_Tree[i]= Sim.Alloc_RE_Tree[i] - Sim.NPP_RE_Tree[i]
  
    # Pruning -----------------------------------------------------------------
  
    # NB: several dates of pruning are allowed
    if Sim.TimetoPrun_Tree[i]
      # Leaves pruning :
      Sim.Mprun_Leaf_Tree[i]= Sim.CM_Leaf_Tree[previous_i(i)] * Parameters.pruningIntensity_Tree
      # Total mortality (cannot exceed total leaf dry mass):
      Sim.Mact_Leaf_Tree[i]= max(0.0, min(Sim.Mact_Leaf_Tree[i] + Sim.Mprun_Leaf_Tree[i], Sim.CM_Leaf_Tree[previous_i(i)]))
  
      # Branch pruning:
      Sim.Mprun_Branch_Tree[i]= Sim.CM_Branch_Tree[previous_i(i)] * Parameters.pruningIntensity_Tree
      Sim.Mact_Branch_Tree[i]= max(0.0,min((Sim.Mact_Branch_Tree[i] + Sim.Mprun_Branch_Tree[i]), Sim.CM_Branch_Tree[previous_i(i)]))
      Sim.Mprun_FRoot_Tree[i]= Parameters.m_FRoot_Tree * Sim.Mprun_Leaf_Tree[i]
      Sim.Mact_FRoot_Tree[i]= max(0.0, min(Sim.Mact_FRoot_Tree[i] + Sim.Mprun_FRoot_Tree[i], Sim.CM_FRoot_Tree[previous_i(i)]))
    end
  
    # Thinning ----------------------------------------------------------------
  
    if Sim.TimetoThin_Tree[i]
      # First, reduce stocking by the predefined rate of thining:
      Sim.Stocking_Tree[i:end] .= Sim.Stocking_Tree[i-1] * (1.0 - Parameters.RateThinning_Tree)
      # Then add mortality (removing) due to thining :
      Sim.MThinning_Stem_Tree[i]= Sim.CM_Stem_Tree[previous_i(i)] * Parameters.RateThinning_Tree
      Sim.MThinning_CR_Tree[i]= Sim.CM_CR_Tree[previous_i(i) ] * Parameters.RateThinning_Tree
      Sim.MThinning_Branch_Tree[i]= Sim.CM_Branch_Tree[previous_i(i)] * Parameters.RateThinning_Tree
      Sim.MThinning_Leaf_Tree[i]= Sim.CM_Leaf_Tree[previous_i(i)] * Parameters.RateThinning_Tree
      Sim.MThinning_FRoot_Tree[i]= Sim.CM_FRoot_Tree[previous_i(i)] * Parameters.RateThinning_Tree
    end
  
    # Mortality update --------------------------------------------------------
  
    Sim.Mortality_Leaf_Tree[i]= Sim.M_Rm_Leaf_Tree[i] + Sim.Mact_Leaf_Tree[i] + Sim.MThinning_Leaf_Tree[i]
    Sim.Mortality_Branch_Tree[i]= Sim.M_Rm_Branch_Tree[i] + Sim.Mact_Branch_Tree[i] + Sim.MThinning_Branch_Tree[i]
    Sim.Mortality_Stem_Tree[i]= Sim.M_Rm_Stem_Tree[i] + Sim.Mact_Stem_Tree[i] + Sim.MThinning_Stem_Tree[i]
    Sim.Mortality_CR_Tree[i]= Sim.M_Rm_CR_Tree[i] + Sim.Mact_CR_Tree[i] + Sim.MThinning_CR_Tree[i]
    Sim.Mortality_FRoot_Tree[i]= Sim.M_Rm_FRoot_Tree[i] + Sim.Mact_FRoot_Tree[i] + Sim.MThinning_FRoot_Tree[i]
  
    # C mass update -----------------------------------------------------------
  
    Sim.CM_Leaf_Tree[i]= max(0.0, Sim.CM_Leaf_Tree[previous_i(i)] + Sim.NPP_Leaf_Tree[i] - Sim.Mortality_Leaf_Tree[i])
    Sim.CM_Branch_Tree[i]= max(0.0, Sim.CM_Branch_Tree[previous_i(i)] + Sim.NPP_Branch_Tree[i] - Sim.Mortality_Branch_Tree[i])
    Sim.CM_Stem_Tree[i]= max(0.0, Sim.CM_Stem_Tree[previous_i(i)] + Sim.NPP_Stem_Tree[i] - Sim.Mortality_Stem_Tree[i])
    Sim.CM_CR_Tree[i]= max(0.0, Sim.CM_CR_Tree[previous_i(i)] + Sim.NPP_CR_Tree[i] - Sim.Mortality_CR_Tree[i])
    Sim.CM_FRoot_Tree[i]= max(0.0, Sim.CM_FRoot_Tree[previous_i(i)] + Sim.NPP_FRoot_Tree[i] - Sim.Mortality_FRoot_Tree[i])
    Sim.CM_RE_Tree[i]= max(0.0, Sim.CM_RE_Tree[previous_i(i)] + Sim.NPP_RE_Tree[i] - Sim.Consumption_RE_Tree[i] - Sim.M_Rm_RE_Tree[i])
  
    # Dry Mass update ---------------------------------------------------------
  
    Sim.DM_Leaf_Tree[i]= Sim.CM_Leaf_Tree[i] / Parameters.CC_Leaf_Tree
    Sim.DM_Branch_Tree[i]= Sim.CM_Branch_Tree[i] / Parameters.CC_wood_Tree
    Sim.DM_Stem_Tree[i]= Sim.CM_Stem_Tree[i] / Parameters.CC_wood_Tree
    Sim.DM_CR_Tree[i]= Sim.CM_CR_Tree[i] / Parameters.CC_wood_Tree
    Sim.DM_FRoot_Tree[i]= Sim.CM_FRoot_Tree[i] / Parameters.CC_wood_Tree
  
    # Respiration -------------------------------------------------------------
  
    Sim.Rg_Tree[i]= Sim.Rg_CR_Tree[i] + Sim.Rg_Leaf_Tree[i] + Sim.Rg_Branch_Tree[i] + Sim.Rg_Stem_Tree[i] +
      Sim.Rg_FRoot_Tree[i] + Sim.Rg_RE_Tree[i]
  
    Sim.Ra_Tree[i]= Sim.Rm_Tree[i] + Sim.Rg_Tree[i]
  
    # Total NPP ---------------------------------------------------------------
  
    Sim.NPP_Tree[i]= Sim.NPP_Stem_Tree[i] + Sim.NPP_Branch_Tree[i] + Sim.NPP_Leaf_Tree[i] + Sim.NPP_CR_Tree[i] +
      Sim.NPP_FRoot_Tree[i] + Sim.NPP_RE_Tree[i]
  
    # Daily C balance that should be nil every day:
    Sim.Cbalance_Tree[i]= Sim.Supply_Total_Tree[i] - (Sim.NPP_Tree[i] + Sim.Rg_Tree[i])
  
    Sim.LAI_Tree[i]= Sim.DM_Leaf_Tree[i] * (Parameters.SLA_Tree / 1000.0)
  
    # Allometries ------------------------------------------------------------
    Base.invokelatest(Parameters.Allometries,Sim,Met_c,Parameters,i)
    Sim.LAIplot[i]= Sim.LAIplot[i] + Sim.LAI_Tree[i]
end  


"""

# Shade Tree subroutine
Make all computations for shade trees (similar to coffee, but no fruits) for the ith day by modifying the `S` list in place.

# Arguments 

- `Sim::DataFrame`: The main simulation DataFrame to make the computation. Is modified in place.
- `Parameters`: A named tuple with parameter values (see [`import_parameters`](@ref)).
- `Met_c::DataFrame`: The meteorology DataFrame (see [`meteorology`](@ref)).
- `i::Int64`: The index of the day since the first day of the simulation.

# Return
Nothing, modify the DataFrame of simulation `Sim` in place. See [`dynacof`](@ref) for more details.

# Note
This function shouldn't be called by the user. It is made as a "sub-module" so it is easier for advanced users to modify the code.
`No_Shade()` is used as an empty function that is called when there are no shade trees.

See also [`dynacof`](@ref)
"""
Shade_Tree, No_Shade