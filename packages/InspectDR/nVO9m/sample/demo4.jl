#Demo 4: Empty/undefined plots
#-------------------------------------------------------------------------------
using InspectDR
using Colors


#==Input
===============================================================================#
#Constants
#-------------------------------------------------------------------------------
black = RGB24(0, 0, 0)
white = RGB24(1, 1, 1)
red = RGB24(1, 0, 0)
green = RGB24(0, 1, 0)
blue = RGB24(0, 0, 1)

#Input data
#-------------------------------------------------------------------------------


#==Generate plot
===============================================================================#
mplot = InspectDR.Multiplot(title="Empty/Undefined Plots")
mplot.layout[:ncolumns] = 2
xlabel = "X-Axis (X-Unit)"
ylabel = "Y-Axis (Y-Unit)"
kwargs = (:xlabel=>xlabel, :ylabels=>[ylabel])

#Subplot 1
#-------------------------------------------------------------------------------
plot = add(mplot, InspectDR.Plot2D(:lin, :lin, title="xmax = ∞"; kwargs...))
wfrm = add(plot, Float64[0, Inf], Float64[0, 1])

#Subplot 2
#-------------------------------------------------------------------------------
plot = add(mplot, InspectDR.Plot2D(:lin, :lin, title="xmin = NaN"; kwargs...))
wfrm = add(plot, Float64[NaN, 1], Float64[0, 1])

#Subplot 3
#-------------------------------------------------------------------------------
plot = add(mplot, InspectDR.Plot2D(:lin, :lin, title="ymin = -∞"; kwargs...))
wfrm = add(plot, Float64[0, 1], Float64[-Inf, 0])

#Subplot 4
#-------------------------------------------------------------------------------
plot = add(mplot, InspectDR.Plot2D(:lin, :lin, title="ymax = NaN"; kwargs...))
wfrm = add(plot, Float64[0, 1], Float64[1, NaN])

#Subplot 5
#-------------------------------------------------------------------------------
plot = add(mplot, InspectDR.Plot2D(:lin, :lin, title="No Data"; kwargs...))

#Subplot 6
#-------------------------------------------------------------------------------
plot = add(mplot, InspectDR.Plot2D(:lin, :lin, title="xmin = xmax"; kwargs...))
wfrm = add(plot, Float64[2, 2], Float64[0, 1])

#Display
#-------------------------------------------------------------------------------
gplot = display(InspectDR.GtkDisplay(), mplot)

:DONE
