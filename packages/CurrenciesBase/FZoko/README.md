# CurrenciesBase.jl

[![Build Status](https://travis-ci.org/JuliaFinance/CurrenciesBase.jl.svg?branch=master)](https://travis-ci.org/JuliaFinance/CurrenciesBase.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/1593mlsleriaex4j?svg=true)](https://ci.appveyor.com/project/EricForgy/currenciesbase-jl)

## Purpose

This package provides the core functionality for [Currencies.jl](https://github.com/JuliaFinance/Currencies.jl).

## Data Source
The currency-related information for this package comes from [this Wikipedia page](https://en.wikipedia.org/wiki/ISO_4217#cite_note-divby5-9), the official ISO standard, and other Wikipedia pages. It is compiled manually and may be in error; please do submit a pull request to correct any errors.

## Usage
This README.md file provides a basic guide to getting started. It is not a replacement for the [documentation](https://juliafinance.github.io/Currencies.jl/latest/). Please file any corrections or missing parts of the documentation as issues, or even better, send in a pull request.

The `Currencies` module exports the `Monetary` type. To access currencies, use the `@usingcurrencies` macro. Basic operation is as follows:

```julia
@usingcurrencies USD
1USD + 2USD  # 3.00 USD
3 * 1.5USD   # 4.50 USD
```

Mixed arithmetic is not supported:

```julia
@usingcurrencies USD, CAD
10USD + 3CAD  # ArgumentError
```

Monetary amounts can be compared:

```julia
@usingcurrencies USD, EUR
1USD < 2USD        # true
sort([2EUR, 1EUR]) # [1EUR, 2EUR]
```

## Using `Monetary` in Practice
`Monetary` types behave a lot like integer types, and they can be used like them for a lot of practical situations. For example, here is a (quite fast) function to give optimal change using the common European system of having coins and bills worth 0.01€, 0.02€, 0.05€, 0.10€, 0.20€, 0.50€, 1.00€, and so forth until 500.00€ (this algorithm doesn't necessarily work for all combinations of coin values).

```julia
@usingcurrencies EUR
COINS = [500EUR, 200EUR, 100EUR, 50EUR, 20EUR, 10EUR, 5EUR, 2EUR, 1EUR, 0.5EUR,
    0.2EUR, 0.1EUR, 0.05EUR, 0.02EUR, 0.01EUR]
function change(amount::Monetary{:EUR,Int})
    coins = Dict{Monetary{:EUR,Int}, Int}()
    for denomination in COINS
        coins[denomination], amount = divrem(amount, denomination)
    end
    coins
end

sum([k*v for (k, v) in change(167.25EUR)])  # 167.25EUR
```
