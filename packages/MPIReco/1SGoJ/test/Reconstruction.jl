using MPIReco

@testset "single- and multi-channel in-memory reconstruction" begin
  bSF = MPIFile("SF_MP")
  b = MPIFile("dataMP01")
  names = (:color, :x, :y, :z, :time)
  values = (1:1,
	    -27.375u"mm":1.25u"mm":11.375u"mm",
	    -11.375u"mm":1.25u"mm":27.375u"mm",
	    0.0u"mm":1.0u"mm":0.0u"mm",
	    0.0u"ms":0.6528u"ms":0.0u"ms")

  # standard reconstruction
  c1 = reconstruction(bSF, b; SNRThresh=5, frames=1, minFreq=80e3,
		      recChannels=1:2, iterations=1, spectralLeakageCorrection=true)
  @test axisnames(c1) == names
  @test axisvalues(c1) == values
  exportImage("./img/Reconstruction1.png", data(data(c1[1,:,:,1,1])))

  # fused lasso
  c2 = reconstruction(bSF, b; SNRThresh=5, frames=1, minFreq=80e3,
		      recChannels=1:2, iterations=100, solver="fusedlasso",
		      loadasreal=true, λ=[0.01,0.01])
  @test axisnames(c2) == names
  @test axisvalues(c2) == values
  exportImage("./img/Reconstruction2.png", data(data(c2[1,:,:,1,1])))

  # with interpolation
  c3 = reconstruction(bSF, b; SNRThresh=5, frames=1, minFreq=80e3,
		      recChannels=1:2, gridsize=[100,100,1],iterations=1)
  @test axisnames(c3) == names
  @test axisvalues(c3) == (values[1], -27.8u"mm":0.4u"mm":11.8u"mm", -11.8u"mm":0.4u"mm":27.8u"mm", values[4:5]...)
  exportImage("./img/Reconstruction3.png", data(data(c3[1,:,:,1,1])))

  # with fov adpation and center shift
  c4 = reconstruction(bSF, b; SNRThresh=5, frames=1, minFreq=80e3,
		      recChannels=1:2, gridsize=[50,50,1],fov=[0.04,0.04,1],
		      center=[0.0,-0.01,0], iterations=1)
  @test axisnames(c4) == names
  # TODO Tobi: does this make sense?
  @test axisvalues(c4) == (values[1], -27.6u"mm":0.8u"mm":11.6u"mm", -11.6u"mm":0.8u"mm":27.6u"mm", 499.5u"mm":1000.0u"mm":499.5u"mm", values[5])
  exportImage("./img/Reconstruction4.png", data(data(c4[1,:,:,1,1])))

  # multi colored reconstruction (deprecated interface)
  c5 = reconstruction([bSF,bSF], b;
		      SNRThresh=5, frames=1, minFreq=80e3,
		      recChannels=1:2, iterations=1)
  @test axisnames(c5) == names
  @test axisvalues(c5) == (1:2,values[2:end]...)
  exportImage("./img/Reconstruction5a.png", data(data(c5[1,:,:,1,1])))
  exportImage("./img/Reconstruction5b.png", data(data(c5[2,:,:,1,1])))

  # multi colored reconstruction (new interface)
  c5 = reconstruction(MultiContrastFile([bSF,bSF]), b;
          SNRThresh=5, frames=1, minFreq=80e3,
          recChannels=1:2, iterations=1)
  @test axisnames(c5) == names
  @test axisvalues(c5) == (1:2,values[2:end]...)
  exportImage("./img/Reconstruction5c.png", data(data(c5[1,:,:,1,1])))
  exportImage("./img/Reconstruction5d.png", data(data(c5[2,:,:,1,1])))

  # dict based reco
  r = defaultRecoParams()
  r[:measPath] = filepath(b)
  r[:SFPath] = filepath(bSF)
  r[:frames] =  1
  r[:minFreq] = 80e3
  r[:SNRThresh] = 4
  r[:lambd] = 0.001
  r[:iterations] = 1
  c6 = reconstruction(r)
  @test axisnames(c6) == names
  @test axisvalues(c6) == values
  exportImage("./img/Reconstruction6.png", data(data(c6[1,:,:,1,1])))

  # channel weighting
  c7a = reconstruction(bSF, b; SNRThresh=5, frames=1, minFreq=80e3,
		      recChannels=1:2, iterations=1, λ=0.1,
          weightType=WeightingType.Channel, channelWeights=[1.0,1.0,1.0])

  exportImage("./img/Reconstruction7a.png", data(data(c7a[1,:,:,1,1])))

  c7b = reconstruction(bSF, b; SNRThresh=5, frames=1, minFreq=80e3,
		      recChannels=1:2, iterations=1, λ=0.1,
          weightType=WeightingType.Channel, channelWeights=[1.0,0.001,1.0])

  exportImage("./img/Reconstruction7b.png", data(data(c7b[1,:,:,1,1])))

  c7c = reconstruction(bSF, b; SNRThresh=5, frames=1, minFreq=80e3,
		      recChannels=1:2, iterations=1, λ=0.1,
          weightType=WeightingType.Channel, channelWeights=[0.001,1.0,1.0])

  exportImage("./img/Reconstruction7c.png", data(data(c7c[1,:,:,1,1])))

end
