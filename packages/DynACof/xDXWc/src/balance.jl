"""
Energy balance

Computes the different components of the energy balance considering the shade tree, the coffee and the soil.

# Return

Nothing, modify the DataFrame of simulation `Sim` in place. See [`dynacof`](@ref) for more details.
"""
function balance_model!(Sim,Parameters,Met_c,i)
 # Tree LE and Rn (can not compute them in the Tree function because we need IntercRevapor)
 Sim.LE_Tree[i]= (Sim.T_Tree[i] + Sim.IntercRevapor[i] * (Sim.LAI_Tree[i] / Sim.LAIplot[i])) * Parameters.λ
 Sim.Rn_Tree[i]= Sim.H_Tree[i] + Sim.LE_Tree[i]
 
 # Coffea layer net radiation
 Sim.LE_Coffee[i]= (Sim.T_Coffee[i] + Sim.IntercRevapor[i] * (Sim.LAI[i] / Sim.LAIplot[i])) * Parameters.λ
 Sim.Rn_Coffee[i]= Sim.H_Coffee[i] + Sim.LE_Coffee[i]

 # Plot transpiration
 Sim.T_tot[i]= Sim.T_Tree[i] + Sim.T_Coffee[i]
 # Evapo-Transpiration
 Sim.ETR[i]= Sim.T_tot[i] + Sim.E_Soil[i] + Sim.IntercRevapor[i]

 # Total plot energy:
 Sim.H_tot[i]= Sim.H_Coffee[i] + Sim.H_Tree[i] + Sim.H_Soil[i]
 Sim.LE_tot[i]= Sim.LE_Coffee[i] + Sim.LE_Tree[i] + Sim.LE_Soil[i]
 Sim.Rn_tot[i]= Sim.Rn_Coffee[i] + Sim.Rn_Tree[i] + Sim.Rn_Soil[i]

 # Latent and Sensible heat fluxes
 Sim.LE_Plot[i]= Sim.ETR[i] * Parameters.λ # NB: LE_Plot should be == to LE_tot    
end