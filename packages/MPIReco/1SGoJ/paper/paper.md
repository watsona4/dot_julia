---
title: 'MPIReco.jl: A Julia Package for Magnetic Particle Imaging Reconstruction'
tags:
  - Julia
  - Magnetic Particle Imaging
  - HDF5
  - MDF
authors:
  - name: Tobias Knopp
    orcid: 0000-0002-1589-8517
    affiliation: "1, 2"
  - name: Martin Möddel
    orcid: 0000-0002-4737-7863
    affiliation: "1, 2"
  - name: Patryk Szwargulski
    orcid: 0000-0003-2563-9006
    affiliation: "1, 2"
affiliations:
 - name: Section for Biomedical Imaging, University Medical Center Hamburg-Eppendorf
   index: 1
 - name: Institute for Biomedical Imaging, Hamburg University of Technology
   index: 2
date: ?? March 2019
bibliography: paper.bib
---

# Summary

Tomographic imaging methods allows to visualize the interior of the human body in a
non-invasive way. Most prominent examples used for medical diagnosis are the
computed tomography (CT) and magnetic resonance imaging (MRI).
In 2015 [@Gleich2005], Bernhard Gleich and Jürgen Weizenecker introduced a new tomographic
imaging method named Magnetic Particle Imaging (MPI) that allows to image
the 3D distribution of magnetic nanoparticles (MNP) in realtime [@knopp2012magnetic; @knopp2017magnetic].
The MNP can be injected intravenously and allow to image the vessel tree as well
as organ perfusion. The MNPs are harmless for the human body and are degraded in the
liver.

When working with an MPI scanner there are various datasets involved. During an
MPI experiment, the signal is measured using inductive receive coils. In order to
reconstruct an image of the MNP distribution one requires knowledge of the MPI
system matrix, which is usually measured within a calibration measurement.
The software package ``MPIFiles.jl`` provides an interface to all these types of data.
In particular it has full support for the Magnetic Particle Imaging
Data Format (MDF) [@knopp2016MDF], which is an open, HDF5 based, data format that
has been developed with the purpose of standardizing data storage in MPI. Additionally,
``MPIFiles.jl`` has full read support for datasets measured with the preclinical
MPI scanner from the vendor Bruker. Each data format is implemented using a dedicated
type and implements a common interface such that the user of the package can write
generic code for different file types. In addition to read support, the package also
has conversion routines for creating MDF files from Brukerfiles.

``MPIFiles.jl`` supports the following types of MPI data
* measurements
* calibration data, i.e. system matrices
* reconstruction results
In addition to a low level access to the data, the package also features
high level routines that provide various post-processing methods such as
frequency filtering, spectral leakage correction, block-averaging, and
transfer function correction.

The API of ``MPIFiles.jl`` is aligned with the parameter names of the MDF
specification such that the latter can be used as a reference for determining
the content and dimensionality of certain parameters.
``MPIFiles.jl`` is licensed under MIT license and is hosted on Github at
https://github.com/MagneticParticleImaging/MPIFiles.jl.

# References
