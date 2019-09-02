# This file is part of Kpax3. License is MIT.

function test_state_list_constructor()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

  settings = Kpax3.KSettings(ifile, ofile)

  x = Kpax3.AminoAcidData(settings)

  (m, n) = size(x.data)

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(x.data, settings.γ, settings.r)

  slist = Kpax3.AminoAcidStateList(x.data, [3; 3; 3; 1; 1; 2], priorR, priorC, settings)

  @test isa(slist.state, Vector{Kpax3.AminoAcidState})
  @test isa(slist.logpp, Vector{Float64})
  @test isa(slist.rank, Vector{Int})
  @test all(slist.logpp .< 0.0)
  @test length(unique(slist.logpp)) > 1
  @test all(0 .< slist.rank .< settings.popsize + 1)
  @test length(unique(slist.rank)) == settings.popsize
  @test all(diff(slist.logpp[slist.rank]) .<= 0)

  @test slist.state[1].R == [3; 3; 3; 1; 1; 2]

  for i in 1:settings.popsize
    t = Kpax3.AminoAcidState(x.data, slist.state[i].R, priorR, priorC, settings)

    l = t.cl[1:t.k]

    @test slist.state[i].R == t.R
    @test slist.state[i].C == t.C
    @test slist.state[i].emptycluster == t.emptycluster
    @test slist.state[i].cl == t.cl
    @test slist.state[i].k == t.k
    @test slist.state[i].v == t.v
    @test slist.state[i].n1s == t.n1s
    for g in l
      @test slist.state[i].unit[g][1:slist.state[i].v[g]]==t.unit[g][1:t.v[g]]
    end
    @test slist.state[i].logpR == t.logpR
    @test slist.state[i].logpC == t.logpC
    @test slist.state[i].loglik == t.loglik
    @test slist.state[i].logpp == t.logpp

    @test isapprox(slist.logpp[i], slist.state[i].logpp, atol=ε)
  end

  state = Kpax3.AminoAcidState(x.data, [3; 3; 3; 1; 1; 2], priorR, priorC, settings)
  slist = Kpax3.AminoAcidStateList(settings.popsize, state)

  @test isa(slist.state, Vector{Kpax3.AminoAcidState})
  @test isa(slist.logpp, Vector{Float64})
  @test isa(slist.rank, Vector{Int})
  @test all(slist.logpp .< 0.0)
  @test length(unique(slist.logpp)) == 1
  @test all(0 .< slist.rank .< settings.popsize + 1)
  @test length(unique(slist.rank)) == settings.popsize
  @test all(diff(slist.logpp[slist.rank]) .<= 0)
  @test slist.rank == Int[i for i in 1:settings.popsize]

  for i in 1:settings.popsize
    @test slist.state[i].R == state.R
    @test slist.state[i].C == state.C
    @test slist.state[i].emptycluster == state.emptycluster
    @test slist.state[i].cl == state.cl
    @test slist.state[i].k == state.k
    @test slist.state[i].v == state.v
    @test slist.state[i].n1s == state.n1s
    for g in 1:3
      @test (slist.state[i].unit[g][1:slist.state[i].v[g]] ==
             state.unit[g][1:state.v[g]])
    end
    @test slist.state[i].logpR == state.logpR
    @test slist.state[i].logpC == state.logpC
    @test slist.state[i].loglik == state.loglik
    @test slist.state[i].logpp == state.logpp
    @test slist.logpp[i] == state.logpp
  end

  nothing
end

test_state_list_constructor()

function test_state_list_copy_basic()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

  settings = Kpax3.KSettings(ifile, ofile)

  x = Kpax3.AminoAcidData(settings)

  (m, n) = size(x.data)

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(x.data, settings.γ, settings.r)

  s1 = Kpax3.AminoAcidStateList(x.data, [3; 3; 3; 1; 1; 2], priorR, priorC, settings)
  s2 = Kpax3.AminoAcidStateList(x.data, [1; 1; 1; 1; 1; 1], priorR, priorC, settings)

  Kpax3.copystatelist!(s2, s1, settings.popsize)

  for i in 1:settings.popsize
    j = s1.rank[i]

    r = 1:s1.state[j].k
    l = s1.state[j].cl[r]

    @test s2.state[i].R == s1.state[j].R
    @test s2.state[i].C[l, :] == s1.state[j].C[l, :]
    @test s2.state[i].emptycluster[r] == s1.state[j].emptycluster[r]
    @test s2.state[i].cl[r] == s1.state[j].cl[r]
    @test s2.state[i].k == s1.state[j].k
    @test s2.state[i].v[l] == s1.state[j].v[l]
    @test s2.state[i].n1s[l, :] == s1.state[j].n1s[l, :]
    for g in l
      @test (s2.state[i].unit[g][1:s2.state[i].v[g]] ==
             s1.state[j].unit[g][1:s1.state[j].v[g]])
    end
    @test s2.state[i].logpR == s1.state[j].logpR
    @test s2.state[i].logpC == s1.state[j].logpC
    @test s2.state[i].loglik == s1.state[j].loglik
    @test s2.state[i].logpp == s1.state[j].logpp

    @test s2.logpp[i] == s1.logpp[j]

    @test s2.rank[i] == i
  end

  nothing
end

test_state_list_copy_basic()
