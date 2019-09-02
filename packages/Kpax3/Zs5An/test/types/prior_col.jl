# This file is part of Kpax3. License is MIT.

# TODO: Test A and B

function test_prior_col_exceptions()
  data = UInt8[0 0 0 0 0 1;
               1 1 1 1 1 0;
               0 0 1 0 1 1;
               1 1 0 1 0 0;
               1 1 0 0 0 0;
               0 0 0 1 1 0;
               1 1 1 0 0 0;
               0 0 0 1 1 1;
               0 0 1 0 0 0;
               1 0 0 1 0 1;
               0 1 0 0 1 0;
               0 0 0 0 0 1;
               1 1 1 0 0 0;
               0 0 0 1 1 0;
               1 1 0 0 1 1;
               0 0 1 1 0 0;
               1 1 0 1 0 0;
               0 0 1 0 1 1]

  γ = [0.6; 0.35; 0.05]
  r = log(0.001) / log(0.95)

  @test_throws Kpax3.KInputError Kpax3.AminoAcidPriorCol(data, [1.0; 1.0; 1.0; 1.0], r)

  @test_throws Kpax3.KDomainError Kpax3.AminoAcidPriorCol(data, [-1.0; 1.0; 1.0], r)
  @test_throws Kpax3.KDomainError Kpax3.AminoAcidPriorCol(data, [1.0; -1.0; 1.0], r)
  @test_throws Kpax3.KDomainError Kpax3.AminoAcidPriorCol(data, [1.0; 1.0; -1.0], r)
  @test_throws Kpax3.KDomainError Kpax3.AminoAcidPriorCol(data, γ, 0.0)
  @test_throws Kpax3.KDomainError Kpax3.AminoAcidPriorCol(data, γ, -1.0)

  nothing
end

test_prior_col_exceptions()

function test_prior_col_constructor()
  data = UInt8[0 0 0 0 0 1;
               1 1 1 1 1 0;
               0 0 1 0 1 1;
               1 1 0 1 0 0;
               1 1 0 0 0 0;
               0 0 0 1 1 0;
               1 1 1 0 0 0;
               0 0 0 1 1 1;
               0 0 1 0 0 0;
               1 0 0 1 0 1;
               0 1 0 0 1 0;
               0 0 0 0 0 1;
               1 1 1 0 0 0;
               0 0 0 1 1 0;
               1 1 0 0 1 1;
               0 0 1 1 0 0;
               1 1 0 1 0 0;
               0 0 1 0 1 1]

  (m, n) = size(data)

  γ = [0.6; 0.35; 0.05]
  r = log(0.001) / log(0.95)

  priorC = Kpax3.AminoAcidPriorCol(data, γ, r)

  logγ = [log(γ[1]); log(γ[2]); log(γ[3])]
  logω = Vector{Float64}[[log(k - 1) - log(k); -log(k)] for k in 1:n]

  @test priorC.logγ == logγ
  @test priorC.logω == logω

  # TODO: Test A and B
  nothing
end

test_prior_col_constructor()
