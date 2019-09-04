# Common Formatting Issues

## Dataset isn't UTF-8

This package relies heavily on the String capabilities of the base Julia language and implements very little custom text processing. If you see garbled characters output by `uCSV.read`, there's a good chance that your dataset is not encoded in UTF-8 and needs to be converted.

### Recommended Solutions

For converting your text file to UTF-8, consider using tools like [iconv](https://en.wikipedia.org/wiki/Iconv) or [StringEncodings.jl](https://github.com/nalimilan/StringEncodings.jl).

## Dataset doesn't use Unix `\n` or Windows `\r\n` line endings

You'll probably catch this when you try to read your data and it's parsed as 1 giant row with `\r` characters in the fields where you expected new rows to begin. This line ending was used by old Mac OS operating systems and continued to be used by Excel for Mac 2003, 2007, and 2011 long after Mac OS switched to using Unix-style `\n` line endings.

Try viewing your file in a command-line plain text viewer like `vi` or `less`. If you see `^M` character sequences at the expected line breaks, you'll need to convert those to either Unix-style `\n` or Windows-style `\r\n` yourself.

### Recommended Solutions

**Unix/Linux/MacOS**

Using homebrew/linuxbrew
```
brew install dos2unix
mac2unix my_file.macOS9.csv my_file.unix.csv
```

tr
```
cat my_file.macOS9.csv | tr '\r' '\n' > my_file.unix.csv
```

This can also be done with vi, sed, perl, awk, emacs, and many other command line text editing tools. If you'd like to see more examples here and have one to contribute, please open a PR!

**Julia**

if starting with a file
```
macOS9_io = open("/path/to/my/file.csv")
# continue to the next example
```

if starting with an `IOStream`
```
unix_io = IOBuffer(replace(read(macOS9_io, String), '\r', '\n'))
# this can now be passed to uCSV.read
```

## ["Smart" punctation](http://smartquotesforsmartpeople.com/)

Any individual "smart" quote will work, but paired "smart" quotes where beginning and ends are oriented differently are not supported.

### Recommended Solutions

Blast them away in your favorite text-editor with find and replace.
