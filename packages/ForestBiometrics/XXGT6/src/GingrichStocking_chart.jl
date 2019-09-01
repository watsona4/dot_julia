#Gingrich stocking chart calculated using the original upland oak parameters
#for more information see:http://oak.snr.missouri.edu/silviculture/tools/gingrich.html

using RecipesBase

amd_convert(qmd) = -0.259 + 0.973qmd
get_tpa(j, i, a) = (1*j*10)/(a[1]+a[2]*amd_convert(i)+a[3]*i^2)

function stklines(stk, dia, a)
  tpa = get_tpa.(stk', dia, Ref(a))
  ba = pi * (dia ./ 24).^2 .* tpa
  tpa, ba
end

@userplot gingrich_chart
@recipe function f(dat::gingrich_chart)

  #define parameters
  a = [-0.0507, 0.1698, 0.0317]
  b = [0.175, 0.205, 0.06]
  #QMD lines
  dia = [7, 8, 10, 12, 14, 16, 18, 20, 22]
  #stocking percent horizontal lines
  stk_percent= 20:10:110

  # plot attributes
  xlabel --> "Trees Per Acre"
  ylabel --> "Basal Area (sq ft./acre)"
  xticks --> 0:50:450
  yticks --> 0:20:200
  legend := false
  primary := false

  tpa, ba = stklines(stk_percent, dia, a)

  # horizontal lines
  @series begin
    linecolor := :black
    tpa, ba
  end

  # vertical lines
  @series begin
    linecolor := :black
    tpa', ba'
  end

  # upper red line
  @series begin
    linecolor := :red
    stklines([100], dia, a)
  end

  # lower red line
  @series begin
    linecolor := :red
    stklines([100], dia, b)
  end

  # the point and the annotations
  @series begin
    primary := true
    seriestype := :scatter
    annotations := (100:38:442, 20:10:110, ["$i%" for i in 20:10:110])

    a,b = dat.args
    [a], [b]
  end
end