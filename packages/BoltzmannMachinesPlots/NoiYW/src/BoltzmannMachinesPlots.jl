"
Contains all plotting functions for displaying information collected
in module `BoltzmannMachines`. Most important function is `plotevaluation`.
"
module BoltzmannMachinesPlots

import BoltzmannMachines
const BMs = BoltzmannMachines

using Compose
using DataFrames
using Gadfly
using Statistics


export plotevaluation, crossvalidationcurve, scatterhidden


function checkdata(plotdata)
   if size(plotdata, 1) == 0
      error("No data for this evaluation in monitor")
   end
end

function getvalue(monitor::BMs.Monitor, evaluation::String, epoch::Int)
   itemidx = findfirst((item -> item.evaluation == evaluation && item.epoch == epoch), monitor)
   monitor[itemidx].value
end

function extractevaluationdata(monitor::BMs.Monitor, evaluation::String)
   evaluationidxs = findall(item -> item.evaluation == evaluation, monitor)
   epochs = map(i -> monitor[i].epoch, evaluationidxs)
   values = map(i -> monitor[i].value, evaluationidxs)
   datasetnames = map(i -> monitor[i].datasetname, evaluationidxs)
   plotdata = DataFrame(epoch = epochs, value = values, datasetname = datasetnames)
end

function extractaisdata(monitor::BMs.Monitor, evaluation::String, sdrange::Float64)

   plotdata = extractevaluationdata(monitor, evaluation)

   # Now integrate the information about the precision of AIS in the dataframe.
   # It is common for all datasets.
   epochs = unique(plotdata[:epoch])

   if sdrange != 0.0

      plotdata[:ymin] = copy(plotdata[:value])
      plotdata[:ymax] = copy(plotdata[:value])

      # Use standard deviation of log partition function estimator to
      # plot ribbon around log probs.
      for epoch in epochs
         sd = getvalue(monitor, BMs.monitoraisstandarddeviation, epoch)
         logr = getvalue(monitor, BMs.monitoraislogr, epoch)

         # log(Z) is subtracted from logproblowerbound, so overstimating log(Z)
         # means underestimating the log probability
         bottom, top = BMs.aisprecision(logr, sd, sdrange)
         plotdata[:ymin][plotdata[:epoch] .== epoch] .-= top
         plotdata[:ymax][plotdata[:epoch] .== epoch] .-= bottom
      end
   end

   # avoid plotting error if NaNs were introduced when calculating ymin/ymax
   plotdata[:ymin][isnan.(plotdata[:ymin])] .= 0
   plotdata[:ymax][isnan.(plotdata[:ymax])] .= 0

   plotdata
end


"
Plots the information about the estimated lower bound of the log probability
that has been gathered while training a BMs.
"
function plotestimatedprob(monitor::BMs.Monitor, evaluationkey::String;
      sdrange::Float64 = 0.0)

   title = plottitledict[evaluationkey]
   plotdata = extractaisdata(monitor, evaluationkey, sdrange)
   checkdata(plotdata)

   # remove ribbon for values that are too uncertain and warn about it
   badribbon = false
   if sdrange != 0
      valrange = abs(maximum(plotdata[:, :value]) - minimum(plotdata[:, :value]))
      for row in eachrow(plotdata)
         if row[:ymin] < row[:value] - 5 * valrange
            row[:ymin] = row[:value]
            badribbon = true
         end
         if row[:ymax] > row[:value] + 5 * valrange
            row[:ymax] = row[:value]
            badribbon = true
         end
      end
   end
   if badribbon
      @warn "Too much uncertainty at some points: Ribbon (partially) not displayed."
   end

   if sdrange != 0
      plot(plotdata, x = "epoch", y = "value", ymin = "ymin", ymax = "ymax",
            color = "datasetname",
            Geom.line, Geom.ribbon,
            Guide.xlabel("Epoch"), Guide.ylabel("Value"),
            Guide.colorkey(title = "Data set"),
            Guide.title(title))
   else
      plot(plotdata, x = "epoch", y = "value", color = "datasetname",
            Guide.xlabel("Epoch"), Guide.ylabel("Value"),
            Guide.colorkey(title = "Data set"),
            Geom.line, Guide.title(title))
   end
end


plottitledict = Dict(
      BMs.monitorreconstructionerror => "Mean reconstruction error",
      BMs.monitorlogproblowerbound => "Average lower bound of log probability",
      BMs.monitorloglikelihood => "Average log-likelihood",
      BMs.monitormeandiff => "L²-difference between means \nof generated and original data",
      BMs.monitorexactloglikelihood => "Exact log-likelihood",
      BMs.monitorweightsnorm => "L²-norm of weights",
      BMs.monitorsd => "Standard deviation parameters of visible units",
      BMs.monitorcordiff => "L²-difference between correlation matrices \nof generated and original data",
      BMs.monitorfreeenergy => "Free energy")


"""
    plotevaluation(monitor; ...)
    plotevaluation(monitor, evaluationkey; ...)
Plots a curve that shows the values of the evaluation contained in the `monitor`
and specified by the `evaluationkey` over the course of the training epochs.
If no evaluationkey is specified, the evaluation type of the first monitor
element is used.

Optional keyword argument `sdrange`:
For evaluations with keys `BoltzmannMachines.monitorloglikelihood` and
`BoltzmannMachines.monitorlogproblowerbound`,
there is additional information about the standard
deviation of the estimator. With the parameter `sdrange`, it is possible
to display this information as a ribbon around the curve. The ribbon indicates
the area around the curve that contains the values that deviate at maximum
`sdrange` times the standard deviation from the estimator.
Default value for `sdrange` is 2.0.
"""
function plotevaluation(monitor::BMs.Monitor,
      evaluationkey::String = monitor[1].evaluation;
      sdrange::Float64 = 2.0, changetitle::Function = identity)

   if evaluationkey in [BMs.monitorloglikelihood; BMs.monitorlogproblowerbound]
      return plotestimatedprob(monitor, evaluationkey; sdrange = sdrange)
   end

   # Otherwise, it is a simple line plot.
   title = changetitle(get(plottitledict, evaluationkey, evaluationkey))
   plotdata = extractevaluationdata(monitor, evaluationkey)
   checkdata(plotdata)
   plot(plotdata, x ="epoch", y = "value", color = "datasetname",
         Guide.xlabel("Epoch"), Guide.ylabel("Value"),
         Guide.colorkey(title = "Data set"),
         Geom.line, Guide.title(title))
end


function plotcurvebundles(x::Matrix{Float64};
      nlabelvars::Int =
            sum(mapslices(col -> all(((col .== 1.0) .| (col .== 0.0))), x, dims = 1))
      )

   if nlabelvars == 0
      plot(x, x = Col.index, y = Col.value, color = Row.index, Geom.line,
            Guide.colorkey(title = "Sample"), Guide.xlabel("Variable index"),
            Guide.ylabel("Value"), Scale.x_discrete, Scale.color_discrete)
   else
      powersoftwo = 2 .^ (0:(nlabelvars-1))
      labels = vec(mapslices(
            row -> sum(powersoftwo[convert(Vector{Bool}, row)]) + 1,
            x[:, 1:nlabelvars], dims = 2))

      nlabels = maximum(labels)
      labelcolors = Scale.default_discrete_colors(nlabels)
      plotdata = convert(DataFrame, x[:, (nlabelvars + 1):end])
      names!(plotdata, map(Symbol, 1:ncol(plotdata)))
      plotdata[:label] = labels
      plotlayerdfs = map(i -> DataFrames.melt(plotdata[i, :], [:label]),
            1:nrow(plotdata))

      plotlayers = map(
            d -> layer(d, x = "variable", y = "value", Geom.line,
                  Theme(default_color = labelcolors[d[1,:label]])),
            plotlayerdfs)
      plot(plotlayers...,
            Guide.xlabel("Variable index"),
            Guide.ylabel("Value"))
   end
end


function scatter(hh::Matrix{Float64};
      labels = Vector{String}(),
      opacity::Float64 = 1.0,
      xlabel::String = "", ylabel::String = "")

   if isempty(labels)
      labelsgiven = false
      labels = repeat([""], size(hh, 1))
      uniquelabels = [""]
   else
      labelsgiven = true
      uniquelabels = unique(labels)
      nsamples = size(hh, 1)
      plotdata = DataFrame(x = hh[:,1], y = hh[:,2])
      if length(labels) == nsamples
         plotdata[:label] = labels
      else
         error("Not enough labels ($(length(labels))) for samples ($nsamples)")
      end
   end

   nuniquelabels = length(uniquelabels)
   labelcolors = Scale.default_discrete_colors(nuniquelabels)
   if opacity != 1.0
      pointcolors = map(c -> Gadfly.Colors.coloralpha(c, opacity),
            labelcolors)
   else
      pointcolors = labelcolors
   end

   layers = map(i -> begin
         labelmask = (labels .== uniquelabels[i])
         layer(
               x = hh[labelmask, 1],
               y = hh[labelmask, 2], Geom.point,
               Theme(default_color = pointcolors[i],
                     discrete_highlight_color = c -> nothing))
      end, nuniquelabels:-1:1)

   if labelsgiven
      legend = [Guide.manual_color_key("", uniquelabels, labelcolors)]
   else
      legend = []
   end
   plot(layers..., Guide.xlabel(xlabel), Guide.ylabel(ylabel), legend...)
end


"""
    scatterhidden(bm, x; ...)
    scatterhidden(h; ...)
Creates a scatter plot of the logarithmized activation potential of
hidden nodes, similar to a PCA plot.
The activation is either induced by the dataset `x` in the Boltzmann machine `bm`
or it is directly specified as matrix `h`.

# Optional keyword arguments:
* `hiddennodes`: Tuple of integers, default `(1,2)`, selecting the first two
  nodes of the (last) hidden layer.
* `labels`: a vector containing string labels for each of the data points
"""
function scatterhidden(bm::BMs.AbstractBM, x::Matrix{Float64};
      hiddennodes::Tuple{Int,Int} = (1,2),
      labels = Vector{String}(),
      opacity::Float64 = 1.0)

   function hiddenactivations(rbm::BMs.AbstractRBM, x)
      BMs.logit.(BMs.hiddenpotential(rbm, x))
   end

   function hiddenactivations(rbm::BMs.AbstractXBernoulliRBM, x)
      BMs.hiddeninput(rbm, x)
   end

   function hiddenactivations(dbm::BMs.MultimodalDBM, x)
      BMs.logit.(BMs.meanfield(dbm, x)[end])
   end

   hh = hiddenactivations(bm, x)
   scatterhidden(hh, hiddennodes = hiddennodes,
         labels = labels, opacity = opacity)
end

function scatterhidden(hh::Matrix{Float64};
      hiddennodes::Tuple{Int,Int} = (1,2),
      labels = Vector{String}(),
      opacity::Float64 = 1.0)

   scatter(hh; labels = labels, opacity = opacity,
         xlabel = "Hidden node " * string(hiddennodes[1]),
         ylabel = "Hidden node " * string(hiddennodes[2]))
end


function crossvalidationcurve(monitor::BMs.Monitor,
         evaluation::String = "")

   if !isempty(evaluation)
      monitor = filter(r -> r.evaluation == evaluation, monitor)
      if isempty(monitor)
         error("No data for specified evaluation")
      end
   else
      evaluations = map(r -> r.evaluation, monitor)
      if length(unique(evaluations)) > 1
         error("Please specify the evaluation via argument 'evaluation'.")
      end
   end

   boxplotdata = DataFrame(
         epoch = map(r -> r.epoch, monitor),
         score = map(r -> r.value, monitor))
   meanplotdata = aggregate(boxplotdata, :epoch, mean)
   plot(
         layer(meanplotdata, x = "epoch", y = "score_mean", Geom.line,
               Theme(default_color = parse(Compose.Colorant, "green"))),
         layer(boxplotdata, x = "epoch", y = "score", Geom.boxplot),
         Guide.xlabel("Epoch"), Guide.ylabel("Score"))
end

end # module BoltzmannMachinesPlots
