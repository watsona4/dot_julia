using MPIReco

@testset "multi-patch in-memory reconstruction" begin
  bSF = MultiMPIFile(["SF_MP"])
  b = MultiMPIFile(["dataMP01", "dataMP02", "dataMP03", "dataMP04"])
  names = (:color, :x, :y, :z, :time)
  values1 = (1:1,
	    -27.5u"mm":1.25u"mm":27.5u"mm",
	    -27.5u"mm":1.25u"mm":27.5u"mm",
	    0.0u"mm":1.0u"mm":0.0u"mm",
	    0.0u"ms":0.6528u"ms":0.0u"ms")
  values2 = (values1[1], -19.375u"mm":1.25u"mm":19.375u"mm",
	     -19.375u"mm":1.25u"mm":19.375u"mm", values1[4:5]...)

  # basic multi-patch reconstruction
  c1 = reconstruction(bSF, b;
			    SNRThresh=5, frames=1, minFreq=80e3,
			    recChannels=1:2,iterations=1,
			    spectralLeakageCorrection=false)
  @test axisnames(c1) == names
  @test axisvalues(c1) == values1
  exportImage("./img/MultiPatch1.png", data(data(c1[1,:,:,1,1])))

  # TODO test description
  c2 = reconstruction(bSF, b;
			    SNRThresh=5, frames=1, minFreq=80e3,
			    recChannels=1:2,iterations=1, roundPatches=true,
			    spectralLeakageCorrection=false)
  @test axisnames(c2) == names
  @test axisvalues(c2) == values1
  exportImage("./img/MultiPatch2.png", data(data(c2[1,:,:,1,1])))

  # multi-patch reconstruction using multiple system matrices
  bSFs = MultiMPIFile(["SF_MP01", "SF_MP02", "SF_MP03", "SF_MP04"])
  c3 = reconstruction(bSFs, b;
			    SNRThresh=5, frames=1, minFreq=80e3,
			    recChannels=1:2,iterations=1,
			    spectralLeakageCorrection=false)
  @test axisnames(c3) == names
  @test axisvalues(c3) == values2
  exportImage("./img/MultiPatch3.png", data(data(c3[1,:,:,1,1])))

  # flexible multi-patch reconstruction
  bSFs = MultiMPIFile(["SF_MP01", "SF_MP02", "SF_MP03", "SF_MP04"])
  mapping = [1,2,3,4]
  freq = filterFrequencies(bSFs, SNRThresh=5, minFreq=80e3)
  S = [getSF(SF,freq,nothing,"kaczmarz", bgcorrection=false)[1] for SF in bSFs]
  SFGridCenter = zeros(3,4)
  FFPos = zeros(3,4)
  FFPos[:,1] = [-0.008, 0.008, 0.0]
  FFPos[:,2] = [-0.008, -0.008, 0.0]
  FFPos[:,3] = [0.008, 0.008, 0.0]
  FFPos[:,4] = [0.008, -0.008, 0.0]
  c4 = reconstruction(bSFs, b;
			    SNRThresh=5, frames=1, minFreq=80e3,
			    recChannels=1:2,iterations=1,
			    spectralLeakageCorrection=false, mapping=mapping,
			    systemMatrices = S, SFGridCenter=SFGridCenter,
			    FFPos=FFPos, FFPosSF=FFPos)
  @test axisnames(c4) == names
  @test axisvalues(c4) == values2
  exportImage("./img/MultiPatch4.png", data(data(c4[1,:,:,1,1])))
  # TODO the last test shows odd results
end
