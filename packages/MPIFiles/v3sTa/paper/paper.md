---
title: 'MPIFiles.jl: A Julia Package for Magnetic Particle Imaging Files'
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
  - name: Florian Griese
    orcid: 0000-0003-3309-9783
    affiliation: "1, 2"
  - name: Franziska Werner
    affiliation: "1, 2"
  - name: Patryk Szwargulski
    orcid: 0000-0003-2563-9006
    affiliation: "1, 2"
  - name: Nadine Gdaniec
    orcid: 0000-0002-5060-0683
    affiliation: "1, 2"
  - name: Marija Boberg
    orcid: 0000-0003-3419-7481
    affiliation: "1, 2"
affiliations:
 - name: Section for Biomedical Imaging, University Medical Center Hamburg-Eppendorf
   index: 1
 - name: Institute for Biomedical Imaging, Hamburg University of Technology
   index: 2
date: ?? May 2019
bibliography: paper.bib
---

# Summary

Tomographic imaging methods allow visualizing the interior of the human body in a
non-invasive way. The most prominent examples used for medical diagnosis are 
computed tomography (CT) and magnetic resonance imaging (MRI).
In 2015, Bernhard Gleich and Jürgen Weizenecker [@Gleich2005] introduced a new tomographic
imaging method named Magnetic Particle Imaging (MPI) that allows imaging
the 3D distribution of magnetic nanoparticles (MNP) in realtime [@knopp2012magnetic; @knopp2017magnetic].
The MNPs can be injected intravenously and allow imaging the vessel tree as well
as organ perfusion [@graser2019human]. The MNPs are harmless to the human body and are degraded in the
liver.

When working with an MPI scanner, different datasets are involved. In addition to the raw data, consisting of the induced voltage signals, a calibration dataset is required to reconstruct the particle concentration. The latter describes the physical relationship between the particle concentration and the measurement signal and is usually recorded in MPI with a delta-shaped point sample.
The software package ``MPIFiles.jl`` provides an interface to all these data types. Besides the proprietary data format recorded with MPI scanners from Bruker, ``MPIFiles.jl`` implements the vendor-independent Magnetic Particle Imaging
Data Format (MDF)[@knopp2016MDF], which is based on HDF5 and was developed with the aim of standardizing data storage in MPI. Each data format implements a common interface and enables the user to write generic code for different file types. In addition to the read and write capability for different data formats, ``MPIFiles.jl`` also offers the possibility of converting between different data formats.

``MPIFiles.jl`` supports the following types of MPI data

* measurements
* calibration data, i.e., system matrices
* reconstruction results

In addition to low-level access to the data, the package also features
high-level routines providing various post-processing methods such as
frequency filtering, spectral leakage correction, block-averaging, and
transfer function correction.

The API of ``MPIFiles.jl`` is based on the parameter names of the MDF specification, so that the latter can be used as a reference for the description of parameters and their dimensionality.
``MPIFiles.jl`` is licensed under the MIT license.

# References
