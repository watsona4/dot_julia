module RoMEPlotting

using Reexport
@reexport using Gadfly
@reexport using Colors

using Statistics, LinearAlgebra
using Compose
# using Graphs
using DistributedFactorGraphs
using KernelDensityEstimate, KernelDensityEstimatePlotting
using IncrementalInference, RoME
using DocStringExtensions
using ApproxManifoldProducts

using ApproxManifoldProducts
# const AMP = ApproxManifoldProducts
# import RoME: AMP

import KernelDensityEstimatePlotting: plot, drawHorDens, plotKDE
import IncrementalInference: CliqGibbsMC, DebugCliqMCMC
import Graphs: plot
import Gadfly: plot

# TODO temporary fix for Compose based plotting in Julia 0.7 (Oct 2018)
# see
# @warn "[TEMPORARY WORKAROUND, pangolayout] for plotting with Compose and Gadfly.jl, see https://github.com/GiovineItalia/Gadfly.jl/issues/1206"
# import Compose: pangolayout
# const pangolayout = PangoLayout()

export
  # Associated with IncrementalInference
  investigateMultidimKDE,
  drawHorDens,
  drawHorBeliefsList,
  spyCliqMat,
  plotKDE,
  plotKDEofnc,
  plotKDEresiduals,
  plotMCMC,
  plotKDE,
  plotUpMsgsAtCliq,
  plotPriorsAtCliq,
  investigateMultidimKDE,
  draw,
  plot,
  whosWith,
  drawUpMsgAtCliq,
  dwnMsgsAtCliq,
  drawPose2DMC!,
  mcmcPose2D!,
  # drawUpMCMCPose2D!,
  # drawDwnMCMCPose2D!,
  drawLbl,
  predCurrFactorBeliefs,
  drawFactorBeliefs,
  localProduct,
  plotLocalProduct,
  plotLocalProductCylinder,
  plotTreeProductUp,
  plotTreeProductDown,
  saveplot,
  animateVertexBelief,
  getColorsByLength,

  # Associated with RoME
  togglePrtStbLines,
  plotLsrScanFeats,
  drawFeatTrackers,
  saveImgSeq,
  stbPrtLineLayers!,
  drawPoses,
  drawLandms,
  drawPosesLandms,
  drawSubmaps,
  investigatePoseKDE, # not sure, likely obsolete -- use plotPose instead
  plotPose,
  drawMarginalContour,
  accumulateMarginalContours,
  plotPose3Pairs,
  progressExamplePlot,
  plotTrckStep,
  plotPose2Vels,
  plotProductVsKDE


include("SolverVisualization.jl")

include("RobotViz.jl")


end
