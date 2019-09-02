# Regex to validate a Roman numeral
using RomanNumerals

Base.string(num::LabelNumeral{Int}) = begin
    sval = num.val |> Base.string
    if num.caselower
        sval = lowercase(sval)
    end
    num.prefix*sval
end
