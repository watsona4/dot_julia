const tol = 10*eps()

"""
ItoIntegral
A struct detailing an ito integral. It contains a MultivariateFunction detailing the integrand as well as a symbol detailing an id of the integral's processes.

Usual (and most general) contructor is:
    ItoIntegral(brownian_id_::Symbol, f_::MultivariateFunction)
Convenience constructor for ItoIntegrals where the integrand is a flat function is:
    ItoIntegral(brownian_id_::Symbol, variance_::Float64)
"""
struct ItoIntegral
    brownian_id_::Symbol
    f_::MultivariateFunction
    function ItoIntegral(brownian_id_::Symbol, variance_::Float64)
        return new(brownian_id_, PE_Function(variance_, 0.0, 0.0, 0))
    end
    function ItoIntegral(brownian_id_::Symbol, f::MultivariateFunction)
        underlying = underlying_dimensions(f)
        if length(underlying) == 0
            return new(brownian_id_, f)
        elseif length(underlying) > 1
            error("At present it is only possible to create an ItoIntegral with a one dimensional MultivariateFunction with that one dimension being the time dimension.")
        end
        f2 = rebadge(f, Dict{Symbol,Symbol}(pop!(underlying) => :default))
        return new(brownian_id_, f2)
    end
end

"""
    get_variance(ito::ItoIntegral, from::Float64, to::Float64)
    get_variance(ito::ItoIntegral, base::Date, from::Date, to::Date)
Get the variance of an ItoIntegral from one point of time to another.
"""
function get_variance(ito::ItoIntegral, from::Float64, to::Float64)
    return integral(ito.f_^2, from, to)
end
function get_variance(ito::ItoIntegral, base::Date, from::Date, to::Date)
    from_fl = years_between(from, base)
    to_fl   = years_between(to, base)
    return get_variance(ito, from_fl, to_fl)
end

"""
    get_volatility(ito::ItoIntegral, on::Date)
Get the volatility of an ItoIntegral on a certain date.
"""
function get_volatility(ito::ItoIntegral, on::Date)
    return evaluate(ito.f_, on)
end

"""
    get_covariance(ito1::ItoIntegral,ito2::ItoIntegral, from::Float64, to::Float64, gaussian_correlation::Float64)
    get_covariance(ito1::ItoIntegral,ito2::ItoIntegral, base::Date, from::Date, to::Date, gaussian_correlation::Float64)
Get the covariance of two ItoIntegrals over a certain period given the underlying Brownian processes have a correlation of gaussian_correlation.
"""
function get_covariance(ito1::ItoIntegral,ito2::ItoIntegral, from::Float64, to::Float64, gaussian_correlation::Float64)
    return gaussian_correlation * integral(ito1.f_ * ito2.f_, from, to)
end
function get_covariance(ito1::ItoIntegral,ito2::ItoIntegral, base::Date, from::Date, to::Date, gaussian_correlation::Float64)
    from_fl = years_between(from, base)
    to_fl   = years_between(to, base)
    return get_covariance(ito1, ito2, from_fl, to_fl, gaussian_correlation)
end

"""
    get_correlation(ito1::ItoIntegral,ito2::ItoIntegral, from::Float64, to::Float64, gaussian_correlation::Float64)
    get_correlation(ito1::ItoIntegral,ito2::ItoIntegral,  base::Date, from::Date, to::Date, gaussian_correlation::Float64)
Get the correlation of two ItoIntegrals over a certain period given the underlying Brownian processes have a correlation of gaussian_correlation.
"""
function get_correlation(ito1::ItoIntegral,ito2::ItoIntegral, from::Float64, to::Float64, gaussian_correlation::Float64)
    cov =  covar(ito1,ito2, base, from, to, gaussian_correlation)
    var1 = var(ito1, from, to)
    var2 = var(ito2, from, to)
    return gaussian_correlation * (cov / (var1 * var2))
end
function get_correlation(ito1::ItoIntegral,ito2::ItoIntegral,  base::Date, from::Date, to::Date, gaussian_correlation::Float64)
    from_fl = years_between(from, base)
    to_fl   = years_between(to, base)
    return get_correlation(ito1, ito2, from_fl, to_fl, gaussian_correlation)
end

"""
    brownians_in_use(itos::Array{ItoIntegral,1}, brownians::Array{Symbol,1})
Determine which Browninan processes are used in an array of ItoIntegrals.
"""
function brownians_in_use(itos::Dict{Symbol,ItoIntegral}, brownians::Array{Symbol,1})
    all_brownians_in_use = unique(map(x -> x.brownian_id_ , values(itos)))
    indices_in_use   = unique(findall(map(x -> x in all_brownians_in_use , brownians)))
    reduced_brownian_list = brownians[indices_in_use]
    return all_brownians_in_use, indices_in_use, reduced_brownian_list
end

"""
    ItoSet
Creates an ItoSet. This contains :
* A correlation matrix of brownian motions.
* A vector giving the axis labels for this correlation matrix.
* A dict of ItoInterals. Here the keys should be ids for the ito integrals and the values should be ItoIntegrals.
Determine which Brownian processes are used in an array of ItoIntegrals.
"""
struct ItoSet
    brownian_correlation_matrix_::Symmetric
    brownian_ids_::Array{Symbol,1}
    ito_integrals_::Dict{Symbol,ItoIntegral}
    function ItoSet(brownian_corr_matrix::Symmetric, brownian_ids::Array{Symbol,1}, ito_integrals::Dict{Symbol,ItoIntegral})
        if (size(brownian_ids)[1] != size(brownian_corr_matrix)[1])
            error("The shape of brownian_ids_ must match the number of rows/columns of brownian_correlation_matrix_")
        end
          all_brownians_in_use, used_brownian_indices, brown_ids = brownians_in_use(ito_integrals, brownian_ids)
          if length(setdiff(all_brownians_in_use, brownian_ids)) > 0
              error("In creating an ItoSet there are some brownian motions referenced by ito integrals for which there are no corresponding entries in the correlation matrix for brownian motions. Thus an ItoSet cannot be built.")
          end
          brownian_corr_matrix_subset      = Symmetric(brownian_corr_matrix[used_brownian_indices,used_brownian_indices])
       return new(brownian_corr_matrix_subset, brown_ids, ito_integrals)
    end
end

"""
    get_correlation(ito::ItoSet, index1::Int, index2::Int)
    get_correlation(ito::ItoSet, brownian_id1::Symbol, brownian_id2::Symbol)
Get correlation between brownian motions in an ItoSet.
"""
function get_correlation(ito::ItoSet, index1::Int, index2::Int)
    return ito.brownian_correlation_matrix_[index1, index2]
end
function get_correlation(ito::ItoSet, brownian_id1::Symbol, brownian_id2::Symbol)
    index1 = findall(brownian_id1 .== ito.brownian_ids_)[1]
    index2 = findall(brownian_id2 .== ito.brownian_ids_)[1]
    return get_correlation(ito, index1, index2)
end

"""
    get_volatility(ito::ItoSet, index::Int, on::Date)
    get_volatility(ito::ItoSet, ito_integral_id::Symbol, on::Date)
Get volatility of an ito_integral on a date.
"""
function get_volatility(ito::ItoSet, index::Int, on::Date)
    return get_volatility(ito.ito_integrals_[index], on)
end

function get_volatility(ito::ItoSet, ito_integral_id::Symbol, on::Date)
    ito_integral = ito.ito_integrals_[ito_integral_id]
    return get_volatility(ito_integral, on)
end

"""
    make_covariance_matrix(ito_set_::ItoSet, from::Float64, to::Float64)
Make a covariance matrix given an ItoSet and a period of time.
"""
function make_covariance_matrix(ito_set_::ItoSet, from::Float64, to::Float64)
    number_of_itos = length(ito_set_.ito_integrals_)
    ito_ids = collect(keys(ito_set_.ito_integrals_))
    cov = Array{Float64,2}(undef, number_of_itos,number_of_itos)
    for r in 1:number_of_itos
        rito = ito_set_.ito_integrals_[ito_ids[r]]
        for c in r:number_of_itos
            #if c < r
            #    cov[r,c] = 0.0 # Since at the end we use the Symmetric thing, this is discarded so we don't bother computing it.
            #end
            cito = ito_set_.ito_integrals_[ito_ids[c]]
            cr_correlation = get_correlation(ito_set_, rito.brownian_id_, cito.brownian_id_)
            cov[r,c] = get_covariance(rito, cito, from, to, cr_correlation)
        end
    end
    return Symmetric(cov), ito_ids
end

"""
    CovarianceAtDate
Creates an CovarianceAtDate object. This contains :
* An Itoset
* Time From
* Time To
And in the constructor the following items are generated and stored in the object:
* A covariance matrix
* Labels for the covariance matrix.
* The cholesky decomposition of the covariance matrix.
* The inverse of the covariance matrix.
* The determinant of the covariance matrix.
"""
struct CovarianceAtDate
    ito_set_::ItoSet
    from_::Float64
    to_::Float64
    covariance_::Symmetric
    covariance_labels_::Array{Symbol,1}
    chol_::Union{Missing,LowerTriangular}
    inverse_::Union{Missing,Symmetric}
    determinant_::Union{Missing,Float64}
    """
    CovarianceAtDate(ito_set_::ItoSet, from_::Float64, to_::Float64;
             calculate_chol::Bool = true, calculate_inverse::Bool = true, calculate_determinant::Bool = true)
    CovarianceAtDate(ito_set_::ItoSet, from::Date, to::Date)
    CovarianceAtDate(old_CovarianceAtDate::CovarianceAtDate, from::Float64, to::Float64)
    CovarianceAtDate(old_CovarianceAtDate::CovarianceAtDate, from::Date, to::Date)
        These are constructors for a CovarianceAtDate struct.
    """
    function CovarianceAtDate(ito_set_::ItoSet, from_::Float64, to_::Float64;
             calculate_chol::Bool = true, calculate_inverse::Bool = true, calculate_determinant::Bool = true)
        covariance_, covariance_labels_ = make_covariance_matrix(ito_set_, from_, to_)
        chol_ = missing
        inverse_ = missing
        determinant_ = missing
        if calculate_chol chol_ = LowerTriangular(cholesky(covariance_).L) end
        if calculate_inverse inverse_           = Symmetric(inv(covariance_)) end
        if calculate_determinant determinant_       = det(covariance_) end
        return new(ito_set_, from_, to_, covariance_, covariance_labels_, chol_, inverse_, determinant_)
    end
    function CovarianceAtDate(ito_set_::ItoSet, from::Date, to::Date)
        from_ = years_from_global_base(from)
        to_   = years_from_global_base(to)
        return CovarianceAtDate(ito_set_, from_, to_)
    end
    function CovarianceAtDate(old_CovarianceAtDate::CovarianceAtDate, from::Float64, to::Float64)
        return CovarianceAtDate(old_CovarianceAtDate.ito_set_, from, to)
    end
    function CovarianceAtDate(old_CovarianceAtDate::CovarianceAtDate, from::Date, to::Date)
        return CovarianceAtDate(old_CovarianceAtDate.ito_set_, from, to)
    end
end

"""
    get_volatility(covar::CovarianceAtDate, index::Int, on::Date)
    get_volatility(covar::CovarianceAtDate, id::Symbol, on::Date)
Get the volatility of an ItoIntegral on a date..
"""
function get_volatility(covar::CovarianceAtDate, index::Int, on::Date)
    return get_volatility(covar.ito_set_, index, on)
end
function get_volatility(covar::CovarianceAtDate, id::Symbol, on::Date)
    return get_volatility(covar.ito_set_, id, on)
end

"""
    get_variance(covar::CovarianceAtDate, id::Symbol)
    get_variance(covar::CovarianceAtDate, index::Int)
Get the variance of an ItoIntegral over a period.
"""
function get_variance(covar::CovarianceAtDate, id::Symbol)
        index = findall(id .== covar.covariance_labels_)[1]
        return get_variance(covar, index)
end
function get_variance(covar::CovarianceAtDate, index::Int)
    return covar.covariance_[index,index]
end

"""
    get_covariance(covar::CovarianceAtDate, index_1::Int, index_2::Int)
    get_covariance(covar::CovarianceAtDate, id1::Symbol, id2::Symbol)
Get the covariance of two ItoIntegrals over a period.
"""
function get_covariance(covar::CovarianceAtDate, index_1::Int, index_2::Int)
    return covar.covariance_[index_1,index_2]
end
function get_covariance(covar::CovarianceAtDate, id1::Symbol, id2::Symbol)
    index_1 = findall(id1 .== covar.covariance_labels_)[1]
    index_2 = findall(id2 .== covar.covariance_labels_)[1]
    return get_covariance(covar, index_1, index_2)
end

"""
    get_correlation(covar::CovarianceAtDate, index_1::Int, index_2::Int)
    get_correlation(covar::CovarianceAtDate, id1::Symbol, id2::Symbol)
Get the correlation of two ItoIntegrals over a period.
"""
function get_correlation(covar::CovarianceAtDate, index_1::Int, index_2::Int)
    covariance = get_covariance(covar, index_1, index_2)
    var1  = get_variance(covar, index_1)
    var2  = get_variance(covar, index_2)
    return covariance/sqrt(var1 * var2)
end
function get_correlation(covar::CovarianceAtDate, id1::Symbol, id2::Symbol)
    index_1 = findall(id1 .== covar.covariance_labels_)[1]
    index_2 = findall(id2 .== covar.covariance_labels_)[1]
    return get_correlation(covar, index_1, index_2)
end

## Random draws
"""
    get_normal_draws(covar::CovarianceAtDate; uniform_draw::Array{Float64} = rand(length(covar.covariance_labels_)))
    get_normal_draws(covar::CovarianceAtDate, num::Int; twister::MersenneTwister = MersenneTwister(1234))
get pseudorandom draws from a CovarianceAtDate struct. Other schemes (like quasirandom) can be done by inserting quasirandom
numbers in as the uniform_draw.
"""
function get_normal_draws(covar::CovarianceAtDate; uniform_draw::Array{Float64} = rand(length(covar.covariance_labels_)))
    number_of_itos = length(covar.covariance_labels_)
    normal_draw = quantile.(Ref(Normal()), uniform_draw)
    scaled_draw = covar.chol_ * normal_draw
    return Dict{Symbol,Float64}(covar.covariance_labels_ .=> scaled_draw)
end
function get_normal_draws(covar::CovarianceAtDate, num::Int; twister::MersenneTwister = MersenneTwister(1234))
    array_of_dicts = Array{Dict{Symbol,Float64}}(undef, num)
    number_of_itos = length(covar.covariance_labels_)
    for i in 1:num
        mersenne_draw = rand(twister,number_of_itos)
        array_of_dicts[i] = get_normal_draws(covar; uniform_draw = mersenne_draw)
    end
    return array_of_dicts
end

"""
    get_sobol_normal_draws(covar::CovarianceAtDate, sob_seq::SobolSeq)
    get_sobol_normal_draws(covar::CovarianceAtDate, num::Int; sob_seq::SobolSeq = SobolSeq(length(covar.ItoSet_.ItoIntegrals_)))
get sobol draws from a CovarianceAtDate struct.
"""
function get_sobol_normal_draws(covar::CovarianceAtDate, sob_seq::SobolSeq)
    sobol_draw = next!(sob_seq)
    return get_normal_draws(covar; uniform_draw = sobol_draw)
end
function get_sobol_normal_draws(covar::CovarianceAtDate, num::Int; sob_seq::SobolSeq = SobolSeq(length(covar.ito_set_.ito_integrals_)))
    array_of_dicts = Array{Dict{Symbol,Float64}}(undef, num)
    for i in 1:num
        array_of_dicts[i] = get_sobol_normal_draws(covar,sob_seq)
    end
    return array_of_dicts
end



# This is most likely useful for bug hunting.
"""
    get_zero_draws(covar::CovarianceAtDate)
get a draw of zero for all ito_integrals. May be handy for bug hunting.
"""
function get_zero_draws(covar::CovarianceAtDate)
    return Dict{Symbol,Float64}(covar.covariance_labels_ .=> 0.0)
end
# This is most likely useful for bug hunting.
"""
    get_zero_draws(covar::CovarianceAtDate, num::Int)
get an array of zero draws for all ito_integrals. May be handy for bug hunting.
"""
function get_zero_draws(covar::CovarianceAtDate, num::Int)
    array_of_dicts = Array{Dict{Symbol,Float64}}(undef, num)
    for i in 1:num
        array_of_dicts[i] = get_zero_draws(covar)
    end
    return array_of_dicts
end

"""
    pdf(covar::CovarianceAtDate, coordinates::Dict{Symbol,Float64})
get the value of the pdf at some coordinates.
"""
function pdf(covar::CovarianceAtDate, coordinates::Dict{Symbol,Float64})
    # The pdf is det(2\pi\Sigma)^{-0.5}\exp(-0.5(x - \mu)^\prime \Sigma(x - \mu))
    # Where Sigma is covariance matrix, \mu is means (0 in this case) and x is the coordinates.
    rank_of_matrix = length(covar.covariance_labels_)
    x = get.(Ref(coordinates), covar.covariance_labels_, 0)
    one_on_sqrt_of_det_two_pi_covar     = 1/(sqrt(covar.determinant_) * (2*pi)^(rank_of_matrix/2))
    return one_on_sqrt_of_det_two_pi_covar * exp(-0.5 * x' * covar.covariance_ * x)
end

"""
    log_likelihood(covar::CovarianceAtDate, coordinates::Dict{Symbol,Float64})
get the log likelihood at some coordinates.
"""
function log_likelihood(covar::CovarianceAtDate, coordinates::Dict{Symbol,Float64})
    # The pdf is det(2\pi\Sigma)^{-0.5}\exp(-0.5(x - \mu)^\prime \Sigma(x - \mu))
    # Where Sigma is covariance matrix, \mu is means (0 in this case) and x is the coordinates.
    rank_of_matrix = length(covar.covariance_labels_)
    x = get.(Ref(coordinates), covar.covariance_labels_, 0)
    one_on_sqrt_of_det_two_pi_covar     = -0.5*log(covar.determinant_)  +  (rank_of_matrix/2)*log(2*pi)
    return one_on_sqrt_of_det_two_pi_covar + (-0.5 * x' * covar.covariance_ * x)
end
