R=8.31451;p=101325;T=293.15

molemass=[
    16.0430,30.0700,44.0970,58.1230,58.1230,72.1500,72.1500,72.1500,
    86.1770,86.1770,86.1770,86.1770,86.1770,100.204,114.231,128.258,
    142.285,28.0540,42.0810,56.1080,56.0180,56.1080,56.1080,70.1340,
    40.0650,54.0920,54.0920,26.0380,70.1340,84.1610,98.1880,84.1610,
    98.1880,112.215,78.1140,92.1410,106.167,106.167,32.0420,48.1090,
    2.01590,18.0153,34.0820,17.0306,27.0260,28.0100,60.0760,76.1430,
    4.00260,20.1797,39.9480,28.0135,31.9988,44.0100,64.0650,44.0129,
    83.8000,131.290]
mol_heat_high=[
    891.090,1561.41,2220.13,2878.57,2869.38,3537.17,3530.24,3516.01,
    4196.58,4188.95,4191.54,4179.15,4186.93,4855.29,5513.88,6173.46,
    6832.31,1411.65,2058.72,2717.75,2711.00,2707.40,2701.10,3376.57,
    1943.53,2594.45,2541.43,1301.21,3320.88,3970.93,4630.19,3954.47,
    4602.35,5264.98,3302.15,3948.84,4608.32,4597.46,764.590,1239.83,
    285.990,44.2240,562.190,383.160,671.600,282.950,548.190,1104.41]
mol_heat_low=[
    802.650,1428.74,2043.23,2657.45,2648.26,3271.83,3264.89,3250.67,
    3887.01,3879.38,3881.97,3869.59,3877.36,4501.49,5115.87,5731.22,
    6345.85,1323.20,1926.05,2540.86,2534.10,2530.50,2524.20,3155.45,
    1855.08,2461.78,2408.76,1256.98,3099.76,3705.59,4320.63,3689.13,
    4292.78,4911.19,3169.48,3771.95,4387.20,4376.34,676.140,1151.39,
    241.760,0.00000,517.970,316.820,649.500,282.950,548.190,1104.41]
z=[
    0.9981,0.9920,0.9834,0.9682,0.9710,0.9450,0.953,0.959,
    0.9190,0.9260,0.9280,0.9350,0.9340,0.8760,0.817,0.735,
    0.6230,0.9940,0.9850,0.9720,0.9690,0.9690,0.972,0.952,
    0.9840,0.9650,0.9730,0.9930,0.9500,0.9270,0.885,0.924,
    0.8940,0.8380,0.9360,0.8920,0.8370,0.8210,0.892,0.978,
    1.0006,0.9520,0.9900,0.9890,0.9200,0.9996,0.988,0.965,
    1.0005,1.0005,0.9993,0.9997,0.9993,0.9944,0.980]
b=[0.0436,0.0894,0.1288,0.1783,0.1703,0.2345,0.2168,0.2025,
0.2846,0.2720,0.2683,0.2550,0.2569,0.3521,0.4278,0.5148,
0.6140,0.0775,0.1225,0.1673,0.1761,0.1761,0.1673,0.2191,
0.1265,0.1871,0.1643,0.0837,0.2236,0.2702,0.3391,0.2757,
0.3256,0.4025,0.2530,0.3286,0.4037,0.4231,0.3286,0.1483,
-0.0051,0.2191,0.1000,0.1049,0.2828,0.0200,0.1095,0.1871,
0.0000,0.0000,0.0265,0.0173,0.0265,0.0728,0.1414]
N=48;N1=55
hhv_mole(x)=sum(mol_heat_high[1:N].*x[1:N])
lhv_mole(x)=sum(mol_heat_low[1:N].*x[1:N])
mole_mass(x)=sum(molemass.*x)
hhv_mass(x)=hhv_mole(x)/mole_mass(x)
lhv_mass(x)=lhv_mole(x)/mole_mass(x)
vol2mol(x)=x[1:N1]./z/sum(x[1:N1]./z)
zmix(x)=1.0-sum(x[1:N1].*b)
lhv_vol(x)=lhv_mole(x)*p/R/T 
hhv_vol(x)=hhv_mole(x)*p/R/T
lhv_real_vol(x)=lhv_vol(x)/zmix(x)
hhv_real_vol(x)=hhv_vol(x)/zmix(x)
rel_ρ(x)=sum(x*mole_mass(x)/28.9625)
abs_ρ(x)=sum(x*mole_mass(x))*p/R/T
real_rel_ρ(x)=rel_ρ(x)*0.99963/zmix(x)
real_abs_ρ(x)=abs_ρ(x)/zmix(x)

function calorific(x,out)
    if out==:mol
        return (lhv_mole(x),hhv_mole(x))
    elseif out==:mass
        return (lhv_mass(x),hhv_mass(x))
    elseif out==:vol
        return (lhv_real_vol(x),hhv_real_vol(x))
    elseif out==:rho
        return (real_rel_ρ(x),real_abs_ρ(x))
    end
end

"""
    ng_calorific(mode=:mol,outoption=:mol;CH4=100.0,C2H6=0,C3H8=0,C4H10=0,C4H10_1=0,C5H12=0,C5H12_1=0.,C5H12_2=0,C6H14=0,
    C6H14_1=0.0,C6H14_2=0.0,C6H14_3=0,C6H14_4=0,C7H16=0,C8H18=0.0,C9H20=0.0,C10H22=0.0,C2H4=0.0,
    C3H6=0.0,C4H8=0.0,C4H8_1=0.0,C4H8_2=0.0,C4H8_3=0.0,C5H10=0.0,C3H4=0.0,C4H6=0.0,C4H6_1=0.0,C2H2=0.0,
    C5H10_1=0.0,C6H12=0.0,C7H12=0.0,C6H12_1=0.0,C7H14=0.0,C8H16=0.0,C6H6=0.0,C7H8=0.0,C8H10=0.0,C8H10_1=0.0,
    CH4O=0.0,C2H6HgS2=0.0,H2=0.0,H2O=0.0,H2S=0.0,NH3=0.0,CHN=0.0,CO2=0.0,COS=0.0,CS2=0.0,He=0.0,Ne=0.0,Ar=0.0,
    N2=0.0,O2=0.0,CO2=0.0,O2S=0.0,N2O=0.0,Kr=0.0,Xe=0.0)
# Augument
- `mode`: `:mol` mol heat;`:mass` mass heat;`:vol heat` volume heat
- `outoption` : `:mol` (mole_low_heat,mole_high_heat) kJ/mo1;`:mass` (mass_low_heat,mass_high_heat) MJ/kg;`:vol`(vol_low_heat,vol_high_heat) u"MJ/m3";
                `:rho` (real rel_density,real abs_density u"kg/m3")
"""
function ng_calorific(mode=:mol,outoption=:mol;CH4=1.0,C2H6=0,C3H8=0,nC4H10=0,iC4H10=0,nC5H12=0,iC5H12=0.,
    C5H12_2=0,nC6H14=0,iC6H14=0.0,C6H14_2=0.0,C6H14_3=0,C6H14_4=0,nC7H16=0,nC8H18=0.0,nC9H20=0.0,nC10H22=0.0,
    C2H4=0.0,C3H6=0.0,C4H8=0.0,C4H8_1=0.0,C4H8_2=0.0,C4H8_3=0.0,C5H10=0.0,C3H4=0.0,C4H6=0.0,C4H6_1=0.0,C2H2=0.0,
    C5H10_1=0.0,C6H12=0.0,C7H12=0.0,C6H12_1=0.0,C7H14=0.0,C8H16=0.0,C6H6=0.0,C7H8=0.0,C8H10=0.0,C8H10_1=0.0,
    CH4O=0.0,C2H6HgS2=0.0,H2=0.0,H2O=0.0,H2S=0.0,NH3=0.0,CHN=0.0,CO=0.0,COS=0.0,CS2=0.0,He=0.0,Ne=0.0,Ar=0.0,
    N2=0.0,O2=0.0,CO2=0.0,O2S=0.0,N2O=0.0,Kr=0.0,Xe=0.0)
    x=[CH4,C2H6,C3H8,nC4H10,iC4H10,nC5H12,iC5H12,C5H12_2,nC6H14,
    iC6H14,C6H14_2,C6H14_3,C6H14_4,nC7H16,nC8H18,nC9H20,nC10H22,C2H4,
    C3H6,C4H8,C4H8_1,C4H8_2,C4H8_3,C5H10,C3H4,C4H6,C4H6_1,C2H2,
    C5H10_1,C6H12,C7H12,C6H12_1,C7H14,C8H16,C6H6,C7H8,C8H10,C8H10_1,
    CH4O,C2H6HgS2,H2,H2O,H2S,NH3,CHN,CO,COS,CS2,He,Ne,Ar,
    N2,O2,CO2,O2S,N2O,Kr,Xe]
    if mode==:vol;x=vol2mol(x);end
    calorific(x,outoption)
    
end

"""
    ng_calorific_cn(mode=:mol,outoption=:mol;甲烷=100,乙烷=0,丙烷=0,丁烷=0,二甲基丙烷=0,戊烷=0,二甲基丁烷=0,
    二二甲基丙烷=0,已烷=0,二甲基戊烷=0,三甲基戊烷=0,二二甲基丁烷=0,二三甲基丁烷=0,庚烷=0,辛烷=0,
    壬烷=0,癸烷=0,乙烯=0,丙烯=0,一丁烯=0,顺二丁烯=0,反二丁烯=0,二甲基丙烯=0,一戊烯=0,丙二烯=0,一二丁二烯=0,
    一三丁二烯=0,乙炔=0,环戊烷=0,甲基环戊烷=0,乙基环戊烷=0,环己烷=0,甲基环己烷=0,乙基环己烷=0,苯=0,
    甲苯=0,乙苯=0,邻二甲苯=0,甲醇=0,甲硫醇=0,氢气=0,水=0,硫化氢=0,氨=0,氰化氢=0,一氧化碳=0,硫氧碳=0,
    二硫化碳=0,氦气=0,氖气=0,氩气=0,氮气=0,氧气=0,二氧化碳=0,二氧化硫=0,一氧化二氮=0,氪气=0,氙气=0)
# Augument
- `mode`: `:mol` mol heat;`:mass` mass heat;`:vol heat` volume heat
- `outoption` : `:mol` (mole_low_heat,mole_high_heat) kJ/mo1;`:mass` (mass_low_heat,mass_high_heat) MJ/kg;`:vol`(vol_low_heat,vol_high_heat) u"MJ/m3";
                `:rho` (real rel_density,real abs_density u"kg/m3")
"""
function ng_calorific_cn(mode=:mol,outoption=:mol;甲烷=1,乙烷=0,丙烷=0,丁烷=0,二甲基丙烷=0,戊烷=0,二甲基丁烷=0,
    二二甲基丙烷=0,已烷=0,二甲基戊烷=0,三甲基戊烷=0,二二甲基丁烷=0,二三甲基丁烷=0,庚烷=0,辛烷=0,
    壬烷=0,癸烷=0,乙烯=0,丙烯=0,一丁烯=0,顺二丁烯=0,反二丁烯=0,二甲基丙烯=0,一戊烯=0,丙二烯=0,一二丁二烯=0,
    一三丁二烯=0,乙炔=0,环戊烷=0,甲基环戊烷=0,乙基环戊烷=0,环己烷=0,甲基环己烷=0,乙基环己烷=0,苯=0,
    甲苯=0,乙苯=0,邻二甲苯=0,甲醇=0,甲硫醇=0,氢气=0,水=0,硫化氢=0,氨=0,氰化氢=0,一氧化碳=0,硫氧碳=0,
    二硫化碳=0,氦气=0,氖气=0,氩气=0,氮气=0,氧气=0,二氧化碳=0,二氧化硫=0,一氧化二氮=0,氪气=0,氙气=0)

    x=[甲烷,乙烷,丙烷,丁烷,二甲基丙烷,戊烷,二甲基丁烷,
    二二甲基丙烷,已烷,二甲基戊烷,三甲基戊烷,二二甲基丁烷,二三甲基丁烷,庚烷,辛烷,
    壬烷,癸烷,乙烯,丙烯,一丁烯,顺二丁烯,反二丁烯,二甲基丙烯,一戊烯,丙二烯,一二丁二烯,
    一三丁二烯,乙炔,环戊烷,甲基环戊烷,乙基环戊烷,环己烷,甲基环己烷,乙基环己烷,苯,
    甲苯,乙苯,邻二甲苯,甲醇,甲硫醇,氢气,水,硫化氢,氨,氰化氢,一氧化碳,硫氧碳,
    二硫化碳,氦气,氖气,氩气,氮气,氧气,二氧化碳,二氧化硫,一氧化二氮,氪气,氙气]
    if mode==:vol;x=vol2mol(x);end
    calorific(x,outoption)
end

"""
    ng_calorific_en(mode=:mol,outoption=:mol;Methane=100.0,Ethane=0.0,Propane=0.0,nButane=0.0,Alkanes=0.0,nPentane=0.0,
    Methylbutane_2=0.0,Dimethylpropane_2_2=0.0,nHexane=0.0,Methylpentane_2=0.0,Methoylpentane_3=0.0,
    Dimethylbutane_2_2=0.0,Dimethylbutane_2_3=0.0,nHeptane=0.0,nOctane=0.0,nNonane=0.0,nDecane=0.0,
    Ethylene=0.0,Propylene=0.0,    Butene_1=0.0,cis_2_Butene=0.0,trans_2_Butene=0.0,Methylpropene_2=0.0,
    Pentene_1=0.0,    Propadiene=0.0,Butadiene_1_2=0.0,Butadiene_1_3=0.0,Acetylene=0.0,Cyclopentane=0.0,
    Methylcyclopentane=0.0,Ethylcyclopentane=0.0,Cyclohexane=0.0,Methylcyclohexane=0.0,Ethylcyclohexane=0.0,
    Benzene=0.0,Toluene=0.0,Ethylbenzene=0.0,o_Xylene=0.0,Methanol=0.0,Methanethiol=0.0,Hydrogen=0.0,
    Water=0.0,Hydrogen_sulfide=0.0,Ammonia=0.0,Hydrogen_cyanide=0.0,Carbon_monoxide=0.0,Carbonyl_sulfide=0.0,
    Carbon_disulfide=0.0,Helium=0.0,Neon=0.0,Argon=0.0,Nitrogen=0.0,Oxygen=0.0,Carbon_dioxide=0.0,Sulfur_Dioxide=0.0,
    Dinitrogen_monoxide=0.0,Krypton=0.0,Xenon=0.0)
# Augument
- `mode`: `:mol` mol heat;`:mass` mass heat;`:vol heat` volume heat
- `outoption` : `:mol` (mole_low_heat,mole_high_heat) kJ/mo1;`:mass` (mass_low_heat,mass_high_heat) MJ/kg;`:vol`(vol_low_heat,vol_high_heat) u"MJ/m3";
                `:rho` (real rel_density,real abs_density u"kg/m3")
"""
function ng_calorific_en(mode=:mol,outoption=:mol;Methane=1.0,Ethane=0.0,Propane=0.0,nButane=0.0,Alkanes=0.0,nPentane=0.0,
    Methylbutane_2=0.0,Dimethylpropane_2_2=0.0,nHexane=0.0,Methylpentane_2=0.0,Methoylpentane_3=0.0,
    Dimethylbutane_2_2=0.0,Dimethylbutane_2_3=0.0,nHeptane=0.0,nOctane=0.0,nNonane=0.0,nDecane=0.0,
    Ethylene=0.0,Propylene=0.0,    Butene_1=0.0,cis_2_Butene=0.0,trans_2_Butene=0.0,Methylpropene_2=0.0,
    Pentene_1=0.0,    Propadiene=0.0,Butadiene_1_2=0.0,Butadiene_1_3=0.0,Acetylene=0.0,Cyclopentane=0.0,
    Methylcyclopentane=0.0,Ethylcyclopentane=0.0,Cyclohexane=0.0,Methylcyclohexane=0.0,Ethylcyclohexane=0.0,
    Benzene=0.0,Toluene=0.0,Ethylbenzene=0.0,o_Xylene=0.0,Methanol=0.0,Methanethiol=0.0,Hydrogen=0.0,
    Water=0.0,Hydrogen_sulfide=0.0,Ammonia=0.0,Hydrogen_cyanide=0.0,Carbon_monoxide=0.0,Carbonyl_sulfide=0.0,
    Carbon_disulfide=0.0,Helium=0.0,Neon=0.0,Argon=0.0,Nitrogen=0.0,Oxygen=0.0,Carbon_dioxide=0.0,Sulfur_Dioxide=0.0,
    Dinitrogen_monoxide=0.0,Krypton=0.0,Xenon=0.0)

    x=[Methane,Ethane,Propane,nButane,Alkanes,nPentane,Methylbutane_2,Dimethylpropane_2_2,nHexane,Methylpentane_2,Methoylpentane_3,
    Dimethylbutane_2_2,Dimethylbutane_2_3,nHeptane,nOctane,nNonane,nDecane,Ethylene,Propylene,Butene_1,cis_2_Butene,trans_2_Butene,
    Methylpropene_2,Pentene_1,Propadiene,Butadiene_1_2,Butadiene_1_3,Acetylene,Cyclopentane,Methylcyclopentane,Ethylcyclopentane,
    Cyclohexane,Methylcyclohexane,Ethylcyclohexane,Benzene,Toluene,Ethylbenzene,o_Xylene,Methanol,Methanethiol,Hydrogen,Water,
    Hydrogen_sulfide,Ammonia,Hydrogen_cyanide,Carbon_monoxide,Carbonyl_sulfide,Carbon_disulfide,Helium,Neon,Argon,Nitrogen,Oxygen,
    Carbon_dioxide,Sulfur_Dioxide,Dinitrogen_monoxide,Krypton,Xenon]
    if mode==:vol;x=vol2mol(x);end
    calorific(x,outoption)
end

export ng_calorific,ng_calorific_cn,ng_calorific_en