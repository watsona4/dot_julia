# This file is part of Kpax3. License is MIT.
RecipesBase.@userplot Kpax3PlotTrace

RecipesBase.@recipe function plottrace(g::Kpax3PlotTrace;
                                       maxlag=200,
                                       M=20000,
                                       main="")
  if (length(g.args) != 1) ||
     (typeof(g.args[1]) != Vector{Float64})
      throw(KInputError("One argument required. Got: $(typeof(g.args))"))
  end

  entropy = g.args[1]

  nsim = length(entropy)

  # plot the last M points
  if M < nsim
    xtr = max(1, nsim - M):nsim
    ytr = entropy[xtr]
  else
    xtr = 1:nsim
    ytr = copy(entropy)
  end

  plot_title = if main != ""
    ac = StatsBase.autocov(entropy, 0:maxlag)

    variid = ac[1] / nsim
    mcvar = imsevar(ac, nsim)
    mcse = sqrt(mcvar)
    eff = min(nsim, ess(variid, mcvar, nsim))

    effstr = if eff <= 100000
      Printf.@sprintf("%d", eff)
    else
      Printf.@sprintf("%.3e", eff)
    end

    sestr = if 0.001 <= mcse <= 1000
      Printf.@sprintf("%.3f", mcse)
    else
      Printf.@sprintf("%.3e", mcse)
    end

    string(main, " (mcse = ", sestr, ", ESS = ", effstr, ")")
  else
    ""
  end

  RecipesBase.@series begin
    seriestype := :path
    linecolor := :black
    background_color := :white
    label := ""
    legend := :none
    title := plot_title
    window_title := ""
    xlims := (minimum(xtr), maximum(xtr))
    ylims := (max(0.0, minimum(ytr) - 0.05), maximum(ytr) + 0.05)

    html_output_format --> :svg
    size --> (800, 600)
    xlabel --> "Iteration"
    ylabel --> "Entropy"

    xtr, ytr
  end
end

RecipesBase.@userplot Kpax3PlotDensity

RecipesBase.@recipe function plotdensity(g::Kpax3PlotDensity;
                                         maxlag=200,
                                         main="")
  if (length(g.args) != 1) ||
     (typeof(g.args[1]) != Vector{Float64})
      throw(KInputError("One argument required. Got: $(typeof(g.args))"))
  end

  entropy = g.args[1]

  nsim = length(entropy)

  plot_title = if main != ""
    ac = StatsBase.autocov(entropy, 0:maxlag)

    variid = ac[1] / nsim
    mcvar = imsevar(ac, nsim)
    mcse = sqrt(mcvar)
    eff = min(nsim, ess(variid, mcvar, nsim))

    effstr = if eff <= 100000
      Printf.@sprintf("%d", eff)
    else
      Printf.@sprintf("%.3e", eff)
    end

    sestr = if 0.001 <= mcse <= 1000
      Printf.@sprintf("%.3f", mcse)
    else
      Printf.@sprintf("%.3e", mcse)
    end

    string(main, " (mcse = ", sestr, ", ESS = ", effstr, ")")
  else
    ""
  end

  kd = KernelDensity.kde(entropy, npoints=256)

  RecipesBase.@series begin
    seriestype := :path
    linecolor := :black
    background_color := :white
    label := ""
    legend := :none
    title := plot_title
    window_title := ""
    xlims := (max(0.0, minimum(entropy) - 0.05), maximum(entropy) + 0.05)

    html_output_format --> :svg
    size --> (800, 600)
    xlabel --> "Entropy"
    ylabel --> "Density"

    kd.x, kd.density
  end
end

RecipesBase.@userplot Kpax3PlotJump

RecipesBase.@recipe function plotjump(g::Kpax3PlotJump;
                                      main="")
  if (length(g.args) != 1) ||
     (typeof(g.args[1]) != Vector{Float64})
      throw(KInputError("One argument required. Got: $(typeof(g.args))"))
  end

  avgd = g.args[1]

  maxlag = length(avgd)

  # Exponential smoothing for estimating the long term mean
  asy = avgd[1]
  for t in 2:maxlag
    asy = 0.6 * asy + 0.4 * avgd[t]
  end

  RecipesBase.@series begin
    seriestype := :scatter
    markercolor := :black
    label := ""
    legend := :none

    1:maxlag, avgd
  end

  RecipesBase.@series begin
    seriestype := :hline
    linestyle := :dash
    linecolor := :black
    background_color := :white
    label := ""
    legend := :none
    title := main
    window_title := ""
    xlims := (0, maxlag + 1)

    html_output_format --> :svg
    size --> (800, 600)
    xlabel --> "Lag"
    ylabel --> "Average distance"

    [asy]
  end
end
