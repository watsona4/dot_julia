# This file is part of Kpax3. License is MIT.

function test_partition_rows_functions()
  for (α, θ) in ((0.4, -0.3), (0.4, 0.0), (0.4, 2.1), (0.0, 2.1), (-2.4, 3))
    ep = Kpax3.EwensPitman(α, θ)

    for i in 1:6
      po = TestPartition.Partition(i)

      pr = 0.0
      qr = 0.0

      for j in 1:po.B
        pr += Kpax3.dPriorRow(po.partition[:, j], ep)
        qr += exp(Kpax3.logdPriorRow(po.partition[:, j], ep))
      end

      @test isapprox(pr, 1.0, atol=ε)
      @test isapprox(qr, 1.0, atol=ε)

      pr = 0.0
      qr = 0.0

      for j in 1:(po.C - 1)
        pr += (po.index[j + 1] - po.index[j]) * Kpax3.dPriorRow(i, po.k[j], po.blocksize[:, j], ep)
        qr += (po.index[j + 1] - po.index[j]) * exp(Kpax3.logdPriorRow(i, po.k[j], po.blocksize[:, j], ep))
      end

      pr += Kpax3.dPriorRow(i, po.k[po.C], po.blocksize[:, po.C], ep)
      qr += exp(Kpax3.logdPriorRow(i, po.k[po.C], po.blocksize[:, po.C], ep))

      @test isapprox(pr, 1.0, atol=ε)
      @test isapprox(qr, 1.0, atol=ε)
    end
  end

  nothing
end

test_partition_rows_functions()
