# SDWBA

## Exported

---

<a id="method__freq_spectrum.1" class="lexicon_definition"></a>
#### freq_spectrum(s::SDWBA.Scatterer{T},  freq1,  freq2,  sound_speed) [¶](#method__freq_spectrum.1)
Calculate backscatter over a range of frequencies.  The insonifying sound comes
from above (i.e., traveling in the -z direction).

#### Parameters
- `s` : Scatterer object
- `freq1`, `freq2` : Endpoints of the angle range to calculate.
- `sound_speed` : Sound speed in the surrounding medium
- `n` : Number of frequencies to calculate; defaults to 100

Returns: A dictionary containing elements "freqs", "sigma_bs", and "TS",
	each a length-n vector.


*source:*
[SDWBA/src/Scatterer.jl:208](https://github.com/ElOceanografo/SDWBA.jl/tree/98bb9c940455455a182b5b0c572df04008018d4e/src/Scatterer.jl#L208)

---

<a id="method__freq_spectrum.2" class="lexicon_definition"></a>
#### freq_spectrum(s::SDWBA.Scatterer{T},  freq1,  freq2,  sound_speed,  n) [¶](#method__freq_spectrum.2)
Calculate backscatter over a range of frequencies.  The insonifying sound comes
from above (i.e., traveling in the -z direction).

#### Parameters
- `s` : Scatterer object
- `freq1`, `freq2` : Endpoints of the angle range to calculate.
- `sound_speed` : Sound speed in the surrounding medium
- `n` : Number of frequencies to calculate; defaults to 100

Returns: A dictionary containing elements "freqs", "sigma_bs", and "TS",
	each a length-n vector.


*source:*
[SDWBA/src/Scatterer.jl:208](https://github.com/ElOceanografo/SDWBA.jl/tree/98bb9c940455455a182b5b0c572df04008018d4e/src/Scatterer.jl#L208)

---

<a id="method__from_csv.1" class="lexicon_definition"></a>
#### from_csv(filename) [¶](#method__from_csv.1)
Load a scatterer from a file on disk with comma-separated values.

#### Parameters
- `filename` : String.  Path to the datafile.  This should be a standard .csv file 
with columns for the x, y, and z coordinates of the scatterer's centerline, as well
as the `a`, `h`, and `g` arguments to Scatterer().
- `columns` : Optional dictionary of column names. If the columns do not have the names 
- `x`, `y`, `z`, `h`, and `g`, this must be provided.  The keys are the standard column
names and the values are the actual ones in the file.


*source:*
[SDWBA/src/Scatterer.jl:230](https://github.com/ElOceanografo/SDWBA.jl/tree/98bb9c940455455a182b5b0c572df04008018d4e/src/Scatterer.jl#L230)

---

<a id="method__from_csv.2" class="lexicon_definition"></a>
#### from_csv(filename,  columns) [¶](#method__from_csv.2)
Load a scatterer from a file on disk with comma-separated values.

#### Parameters
- `filename` : String.  Path to the datafile.  This should be a standard .csv file 
with columns for the x, y, and z coordinates of the scatterer's centerline, as well
as the `a`, `h`, and `g` arguments to Scatterer().
- `columns` : Optional dictionary of column names. If the columns do not have the names 
- `x`, `y`, `z`, `h`, and `g`, this must be provided.  The keys are the standard column
names and the values are the actual ones in the file.


*source:*
[SDWBA/src/Scatterer.jl:230](https://github.com/ElOceanografo/SDWBA.jl/tree/98bb9c940455455a182b5b0c572df04008018d4e/src/Scatterer.jl#L230)

---

<a id="method__length.1" class="lexicon_definition"></a>
#### length(s::SDWBA.Scatterer{T}) [¶](#method__length.1)
Return the length of the scatterer (cartesian distance from one end to the other).


*source:*
[SDWBA/src/Scatterer.jl:61](https://github.com/ElOceanografo/SDWBA.jl/tree/98bb9c940455455a182b5b0c572df04008018d4e/src/Scatterer.jl#L61)

---

<a id="method__rotate.1" class="lexicon_definition"></a>
#### rotate(s::SDWBA.Scatterer{T}) [¶](#method__rotate.1)
Rotate the scatterer in space, returning a rotated copy.

#### Parameters
- `roll` : Angle to roll the scatterer, in degrees. Defaults to 0.
- `tilt` : Angle to tilt the scatterer, in degrees. Defaults to 0.
- `yaw` : Angle to yaw the scatterer, in degrees. Defaults to 0.

#### Returns
A Scatterer with the same shape and properties, but a new orientation.

The roll, tilt, and yaw refer to rotations around the x, y, and z axes,
respectively. They are applied in that order.


*source:*
[SDWBA/src/Scatterer.jl:77](https://github.com/ElOceanografo/SDWBA.jl/tree/98bb9c940455455a182b5b0c572df04008018d4e/src/Scatterer.jl#L77)

---

<a id="method__tilt_spectrum.1" class="lexicon_definition"></a>
#### tilt_spectrum(s::SDWBA.Scatterer{T},  angle1,  angle2,  k) [¶](#method__tilt_spectrum.1)
Calculate backscatter over a range of angles.

#### Parameters

- `s` : Scatterer object
- `angle1`, `angle2` : Endpoints of the angle range to calculate.
- `k` : Acoustic wavenumber vector
- `n` : Number of angles to calculate; defaults to 100

#### Returns

A dictionary containing elements "angles", "sigma_bs", and "TS",
each a length-n vector.


*source:*
[SDWBA/src/Scatterer.jl:183](https://github.com/ElOceanografo/SDWBA.jl/tree/98bb9c940455455a182b5b0c572df04008018d4e/src/Scatterer.jl#L183)

---

<a id="method__tilt_spectrum.2" class="lexicon_definition"></a>
#### tilt_spectrum(s::SDWBA.Scatterer{T},  angle1,  angle2,  k,  n) [¶](#method__tilt_spectrum.2)
Calculate backscatter over a range of angles.

#### Parameters

- `s` : Scatterer object
- `angle1`, `angle2` : Endpoints of the angle range to calculate.
- `k` : Acoustic wavenumber vector
- `n` : Number of angles to calculate; defaults to 100

#### Returns

A dictionary containing elements "angles", "sigma_bs", and "TS",
each a length-n vector.


*source:*
[SDWBA/src/Scatterer.jl:183](https://github.com/ElOceanografo/SDWBA.jl/tree/98bb9c940455455a182b5b0c572df04008018d4e/src/Scatterer.jl#L183)

