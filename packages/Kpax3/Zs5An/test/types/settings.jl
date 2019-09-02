# This file is part of Kpax3. License is MIT.

function test_settings_exceptions()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, miss=UInt8[63; 0])
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, l=-1)
  @test_throws Kpax3.KInputError  Kpax3.KSettings(ifile, ofile, gamma=[1.0; 0.0])
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, gamma=[1.0; 0.0; -1.0])
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, r=0.0)
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, r=-1.0)
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, maxclust=0)
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, maxunit=0)
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, verbosestep=-1)
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, popsize=-1)
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, popsize=0)
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, popsize=1)
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, maxiter=0)
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, maxgap=-1)
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, xrate=-1.0)
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, xrate=2.0)
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, mrate=-1.0)
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, mrate=2.0)
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, T=0)
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, burnin=-1)
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, tstep=-1)
  @test_throws Kpax3.KInputError  Kpax3.KSettings(ifile, ofile, op=[1.0; 0.0])
  @test_throws Kpax3.KDomainError Kpax3.KSettings(ifile, ofile, op=[1.0; -1.0; 0.0])

  nothing
end

test_settings_exceptions()

function test_settings_constructor()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"
  protein = false
  miss = zeros(UInt8, 0)
  l = 10
  α = 0.0
  θ = 1.0
  γ = [0.3; 0.3; 0.4]
  r = log(0.01) / log(0.9)
  maxclust = 2
  maxunit = 2
  verbose = false
  verbosestep = 1
  popsize = 10
  maxiter = 5
  maxgap = 1
  xrate = 0.8
  mrate = 0.2
  T = 10
  burnin = 100
  tstep = 2
  op = [0.7; 0.3; 0.0]

  settings = Kpax3.KSettings(ifile, ofile, protein=protein, miss=miss, l=l, alpha=α, theta=θ, gamma=γ, r=r, maxclust=maxclust, maxunit=maxunit, verbose=verbose, verbosestep=verbosestep, popsize=popsize, maxiter=maxiter, maxgap=maxgap, xrate=xrate, mrate=mrate, T=T, burnin=burnin, tstep=tstep, op=op)

  @test settings.ifile == ifile
  @test settings.ofile == ofile
  @test settings.l == l
  @test settings.α == α
  @test settings.θ == θ
  @test settings.γ == γ
  @test settings.r == r
  @test settings.maxclust == maxclust
  @test settings.maxunit == maxunit
  @test settings.verbose == verbose
  @test settings.verbosestep == verbosestep
  @test settings.popsize == popsize
  @test settings.maxiter == maxiter
  @test settings.maxgap == maxgap
  @test settings.xrate == xrate
  @test settings.mrate == mrate
  @test settings.T == T
  @test settings.burnin == burnin
  @test settings.tstep == tstep
  @test isa(settings.op, StatsBase.ProbabilityWeights)
  @test values(settings.op) == op

  settings = Kpax3.KSettings(ifile, ofile, protein=true, miss=zeros(UInt8, 0))

  @test settings.protein
  @test settings.miss == UInt8['?', '*', '#', '-', 'b', 'j', 'x', 'z']

  settings = Kpax3.KSettings(ifile, ofile, protein=true, miss=UInt8['?', '*', '#', 'b', 'j', 'x', 'z'])

  @test settings.protein
  @test settings.miss == UInt8['?', '*', '#', 'b', 'j', 'x', 'z']

  settings = Kpax3.KSettings(ifile, ofile, protein=false, miss=zeros(UInt8, 0))

  @test !settings.protein
  @test settings.miss == UInt8['?', '*', '#', '-', 'b', 'd', 'h', 'k', 'm', 'n', 'r', 's', 'v', 'w', 'x', 'y', 'j', 'z']

  settings = Kpax3.KSettings(ifile, ofile, protein=false, miss=UInt8['?', '*', '#', 'b', 'd', 'h', 'k', 'm', 'n', 'r', 's', 'v', 'w', 'x', 'y', 'j', 'z'])

  @test !settings.protein
  @test settings.miss == UInt8['?', '*', '#', 'b', 'd', 'h', 'k', 'm', 'n', 'r', 's', 'v', 'w', 'x', 'y', 'j', 'z']

  settings = Kpax3.KSettings(ifile, ofile, misscsv=Array{String}(undef, 0))

  @test settings.misscsv == [""]

  settings = Kpax3.KSettings(ifile, ofile, misscsv=["", "?", "X", "NA", "-", "."])

  @test settings.misscsv == ["", "?", "X", "NA", "-", "."]

  settings = Kpax3.KSettings(ifile, ofile, misscsv=["?", "X", "NA", "-", "."])

  @test settings.misscsv == ["", "?", "X", "NA", "-", "."]

  nothing
end

test_settings_constructor()
