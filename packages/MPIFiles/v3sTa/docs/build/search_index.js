var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#MPIFiles.jl-1",
    "page": "Home",
    "title": "MPIFiles.jl",
    "category": "section",
    "text": "Magnetic Particle Imaging Files"
},

{
    "location": "index.html#Introduction-1",
    "page": "Home",
    "title": "Introduction",
    "category": "section",
    "text": "MPIFiles.jl is a Julia package for handling files that are related to the tomographic imaging method magnetic particle imaging. It supports different file formats:Brukerfiles, i.e. files stored using the preclinical MPI scanner from Bruker\nMagnetic Particle Imaging Data Format (MDF) files\nIMT files, i.e. files created at the Institute of Medical Engineering in LübeckFor all of these formats there is full support for reading the files. Write support is currently only available for MDF files. All files can be converted to MDF files using this capability.MPIFiles.jl provides a generic interface for different MPI files. In turn it is possible to write generic algorithms that work for all supported file formats.MPI files can be divided into three different categoriesMeasurements\nSystem Matrices\nReconstruction ResultsEach of these file types is supported and discussed in the referenced pages."
},

{
    "location": "index.html#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "Start julia and open the package mode by entering ]. Then enteradd MPIFilesThis will install the packages MPIFiles.jl and all its dependencies."
},

{
    "location": "index.html#License-/-Terms-of-Usage-1",
    "page": "Home",
    "title": "License / Terms of Usage",
    "category": "section",
    "text": "The source code of this project is licensed under the MIT license. This implies that you are free to use, share, and adapt it. However, please give appropriate credit by citing the project."
},

{
    "location": "index.html#Contact-1",
    "page": "Home",
    "title": "Contact",
    "category": "section",
    "text": "If you have problems using the software, find mistakes, or have general questions please use the issue tracker to contact us."
},

{
    "location": "index.html#Contributors-1",
    "page": "Home",
    "title": "Contributors",
    "category": "section",
    "text": "Tobias Knopp\nMartin Möddel\nPatryk Szwargulski\nFlorian Griese\nFranziska Werner\nNadine Gdaniec\nMarija Boberg"
},

{
    "location": "gettingStarted.html#",
    "page": "Getting Started",
    "title": "Getting Started",
    "category": "page",
    "text": ""
},

{
    "location": "gettingStarted.html#Getting-Started-1",
    "page": "Getting Started",
    "title": "Getting Started",
    "category": "section",
    "text": "An MPI data file consists of a collection of parameters that can be divided into metadata and measurement data. Let us now consider that the string filename contains the path to an MPI file (e.g. an MDF file). Then be can open the file by callingjulia> f = MPIFile(filename)f can be considered to be a handle to the file. The file will be automatically be closed when f is garbage collected. The philosophy of MPIFiles.jl is that the content of the file is only loaded on demand. Hence, opening an MPI file is a cheap operations. This design allows it, to handle system matrices, which are larger than the main memory of the computer.Using the file handle it is possible now to read out different metadata. For instance we can determine the number of frames measured:julia> acqNumFrames(f)\n500Or we can access the drive field strengthjulia> dfStrength(f)\n1×3×1 Array{Float64,3}:\n[:, :, 1] =\n 0.014  0.014  0.0Now let us load some measurement data. This can be done by callingu = getMeasurementsFD(f, frames=1:100, numAverages=100)Then we can display the data using the PyPlot packageusing PyPlot\nfigure(6, figsize=(6,4))\nsemilogy(abs.(u[1:400,1,1,1]))(Image: Spectrum)This shows a typical spectrum for a 2D Lissajous sampling pattern. The getMeasurementsFD is a high level interface for loading MPI data, which has several parameters that allow to customize the loading process. Details on loading measurement data are outlined in Measurements.In the following we will first discuss the low level interface."
},

{
    "location": "lowlevel.html#",
    "page": "Low Level Interface",
    "title": "Low Level Interface",
    "category": "page",
    "text": ""
},

{
    "location": "lowlevel.html#Low-Level-Interface-1",
    "page": "Low Level Interface",
    "title": "Low Level Interface",
    "category": "section",
    "text": "The low level interface of MPIFiles.jl consists of a collection of methods that need to be implemented for each file format. It consists of the following methods# general\nversion, uuid\n\n# study parameters\nstudyName, studyNumber, studyUuid, studyDescription\n\n# experiment parameters\nexperimentName, experimentNumber, experimentUuid, experimentDescription,\nexperimentSubject, experimentIsSimulation, experimentIsCalibration,\nexperimentHasMeasurement, experimentHasReconstruction\n\n# tracer parameters\ntracerName, tracerBatch, tracerVolume, tracerConcentration, tracerSolute,\ntracerInjectionTime, tracerVendor\n\n# scanner parameters\nscannerFacility, scannerOperator, scannerManufacturer, scannerName, scannerTopology\n\n# acquisition parameters\nacqStartTime, acqNumFrames, acqNumAverages, acqGradient, acqOffsetField,\nacqNumPeriodsPerFrame, acqSize\n\n# drive-field parameters\ndfNumChannels, dfStrength, dfPhase, dfBaseFrequency, dfCustomWaveform, dfDivider,\ndfWaveform, dfCycle\n\n# receiver parameters\nrxNumChannels, rxBandwidth, rxNumSamplingPoints, rxTransferFunction, rxUnit,\nrxDataConversionFactor, rxInductionFactor\n\n# measurements\nmeasData, measDataTDPeriods, measIsFourierTransformed, measIsTFCorrected,\nmeasIsBGCorrected, measIsTransposed, measIsFramePermutation, measIsFrequencySelection,\nmeasIsBGFrame, measIsSpectralLeakageCorrected, measFramePermutation\n\n# calibrations\ncalibSNR, calibFov, calibFovCenter, calibSize, calibOrder, calibPositions,\ncalibOffsetField, calibDeltaSampleSize, calibMethod, calibIsMeanderingGrid\n\n# reconstruction results\nrecoData, recoFov, recoFovCenter, recoSize, recoOrder, recoPositions\n\n# additional functions that should be implemented by an MPIFile\nfilepath, systemMatrixWithBG, systemMatrix, selectedChannelsThe interface is structured in a similar way as the parameters within the MDF. Basically, there is a direct mapping between the MDF parameters and the MPIFiles interface. For instance the parameter acqNumAvarages maps to the MDF parameter /acquisition/numAverages. Also the dimensionality of the parameters described in the MDF is preserved. Thus, the MDF specification can be used as a documentation of the low level interface of MPIFiles.note: Note\nNote that the dimensions in the MDF documentation are flipped compared to the dimensions in Julia. This is because Julia stores the data in column major order, while HDF5 considers row major order"
},

{
    "location": "conversion.html#",
    "page": "Conversion",
    "title": "Conversion",
    "category": "page",
    "text": ""
},

{
    "location": "conversion.html#Conversion-1",
    "page": "Conversion",
    "title": "Conversion",
    "category": "section",
    "text": "With the support for reading different file formats and the ability to store data in the MDF, it is also possible to convert files into MDF. This can be done by callingsaveasMDF(filenameOut, filenameIn)The second argument can alternatively also be an MPIFile handle.There is also a more low level interface which gives the user the control to change parameters before storing. This look like thisparams = loadDataset(f)\n# do something with params\nsaveasMDF(filenameOut, params)Here, f is an MPIFile handle and the command loadDataset loads the entire dataset including all parameters into a Julia Dict that can be modified by the user. After modification one can store the data by passing the Dict as the second argument to the saveasMDF function.note: Note\nThe parameters in the Dict returned by loadDataset have the same keys as the corresponding accessor functions listed in the Low Level Interface."
},

{
    "location": "measurements.html#",
    "page": "Measurements",
    "title": "Measurements",
    "category": "page",
    "text": ""
},

{
    "location": "measurements.html#Measurements-1",
    "page": "Measurements",
    "title": "Measurements",
    "category": "section",
    "text": "The low level interface allows to load measured MPI data via the measData function. The returned data is exactly how it is stored on disc. This has the disadvantage that the user needs to handle different sorts of data that can be stored in the measData field. To cope with this issue, the MDF also has a high level interface for loading measurement data. The first is the functionfunction getMeasurements(f::MPIFile, neglectBGFrames=true;\n                frames=neglectBGFrames ? (1:acqNumFGFrames(f)) : (1:acqNumFrames(f)),\n                numAverages=1,\n                bgCorrection=false,\n                interpolateBG=false,\n                tfCorrection=measIsTFCorrected(f),\n                sortFrames=false,\n                spectralLeakageCorrection=true,\n                kargs...)that loads the MPI data in time domain. Background frames can be neglected or included, frames can be selected by specifying frames, block averaging can be applied by specifying numAverages, bgCorrection allows to apply background correction, tfCorrection allows for a correction of the transfer function, interpolateBG applies an optional interpolation in case that multiple background intervals are included in the measurement, sortFrames puts all background frames to the end of the returned data file, and spectralLeakageCorrection controls whether a spectral leakage correction is applied.The array returned by getMeasurements is of type Float32 and has four dimensionstime dimension (over one period)\nreceive channel dimension\npatch dimension\nframe dimensionInstead of loading the data in time domain, one can also load the frequency domain data by callingfunction getMeasurementsFD(f::MPIFile, neglectBGFrames=true;\n                  loadasreal=false,\n                  transposed=false,\n                  frequencies=nothing,\n                  tfCorrection=measIsTFCorrected(f),\n                  kargs...)The function has basically the same parameters as getMeasurements but additionally it is possible to load the data in real form (useful when using a solver that cannot handle complex numbers), it is possible to specify the frequencies (specified by the indices) that should be loaded, and it is possible to transpose the data in a special way, where the frame dimension is changed to be the first dimension. getMeasurementsFD returns a 4D array where of type ComplexF32 with dimensionsfrequency dimension\nreceive channel dimension\npatch dimension\nframe dimension"
},

{
    "location": "systemmatrix.html#",
    "page": "System Matrix",
    "title": "System Matrix",
    "category": "page",
    "text": ""
},

{
    "location": "systemmatrix.html#System-Matrices-1",
    "page": "System Matrix",
    "title": "System Matrices",
    "category": "section",
    "text": "For loading the system matrix, one could in principle again call measData but there is again a high level function for this job. Since system functions can be very large it is crutial to load only the subset of frequencies that are used during reconstruction The high level system matrix loading function is called getSystemMatrix and has the following interfacefunction getSystemMatrix(f::MPIFile,\n                         frequencies=1:rxNumFrequencies(f)*rxNumChannels(f);\n                         bgCorrection=false,\n                         loadasreal=false,\n                         kargs...)loadasreal can again be used when using a solver requiring real numbers. The most important parameter is frequencies, which defaults to all possible frequencies over all receive channels. In practice one will determine the frequencies using the the Frequency Filter functionality."
},

{
    "location": "frequencyFilter.html#",
    "page": "Frequency Filter",
    "title": "Frequency Filter",
    "category": "page",
    "text": ""
},

{
    "location": "frequencyFilter.html#Frequency-Filter-1",
    "page": "Frequency Filter",
    "title": "Frequency Filter",
    "category": "section",
    "text": "A frequency filter can be calculated using the functionfunction filterFrequencies(f::MPIFile;\n                           SNRThresh=-1,\n                           minFreq=0, maxFreq=rxBandwidth(f),\n                           recChannels=1:rxNumChannels(f),\n                           sortBySNR=false,\n                           numUsedFreqs=-1,\n                           stepsize=1,\n                           maxMixingOrder=-1,\n                           sortByMixFactors=false)Usually one will apply an SNR threshold SNRThresh > 1.5 and a minFreq that is larger than the excitation frequencies. The frequencies are specified in Hz. Also useful is the opportunity to select specific receive channels by specifying recChannels.The return value of filterFrequencies is of type Vector{Int64} and can be directly passed to getMeasurements, getMeasurementsFD, and getSystemMatrix."
},

{
    "location": "images.html#",
    "page": "Reconstructions",
    "title": "Reconstructions",
    "category": "page",
    "text": ""
},

{
    "location": "images.html#Reconstruction-Results-1",
    "page": "Reconstructions",
    "title": "Reconstruction Results",
    "category": "section",
    "text": "MDF files can also contain reconstruction results instead of measurement data. The low level results can be retrieved using the Low Level Interfacefunction recoData(f::MPIFile)\nfunction recoFov(f::MPIFile)\nfunction recoFovCenter(f::MPIFile)\nfunction recoSize(f::MPIFile)\nfunction recoOrder(f::MPIFile)\nfunction recoPositions(f::MPIFile)Instead one can also combine these data into an ImageMetadata object from the Images.jl package by calling the functionsfunction loadRecoData(filename::AbstractString)The ImageMetadata object does also pull all relevant metadata from an MDF such that the file can be also be stored usingfunction saveRecoData(filename, image::ImageMeta)These two functions are especially relevant when using the package   MPIReco.jl"
},

]}
