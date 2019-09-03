"""
This submodule contains ready-to-use Scatterer models of zooplankton.
"""
module Models

using SDWBA
using DelimitedFiles

export  krill_mcgeehee,
		krill_conti,
		calanoid_copepod,
		sandeel,
		daphnia,
		nauplius


DATA_DIR = joinpath(dirname(@__FILE__), "data/")


"""
Krill shape from McGeehee et al. 1998, 'Effects of orientation on acoustic scattering
from Antarctic krill at 120 kHz.' Deep-Sea Research II 45(7), 1273-1294.
"""
krill_mcgeehee = from_csv(joinpath(DATA_DIR, "generic_krill_McGeehee1998.csv"))

"""
Krill shape from Conti and Demer, 2006, 'Improved parameterization of the SDWBA for
estimating krill target strength.' ICES Journal of Marine Science 63(5), 928-935.
"""
krill_conti = from_csv(joinpath(DATA_DIR, "generic_krill_Conti2006.csv"))

"""
Generic sand eel/sand lance shape (Ammodytes spp.).  Shape is taken from illustration in
Bigelow and Schroeder, 'Fishes of the Gulf of Maine.'  Material properties from
Yasuma et al. (2009), 'Density and sound-speed contrasts, and target strength of
Japanese sandeel Ammodytes personatus.' Fisheries Science 75 (3) 545-552.
"""
sandeel = from_csv(joinpath(DATA_DIR, "sand_eel.csv"))

"""
Generic calanoid copepod shape, 1 mm long, with g and h for "typical" marine zooplankton
(both 1.04, as per Stanton and Chu 2000, 'Review and recommendations for the modelling
of acoustic scattering by fluid-like elongated zooplankton: euphausiids and copepods.'
ICES Journal of Marine Science 57, 793-807).
"""
calanoid_copepod = from_csv(joinpath(DATA_DIR, "generic_acartia.csv"))

"""
Generic Daphnia shape used in Warren et al. 2016, 'Measuring the distribution,
abundance, and biovolume of zooplankton in an oligotrophic freshwater lake
with a 710 kHz scientific echosounder.' Limnology and Oceanography: Methods
"""
daphnia = from_csv(joinpath(DATA_DIR, "daphnia.csv"))

"""
Alternative (more realistic?) daphnia shape
"""
daphnia2 = from_csv(joinpath(DATA_DIR, "daphnia2.csv"))

"""
Generic nauplius larva shape, 0.5 mm long, with g and h for "typical" marine zooplankton
(both 1.04, as per Stanton and Chu 2000, 'Review and recommendations for the modelling
of acoustic scattering by fluid-like elongated zooplankton: euphausiids and copepods.'
ICES Journal of Marine Science 57, 793-807).
"""
nauplius = from_csv(joinpath(DATA_DIR, "nauplius.csv"))

end
