##Reineke SDI chart

using RecipesBase

@userplot sdi_chart
@recipe function f(dat::sdi_chart ;maxsdi=450)

diarng = 1:1:20
#tparng = [1,1200] #unusued for now, TODO: figure out how to autoscale plot?
maxline() = maxsdi ./ (diarng ./ 10.0).^1.605

  # plot attributes
  xlabel --> "Trees Per Acre"
  ylabel --> "Quadratic Mean Diameter"
  xticks --> (0:50:450)
  yticks --> (0:20:200)
  xscale --> :log10
  yscale --> :log10

  legend := false
  primary := false

#max SDI line
@series begin
    linecolor := :black
    maxline()
end

#competition induced mortality SDI line
@series begin
    linecolor := :orange
    maxline() * 0.55
end

#crown closure SDI line
@series begin
    linecolor := :red
    maxline() * 0.35
end

 # the point and the annotations
 @series begin
    primary := true
    seriestype := :scatter
    #annotations := (100:38:442, 20:10:110, ["$i%" for i in 20:10:110])

    a,b = dat.args
    [a], [b]
 end
end