# This file is part of Kpax3. License is MIT.

abstract type KData end

"""
# Genetic data

## Description

DNA data and its metadata.

## Fields

* `data` Multiple sequence alignment (MSA) encoded as a binary (UInt8) matrix
* `id` units' ids
* `ref` reference sequence, i.e. a vector of the same length of the original
sequences storing the values of homogeneous sites. SNPs are instead represented
by a value of 29
* `val` vector with unique values per MSA site
* `key` vector with indices of each value

## Details

Let `n` be the total number of units and `ml` be the total number of unique
values observed at SNP `l`. Define m = m1 + ... + mL, where L is the total
number of SNPs.

`data` is a `m`-by-`n` indicator matrix, i.e. `data[j, i]` is `1` if unit `i`
possesses value `j`, `0` otherwise.

The value associated with column `j` can be obtained by `val[j]` while the SNP
position by `findall(ref == 29)[key[j]]`.

## References

Pessia A., Grad Y., Cobey S., Puranen J. S. and Corander J. (2015). K-Pax2:
Bayesian identification of cluster-defining amino acid positions in large
sequence datasets. _Microbial Genomics_ **1**(1).
<http://dx.doi.org/10.1099/mgen.0.000025>.
"""
struct NucleotideData <: KData
  data::Matrix{UInt8}
  id::Vector{String}
  ref::Vector{UInt8}
  val::Vector{UInt8}
  key::Vector{Int}
end

function NucleotideData(settings::KSettings)
  missval = if (length(settings.miss) == 1) && (settings.miss[1] == 0x00)
              0x00
            else
              UInt8('?')
            end

  (data, id, ref) = readfasta(settings.ifile, false, settings.miss, settings.l,
                              settings.verbose, settings.verbosestep)
  (bindata, val, key) = categorical2binary(data, UInt8(127), missval)

  NucleotideData(bindata, id, ref, val, key)
end

"""
# Genetic data

## Description

Amino acid data and its metadata.

## Fields

* `data` Multiple sequence alignment (MSA) encoded as a binary (UInt8) matrix
* `id` units' ids
* `ref` reference sequence, i.e. a vector of the same length of the original
sequences storing the values of homogeneous sites. SNPs are instead represented
by a value of 29
* `val` vector with unique values per MSA site
* `key` vector with indices of each value

## Details

Let `n` be the total number of units and `ml` be the total number of unique
values observed at SNP `l`. Define m = m1 + ... + mL, where L is the total
number of SNPs.

`data` is a `m`-by-`n` indicator matrix, i.e. `data[j, i]` is `1` if unit `i`
possesses value `j`, `0` otherwise.

The value associated with column `j` can be obtained by `val[j]` while the SNP
position by `findall(ref == 29)[key[j]]`.

## References

Pessia A., Grad Y., Cobey S., Puranen J. S. and Corander J. (2015). K-Pax2:
Bayesian identification of cluster-defining amino acid positions in large
sequence datasets. _Microbial Genomics_ **1**(1).
<http://dx.doi.org/10.1099/mgen.0.000025>.
"""
struct AminoAcidData{T} <: KData
  # generalize AminoAcidData to represent generic categorical data. Code must
  # be refactored
  data::Matrix{UInt8}
  id::Vector{String}
  ref::Vector{T}
  val::Vector{T}
  key::Vector{Int}
end

function AminoAcidData(settings::KSettings)
  missval = if (length(settings.miss) == 1) && (settings.miss[1] == 0x00)
              0x00
            else
              UInt8('?')
            end

  (data, id, ref) = readfasta(settings.ifile, true, settings.miss, settings.l,
                              settings.verbose, settings.verbosestep)
  (bindata, val, key) = categorical2binary(data, UInt8(127), missval)

  AminoAcidData(bindata, id, ref, val, key)
end

"""
# CSV data

## Description

Generic data and its metadata.

## Fields

* `data` original data matrix encoded as a binary (UInt8) matrix
* `id` units' ids
* `ref` reference observation, i.e. a vector of the same length of the original
observations storing the values of homogeneous sites. Polymorphisms are instead
represented by the string "."
* `val` vector with unique values per dataset column
* `key` vector with indices of each value

## Details

Let `n` be the total number of units and `ml` be the total number of unique
values observed at polymorphic column `l`. Define m = m1 + ... + mL, where L is
the total number of polymorphic columns.

`data` is a `m`-by-`n` indicator matrix, i.e. `data[j, i]` is `1` if unit `i`
possesses value `j`, `0` otherwise.

The value associated with column `j` can be obtained by `val[j]` while the
polymorphic position by `findall(ref == ".")[key[j]]`.

## References

Pessia A., Grad Y., Cobey S., Puranen J. S. and Corander J. (2015). K-Pax2:
Bayesian identification of cluster-defining amino acid positions in large
sequence datasets. _Microbial Genomics_ **1**(1).
<http://dx.doi.org/10.1099/mgen.0.000025>.
"""
function CategoricalData(settings::KSettings)
  (data, id, ref) = readdata(settings.ifile, ',', settings.misscsv,
                             settings.verbose, settings.verbosestep)
  (bindata, val, key) = categorical2binary(data, "")

  #CategoricalData(bindata, id, ref, val, key)
  # return an AminoAcidData object until the code has been refactored
  AminoAcidData(bindata, id, ref, val, key)
end

#=
struct CategoricalData <: KData
  data::Matrix{UInt8}
  id::Vector{String}
  ref::Vector{String}
  val::Vector{String}
  key::Vector{Int}
end
=#
