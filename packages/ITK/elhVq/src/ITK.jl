module ITK
using Cxx, Libdl

include("init.jl")

function __init__()
    loadcxx(libitk, dirname(libitk))
end

"Loads shared library and header file."
function loadcxx(libpath::String=libitk, headerdir::String=dirname(libitk))
    addHeaderDir(headerdir, kind=C_System)
    Libdl.dlopen(libpath, Libdl.RTLD_GLOBAL)
    cxxinclude("JuliaWrap.h")
end

"Sanity checker. Returns x if able to read C++ files."
function verifycxx(x::Int)
    sanity_check(n::Int) = @cxx sanity(n)
    return sanity_check(x)
end

"""
    registerframe(fixedImage, movingImage, outputImage, writeImage, optimizer)

Test method which registers movingImage in relation to fixedImage, writing the resulting image to outputImage if writeImage is true.
Uses Mattes Mutual Information Metric, and either Regular Step Gradient Descent or Amoeba optimizer.

# Arguments
- `fixedImage::String`: path to fixed image file
- `movingImage::String`: path to moving image file
- `outputImage::String`: path to desired output image file
- `writeImage::Bool=true`: whether or not to save the output image file
- `optimizer::String="Gradient"`: which optimizer to use, "Gradient" | "Amoeba"

# Returns
- (x translation, y translation, metric information)
"""
function registerframe(fixedImage::String, movingImage::String, outputImage::String, writeImage::Bool=true, optimizer::String="Gradient")
    register_amoeba_optimizer(fix::Ptr{UInt8}, moving::Ptr{UInt8}, output::Ptr{UInt8}, write::Bool) = @cxx test_registration1(fix, moving, output, write)
    register_gradient_optimizer(fix::Ptr{UInt8}, moving::Ptr{UInt8}, output::Ptr{UInt8}, write::Bool) = @cxx test_registration2(fix, moving, output, write)
    if optimizer == "Amoeba"
        result = register_amoeba_optimizer(pointer(fixedImage), pointer(movingImage), pointer(outputImage), writeImage)
    else
        result = register_gradient_optimizer(pointer(fixedImage), pointer(movingImage), pointer(outputImage), writeImage)
    end
    x, y, metric = unsafe_load(result,1), unsafe_load(result,2), unsafe_load(result,3)
    return x, y, metric
end

"""
    MMIGradientRegistration(fixedImage, movingImage, outputImage, writeImage, learningRate, minStepLength, maxIterations, relaxationFactor) 

Register movingImage to fixedImage with Mattes Mutual Information metric and Regular Step Gradient Descent optimizer.

# Arguments
- `fixedImage::String`: path to fixed image file
- `movingImage::String`: path to moving image file
- `outputImage::String`: path to desired output image file
- `writeImage::Bool`: whether or not to save the output image file
- `learningRate::Float64`: higher values result in quicker but potentially unstable registration (recommended range 1.0:5.0)
- `minStepLength::Float64`: step size (recommended range 0.001:0.05)
- `maxIterations::Int64`: max number of iterations (recommended range 100:200)
- `relaxationFactor::Float64`: factor to slow down shift between iterations, higher values result in quicker, potentially unstable registration (recommended range 0.3:0.7)

# Returns
- (x translation, y translation, metric information)
"""
function MMIGradientRegistration(fixedImage::String, movingImage::String, outputImage::String, writeImage::Bool, learningRate::Float64, minStepLength::Float64, maxIterations::Int64, relaxationFactor::Float64)
    register(fix::Ptr{UInt8}, moving::Ptr{UInt8}, output::Ptr{UInt8}, write::Bool, LR::Float64, minStep::Float64, maxIter::Int64, relaxFactor::Float64) = @cxx MMIGradientTranslation(fix, moving, output, write, LR, minStep, maxIter, relaxFactor)
    result = register(pointer(fixedImage), pointer(movingImage), pointer(outputImage), writeImage, learningRate, minStepLength, maxIterations, relaxationFactor)
    x, y, metric = unsafe_load(result, 1), unsafe_load(result, 2), unsafe_load(result, 3)
    return x, y, metric
end

"""
    MMIAmoebaRegistration(fixedImage, movingImage, outputImage, writeImage, initialSimplex, pixelTolerance, metricTolerance, maxIterations)

Registers movingImage to fixedImage with MattesMutualInformation metric, with Amoeba optimizer with specified parameters.

# Arguments
- `fixedImage::String`: path to fixed image file
- `movingImage::String`: path to moving image file
- `outputImage::String`: path to desired output image file
- `writeImage::Bool`: whether or not to save the output image file
- `initialSimplex::Float64`: initial size of simplex moving along cost surface (recommended 5.0)
- `pixelTolerance::Float64`: convergence tolerance in pixels (recommended range 0.01:0.5)
- `metricTolerance::Float64`: function convergence tolerance (recommended 0.1)
- `maxIterations::Int64`: max number of iterations (recommended range 100:200)

# Returns
- (x translation, y translation, metric information)
"""
function MMIAmoebaRegistration(fixedImage::String, movingImage::String, outputImage::String, writeImage::Bool, initialSimplex::Float64, pixelTolerance::Float64, metricTolerance::Float64, maxIterations::Int64)
    register(fix::Ptr{UInt8}, moving::Ptr{UInt8}, output::Ptr{UInt8}, write::Bool, simplex::Float64, pixelT::Float64, metricT::Float64, maxIter::Int64) = @cxx MMIAmoebaTranslation(fix, moving, output, write, simplex, pixelT, metricT, maxIter)
    result = register(pointer(fixedImage), pointer(movingImage), pointer(outputImage), writeImage, initialSimplex, pixelTolerance, metricTolerance, maxIterations)
    x, y, metric = unsafe_load(result, 1), unsafe_load(result, 2), unsafe_load(result, 3)
    return x, y, metric
end

"""
    MMIOnePlusOneRegistration(fixedImage, movingImage, outputImage, writeImage, initialize, epsilon, maxIterations)

Registers movingImage to fixedImage with MattesMutualInformation metric, with 1+1 Evolutionary optimizer with specified parameters.

# Arguments
- `fixedImage::String`: path to fixed image file
- `movingImage::String`: path to moving image file
- `outputImage::String`: path to desired output image file
- `writeImage::Bool`: whether or not to save the output image file
- `initialRadius::Float64`: initial size of radius (recommended 6.25e-3)
- `epsilon::Float64`: minimum size of search radius (recommended 1.5e-6)
- `maxIterations::Int64`: max number of iterations (recommended range 100:200)

# Returns
- (x translation, y translation, metric information)
"""
function MMIOnePlusOneRegistration(fixedImage::String, movingImage::String, outputImage::String, writeImage::Bool, initialRadius::Float64, epsilon::Float64, maxIterations::Int64)
    register(fix::Ptr{UInt8}, moving::Ptr{UInt8}, output::Ptr{UInt8}, write::Bool, init::Float64, ep::Float64, maxIter::Int64) = @cxx MMIOnePlusOneTranslation(fix, moving, output, write, init, ep, maxIter)
    result = register(pointer(fixedImage), pointer(movingImage), pointer(outputImage), writeImage, initialRadius, epsilon, maxIterations)
    x, y, metric = unsafe_load(result, 1), unsafe_load(result, 2), unsafe_load(result, 3)
    return x, y, metric
end

"""
MeanSquaresGradientRegistration(fixedImage, movingImage, outputImage, writeImage, learningRate, minStepLength, maxIterations, relaxationFactor)

Register movingImage to fixedImage with Mean Squares metric and Regular Step Gradient Descent optimizer.

# Arguments
- `fixedImage::String`: path to fixed image file
- `movingImage::String`: path to moving image file
- `outputImage::String`: path to desired output image file
- `writeImage::Bool`: whether or not to save the output image file
- `learningRate::Float64`: higher values result in quicker but potentially unstable registration (recommended range 1.0:5.0)
- `minStepLength::Float64`: step size (recommended range 0.001:0.05)
- `maxIterations::Int64`: max number of iterations (recommended range 100:200)
- `relaxationFactor::Float64`: factor to slow down shift between iterations, higher values result in quicker, potentially unstable registration (recommended range 0.3:0.7)

# Returns
- (x translation, y translation, metric information)
"""
function MeanSquaresGradientRegistration(fixedImage::String, movingImage::String, outputImage::String, writeImage::Bool, learningRate::Float64, minStepLength::Float64, maxIterations::Int64, relaxationFactor::Float64)
    register(fix::Ptr{UInt8}, moving::Ptr{UInt8}, output::Ptr{UInt8}, write::Bool, LR::Float64, minStep::Float64, maxIter::Int64, relaxFactor::Float64) = @cxx MeanSquaresGradientTranslation(fix, moving, output, write, LR, minStep, maxIter, relaxFactor)
    result = register(pointer(fixedImage), pointer(movingImage), pointer(outputImage), writeImage, learningRate, minStepLength, maxIterations, relaxationFactor)
    x, y, metric = unsafe_load(result, 1), unsafe_load(result, 2), unsafe_load(result, 3)
    return x, y, metric
end

export registerframe
export MMIGradientRegistration
export MMIAmoebaRegistration
export MMIOnePlusOneRegistration
export MeanSquaresGradientRegistration

end # module ITK
