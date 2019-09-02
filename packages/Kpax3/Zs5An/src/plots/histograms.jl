# This file is part of Kpax3. License is MIT.

RecipesBase.@userplot Kpax3PlotK

RecipesBase.@recipe function plotk(g::Kpax3PlotK)
  if (length(g.args) != 2) ||
     (typeof(g.args[1]) != Vector{Int}) ||
     (typeof(g.args[2]) != Vector{Float64})
      throw(KInputError("Two arguments required. Got: $(typeof(g.args))"))
  end

  k, pk = g.args

  x = if @isdefined xlims
    collect(xlims)
  else
    collect(max(1, k[1] - 5):(k[end] + 5))
  end

  u = length(k)
  v = length(x)

  y = zeros(Float64, v)
  M = 0.0

  i = 1
  j = 1
  while (i <= u) && (j <= v)
    if k[i] == x[j]
      y[j] = pk[i]

      if y[j] > M
        M = y[j]
      end

      i += 1
    end

    j += 1
  end

  multiplier = 10.0
  while (M * multiplier) <= 1.0
    multiplier *= 10
  end
  multiplier *= 10

  M = ceil(M * multiplier) / multiplier

  RecipesBase.@series begin
    seriestype := :bar
    orientation := :vertical
    legend := :none
    ylims := (0, M)

    fillcolor --> :black
    background_color --> :white
    html_output_format --> :svg
    size --> (800, 600)
    window_title --> ""
    grid --> true
    title --> ""
    xlabel --> "k"
    xticks --> :auto
    xlims --> :auto
    ylabel --> "p(k | x)"

    x, y
  end
end
