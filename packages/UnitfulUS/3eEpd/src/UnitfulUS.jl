__precompile__(true)
module UnitfulUS

import Unitful
using Unitful: @unit
export @us_str

# Survey lengths
@unit sinch_us    "inˢ"       USSurveyInch      (100//3937)*Unitful.m   false
@unit sft_us      "ftˢ"       USSurveyFoot      12sinch_us              false
@unit sli_us      "liˢ"       USSurveyLink      (33//50)sft_us          false
@unit syd_us      "ydˢ"       USSurveyYard      3sft_us                 false
@unit srd_us      "rdˢ"       USSurveyRod       25sli_us                false
@unit sch_us      "chˢ"       USSurveyChain     4srd_us                 false
@unit sfur_us     "furˢ"      USSurveyFurlong   10sch_us                false
@unit smi_us      "miˢ"       USSurveyMile      8sfur_us                false
@unit slea_us     "leaˢ"      USSurveyLeague    3smi_us                 false

# Survey areas
@unit sac_us      "acˢ"       USSurveyAcre      43560sft_us^2           false
@unit town_us     "township"  USSurveyTownship  36smi_us^2              false

# Dry volumes
# Exact but the fraction is awful; will fix later
@unit drypt_us    "dryptᵘˢ"   USDryPint   550.6104713575*Unitful.ml^3   false
@unit dryqt_us    "dryqtᵘˢ"   USDryQuart        2drypt_us               false
@unit pk_us       "pkᵘˢ"      USPeck            8dryqt_us               false
@unit bushel_us   "buᵘˢ"      USBushel          4pk_us                  false

# Liquid volumes
@unit gal_us      "galᵘˢ"     USGallon          231*(Unitful.inch)^3    false
@unit qt_us       "qtᵘˢ"      USQuart           gal_us//4               false
@unit pt_us       "ptᵘˢ"      USPint            qt_us//2                false
@unit cup_us      "cupᵘˢ"     USCup             pt_us//2                false
@unit gill_us     "gillᵘˢ"    USGill            cup_us//2               false
@unit floz_us     "fl ozᵘˢ"   USFluidOunce      pt_us//16               false
@unit tbsp_us     "tbspᵘˢ"    USTablespoon      floz_us//2              false
@unit tsp_us      "tspᵘˢ"     USTeaspoon        tbsp_us//3              false
@unit fldr_us     "fl drᵘˢ"   USFluidDram       floz_us//8              false
@unit minim_us    "minimᵘˢ"   USMinim           fldr_us//60             false

# Mass
@unit cwt_us      "cwtᵘˢ"     USHundredweight   100*Unitful.lb          false
@unit ton_us      "tonᵘˢ"     USTon             2000*Unitful.lb         false

include("usmacro.jl")

# Some gymnastics required here because if we precompile, we cannot add to
# Unitful.basefactors at compile time and expect the changes to persist to runtime.
const localunits = Unitful.basefactors
function __init__()
    merge!(Unitful.basefactors, localunits)
    Unitful.register(UnitfulUS)
end

end # module
