# Popis implementace

!!! note "Poznámka"
    Tento text pojednává o konkrétní implementaci Markovova řetězce v tomto balíčku. Obecnému principu se věnuje oddíl [Popis principu funkce](@ref).

Generování textu se dá rozdělit na několik logických podcelků:

1. Rozložení textu na tokeny.
2. Trénování modelu na základě tokenů.
3. Procházení modelového grafu.

## Rozložení textu na tokeny

Text je před zpracováním nutno rozdělit na menší celky. Má konkrétní implementace modelu počítá s tím, že text bude rozložen na pole polí tokenů, například: `PoleVět{PoleSlov{Slova}}`. K tomu slouží modul [Markovify.Tokenizer](@ref pub_tokenizer)), který nabízí několik jednoduchých kombinátorů, které může uživatel použít k rozdělení textu podle vět, řádků, slov a podobně. Jejich implementace není ničím zajímavá, jedná se o one-line funkce pracující na základě regexů.

## Trénování modelu na základě tokenů

Reprezentovat model grafem je zbytečně složité; hlavně implementačně, protože se jedná o rekurzivní datovou strukturu. Je proto vhodné převést tuto ústřední datovou strukturu na jinou, se kterou se v kódu lépe pracuje.

### Datové struktury

Pro zjednodušení je možné využít toho, že dva po sobě jdoucí stavy se liší pouze o jeden token. Celý graf pak jde převést na slovník párující vždy nějaký stav se všemi tokeny, které se po něm vyskytují.

Pokud zadefinuji pomocné datové struktury `State` a `TokenOccurences`

```julia
State{T} = Vector{Token{T}}
TokenOccurences{T} = Dict{Token{T}, Int}
```

mohu graf/Markovův řetězec/model implementovat následovně

```julia
struct Model{T}
    order::Int
    nodes::Dict{State{T}, TokenOccurences{T}}
end
```

### Trénování

Ze vstupních tokenů chceme vytvořit `Model`; k tomu slouží konstruktor [`Model`](@ref). Každý model má pevně určený řád (order), který je nutné této funkci předat jako argument.

Konstruktor poté prochází jednotlivá pole tokenů, vždy zkoumá ``k``-tici tokenů v jednom poli — ta tvoří stav. Tento stav bude klíčem ve slovníku `nodes` — všechny klíče tohoto slovníku tvoří kompletní stavový prostor Markovova řetězce. Hodnota pod tímto klíčem bude další slovník, konkrétně slovník `TokenOccurences` párující vždy token a číslo představující počet, kolikrát se tento token za daným stavem vyskytl (>=1).

Ještě před touto analýzou tokenů je nutné doplnit některé tokeny pomocné, konkrétně symboly `:begin` a `:end`, které vyznačují začátek a konec "věty" (tedy jednoho z dílčích polí). Každé pole tokenů bude po úpravě vypadat takto: `[:begin :begin ... :begin token token ... token :end]`.

- Počet symbolů `:begin` na začátku pole je roven řádu celého řetězce. To je nutné proto, abych nemusel ukládat počáteční stavy do speciální proměnné.

- Účel symbolu `:end` je jednoduchý: ukončuje náhodné procházení modelu ve funkci [`walk`](@ref).

Původně měla struktura `Model` ještě jedno pole, které bylo speciálně vyhrazené pro počáteční stavy (a `:begin` nebylo používáno). Nastal by pak ale drobný problém, kdyby uživatel chtěl využít externí balíček pro ukládání do souboru JSON, protože `Model` by byl reprezentován dvěma slovníky a bylo by nutné toto při ukládání ošeřit. Uchýlil jsem se proto v pozdějších verzích k tomuto jednoslovníkovému řešení; uživateli teď stačí uložit do souboru pouze slovník `nodes` a využít funkci [`Model`](@ref) k opětovné rekonstrukci modelu.

Místo symbolu `:begin` byl využíván v dřívějších verzích přímo string `"~~BEGIN~~"`. Pokud by však uživatel z nějakého důvodu toto slovo měl ve vstupním textu, byl by klidně i prostředek věty omylem pokládán za počáteční stav. Z toho důvodu nakonec používám datový typ `Symbol`, který je podobný symbolům v LISP.

Současný stav je vlastně pole tokenů. Je tedy teoreticky možné, že by se u jednoho modelu mohly objevit různě dlouhé stavy (například pole s jedním a dvěma prvky), což je samozřejmě chyba, protože každý model má fixní řád. Bylo by tedy lepší, aby byl stav reprezentovaný tuplem, který má už ve svém typu pevně stanovenou délku. V Julii je toto ovšem netriviální na implementaci (bylo by nutné změnit velkou část funkčního kódu) a tak jsem zatím tento krok nepodnikl.

## Procházení modelového grafu

K procházení grafu a generování náhodného textu slouží funkce [`walk`](@ref) a [`walk2`](@ref). Z modelu získají jeho slovník všech stavů, `nodes`. Generování začne ve stavu `[:begin :begin ... :begin]` a poté postupuje po krocích (co je *krok* viz níže). Jakmile narazí na token `:end`, vrátí pole vybraných tokenů.

Co je krok:
1. Nacházíme se v nějakém stavu.
2. Koukneme se do slovníku `nodes` na všechny možné tokeny, které následují po současném stavu.
3. Vybereme jeden z nich. Způsob výběru je náhodný, řídí se ale relativními četnostmi jednotlivých tokenů za daným stavem. Pokud je `nodes[současný_stav]` rovno `Dict(A => 2, B => 1)`, je šance, že zvolený token bude A, dvakrát vyšší, než že to bude B.
4. Vybraný token zařadíme za současný stav (který je jen polem tokenů) a odstraníme z něj zároveň token, který je na začátku. Toto označíme jako nový stav (má stejnou délku jako ten starý) a jdeme na bod 1.

Jak funguje pseudonáhodný výběr ze slovníku, tedy bod 3:
1. Uděláme postupný součet všech četností jednotlivých tokenů. Tj. pro `Dict(A => 2, B => 1, C => 5)` bychom vytvořili pole `[2, 3, 8]`.
2. Vygenerujeme náhodné číslo v rozmezí od nuly do nejvyššího čísla tohoto pole a pokusíme se ho zařadit do tohoto pole tak, aby pole zůstalo seřazené.
3. Index, na který bychom číslo umístili, použijeme jako index následujícího tokenu. Pravděpodobnost, že zařadíme toto náhodné číslo na konkrétní index je ovlivněna vzdáleností mezi sousedními čísly, a tedy vlastně relativní četností jednotlivých tokenů.
