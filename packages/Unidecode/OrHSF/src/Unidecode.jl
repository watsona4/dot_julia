module Unidecode
    using REPL, Unicode
    const emoji_dict = Dict((v => k) for (k, v) in REPL.REPLCompletions.emoji_symbols)
    function decode_emoji(x)
        string((c ∈ keys(emoji_dict) ? emoji_dict[c][2:end] : c for c in graphemes(x))...)
    end
    const latex_dict = Dict((v => k) for (k, v) in REPL.REPLCompletions.latex_symbols)
    function decode_latex(x)
        string((c ∈ keys(latex_dict) ? latex_dict[c][2:end] : c for c in graphemes(x))...)
    end
    function unidecode(x)
        decode_emoji(decode_latex(x))
    end
    export unidecode, decode_emoji, decode_latex
end
