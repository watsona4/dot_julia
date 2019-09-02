# LabelNumerals

[![Build Status](https://travis-ci.org/sambitdash/LabelNumerals.jl.svg?branch=master)](https://travis-ci.org/sambitdash/LabelNumerals.jl)
[![Win status](https://ci.appveyor.com/api/projects/status/ag1tt93vbh3gdac0?svg=true)](https://ci.appveyor.com/project/sambitdash/LabelNumerals-jl)
[![Coverage Status](https://coveralls.io/repos/sambitdash/LabelNumerals.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/sambitdash/LabelNumerals.jl?branch=master)
[![codecov.io](http://codecov.io/github/sambitdash/LabelNumerals.jl/coverage.svg?branch=master)](http://codecov.io/github/sambitdash/LabelNumerals.jl?branch=master)

[Documentation Link](https://sambitdash.github.io/LabelNumerals.jl/docs/build/)

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

  1. LetterNumeral - A, B, ..., Z, AA, BB, ..., ZZ, AAA... (group of 26 characters each)
  2. ArabicNumeral - 1, 2, 3, ...
  3. LookupNumeral - Mapped strings to integers like English words "One", "Two" etc.
  4. AlphaNumNumeral - Alphabets representing numbers like BA, BB, BC etc.

 It also supports `RomanNumeral` from
 [`RomanNumerals`](https://github.com/anthonyclays/RomanNumerals.jl) package.

They support ability to provide a string prefix. The prefix does not get incremented as
numbers are incremented.

 ### Examples

TBD

 ## Features

TBD

 ## Contributing
 Pull requests adding functionality are welcome (but please take note of the style guidelines)
