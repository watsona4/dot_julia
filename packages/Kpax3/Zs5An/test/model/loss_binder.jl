# This file is part of Kpax3. License is MIT.

function test_loss_binder()
  P = [1.000 0.571 0.458 0.458 0.442 0.357;
       0.571 1.000 0.458 0.458 0.442 0.357;
       0.458 0.458 1.000 0.571 0.357 0.442;
       0.458 0.458 0.571 1.000 0.357 0.442;
       0.442 0.442 0.357 0.357 1.000 0.426;
       0.357 0.357 0.442 0.442 0.426 1.000]

  # k = 1
  R = Int[1; 1; 1; 1; 1; 1]
  A = Float64[1 1 1 1 1 1;
              1 1 1 1 1 1;
              1 1 1 1 1 1;
              1 1 1 1 1 1;
              1 1 1 1 1 1;
              1 1 1 1 1 1]

  losscorrect = sum(abs.(A - P)) / 2
  lossfunction = Kpax3.loss_binder(R, P)

  @test isapprox(lossfunction, losscorrect, atol=ε)

  # k = 2
  R = Int[1; 1; 2; 2; 1; 2]
  A = Float64[1 1 0 0 1 0;
              1 1 0 0 1 0;
              0 0 1 1 0 1;
              0 0 1 1 0 1;
              1 1 0 0 1 0;
              0 0 1 1 0 1]

  losscorrect = sum(abs.(A - P)) / 2
  lossfunction = Kpax3.loss_binder(R, P)

  @test isapprox(lossfunction, losscorrect, atol=ε)

  R = Int[2; 1; 2; 1; 2; 1]
  A = Float64[1 0 1 0 1 0;
              0 1 0 1 0 1;
              1 0 1 0 1 0;
              0 1 0 1 0 1;
              1 0 1 0 1 0;
              0 1 0 1 0 1]

  losscorrect = sum(abs.(A - P)) / 2
  lossfunction = Kpax3.loss_binder(R, P)

  @test isapprox(lossfunction, losscorrect, atol=ε)

  # k = 3
  R = Int[1; 1; 2; 2; 3; 2]
  A = Float64[1 1 0 0 0 0;
              1 1 0 0 0 0;
              0 0 1 1 0 1;
              0 0 1 1 0 1;
              0 0 0 0 1 0;
              0 0 1 1 0 1]

  losscorrect = sum(abs.(A - P)) / 2
  lossfunction = Kpax3.loss_binder(R, P)

  @test isapprox(lossfunction, losscorrect, atol=ε)

  R = Int[1; 2; 3; 1; 2; 3]
  A = Float64[1 0 0 1 0 0;
              0 1 0 0 1 0;
              0 0 1 0 0 1;
              1 0 0 1 0 0;
              0 1 0 0 1 0;
              0 0 1 0 0 1]

  losscorrect = sum(abs.(A - P)) / 2
  lossfunction = Kpax3.loss_binder(R, P)

  @test isapprox(lossfunction, losscorrect, atol=ε)

  # k = 4
  R = Int[1; 1; 2; 2; 3; 4]
  A = Float64[1 1 0 0 0 0;
              1 1 0 0 0 0;
              0 0 1 1 0 0;
              0 0 1 1 0 0;
              0 0 0 0 1 0;
              0 0 0 0 0 1]

  losscorrect = sum(abs.(A - P)) / 2
  lossfunction = Kpax3.loss_binder(R, P)

  @test isapprox(lossfunction, losscorrect, atol=ε)

  R = Int[1; 2; 3; 4; 3; 2]
  A = Float64[1 0 0 0 0 0;
              0 1 0 0 0 1;
              0 0 1 0 1 0;
              0 0 0 1 0 0;
              0 0 1 0 1 0;
              0 1 0 0 0 1]

  losscorrect = sum(abs.(A - P)) / 2
  lossfunction = Kpax3.loss_binder(R, P)

  @test isapprox(lossfunction, losscorrect, atol=ε)

  # k = 5
  R = Int[1; 2; 3; 3; 4; 5]
  A = Float64[1 0 0 0 0 0;
              0 1 0 0 0 0;
              0 0 1 1 0 0;
              0 0 1 1 0 0;
              0 0 0 0 1 0;
              0 0 0 0 0 1]

  losscorrect = sum(abs.(A - P)) / 2
  lossfunction = Kpax3.loss_binder(R, P)

  @test isapprox(lossfunction, losscorrect, atol=ε)

  R = Int[1; 2; 3; 4; 1; 5]
  A = Float64[1 0 0 0 1 0;
              0 1 0 0 0 0;
              0 0 1 0 0 0;
              0 0 0 1 0 0;
              1 0 0 0 1 0;
              0 0 0 0 0 1]

  losscorrect = sum(abs.(A - P)) / 2
  lossfunction = Kpax3.loss_binder(R, P)

  @test isapprox(lossfunction, losscorrect, atol=ε)

  # k = 6
  R = Int[1; 2; 3; 4; 5; 6]
  A = Float64[1 0 0 0 0 0;
              0 1 0 0 0 0;
              0 0 1 0 0 0;
              0 0 0 1 0 0;
              0 0 0 0 1 0;
              0 0 0 0 0 1]

  losscorrect = sum(abs.(A - P)) / 2
  lossfunction = Kpax3.loss_binder(R, P)

  @test isapprox(lossfunction, losscorrect, atol=ε)

  nothing
end

test_loss_binder()
