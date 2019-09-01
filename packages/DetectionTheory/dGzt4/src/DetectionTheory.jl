# -*- coding: utf-8 -*-
#   Copyright (C) 2015-2017 Samuele Carcagno <sam.carcagno@gmail.com>
#   This file is part of DetectionTheory.jl

#    DetectionTheory.jl is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    DetectionTheory.jl is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with DetectionTheory.jl.  If not, see <http://www.gnu.org/licenses/>.

module DetectionTheory

export dprimeABX, dprimeMAFC, dprimeOddity, dprimeYesNo, dprimeSD

using DocStringExtensions, Distributions, QuadGK, Roots

"""
Compute d' for an ABX task from 'hit' and 'false alarm' rates.

$(SIGNATURES)

##### Arguments

* `H::Real`: Hit rate.
* `FA::Real` : False alarm rate.
* `method::String`: 'diff' for differencing strategy or 'IO' for independent observations strategy.

##### Returns

* `dprime::Real`: d' value

##### References

* Macmillan, N. A., & Creelman, C. D. (2004). _Detection Theory: A User’s Guide (2nd ed.)_. London: Lawrence Erlbraum Associates.

##### Examples

```julia
    #independent observations model
    dp = dprimeABX(0.7, 0.2, "IO")
    #differencing model
    dp = dprimeABX(0.7, 0.2, "diff")
```
"""
function dprimeABX(H::Real, FA::Real, method::String)

    if H < 0 || H > 1
        error("H must be between 0 and 1")
    end
    if FA < 0 || FA > 1
        error("FA must be between 0 and 1")
    end

    zdiff = quantile(Normal(), H) - quantile(Normal(), FA)
    pcUnb = cdf(Normal(), zdiff/2)

    if (pcUnb < 0.5) || (isnan(pcUnb))
        error("H must be >= FA and unbiased PC must be > 0.5")
    end
    root2 = sqrt(2)
    if method == "diff"
        root6 = sqrt(6)
        estdp(dp) = pcUnb - cdf(Normal(), dp/root2)*cdf(Normal(), dp/root6)-cdf(Normal(), -dp/root2)*cdf(Normal(), -dp/root6)
        dprime = fzero(estdp, [0, 10])
    elseif method == "IO"
        estdp2(dp) = pcUnb - cdf(Normal(), dp/root2)*cdf(Normal(), dp/2) - cdf(Normal(), -dp/root2)*cdf(Normal(), -dp/2)
        dprime = fzero(estdp2, [0, 10])
    else
        error("`method` must be either 'diff', or 'IO'")
    end

    return dprime
end




"""
Compute d' corresponding to a certain proportion of correct
responses in m-AFC tasks.

$(SIGNATURES)

##### Arguments

* `Pc::Real`: Proportion of correct responses.
* `m::Integer`: Number of alternatives.

##### Returns

* `dprime::Real`: d' value

##### References

* Green, D. M., & Swets, J. A. (1988). _Signal Detection Theory and Psychophysics_. Los Altos, California: Peninsula Publishing.
* Green, D. M., & Dai, H. P. (1991). Probability of being correct with 1 of M orthogonal signals. _Perception & Psychophysics, 49(1)_, 100–101.

##### Examples

```julia
    dp = dprimeMAFC(0.7, 3)
```

"""
function dprimeMAFC(pc::Real, m::Integer)

    if m < 2
        error("m must be an integer greater than 1")
    end

    if pc <= 0 || pc >= 1
        error("pc must be in (0,1)")
    end

    estdp = function(dp)
        pr = function(x)
            pdf(Normal(), x-dp) * cdf(Normal(), x)^(m-1)
        end
        pc - QuadGK.quadgk(pr, -Inf, Inf)[1]
    end
    dprime = fzero(estdp, [-10, 10])
    return dprime
end

"""
Compute d' for an odd-one-out task.

$(SIGNATURES)

##### Arguments

* `pc::Real`: Proportion of correct responses.
* `method::String`: 'diff' for differencing strategy or 'IO' for independent observations strategy.

##### Returns

* `dprime::Real`: d' value

##### References

* Macmillan, N. A., & Creelman, C. D. (2004). _Detection Theory: A User’s Guide (2nd ed.)_. London: Lawrence Erlbraum Associates.
* Versfeld, N. J., Dai, H., & Green, D. M. (1996). The optimum decision rules for the oddity task. _Perception & Psychophysics, 58(1)_, 10–21.

##### Examples

```julia
    dp = dprimeOddity(0.7, "diff")
    dp = dprimeOddity(0.7, "IO")
```

"""
function dprimeOddity(pc::Real, method::String)

    if pc < 1/3 || pc >= 1
        error("pc must be greater than 1/3 and less than 1")
    end

    if method == "diff"
        root3 = sqrt(3)
        root2Over3 = sqrt(2)/root3

        estdp = function(dp)
            pr = function(x)
                2 *(cdf(Normal(), -x*root3+dp*root2Over3) + cdf(Normal(), -x*root3-dp*root2Over3)) * pdf(Normal(), x)
            end
            pc - QuadGK.quadgk(pr, 0, Inf)[1]
        end

        dpres = fzero(estdp, [0, 10])

    elseif method == "IO"
        estdp = function(dp)
            pr1 = function(x)
                return  pdf(Normal(), x)* cdf(Normal(), x+dp)^2
            end
            pr2 = function(x)
                return pdf(Normal(), x)*(1-cdf(Normal(), x+dp))^2
            end
            return pc - (cdf(Normal(), dp/2)^3 + QuadGK.quadgk(pr1, -Inf, -dp/2)[1] + (1-cdf(Normal(), dp/2))^3 + QuadGK.quadgk(pr2, -dp/2, Inf)[1])
        end
        dpres = fzero(estdp, [0, 10])
    end
    
    return dpres
end 

"""
Compute d' for one interval "yes/no" type tasks from hits and false alarm rates.

$(SIGNATURES)

##### Arguments

* `H::Real`: Hit rate.
* `FA::Real`: False alarms rate.

##### Returns

* `dprime::Real`: d' value

##### References

* Green, D. M., & Swets, J. A. (1988). _Signal Detection Theory and Psychophysics_. Los Altos, California: Peninsula Publishing.
* Macmillan, N. A., & Creelman, C. D. (2004). _Detection Theory: A User’s Guide (2nd ed.)_. London: Lawrence Erlbraum Associates.

##### Examples

```julia
    dp = dprimeYesNo(0.7, 0.2)
```

"""
function dprimeYesNo(H::Real, FA::Real)
    if H < 0 || H > 1
        error("H must be between 0 and 1")
    end
    if FA < 0 || FA > 1
        error("FA must be between 0 and 1")
    end

    dprime = quantile(Normal(), H) - quantile(Normal(), FA)

    return dprime
end


"""
Compute d' for one interval same/different task from 'hit' and 'false alarm' rates.

$(SIGNATURES)

##### Arguments

* `H::Real`: Hit rate.
* `FA::Real` : False alarm rate.
* `method::String`: 'diff' for differencing strategy or 'IO' for independent observations strategy.

##### Returns

* `dprime::Real`: d' value

##### References

* Macmillan, N. A., & Creelman, C. D. (2004). _Detection Theory: A User’s Guide (2nd ed.)_. London: Lawrence Erlbraum Associates.
* Kingdom, F. A. A., & Prins, N. (2010). _Psychophysics: A Practical Introduction_. Academic Press.

##### Examples

```julia
    #independent observations model
    dp = dprimeSD(0.7, 0.2, "IO")
    #differencing model
    dp = dprimeSD(0.7, 0.2, "diff")
```
"""
function dprimeSD(H::Real, FA::Real, method::String)

    if H < 0 || H > 1
        error("H must be between 0 and 1")
    end
    if FA < 0 || FA > 1
        error("FA must be between 0 and 1")
    end


    if method == "diff"
        if H .== FA
            dprime = 0
        else
            k = sqrt(2) * quantile(Normal(), FA/2)
            est_dp2(dp) = (H - cdf(Normal(), (k+dp)./sqrt(2)) - cdf(Normal(), (k-dp)./sqrt(2)))
            dprime =  fzero(est_dp2, [0, 10])
        end
    elseif method == "IO"
        zdiff = quantile(Normal(), H) - quantile(Normal(), FA)
        pcMax = cdf(Normal(), zdiff/2)
        dp_sign = sign(pcMax - 0.5)
        if pcMax < 0.5
            val = 2 * quantile(Normal(), 0.5 * (1 + sqrt(2 * (1 - pcMax) - 1)))
        else
            val = 2 * quantile(Normal(), 0.5 * (1 + sqrt(2 * pcMax - 1)))
        end
        dprime = dp_sign*val
    else
        error("`method` must be either 'diff', or 'IO'")
    end

    return dprime
end


end #module
