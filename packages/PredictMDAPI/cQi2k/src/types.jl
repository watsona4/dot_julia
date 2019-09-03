abstract type AbstractFittable end
abstract type AbstractEstimator <: AbstractFittable end
abstract type AbstractPipeline <: AbstractFittable end
abstract type AbstractTransformer <: AbstractFittable end

abstract type AbstractFeatureContrasts end
abstract type AbstractNonExistentFeatureContrasts <: AbstractFeatureContrasts end

abstract type AbstractNonExistentUnderlyingObject end

abstract type AbstractBackend end

abstract type AbstractPlot end
