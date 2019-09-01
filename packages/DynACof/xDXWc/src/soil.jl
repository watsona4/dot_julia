
"""
# Soil module subroutine

Make all computations for soil water balance for the ith day by modifying the `Sim` DataFrame in place.

# Arguments  

- `Sim::DataFrame`: The main simulation DataFrame to make the computation. Is modified in place.
- `Parameters`: A named tuple with parameter values (see [`import_parameters`](@ref)).
- `Met_c::DataFrame`: The meteorology DataFrame (see [`meteorology`](@ref)).
- `i::Int64`: The index of the day since the first day of the simulation.

# Return
Nothing, modify the DataFrame of simulation `Sim` in place. See [`dynacof`](@ref) for more details.

# Note
This function shouldn't be called by the user. It is made as a sub-module so it is easier for advanced users to modify the code.

# See also

[`dynacof`](@ref)
"""
function soil_model!(Sim,Parameters,Met_c,i)

    # Rn understorey using Shuttleworth & Wallace, 1985, eq. 21 for reference
    Sim.Rn_Soil_SW[i]= Met_c.Rn[i] * exp(-Parameters.k_Rn * Sim.LAIplot[i])

    # Rn understorey using metamodels
    Base.invokelatest(Parameters.Metamodels_soil,Sim,Met_c,i)
    # NB: soil heat storage is negligible at daily time-step (or equilibrate rapidly)

    # 1/ Rainfall interception, source Gomez-Delgado et al.2011, Box A: IntercMax=AX;
    Sim.IntercMax[i]= Parameters.IntercSlope * Sim.LAIplot[i]

    Sim.CanopyHumect[i]= max(0.0, Sim.CanopyHumect[previous_i(i)] + Met_c.Rain[i])

    Potential_LeafEvap=
        PENMON(Rn= Met_c.Rn[i], Wind= Met_c.WindSpeed[i], Tair = Met_c.Tair[i],
               ZHT = Parameters.ZHT, Z_top = max(Sim.Height_Tree[i], Parameters.Height_Coffee),
               Pressure = Met_c.Pressure[i], Gs = 1E09, VPD = Met_c.VPD[i], LAI= Sim.LAIplot[i],
               extwind = Parameters.extwind, wleaf= Parameters.wleaf)

    if Sim.CanopyHumect[i] <= Sim.IntercMax[i]
        Sim.Throughfall[i]= 0.0
        Sim.IntercRevapor[i]= min(Sim.CanopyHumect[i], Potential_LeafEvap)
        Sim.CanopyHumect[i]= max(0.0, Sim.CanopyHumect[i] - Sim.IntercRevapor[i])
    else
        Sim.Throughfall[i]= Sim.CanopyHumect[i] - Sim.IntercMax[i]
        Sim.IntercRevapor[i]= min(Sim.IntercMax[i], Potential_LeafEvap)
        Sim.CanopyHumect[i]= max(0.0, Sim.IntercMax[i] - Sim.IntercRevapor[i])
    end

    # 2/ SURFACE RUNOFF / INFILTRATION source Gomez-Delgado et al. 2011,
    # Box B:WSurfResMax = BX; WSurfaceRes=Bt;
    #ExcessRunoff=QB2; SuperficialRunoff=QB1;  TotSuperficialRunoff=QB; Infiltration=i
    # 2.a Adding throughfall to superficial-box, calculation of surface runoff, updating of
    # stock in superficial-box
    Sim.WSurfaceRes[i]= Sim.WSurfaceRes[previous_i(i)] + Sim.Throughfall[i]

    if Sim.WSurfaceRes[i] > Parameters.WSurfResMax
        Sim.ExcessRunoff[i] = Sim.WSurfaceRes[i] - Parameters.WSurfResMax
        Sim.WSurfaceRes[i]= Parameters.WSurfResMax # removing ExcessRunoff
        Sim.SuperficialRunoff[i] = Parameters.kB  *  Sim.WSurfaceRes[i]
        #Subsuperficial runoff from runoffbox
        Sim.TotSuperficialRunoff[i] = Sim.ExcessRunoff[i]  +  Sim.SuperficialRunoff[i]
        Sim.WSurfaceRes[i] = Sim.WSurfaceRes[i] - Sim.SuperficialRunoff[i]
    else
        #updating WSurfaceRes, the ExcessRunoff has already been retrieved
        Sim.ExcessRunoff[i]= 0.0
        Sim.SuperficialRunoff[i] = Parameters.kB  *  Sim.WSurfaceRes[i]
        Sim.TotSuperficialRunoff[i] = Sim.SuperficialRunoff[i]
        Sim.WSurfaceRes[i] = Sim.WSurfaceRes[i] - Sim.SuperficialRunoff[i]
    end

    # 2.b Computing the infiltration capacity as a function of soil water content in W_1
    Sim.W_1[i]= Sim.W_1[previous_i(i)]

    if Sim.W_1[i] <= Parameters.Wm1
        Sim.InfilCapa[i]= Parameters.fo # InfilCapa: infiltration capacity
    else
        if Sim.W_1[i]<= Parameters.Wf1
        Sim.InfilCapa[i]= Parameters.fo - (Sim.W_1[i] - Parameters.Wm1) * (Parameters.fo - Parameters.fc) / (Parameters.Wf1 - Parameters.Wm1)
        else
        Sim.InfilCapa[i]= Parameters.fc
        end
    end

    # 2.c Calculating infiltration from superficial-box to soil-boxes and updating stock
    # in superficial-box
    if Sim.InfilCapa[i]<= Sim.WSurfaceRes[i]
        Sim.Infiltration[i]= Sim.InfilCapa[i]
        Sim.WSurfaceRes[i]= Sim.WSurfaceRes[i] - Sim.Infiltration[i]
    else
        Sim.Infiltration[i]= Sim.WSurfaceRes[i]
        Sim.WSurfaceRes[i]= 0.0
    end

    # 3/ Adding Infiltration to soil water content of the previous day, computing drainage,
    # source Gomez-Delgado et al. 2010
    Sim.W_1[i]= Sim.W_1[previous_i(i)] + Sim.Infiltration[i]

    # Preventing W_1 to be larger than the soil storage at field capacity:
    if Sim.W_1[i] > Parameters.Wf1
        Sim.Drain_1[i]= Sim.W_1[i] - Parameters.Wf1
        Sim.W_1[i] = Parameters.Wf1
    else
        # Water excess in the root-box that drains (m)
        Sim.Drain_1[i]= 0.0
    end

    Sim.W_2[i]= Sim.W_2[previous_i(i)] + Sim.Drain_1[i]

    # Preventing W_2 to be larger than the soil storage at field capacity:
    if Sim.W_2[i] > Parameters.Wf2
        Sim.Drain_2[i]= Sim.W_2[i] - Parameters.Wf2
        Sim.W_2[i] = Parameters.Wf2
    else
        Sim.Drain_2[i]= 0.0
    end

    Sim.W_3[i]= Sim.W_3[previous_i(i)] + Sim.Drain_2[i]

    # Preventing W_3 to be larger than the soil storage at field capacity:
    if Sim.W_3[i] > Parameters.Wf3
        Sim.Drain_3[i]= Sim.W_3[i] - Parameters.Wf3
        Sim.W_3[i] = Parameters.Wf3
    else
        Sim.Drain_3[i]= 0.0
    end

    # 4/ First computing water per soil layer
    Sim.EW_1[i]= Sim.W_1[i] - Parameters.Wm1 # Extractable water (m)
    # Relative extractable water (dimensionless):
    Sim.REW_1[i]= Sim.EW_1[i] / (Parameters.Wf1 - Parameters.Wm1)
    Sim.EW_2[i]= Sim.W_2[i] - Parameters.Wm2
    Sim.REW_2[i]= Sim.EW_2[i] / (Parameters.Wf2 - Parameters.Wm2)
    Sim.EW_3[i]= Sim.W_3[i] - Parameters.Wm3
    Sim.REW_3[i]= Sim.EW_3[i] / (Parameters.Wf3 - Parameters.Wm3)
    Sim.EW_tot[i]= Sim.EW_1[i] + Sim.EW_2[i] + Sim.EW_3[i]
    Sim.REW_tot[i]= Sim.EW_tot[i] / ((Parameters.Wf1 - Parameters.Wm1) + (Parameters.Wf2 - Parameters.Wm2) +
                    (Parameters.Wf3 - Parameters.Wm3))

    # 5/ Evaporation of the Understorey, E_Soil (from W_1 only)
    Sim.E_Soil[i]= Sim.Rn_Soil[i] * Parameters.Soil_LE_p / Parameters.λ
    # Avoid depleting W_1 below Wm1 and udating Wx after retrieving actual E_Soil
    if (Sim.W_1[i] - Sim.E_Soil[i]) >= Parameters.Wm1
        Sim.W_1[i]= Sim.W_1[i] - Sim.E_Soil[i]
    else
        Sim.E_Soil[i]= Sim.W_1[i] - Parameters.Wm1
        Sim.W_1[i]= Parameters.Wm1
    end

    # 6/ Root Water Extraction by soil layer, source Granier et al., 1999
    Sim.RootWaterExtract_1[i]= Sim.T_tot[i] * Parameters.RootFraction1
    Sim.RootWaterExtract_2[i]= Sim.T_tot[i] * Parameters.RootFraction2
    Sim.RootWaterExtract_3[i]= Sim.T_tot[i] * Parameters.RootFraction3
    # Avoiding depleting Wx below Wmx, and udating Wx after retrieving actual RootWaterExtract
    if (Sim.W_1[i] - Sim.RootWaterExtract_1[i]) >= Parameters.Wm1
        Sim.W_1[i]= Sim.W_1[i] - Sim.RootWaterExtract_1[i]
    else
        Sim.RootWaterExtract_1[i]= Sim.W_1[i] - Parameters.Wm1
        Sim.W_1[i]= Parameters.Wm1
    end

    if (Sim.W_2[i] - Sim.RootWaterExtract_2[i]) >= Parameters.Wm2
        Sim.W_2[i]= Sim.W_2[i] - Sim.RootWaterExtract_2[i]
    else
        Sim.RootWaterExtract_2[i]= Sim.W_2[i] - Parameters.Wm2
        Sim.W_2[i]= Parameters.Wm2
    end

    if (Sim.W_3[i] - Sim.RootWaterExtract_3[i]) >= Parameters.Wm3
        Sim.W_3[i]= Sim.W_3[i] - Sim.RootWaterExtract_3[i]
    else
        Sim.RootWaterExtract_3[i]= Sim.W_3[i] - Parameters.Wm3
        Sim.W_3[i]= Parameters.Wm3
    end

    # 7/ Second Updating water per soil layer
    Sim.W_tot[i]= Sim.W_1[i] + Sim.W_2[i] + Sim.W_3[i]
    Sim.EW_1[i]= Sim.W_1[i] - Parameters.Wm1 # Extractable water (m)
    Sim.REW_1[i]= Sim.EW_1[i] / (Parameters.Wf1 - Parameters.Wm1)
    # Relative extractable water (dimensionless)
    Sim.EW_2[i]= Sim.W_2[i] - Parameters.Wm2
    Sim.REW_2[i]= Sim.EW_2[i] / (Parameters.Wf2 - Parameters.Wm2)
    Sim.EW_3[i]= Sim.W_3[i] - Parameters.Wm3
    Sim.REW_3[i]= Sim.EW_3[i] / (Parameters.Wf3 - Parameters.Wm3)
    Sim.EW_tot[i]= Sim.EW_1[i] + Sim.EW_2[i] + Sim.EW_3[i]
    Sim.REW_tot[i]= Sim.EW_tot[i] / ((Parameters.Wf1 - Parameters.Wm1) + (Parameters.Wf2 - Parameters.Wm2) + 
                    (Parameters.Wf3 - Parameters.Wm3))

    # 8/ Soil water deficit
    if Parameters.REWc * Parameters.EWMtot-Sim.EW_tot[i] > 0.0
        Sim.SWD[i]= Parameters.REWc * Parameters.EWMtot - Sim.EW_tot[i]
    else
        Sim.SWD[i]= 0.0
    end

    # 9/ Soil Water potential, Campbell (1974) equation
    Sim.SoilWaterPot[i]= Parameters.PSIE * (((Sim.W_1[i] + Sim.W_2[i] + Sim.W_3[i]) / (Parameters.TotalDepth * 1000.0)) /
                            Parameters.PoreFrac)^(-Parameters.B)

    # 10/ Energy balance
    Sim.LE_Soil[i]= Sim.E_Soil[i] * Parameters.λ
    Sim.H_Soil[i]= Sim.Rn_Soil[i] * (1.0 - Parameters.Soil_LE_p)
    Sim.Q_Soil[i]= 0.0
    # RV: Q_Soil is negligible at yearly time-step, and equilibrate between several
    # days anyway.
    Sim.Rn_Soil[i]= Sim.H_Soil[i]  +  Sim.LE_Soil[i]  +  Sim.Q_Soil[i]

    # 11/ Soil temperature

    Sim.TSoil[i]= Sim.TairCanopy[i] + (Sim.H_Soil[i] * Parameters.MJ_to_W) / 
                  (air_density(Sim.TairCanopy[i], Met_c.Pressure[i]/10.0) * Parameters.cp *
                   G_soilcan(Wind= Met_c.WindSpeed[i], ZHT=Parameters.ZHT, Z_top= max(Sim.Height_Tree[i], Parameters.Height_Coffee),
                             LAI = Sim.LAI_Tree[i]  +  Sim.LAI[i], extwind= Parameters.extwind))

end  