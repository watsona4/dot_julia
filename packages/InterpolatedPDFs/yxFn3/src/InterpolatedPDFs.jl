module InterpolatedPDFs

using Distributions
using NumericalIntegration

using Interpolations
using Interpolations: Extrapolation, GriddedInterpolation, BSplineInterpolation

export LinearInterpolatedPDF, fit_cpl, pdf, cdf, quantile, get_knots

include("linear_1d.jl")

#get_knots(d::LinearInterpolatedPDF) = d.pdf_itp

end # module
