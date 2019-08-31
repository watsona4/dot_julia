using Fontconfig
using Compat.Test

# select basic font
pattern = Fontconfig.Pattern(family="Helvetica", size=10, hinting=true)

# check that methods don't crash
match(pattern)
format(pattern)
list(pattern)
