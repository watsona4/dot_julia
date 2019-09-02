# Markovify.jl

Generování náhodného textu na bázi textu trénovacího.

!!! note "Poznámka"
    V této sekci jsou popsány důvody, které vedly ke vzniku tohto balíčku. Konkrétní funkce jsou zdokumentovány v oddílu Library, konkrétně [Public Documentation](@ref) a [Internal Documentation](@ref).

## K čemu tento balík slouží

Hlavním úkolem tohoto balíčku je nabídnout kladnou odpověď na otázku: "Může nějaký program vyloudit úsměv na tváři?" — a to i z jiného důvodu, než je kvalita jeho kódu. Konkrétně se jedná o co možná nejobecnější implementaci Markovových řetězců, sloužící ke generování náhodného textu jakéhokoliv rozsahu na základě vstupních dat.

Pár správných textových souborů a tento balíček je vše, co vám stačí ke generování jmen, náhodných slov,
vět, i delších textů, a to v jakémkoli jazyce. Balíček je navrhnut tak, aby se dal použít na co možná nejširší škálu problémů.

## Moduly

Balíček exportuje dva moduly, Tokenizer a Markovify.

Modul [Markovify.Tokenizer](@ref pub_tokenizer) slouží k rozdělení jednolitého textu na menší části, takzvané *tokeny*. To je nutné proto, že modul Markovify umí pracovat právě pouze s polem polí takovýchto tokenů. V modulu se nechází několikero funkcí, které lze skládat a které nabízejí různé způsoby rozkládání textu.

Modul [Markovify](@ref pub_markov) dovoluje uživateli vytvořit [`Model`](@ref), který reprezentuje Markovův řetězec. Pomocí modelu je pak možné generovat náhodný text, který sdílí s původním textem určité vlastnosti: většinou poměr znaků a délku slov/celků. Princip funkce je konkrétně popsán v oddílu [Popis principu funkce](@ref). Lze nastavit i řád modelu a tak regulovat, jak moc se bude generovaný text podobat tomu původnímu.
