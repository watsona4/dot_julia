# This file is part of Kpax3. License is MIT.

RecipesBase.@userplot Kpax3PlotP

RecipesBase.@recipe function plotp(g::Kpax3PlotP;
                                   clusterorder=:auto,
                                   clusterlabel=:auto)
  if (length(g.args) != 2) ||
     (typeof(g.args[1]) != Vector{Int}) ||
     (typeof(g.args[2]) != Matrix{Float64})
      throw(KInputError("Two arguments required. Got: $(typeof(g.args))"))
  end

  R, P = g.args

  n = length(R)
  k = maximum(R)

  if (clusterorder == :auto) || (length(clusterorder) != k)
    clusterorder = collect(1:k)
  end

  if (clusterlabel == :auto) || (length(clusterlabel) != k)
    clusterlabel = string.(clusterorder)
  end

  (ord, mid, sep) = reorderunits(R, P, clusterorder)

  mid .-= 0.5
  sep .-= 0.5

  N = n^2

  x = zeros(Int, N)
  y = zeros(Int, N)
  z = fill("", N)

  idx = 1
  pij = 0.0
  for j = 1:n, i = 1:n
    x[idx] = j
    y[idx] = i

    pij = P[ord[i], ord[j]]
    z[idx] = if pij <= 0.2
      "#FFFFFF"
    elseif pij <= 0.4
      "#F0F0F0"
    elseif pij <= 0.6
      "#BDBDBD"
    elseif pij <= 0.8
      "#636363"
    else
      "#000000"
    end

    idx += 1
  end

  # try to minimize the number of rectangles. We will do this greedly by
  # dividing the image into maximal adjacent rectangles
  # Hopefully the SVG file won't be too big
  #
  # TODO: improve the algorithm
  processed = falses(n, n)

  len = zero(Int)
  xmin = zeros(Int, len)
  xmax = zeros(Int, len)
  ymin = zeros(Int, len)
  ymax = zeros(Int, len)
  col = fill("", len)

  # elements on the diagonal have always p = 1.0
  val = "#000000"

  j = 1
  while j <= n
    jmax = expandsquarediag(j, n, val, z)

    push!(xmin, j - 1)
    push!(xmax, jmax)
    push!(ymin, j - 1)
    push!(ymax, jmax)
    push!(col, val)

    len += 1

    processed[j:jmax, j:jmax] .= true
    j = jmax + 1
  end

  # scan the lower triangular matrix
  j = 1
  while j < n
    # start a new column from the first non processed element
    i = j + 1
    while i <= n
      if !processed[i, j]
        val = z[LinearIndices((n, n))[i, j]]

        (imax, jmax) = expandrect(i, j, n, n, val, z, processed)

        # lower triangular
        push!(xmin, j - 1)
        push!(xmax, jmax)
        push!(ymin, i - 1)
        push!(ymax, imax)
        push!(col, val)

        len += 1

        # upper triangular (transpose)
        push!(xmin, i - 1)
        push!(xmax, imax)
        push!(ymin, j - 1)
        push!(ymax, jmax)
        push!(col, val)

        len += 1

        processed[i:imax, j:jmax] .= true
        i = imax + 1
      else
        while i <= n && processed[i, j]
          i += 1
        end
      end
    end

    j += 1
  end

  xborder = zeros(Float64, 5, k)
  yborder = zeros(Float64, 5, k)
  for i = 1:k
    xborder[:, i] = [sep[i]; sep[i]; sep[i + 1]; sep[i + 1]; sep[i]]
    yborder[:, i] = [sep[i]; sep[i + 1]; sep[i + 1]; sep[i]; sep[i]]
  end

  mcol = ["#FFFFFF" "#F0F0F0" "#BDBDBD" "#636363" "#000000"]
  mlab = ["[0.0, 0.2]" "(0.2, 0.4]" "(0.4, 0.6]" "(0.6, 0.8]" "(0.8, 1.0]"]

  rect_x = zeros(Float64, 5 * len)
  rect_y = zeros(Float64, 5 * len)
  for i = 1:len
    idx = LinearIndices((5, len))[:, i]
    rect_x[idx] .= [xmin[i]; xmax[i]; xmax[i]; xmin[i]; NaN]
    rect_y[idx] .= [ymin[i]; ymin[i]; ymax[i]; ymax[i]; NaN]
  end

  # start by plotting cluster borders
  RecipesBase.@series begin
    seriestype := :path
    linecolor := :black
    label := ""
    legend := :none

    xborder, yborder
  end

  # add the rectangles and fill them with color
  RecipesBase.@series begin
    seriestype := :shape
    fillcolor := col
    linealpha := 0.0
    linewidth := 0.0
    linestyle := :dot
    label := ""

    rect_x, rect_y
  end

  # complete the plot by adding the legend
  RecipesBase.@series begin
    seriestype := :scatter
    background_color := :white
    grid := false
    markershape := :rect
    markercolor := mcol
    label := mlab
    xlims := (0, n)
    xticks := (mid, clusterlabel)
    ylims := (0, n)
    yticks := (mid, clusterlabel)
    yflip := true

    html_output_format --> :svg
    size --> (800, 600)
    window_title --> ""
    title --> ""
    legend --> :right
    xlabel --> "Samples by cluster"
    ylabel --> "Samples by cluster"

    fill(-2.0, 1, length(mcol)), fill(-2.0, 1, length(mcol))
  end
end

RecipesBase.@userplot Kpax3PlotC

RecipesBase.@recipe function plotc(g::Kpax3PlotC)
  if (length(g.args) != 3) ||
     (typeof(g.args[1]) != Vector{Int}) ||
     (typeof(g.args[2]) != Vector{Float64}) ||
     (typeof(g.args[3]) != Matrix{Float64})
      throw(KInputError("Three arguments required. Got: $(typeof(g.args))"))
  end

  site, freq, C = g.args

  m = site[end]
  M = length(site)

  noise = zeros(Float64, m)
  weak = zeros(Float64, m)

  key = 1
  for b in 1:M
    if site[b] != key
      weak[key] += noise[key]
      key += 1
    end

    noise[key] += freq[b] * C[1, b]
    weak[key] += freq[b] * C[2, b]
  end

  weak[key] += noise[key]

  mcol = ["#FFFFFF" "#808080" "#000000"]
  mlab = ["Noise" "Weak signal" "Strong signal"]

  # start with a complete black plot (strong signal)
  RecipesBase.@series begin
    seriestype := :path
    linecolor := :black
    fill := (0, :black)
    label := ""
    legend := :none

    1:m, ones(Float64, m)
  end

  # add the weak signal on top
  RecipesBase.@series begin
    seriestype := :path
    linecolor := "#808080"
    fill := (0, "#808080")
    label :=""
    legend := :none

    1:m, weak
  end

  # finally add the white noise
  RecipesBase.@series begin
    seriestype := :path
    linecolor := :white
    fill := (0, :white)
    label :=""
    legend := :none

    1:m, noise
  end

  # add the legend
  RecipesBase.@series begin
    seriestype := :scatter
    background_color := :white
    grid := false
    markershape := :rect
    markercolor := mcol
    label := mlab
    legend := :right
    xlims := (1, m)
    ylims := (0, 1)

    html_output_format --> :svg
    size --> (800, 600)
    window_title --> ""
    title --> ""
    legend --> :right
    xlabel --> "Site"
    ylabel --> "Posterior probability"

    fill(-2, 1, length(mcol)), fill(-2, 1, length(mcol))
  end
end

RecipesBase.@userplot Kpax3PlotD

RecipesBase.@recipe function plotd(g::Kpax3PlotD;
                                   clusterorder=:auto,
                                   clusterlabel=:auto)
  if length(g.args) != 2
      throw(KInputError("Two arguments required. Got: $(typeof(g.args))"))
  end

  x, state = g.args

  (m, n) = size(x.data)
  M = length(x.ref)

  if (clusterorder == :auto) || (length(clusterorder) != state.k)
    clusterorder = collect(1:state.k)
  end

  if (clusterlabel == :auto) || length(clusterlabel) != state.k
    clusterlabel = string.(clusterorder)
  end

  v = zeros(Float64, state.k)
  for i in 1:n
    v[state.R[i]] += 1.0
  end
  v /= n

  v = [0.0; v[clusterorder]]

  cumsum!(v, v)

  xax = collect(1:M)

  yax = zeros(Float64, state.k)
  for g in 1:state.k
    yax[g] = (v[g] + v[g + 1]) / 2
  end
  round.(yax, digits=3)

  # colors
  colset = [("A", "Ala", "#FF3232");
            ("R", "Arg", "#FF7F00");
            ("N", "Asn", "#CAB2D6");
            ("D", "Asp", "#FDBF6F");
            ("C", "Cys", "#33A02C");
            ("E", "Glu", "#1F4E78");
            ("Q", "Gln", "#FF3300");
            ("G", "Gly", "#660066");
            ("H", "His", "#B2DF8A");
            ("I", "Ile", "#CC6600");
            ("L", "Leu", "#375623");
            ("K", "Lys", "#A6CEE3");
            ("M", "Met", "#CC3399");
            ("F", "Phe", "#FB9A99");
            ("P", "Pro", "#C81414");
            ("S", "Ser", "#1F78B4");
            ("T", "Thr", "#6A3D9A");
            ("W", "Trp", "#FFFF99");
            ("Y", "Tyr", "#FF66CC");
            ("V", "Val", "#993300");
            ("U", "Sec", "#00FFFF");
            ("O", "Pyl", "#FFFF00");
            ("B", "Asx", "#E4B9A3");
            ("Z", "Glx", "#8F413C");
            ("J", "Xle", "#825E12");
            ("X", "Xaa", "#000000");
            ("-",   "-", "#E0E0E0");
            ("*",   "*", "#000000");
            ( "",    "", "#FFFFFF")]

  coltable = Dict(map(a -> (a[1], a[3]), colset))

  # indices
  idx = 1
  s = 0
  t = 1
  b = 1
  g = 1
  h = 1

  # temporary values
  c = 0x01
  w = 0
  flag = false

  z = fill("#FFFFFF", state.k * M)

  for j in 1:M
    if x.ref[j] == UInt8('.')
      s += 1
      c = 0x01

      while (b <= m) && (x.key[b] == s)
        if state.C[state.cl[1], b] > c
          c = state.C[state.cl[1], b]
        end
        b += 1
      end

      if c > 0x02
        for g in 1:state.k
          h = clusterorder[g]
          w = t
          flag = false

          while !flag && w < b
            flag = state.C[state.cl[h], w] == 0x04
            w += 1
          end

          if flag
            z[idx] = coltable[uppercase(string(Char(x.val[w - 1])))]
          end

          idx += 1
        end
      else
        idx += state.k
      end

      t = b
    else
      idx += state.k
    end
  end

  # try to minimize the number of rectangles. We will do this greedly by
  # dividing the image into maximal adjacent rectangles
  # Hopefully the SVG file won't be too big
  #
  # TODO: improve the algorithm
  processed = falses(state.k, M)

  len = zero(Int)
  xmin = zeros(Int, len)
  xmax = zeros(Int, len)
  ymin = zeros(Float64, len)
  ymax = zeros(Float64, len)
  col = fill("", len)

  j = 1
  while j <= M
    # start a new column from the first non processed element
    i = 1
    while i <= state.k
      if !processed[i, j]
        val = z[LinearIndices((state.k, M))[i, j]]

        (imax, jmax) = expandrect(i, j, state.k, M, val, z, processed)

        push!(xmin, j - 1)
        push!(xmax, jmax)
        push!(ymin, v[i])
        push!(ymax, v[imax + 1])
        push!(col, val)

        len += 1

        processed[i:imax, j:jmax] .= true
        i = imax + 1
      else
        while i <= state.k && processed[i, j]
          i += 1
        end
      end
    end

    j += 1
  end

  mcol = reshape(map(a -> a[3], colset[1:26]), 1, 26)
  mlab = reshape(map(a -> a[2], colset[1:26]), 1, 26)

  rect_x = zeros(Float64, 5 * len)
  rect_y = zeros(Float64, 5 * len)
  for i = 1:len
    idx = LinearIndices((5, len))[:, i]
    rect_x[idx] .= [xmin[i]; xmax[i]; xmax[i]; xmin[i]; NaN]
    rect_y[idx] .= [ymin[i]; ymin[i]; ymax[i]; ymax[i]; NaN]
  end

  # draw the rectangles
  RecipesBase.@series begin
    seriestype := :shape
    fillcolor := col
    linecolor := col
    label := ""
    legend := :none

    rect_x, rect_y
  end

  # add cluster separators
  RecipesBase.@series begin
    seriestype := :hline
    linecolor := :black
    label := ""
    legend := :none

    v
  end

  # complete the plot by adding the legend
  RecipesBase.@series begin
    seriestype := :scatter
    background_color := :white
    grid := false
    markershape := :rect
    markercolor := mcol
    label := mlab
    xlims := (1, M)
    ylims := (0, 1)
    yticks := (yax, clusterlabel)
    yflip := true

    html_output_format --> :svg
    size --> (800, 600)
    window_title --> ""
    title --> ""
    legend --> :right
    xlabel --> "Site"
    ylabel --> "Cluster"

    fill(-2, 1, length(mcol)), fill(-2, 1, length(mcol))
  end
end
