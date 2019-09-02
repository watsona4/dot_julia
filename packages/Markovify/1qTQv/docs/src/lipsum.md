# Lorem ipsum

!!! note "Poznámka"
    V této sekci najdete krátkou demonstraci toho, jak lze můj balíček používat.

[Lorem ipsum](https://cs.wikipedia.org/wiki/Lorem_ipsum) je souhrnné označení pro text, který se sice podobá reálnému textu svou stavbou (tedy délkou slov, vět, poměrem samohlásek/souhlásek), ale který nedává smysl. Takový text se používá například v designu nebo typografii, kde by smysluplný text jen odváděl pozoronost. Originální lorem ipsum je latinský text, jehož první věta *Lorem ipsum dolor sit amet, consectetur adipisici elit* připomíná úsek z Ciceronovy tvorby.


## Program

Chceme vyprodukovat vlastní lorem ipsum, jedno ve francouzštině a druhé v němčině, abychom viděli, jak bude náš layout na plakát fungovat s různými jazyky. Trénovací texty uložíme do složky `assets/corpora/*jazyk*/` pod názvy `src1.txt` až `src3.txt`.[^1]

Obecně se každý program bude držet následující struktury:
1. Načíst text a převést jej do tokenů.
2. Natrénovat na tokenech model Markovova řetězce.
3. Vygenerovat text pomocí modelu.

Nejprve je nutné importovat oba moduly, které tento balíček obsahuje. Pomocí klíčového slova `using` je naimportujete včetně jejich exportovaných symbolů. *Pozn: Ve vašem programu pište jména modulů bez tečky před jménem.*

```@example 1
include("../src/Tokenizer.jl") #hide
include("../src/Markovify.jl") #hide

using .Markovify
using .Markovify.Tokenizer

filenames_fr = [
    "assets/corpora/french/src1.txt",
    "assets/corpora/french/src2.txt",
    "assets/corpora/french/src3.txt"
]

filenames_de = [
    "assets/corpora/german/src1.txt",
    "assets/corpora/german/src2.txt",
    "assets/corpora/german/src3.txt"
]

nothing #hide
```

Modelové texty, na kterých se bude náš řetězec trénovat, máme uložené v několika souborech. Je tedy dobré definovat funkci, která bude umět postavit modely i z více souborů. Tyto modely poté můžeme spojit pomocí funkce [`combine`](@ref).

Protože funkce [`Model`](@ref) očekává pole polí tokenů, musíme text tokenizovat. K tomu využijeme funkcí [`tokenize`](@ref) a [`words`](@ref). Tím dokončíme krok 1.

```@example 1
function loadfiles(filenames)
    # Return an iterator
    return (
        open(filename) do f
            # Tokenize on words
            tokens = tokenize(read(f, String); on=words)
            return Model(tokens; order=1)
        end
        for filename in filenames
    )
end

nothing #hide
```

Když už máme model, chtěli bychom pomocí něj vygenerovat náhodné věty. Definujeme tedy pomocnou funkci, která nám pomocí `modelu` vygeneruje `n` vět a ještě zkontroluje, zda nejsou moc krátké či dlouhé. Z toho sestává krok 2.

```@example 1
function gensentences(model, n)
    sentences = []
    # Stop only after n sentences were generated
    # and passed through the length test
    while length(sentences) < n
        seq = walk(model)
        # Add the sentence to the array iff its length is ok
        if length(seq) > 5 && length(seq) < 15
            push!(sentences, join(seq, " "))
        end
    end
    # Print each sentence on its own line
    println(join(sentences, "\n"))
end

nothing #hide
```

Nyní už stačí jen vytvořit a natrénovat model a začít generovat! To je 3. a poslední krok.

```@example 1
MODEL_DE = combine(loadfiles(filenames_de)...)
gensentences(MODEL_DE, 4)
```

A podobně také ve francouzštině:

```@example 1
MODEL_FR = combine(loadfiles(filenames_fr)...)
gensentences(MODEL_FR, 4)
```

---
[^1]: Všechny texty použité v této demonstraci pocházejí z [projektu Gutenberg](https://www.gutenberg.org).
