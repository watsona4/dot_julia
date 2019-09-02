# LorentzDrudeMetals.jl

Permittivities of common metals, using the Lorentz-Drude model and data from 'Optical properties of metallic films for vertical-cavity optoelectronic devices', Rakić et al (1998).


## Example usage

```
using LorentzDrudeMetals

wavelengths = range(0.3, stop=2.0, length=1000)
epAg = LorentzDrudeMetals.Ag[wavelengths]
```
