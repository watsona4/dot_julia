# This file is part of Kpax3. License is MIT.

function test_selection()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

  settings = Kpax3.KSettings(ifile, ofile)

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

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)

  state = [Kpax3.AminoAcidState(data, [1; 1; 1; 1; 1; 1], priorR, priorC, settings);
           Kpax3.AminoAcidState(data, [1; 2; 3; 4; 5; 6], priorR, priorC, settings);
           Kpax3.AminoAcidState(data, [1; 1; 2; 2; 3; 3], priorR, priorC, settings);
           Kpax3.AminoAcidState(data, [1; 1; 1; 1; 2; 2], priorR, priorC, settings);
           Kpax3.AminoAcidState(data, [1; 2; 3; 1; 2; 3], priorR, priorC, settings)]

  popsize = 5

  logpp = Float64[state[i].logpp for i in 1:popsize]

  # (1, 2) => 2 wins
  # (1, 3) => 1 wins
  # (1, 4) => 1 wins
  # (1, 5) => 1 wins
  # (2, 3) => 2 wins
  # (2, 4) => 2 wins
  # (2, 5) => 2 wins
  # (3, 4) => 4 wins
  # (3, 5) => 3 wins
  # (4, 5) => 4 wins
  #
  # possible candidates:
  #
  # (1, 2, 3, 4) => (2) (4)
  # (1, 2, 3, 5) => (2) (3)
  # (1, 2, 4, 5) => (2) (4)
  # (1, 3, 2, 4) => (1) (2)
  # (1, 3, 2, 5) => (1) (2)
  # (1, 3, 4, 5) => (1) (4)
  # (1, 4, 2, 3) => (1) (2)
  # (1, 4, 2, 5) => (1) (2)
  # (1, 4, 3, 5) => (1) (3)
  # (1, 5, 2, 3) => (1) (2)
  # (1, 5, 2, 4) => (1) (2)
  # (1, 5, 3, 4) => (1) (4)
  # (2, 3, 4, 5) => (2) (4)
  # (2, 4, 3, 5) => (2) (3)
  # (2, 5, 3, 4) => (2) (4)
  #
  # each winning index is repeated 8 times
  # there are a total of 240 possible combinations (15 * 8 * 2)
  pr = [72 / 240; 96 / 240; 24 / 240; 48 / 240; 0.0]

  N = 1000000
  tmp = zeros(Float64, popsize)
  i1 = 0
  i2 = 0

  for i in 1:N
    (i1, i2) = Kpax3.selection(logpp)

    tmp[i1] += 1
    tmp[i2] += 1
  end

  tmp /= 2 * N

  @test isapprox(tmp, pr, rtol=0.01)

  nothing
end

test_selection()
