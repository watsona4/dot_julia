module TheCannon
using Optim, Statistics, LinearAlgebra, ForwardDiff
export expanded_size,
       collapsed_size,
       expand_labels,
       standardize_labels,
       unstandardize_labels,
       train,
       infer,
       quad_coeff_matrix

@deprecate projected_size expanded_size
@deprecate deprojected_size collapsed_size
@deprecate project_labels expand_labels

"""

    expandeded_size(nlabels; quadratic=true)

The length of a label vector of length `nlabels` after it has been 
quadratically expanded.

See also: [`collapsed_size`](@ref)
"""
function expanded_size(nlabels; quadratic=true)
    if quadratic
        Int(1 + 2nlabels + nlabels*(nlabels-1)/2)
    else
        nlabels + 1
    end
end

"""

    collapsed_size(nelabels; quadratic=true)

The length of a label vector corresponding to an expanded label 
vector of length nelabels.

See also: [`expanded_size`](@ref)
"""
function collapsed_size(nplabels; quadratic=true)
    if quadratic
        Int((-3 + sqrt(1 + 8nplabels))/2)
    else
        nplabels - 1
    end
end

function expand_labels(labels::Vector{R}; quadratic=true) where R <: Real
    vec(expand_labels(Matrix(transpose(labels)), quadratic=quadratic))
end
function expand_labels(labels::Matrix{R}; quadratic=true) where R <: Real
    nstars, nlabels = size(labels)
    plabels = Matrix{R}(undef, nstars, expanded_size(nlabels; quadratic=quadratic))
    plabels[:, 1] .= 1
    plabels[:, 2:nlabels+1] .= labels
    if quadratic
        k = 1
        for i in 1:nlabels
            for j in i:nlabels
                plabels[:, nlabels + 1 + k] .= labels[:, i] .* labels[:, j]
                k += 1
            end
        end
    end
    plabels
end

"""
Get the quadratic terms of theta as matrices.
returns an array of dimensions nlabels x nlabels x npixels

   Q = quad_coeff_matrix(theta)
   Q[:, :, 1] #quadratic coefficients for first pixel

"""
function quad_coeff_matrix(theta::Matrix{F}) :: Array{F, 3} where F <: AbstractFloat
    nlabels = collapsed_size(size(theta, 1)) 
    npix = size(theta, 2)
    Q = Array{F}(undef, nlabels, nlabels, npix)
    for p in 1:npix
        k = 1
        for i in 1:nlabels
            for j in i:nlabels
                Q[i, j, p] = theta[nlabels + 1 + k, p]
                Q[j, i, p] = Q[i, j, p]
                k += 1
            end 
        end 
    end 
    Q
end

function standardize_labels(labels)
    pivot = mean(labels, dims=1)
    scale = std(labels, dims=1)
    (labels .- pivot)./scale, vec(pivot), vec(scale)
end

function unstandardize_labels(labels, pivot, scale)
    labels.*transpose(hcat(scale)) .+ transpose(hcat(pivot))
end

function linear_soln(labels, Σ, flux)
    lT_invcov_l = transpose(labels) * inv(Σ) * labels 
    #if cond(lT_invcov_l) > 1e8
    #    @warn "dangerous condition number in normal equation"
    #end
    lT_invcov_F = transpose(labels) * inv(Σ) * flux
    lT_invcov_l \ lT_invcov_F
end


"""
    train(flux, ivar, labels)

returns: theta, scatters
Run the training step of The Cannon, i.e. calculate coefficients for each pixel.
 - `flux` contains the spectra for each pixel in the training set.  It should be 
    `nstars x npixels` (row-vectors are spectra)
 - `ivar` contains the inverse variance for each pixel in the same shape as `flux`
 - `labels` contains the labels for each star.  It should be `nstars x nlabels`.
    It will be expanded into the quadratic label space before training.
"""
function train(flux::AbstractMatrix{F}, ivar::AbstractMatrix{F}, 
               labels::AbstractMatrix{F}; verbose=true, quadratic=true
              ) :: Tuple{Matrix{F}, Vector{F}} where F <: AbstractFloat
    #count everything
    nstars = size(flux,1)
    npix = size(flux, 2)
    nlabels = size(labels, 2)
    labels = expand_labels(labels, quadratic=quadratic)
    nplabels = size(labels, 2)
    if verbose 
        println("$nstars stars, $npix pixels, $nplabels expanded labels")
    end
    #initialize output variables
    theta = Matrix{F}(undef, nplabels, npix)
    scatters = Vector{F}(undef, npix)
    #train on each pixel independently
    for i in 1:npix
        if verbose && i % 500 == 0
            println("training on pixel $i")
        end
        function negative_log_likelihood(scatter) #up to constant
            scatter = scatter[1]
            Σ = Diagonal(ivar[:, i].^(-1) .+ scatter^2)
            coeffs = linear_soln(labels, Σ, flux[:, i])
            χ = labels*coeffs - flux[:, i]
            (0.5*(transpose(χ) * inv(Σ) * χ) + #chi-squared
             0.5*sum(log.(diag(Σ)))) #normalizaion term
        end
        fit = optimize(negative_log_likelihood, 1e-16, 1, rel_tol=0.01)
        #fit = optimize(negative_log_likelihood, [0.01], LBFGS(); autodiff=:forward)
        if ! fit.converged
            @warn "pixel $i not converged"
        end

        scatters[i] = fit.minimizer[1]
        Σ = Diagonal(ivar[:, i].^(-1) .+ scatters[i]^2)
        theta[:, i] = linear_soln(labels, Σ, flux[:, i])
    end
    theta, scatters
end

"""

   infer(flux, ivar, theta, scatters)

Run the test step of the cannon.
Given a Cannon model (from training), infer stellar parameters
"""
function infer(flux::AbstractMatrix{Fl}, 
               ivar::AbstractMatrix{Fl},
               theta::AbstractMatrix{Fl}, 
               scatters::AbstractVector{Fl};
               quadratic=true, verbose=true) where Fl <: AbstractFloat
    nstars = size(flux, 1)
    nplabels = size(theta, 1)
    nlabels = collapsed_size(nplabels; quadratic=quadratic)

    inferred_labels = Matrix{Float64}(undef, nstars, nlabels)
    chi_squared = Vector{Float64}(undef, nstars)
    information = Array{Float64, 3}(undef, nstars, nlabels, nlabels)

    thetaT = transpose(theta)
    for i in 1:nstars
        if verbose && i%100==0
            println("inferring labels for star $i")
        end

        F = flux[i, :]
        invσ2 = (ivar[i, :].^(-1) .+ scatters.^2).^(-1)
        function negative_log_post(labels)
            A2 = (thetaT * expand_labels(labels; quadratic=quadratic) .- F).^2
            0.5 * sum(A2 .* invσ2) 
        end
        fit = optimize(negative_log_post, zeros(nlabels), Optim.Options(g_tol=1e-6),
                      autodiff=:forward)
        
        inferred_labels[i, :] = fit.minimizer
        chi_squared[i] = sum((thetaT * expand_labels(fit.minimizer; quadratic=quadratic) .- F).^2 .* invσ2)
        information[i, :, :] = ForwardDiff.hessian(negative_log_post, fit.minimizer)
    end
    inferred_labels, chi_squared, information
end

end
