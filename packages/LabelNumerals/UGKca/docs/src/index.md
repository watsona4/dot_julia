# Numbers as Labels

Numeric quantities are used sometimes for pure representational purposes without any true a
 numeric significance. For example, the page numbering is carried out using simple arabic
 numerals, roman numerals, alphabets. These numbers have additive properties but may not
 have any multiplicative significance. Such numbers can also have prefix notations as well.
 In some cases, the representation can be in upper case or lower case as well. This package
 implements such a numerals. Such numeric schemes are used as page numbers in PDF file
 specification. However, the need may be felt else where as well, which prompted the author
 to implement it as an independent package. The interface has been also influenced
 significantly by the [RomanNumerals](https://github.com/anthonyclays/RomanNumerals.jl) package.

 ## Usage
 LabelNumerals introduces the following new types:

  1. LetterNumeral - `LabelNumeral{AlphaNumeral}` - A, B, ..., Z, AA, BB, ..., ZZ, AAA... (group of 26 characters each)
  2. ArabicNumeral - `LabelNumeral{Int}` - 1, 2, 3, ...
  3. LookupNumeral - `LabelNumeral{LookupNumeral}` - mapped strings to integers like English words "One", "Two" etc.
  4. AlphaNumNumeral - `LabelNumeral{AlphaNumNumeral}` - alphabets representing numbers like BA, BB, BC etc.

 It also supports `RomanNumeral` from
 [`RomanNumerals`](https://github.com/anthonyclays/RomanNumerals.jl) package.

They support ability to provide a string prefix. The prefix does not get incremented as
numbers are incremented.

!!Note: Letter, arabic and roman numerals are used in the PDF file pages as page number
labels.

## LabelNumeral
```@docs
LabelNumeral{T <: Integer}
LabelNumeral{T <: Integer}(t::T; prefix="", caselower=false)
findLabels
```

## AlphaNumeral
```@docs
AlphaNumeral
AlphaNumeral(::String)
@an_str
```

## AlphaNumNumeral
```@docs
AlphaNumNumeral
AlphaNumNumeral(::String)
@ann_str
```
## LookupNumeral
```@docs
LookupNumeral
LookupNumeral(::String)
@ln_str
```

## External Numeral Types

### ArabicNumeral
Represented as `Int` types.

### RomanNumeral
Represented as `RomanNumeral` from the [`RomanNumerals`](https://github.com/anthonyclays/RomanNumerals.jl) package.
