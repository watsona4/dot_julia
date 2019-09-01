module CurrenciesBase

using FixedPointDecimals

import Base: +, -, *, /, ==

# Exports
export AbstractMonetary, Monetary
export currency, decimals, majorunit, @usingcurrencies
export currencyinfo, iso4217num, iso4217alpha, shortsymbol, longsymbol
export newcurrency!, @usingcustomcurrency

# Currency data
include("data/currencies.jl")
include("data/locale.jl")
include("data/symbols.jl")

# Monetary type, currencies, and arithmetic
include("monetary.jl")
include("currency.jl")
include("arithmetic.jl")
include("mixed.jl")

# Custom currencies and macros
include("usingcurrencies.jl")
include("custom.jl")

# Display
include("formatting.jl")

end  # module CurrenciesBase
