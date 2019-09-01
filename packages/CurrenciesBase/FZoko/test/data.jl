## Tests relating to data integrity. ##

@testset "Data" begin

# long symbols should be unique
alllongsymbols = values(CurrenciesBase.LONG_SYMBOL)
@test length(Set(alllongsymbols)) == length(alllongsymbols)

# symbols should all be registered currencies
registeredcurrencies = keys(CurrenciesBase.ISO4217)
for sym in keys(CurrenciesBase.SHORT_SYMBOL)
    @test sym ∈ registeredcurrencies
end
for sym in keys(CurrenciesBase.LONG_SYMBOL)
    @test sym ∈ registeredcurrencies
end

# locale keys should be registered currencies, and value :before or :after
for (sym, val) in CurrenciesBase.LOCAL_SYMBOL_LOCATION
    @test sym ∈ registeredcurrencies
    @test val ∈ (:before, :after)
end

end  # @testset "Data"
