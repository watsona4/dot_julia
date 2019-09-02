var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#MPIReco.jl-1",
    "page": "Home",
    "title": "MPIReco.jl",
    "category": "section",
    "text": "Julia package for the reconstruction of magnetic particle imaging (MPI) data"
},

{
    "location": "index.html#Introduction-1",
    "page": "Home",
    "title": "Introduction",
    "category": "section",
    "text": "This project provides functions for the reconstruction of MPI data. The project is implemented in the programming language Julia and contains algorithms forBasic Reconstruction using a system matrix based approach\nMulti-Patch Reconstruction for data that has been acquired using a focus field sequence\nMulti-Contrast Reconstruction\nMatrix-Compression TechniquesKey features areFrequency filtering for memory efficient reconstruction. Only frequencies used during reconstructions are loaded into memory.\nDifferent solvers provided by the package RegularizedLeastSquares.jl\nHigh-level until low-level reconstruction providing maximum flexibility for the user\nSpectral leakage correction (implemented in MPIFiles.jl)"
},

{
    "location": "index.html#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "Start julia and open the package mode by entering ]. Then enteradd MPIRecoThis will install the packages MPIReco.jl and all its dependencies. In particular this will install the core dependencies MPIFiles and RegularizedLeastSquares."
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
    "text": "Tobias Knopp\nMartin Möddel\nPatryk Szwargulski"
},

{
    "location": "overview.html#",
    "page": "Getting Started",
    "title": "Getting Started",
    "category": "page",
    "text": ""
},

{
    "location": "overview.html#Getting-Started-1",
    "page": "Getting Started",
    "title": "Getting Started",
    "category": "section",
    "text": "In order to get started we will first gather some MPI data. To this end we enter the Pkg mode in Julia (]) and execute the unit tests of MPIRecotest MPIRecoNow there will be several MPI files in the test directory. All the following examples assume that you entered the test directory and loaded MPIReco usingusing MPIReco\ncd(joinpath(dirname(pathof(MPIReco)),\"..\",\"test\"))"
},

{
    "location": "overview.html#First-Reconstruction-1",
    "page": "Getting Started",
    "title": "First Reconstruction",
    "category": "section",
    "text": "We will start looking at a very basic reconstruction scriptusing MPIReco\n\nfSF = MPIFile(\"SF_MP\")\nf = MPIFile(\"dataMP01\")\n\nc = reconstruction(fSF, f;\n                   SNRThresh=5,\n                   frames=1:10,\n                   minFreq=80e3,\n                   recChannels=1:2,\n                   iterations=1,\n                   spectralLeakageCorrection=true)\nLets go through that script step by step. First, we create handles for the system matrix and the measurement data. Both are of the type MPIFile which is an abstract type that can for instance be an MDFFile or a BrukerFile.Using the handles to the MPI datasets we can call the reconstruction function that has various variants depending on the types that are passed to it. Here, we exploit the multiple dispatch mechanism of julia. In addition to the file handles we also apply several reconstruction parameters using keyword arguments. In this case, we set the SNR threshold to 5 implying that only matrix rows with an SNR above 5 are used during reconstruction. The parameter frame decides which frame of the measured data should be reconstructed.The object c is of type ImageMeta and contains not only the reconstructed data but also several metadata such as the reconstruction parameters being used. More details on the return type are discussed in the Reconstruction Results"
},

{
    "location": "overview.html#Data-Storage-1",
    "page": "Getting Started",
    "title": "Data Storage",
    "category": "section",
    "text": "One can store the reconstruction result into an MDF file by callingsaveRecoData(\"filename.mdf\", c)In order to load the data one callsc = loaddata(\"filename.mdf\", c)We will next take a closer look at different forms of the reconstruction routine."
},

{
    "location": "basicReconstruction.html#",
    "page": "Basic Reconstruction",
    "title": "Basic Reconstruction",
    "category": "page",
    "text": ""
},

{
    "location": "basicReconstruction.html#Basic-Reconstruction-1",
    "page": "Basic Reconstruction",
    "title": "Basic Reconstruction",
    "category": "section",
    "text": "MPIReco.jl provides different reconstruction levels. All of these reconstruction routines are called reconstruction and the dispatch is done based on the input types."
},

{
    "location": "basicReconstruction.html#On-Disk-Reconstruction-1",
    "page": "Basic Reconstruction",
    "title": "On Disk Reconstruction",
    "category": "section",
    "text": "This is the highest level reconstruction. The function signature is given byfunction reconstruction(d::MDFDatasetStore, study::Study,\n                        exp::Experiment, recoParams::Dict)This reconstruction is also called an on disk reconstruction because it assumes that one has a data store (i.e. a structured folder of files) where the file location is uniquely determined by the study name and experiment number. All reconstruction parameters are passed to this method by the recoParams dictionary. On disk reconstruction has the advantage that the routine will perform reconstruction only once for a particular set of parameters. If that parameter set has already been reconstructed, the data will loaded from disk. However, the on disk reconstruction needs some experience with dataset stores to set it up correctly and is not suited for unstructured data."
},

{
    "location": "basicReconstruction.html#In-Memory-Reconstruction-1",
    "page": "Basic Reconstruction",
    "title": "In Memory Reconstruction",
    "category": "section",
    "text": "The next level is the in memory reconstruction. Its function signature readsfunction reconstruction(recoParams::Dict)This routine requires that all parameters are put into a dictionary. An overview how this dictionary looks like is given in the section Parameters.The above reconstruction method basically does two thingsPull out the location of measurement data and system matrix from the recoParams dictionary.\nPass all parameter to the low level reconstruction method in the form of keyword parameters.In turn the next level reconstruction looks like thisfunction reconstruction(bSF::Union{T,Vector{T}}, bMeas::MPIFile; kargs...)There are, however also some reconstruction methods in-between that look like thisfunction reconstruction(filenameSF::AbstractString, filenameMeas::AbstractString; kargs...)\nfunction reconstruction(filenameMeas::AbstractString; kargs...)In both cases, an MPIFile is created based on the input filename. The second version also guesses the system matrix based on what is stored within the measurement file. This usually only works, if this is executed on a system where the files are stored at exactly the same location as how they have been measured."
},

{
    "location": "basicReconstruction.html#Middle-Level-Reconstruction-1",
    "page": "Basic Reconstruction",
    "title": "Middle Level Reconstruction",
    "category": "section",
    "text": "The middle level reconstruction first checks, whether the dataset is a multi-patch or a single-patch file. Then it will call either reconstructionSinglePatch or reconstructionMultiPatch. Both have essentially the signaturefunction reconstructionSinglePatch(bSF::Union{T,Vector{T}}, bMeas::MPIFile;\n                                  minFreq=0, maxFreq=1.25e6, SNRThresh=-1,\n                                  maxMixingOrder=-1, numUsedFreqs=-1, sortBySNR=false, recChannels=1:numReceivers(bMeas),\n                                  bEmpty = nothing, bgFrames = 1, fgFrames = 1,\n                                  varMeanThresh = 0, minAmplification=2, kargs...) where {T<:MPIFile}Here, one can see various parameters that can be used to control, which frequency components are being used for reconstruction. All these parameters are passed to the filterFrequencies function from MPIFiles.jl.The function reconstructionSinglePatch performs the frequency filtering and then callsfunction reconstruction(bSF::Union{T,Vector{T}}, bMeas::MPIFile, freq::Array;\n  bEmpty = nothing, bgFrames = 1,  denoiseWeight = 0, redFactor = 0.0, thresh = nothing,\n  loadasreal = false, solver = \"kaczmarz\", sparseTrafo = nothing, saveTrafo=false,\n  gridsize = gridSizeCommon(bSF), fov=calibFov(bSF), center=[0.0,0.0,0.0], useDFFoV=false,\n  deadPixels=Int[], bgCorrectionInternal=false, kargs...) where {T<:MPIFile}One can see that the frequency index is passed to this function as the third argument. All new keyword arguments are essentially used for determining the way how the system matrix is loaded. For instance with the parameters gridsize, fov, center it is possible to change the grid at which the system function is being loaded.Once the system matrix is loaded, the next lower level function is called:function reconstruction(S, bSF::Union{T,Vector{T}}, bMeas::MPIFile, freq::Array, grid;\n  frames = nothing, bEmpty = nothing, bgFrames = 1, nAverages = 1, numAverages=nAverages,\n  sparseTrafo = nothing, loadasreal = false, maxload = 100, maskDFFOV=false,\n  weightType=WeightingType.None, weightingLimit = 0, solver = \"kaczmarz\",\n  spectralCleaning=true, fgFrames=1:10, bgCorrectionInternal=false,\n  noiseFreqThresh=0.0, kargs...) where {T<:MPIFile}This function is responsible for loading the measurement data and potential background data that is subtracted from the measurements. For any frame to be reconstructed, the low level reconstruction routine is called."
},

{
    "location": "basicReconstruction.html#Low-Level-Reconstruction-1",
    "page": "Basic Reconstruction",
    "title": "Low Level Reconstruction",
    "category": "section",
    "text": "Finally, we have arrived at the low level reconstruction routine that has the signaturefunction reconstruction(S, u::Array, shape; sparseTrafo = nothing,\n                        lambd=0, progress=nothing, solver = \"kaczmarz\",\n                        weights=nothing, reshapesolution = true, kargs...)One can see that it requires the system matrix S and the measurements u to be already loaded.We note that S is typeless for a reason here. For a regular reconstruction one will basically feed in an Array{ComplexF32,2} in here, although more precisely it will be a Transposed version of that type if the Kaczmarz algorithm is being used for efficiency reasons.However, in case that matrix compression is applied S will be of type SparseMatrixCSC. And for Multi-Patch Reconstruction S will be of type FFOperator. Hence, the solvers are implemented in a very generic way and require only certain functions to be implemented. The low level reconstruction method calls one of the solvers from RegularizedLeastSquares.jl."
},

{
    "location": "parameters.html#",
    "page": "Parameters",
    "title": "Parameters",
    "category": "page",
    "text": ""
},

{
    "location": "parameters.html#Parameters-1",
    "page": "Parameters",
    "title": "Parameters",
    "category": "section",
    "text": ""
},

{
    "location": "recoResults.html#",
    "page": "Results",
    "title": "Results",
    "category": "page",
    "text": ""
},

{
    "location": "recoResults.html#Reconstruction-Results-1",
    "page": "Results",
    "title": "Reconstruction Results",
    "category": "section",
    "text": "The object c is of type ImageMeta and contains not only the reconstructed data but also several metadata such as the reconstruction parameters being used. c has in total 5 dimensions. The first dimension encodes multi-spectral channels. Dimensions 2-4 encode the three spatial dimensions. The last dimension contains the number of frames being stored in c."
},

{
    "location": "multiContrast.html#",
    "page": "Multi-Contrast",
    "title": "Multi-Contrast",
    "category": "page",
    "text": ""
},

{
    "location": "multiContrast.html#Multi-Contrast-Reconstruction-1",
    "page": "Multi-Contrast",
    "title": "Multi-Contrast Reconstruction",
    "category": "section",
    "text": "Until now we have discussed single-contrast reconstruction in which case the reconstructed image c has a singleton first dimension. To perform multi-contrast reconstruction one has to specify multiple system matricesbSFa = MPIFile(filenameA)\nbSFb = MPIFile(filenameB)and can then invokec = reconstruction([bSFa, bSFb], b;\n                    SNRThresh=5, frames=1, minFreq=80e3,\n                    recChannels=1:2, iterations=1)Now one can access the first and second channel by c[1,:,:,:] and c[2,:,:,:]."
},

{
    "location": "multiPatch.html#",
    "page": "Multi-Patch",
    "title": "Multi-Patch",
    "category": "page",
    "text": ""
},

{
    "location": "multiPatch.html#Multi-Patch-Reconstruction-1",
    "page": "Multi-Patch",
    "title": "Multi-Patch Reconstruction",
    "category": "section",
    "text": "For multi-patch reconstruction the method proposed by Szwargulski et al. is implemented in MPIReco. It is generalized however.We first discuss the measurements for the multi-patch case. On modern MPI scanners the BrukerFile or MDFFile can be used as is. However, the data that we use in our unit tests consists of several single-patch measurements. to combine these measurements we callb = MultiMPIFile([\"dataMP01\", \"dataMP02\", \"dataMP03\", \"dataMP04\"])b now can be uses as if were a multi-patch file.Now we get to the system matrix. The most simple approach is to use a single system matrix that was measured at the center. This can be done usingbSF = MultiMPIFile([\"SF_MP\"])\n\nc = reconstruction(bSF, b; SNRThresh=5, frames=1, minFreq=80e3,\n                   recChannels=1:2, iterations=1, spectralLeakageCorrection=false)The reconstruction parameters are not special here but are the same as discussed in the Parameters section.It is also possible to use multiple system matrices, which is currently the best way to take field imperfection into account. Our test data has four patches and we therefore can usebSF = MultiMPIFile([\"SF_MP01\", \"SF_MP02\", \"SF_MP03\", \"SF_MP04\"])\n\nc = reconstruction(bSF, b; SNRThresh=5, frames=1, minFreq=80e3,\n                   recChannels=1:2, iterations=1, spectralLeakageCorrection=false)Now we want somewhat more flexibility anddefine a mapping between the system matrix and the patches, here we allow to use the same system matrix for multiple patches\nmake it possible to change the FFP position. Usually the value stored in the file is not 100% correct due to field imperfections.\nwe might also want to preload the system matricesAll those thing can be done as is shown in the following examplebSFs = MultiMPIFile([\"SF_MP01\", \"SF_MP02\", \"SF_MP03\", \"SF_MP04\"])\nmapping = [1,2,3,4]\nfreq = filterFrequencies(bSFs, SNRThresh=5, minFreq=80e3)\nS = [getSF(SF,freq,nothing,\"kaczmarz\", bgcorrection=false)[1] for SF in bSFs]\nSFGridCenter = zeros(3,4)\nFFPos = zeros(3,4)\nFFPos[:,1] = [-0.008, 0.008, 0.0]\nFFPos[:,2] = [-0.008, -0.008, 0.0]\nFFPos[:,3] = [0.008, 0.008, 0.0]\nFFPos[:,4] = [0.008, -0.008, 0.0]\nc4 = reconstruction(bSFs, b; SNRThresh=5, frames=1, minFreq=80e3,\n        recChannels=1:2,iterations=1, spectralLeakageCorrection=false,\n        mapping=mapping, systemMatrices = S, SFGridCenter=SFGridCenter,\n        FFPos=FFPos, FFPosSF=FFPos)"
},

{
    "location": "matrixCompression.html#",
    "page": "Compression",
    "title": "Compression",
    "category": "page",
    "text": ""
},

{
    "location": "matrixCompression.html#Matrix-Compression-Techniques-1",
    "page": "Compression",
    "title": "Matrix-Compression Techniques",
    "category": "section",
    "text": ""
},

]}
