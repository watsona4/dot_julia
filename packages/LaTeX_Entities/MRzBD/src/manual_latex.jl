# Parly derived from latex_symbols.jl, which is a part of Julia
# License is MIT: http://julialang.org/license

const greek_letters =
    ("Alpha"   => "A",
     "Beta"    => "B",
     "Gamma"   => "G",
     "Delta"   => "D",
     "Epsilon" => "E",
     "Zeta"    => "Z",
     "Eta"     => "H",
     "Theta"   => "J",
     "Iota"    => "I",
     "Kappa"   => "K",
     "Lambda"  => "L",
     "Mu"      => "M",
     "Nu"      => "N",
     "Xi"      => "X",
     "Omicron" => "U",
     "Pi"      => "P",
     "Rho"     => "R",
     "Sigma"   => "S",
     "Tau"     => "T",
     "Upsilon" => "Y",
     "Phi"     => "F",
     "Chi"     => "C",
     "Psi"     => "W",
     "Omega"   => "O",
     "alpha"   => "a",
     "beta"    => "b",
     "gamma"   => "g",
     "delta"   => "d",
     "epsilon" => "e",
     "zeta"    => "z",
     "eta"     => "h",
     "theta"   => "j",
     "iota"    => "i",
     "kappa"   => "k",
     "lambda"  => "l",
     "mu"      => "m",
     "nu"      => "n",
     "xi"      => "x",
     "omicron" => "u",
     "pi"      => "p",
     "rho"     => "r",
     "sigma"   => "s",
     "tau"     => "t",
     "upsilon" => "y",
     "phi"     => "f",
     "chi"     => "c",
     "psi"     => "w",
     "omega"   => "o",
)

const var_greek =
    ("varTheta"   => "J",
     "nabla"      => "n",
     "partial"    => "d", # partial differential
     "varepsilon" => "e",
     "varsigma"   => "s",
     "vartheta"   => "j",
     "varkappa"   => "k",
     "varphi"     => "f",
     "varrho"     => "r",
     "varpi"      => "p"
     )

const digits = (
    "zero"  => "0",
    "one"   => "1",
    "two"   => "2",
    "three" => "3",
    "four"  => "4",
    "five"  => "5",
    "six"   => "6",
    "seven" => "7",
    "eight" => "8",
    "nine"  => "9"
    )

const remove_lead_char = "AEt"
const remove_prefix = ("APL", "Elz", "Elx", "El", "textascii", "text")

const replace_lead_char = "Bm"
const replace_prefix =
    (("Bbb",       "d",   "bb"),	# double-struck or blackboard
     ("mbfsans",   "sb",  "bsans"),     # bold sans-serif
     ("mbfscr",    "cb",  "bscr"),	# bold cursive script
     ("mbffrak",   "fb",  "bfrak"),     # bold fraktur
     ("mbfitsans", "sib", "bisans"),    # bold italic sans-serif
     ("mbfit",     "ib",  "bi"),        # bold italic
     ("mbf",       "b",   "bf"),        # bold
     ("mfrak",     "f",   "frak"),      # fraktur
     ("mitsans",   "si",  "isans"),     # italic sans-serif
     ("mitBbb",    "di",  "bbi"),       # italic double-struck (or blackboard)
     ("mit",       "i",   "it"),        # italic
     ("msans",     "s",   "sans"),      # sans-serif
     ("mscr",      "c",   "scr"),       # cursive script
     ("mtt",       "t",   "tt")         # teletype (monospaced)
)

const remove_name = ("Elxsqcup", "Elxuplus", "ElOr", "textTheta", "Elzbar")

const replace_name = (
    "textasciiacute"  => "textacute",
    "textasciibreve"  => "textbreve",
    "textasciimacron" => "highminus",
    "textphi"         => "ltphi",
    "Eulerconst"      => "eulermascheroni",
    "Hermaphrodite"   => "hermaphrodite",
    "Planckconst"     => "planck",
    "bkarow"          => "bkarrow",
    "dbkarow"         => "dbkarrow",
    "hksearow"        => "hksearrow",
    "hkswarow"        => "hkswarrow"
    )

const manual = [
    "cbrt"        => "\u221B", # synonym of \cuberoot
    "mars"        => "♂",      # synonym of \male
    "pprime"      => "″",      # synonym of \dprime
    "ppprime"     => "‴",      # synonym of \trprime
    "pppprime"    => "⁗",      # synonym of \qprime
    "backpprime"  => "‶",      # synonym of \backdprime
    "backppprime" => "‷",      # synonym of \backtrprime
    "emptyset"    => "∅",      # synonym of \varnothing
    "llbracket"   => "⟦",      # synonym of \lBrack
    "rrbracket"   => "⟧",      # synonym of \rBrack
    "xor"         => "⊻",      # synonym of \veebar
    "iff"         => "⟺",
    "implies"     => "⟹",
    "impliedby"   => "⟸",
    "to"          => "→",
    "euler"       => "ℯ",

    # Misc. Math and Physics
    "del"         => "∇",      # synonym of \nabla (combining character)
    "sout"        => "\u0336", # synonym of \Elzbar (from ulem package)
    "strike"      => "\u0336", # synonym of \Elzbar
    "zbar"        => "\u0336", # synonym of \Elzbar

    # Avoid getting "incorrect" synonym
    "imath"       => "ı",
    "jmath"       => "ȷ",
    "i_imath"     => "\U1d6a4",     # mathematical italic small dotless i
    "i_jmath"     => "\U1d6a5",     # mathematical italic small dotless j
    "hbar"        => "\u0127",      # ħ synonym of \Elzxh
    "AA"          => "\u00c5",      # Å
    "Upsilon"     => "\u03a5",      # Υ
    "setminus"    => "\u2216",      # ∖ synonym of \smallsetminus
    "ddot{i}"     => "\u00cf",      # is ddot{\imath} in unicode.xml
    "bigsetminus" => "\u29f5",      # add to allow access to standard setminus
    "circlearrowleft"  => "\u21ba", # ↺ synonym of acwopencirclearrow
    "circlearrowright" => "\u21bb", # ↻ synonym of cwopencirclearrow
]

# Vulgar fractions
const fractions = [
    "1/4"  => "¼", # vulgar fraction one quarter
    "1/2"  => "½", # vulgar fraction one half
    "3/4"  => "¾", # vulgar fraction three quarters
    "1/7"  => "⅐",# vulgar fraction one seventh
    "1/9"  => "⅑", # vulgar fraction one ninth
    "1/10" => "⅒", # vulgar fraction one tenth
    "1/3"  => "⅓", # vulgar fraction one third
    "2/3"  => "⅔", # vulgar fraction two thirds
    "1/5"  => "⅕", # vulgar fraction one fifth
    "2/5"  => "⅖", # vulgar fraction two fifths
    "3/5"  => "⅗", # vulgar fraction three fifths
    "4/5"  => "⅘", # vulgar fraction four fifths
    "1/6"  => "⅙", # vulgar fraction one sixth
    "5/6"  => "⅚", # vulgar fraction five sixths
    "1/8"  => "⅛", # vulgar fraction one eigth
    "3/8"  => "⅜", # vulgar fraction three eigths
    "5/8"  => "⅝", # vulgar fraction five eigths
    "7/8"  => "⅞", # vulgar fraction seventh eigths
    "1/"   => "⅟", # fraction numerator one
    "0/3"  => "↉", # vulgar fraction zero thirds
    "1/4"  => "¼", # vulgar fraction one quarter
]

const superscripts = [
    "^0" => "⁰",
    "^1" => "¹",
    "^2" => "²",
    "^3" => "³",
    "^4" => "⁴",
    "^5" => "⁵",
    "^6" => "⁶",
    "^7" => "⁷",
    "^8" => "⁸",
    "^9" => "⁹",
    "^+" => "⁺",
    "^-" => "⁻",
    "^=" => "⁼",
    "^(" => "⁽",
    "^)" => "⁾",
    "^a" => "ᵃ",
    "^b" => "ᵇ",
    "^c" => "ᶜ",
    "^d" => "ᵈ",
    "^e" => "ᵉ",
    "^f" => "ᶠ",
    "^g" => "ᵍ",
    "^h" => "ʰ",
    "^i" => "ⁱ",
    "^j" => "ʲ",
    "^k" => "ᵏ",
    "^l" => "ˡ",
    "^m" => "ᵐ",
    "^n" => "ⁿ",
    "^o" => "ᵒ",
    "^p" => "ᵖ",
    "^r" => "ʳ",
    "^s" => "ˢ",
    "^t" => "ᵗ",
    "^u" => "ᵘ",
    "^v" => "ᵛ",
    "^w" => "ʷ",
    "^x" => "ˣ",
    "^y" => "ʸ",
    "^z" => "ᶻ",
    "^A" => "ᴬ",
    "^B" => "ᴮ",
    "^D" => "ᴰ",
    "^E" => "ᴱ",
    "^G" => "ᴳ",
    "^H" => "ᴴ",
    "^I" => "ᴵ",
    "^J" => "ᴶ",
    "^K" => "ᴷ",
    "^L" => "ᴸ",
    "^M" => "ᴹ",
    "^N" => "ᴺ",
    "^O" => "ᴼ",
    "^P" => "ᴾ",
    "^R" => "ᴿ",
    "^T" => "ᵀ",
    "^U" => "ᵁ",
    "^V" => "ⱽ",
    "^W" => "ᵂ",
    "^alpha" => "ᵅ",
    "^beta" => "ᵝ",
    "^gamma" => "ᵞ",
    "^delta" => "ᵟ",
    "^epsilon" => "ᵋ",
    "^theta" => "ᶿ",
    "^iota" => "ᶥ",
    "^phi" => "ᵠ",
    "^chi" => "ᵡ",
    "^Phi" => "ᶲ",
]

const subscripts = [
    "_0" => "₀",
    "_1" => "₁",
    "_2" => "₂",
    "_3" => "₃",
    "_4" => "₄",
    "_5" => "₅",
    "_6" => "₆",
    "_7" => "₇",
    "_8" => "₈",
    "_9" => "₉",
    "_+" => "₊",
    "_-" => "₋",
    "_=" => "₌",
    "_(" => "₍",
    "_)" => "₎",
    "_a" => "ₐ",
    "_e" => "ₑ",
    "_h" => "ₕ",
    "_i" => "ᵢ",
    "_j" => "ⱼ",
    "_k" => "ₖ",
    "_l" => "ₗ",
    "_m" => "ₘ",
    "_n" => "ₙ",
    "_o" => "ₒ",
    "_p" => "ₚ",
    "_r" => "ᵣ",
    "_s" => "ₛ",
    "_t" => "ₜ",
    "_u" => "ᵤ",
    "_v" => "ᵥ",
    "_x" => "ₓ",
    "_schwa" => "ₔ",
    "_beta" => "ᵦ",
    "_gamma" => "ᵧ",
    "_rho" => "ᵨ",
    "_phi" => "ᵩ",
    "_chi" => "ᵪ"
]

const mansym = [manual, fractions, superscripts, subscripts]
const mantyp = ["manual", "fractions", "superscripts", "subscripts"]
