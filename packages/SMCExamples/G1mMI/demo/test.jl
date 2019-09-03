function testSMC(model::SMCModel, N::Int64, numTrials::Int64,
  fullOutput = false, essThreshold::Float64 = 2.0)
  smcio = SMCIO{model.particle, model.pScratch}(N, model.maxn, 1, fullOutput,
    essThreshold)
  println("Running SMC. N = $N, nthreads = 1, fullOutput = $fullOutput, essThreshold = $essThreshold")
  for i=1:numTrials
    @time smc!(model, smcio)
    left = max(length(smcio.logZhats)-10,1)
    right = length(smcio.logZhats)
    println(smcio.logZhats[left:right])
    println(sign.(smcio.Vhat1s[left:right]) .*
      sqrt.(abs.(smcio.Vhat1s[left:right])))
  end
end

function testSMCParallel(model::SMCModel, N::Int64, numTrials::Int64,
  fullOutput = false, essThreshold::Float64 = 2.0)
  nthreads = Threads.nthreads()
  smcio = SMCIO{model.particle, model.pScratch}(N, model.maxn, nthreads,
    fullOutput, essThreshold)
  println("Running SMC. N = $N, nthreads = $nthreads, fullOutput = $fullOutput, essThreshold = $essThreshold")
  for i = 1:numTrials
    @time smc!(model, smcio)
    left = max(length(smcio.logZhats)-10,1)
    right = length(smcio.logZhats)
    println(smcio.logZhats[left:right])
    println(sign.(smcio.Vhat1s[left:right]) .*
      sqrt.(abs.(smcio.Vhat1s[left:right])))
  end
end
