# Bobby.jl

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://travis-ci.org/alemelis/Bobby.jl.svg?branch=master)](https://travis-ci.org/alemelis/Bobby.jl)
[![codecov](https://codecov.io/gh/alemelis/Bobby.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/alemelis/Bobby.jl)

Bobby is a chess move validator, i.e. given a position and a candidate move, Bobby tells you whether the move is legal or not. He can also look for check/mates and stalemates.

## Features
- 64-bit [bitboard](https://www.chessprogramming.org/Bitboards)
- [perft and divide](http://www.rocechess.ch/perft.html) calculation
- check and checkmate
- castling
- en-passant
- promotion

## Install

In Julia REPL

```
julia> ]
(v1.1) pkg> add https://github.com/alemelis/Bobby.jl
(v1.1) pkg> activate .
```

## Play
You can play against Bobby, but he'll simply move randomly

```
julia> using Bobby
julia> Bobby.play()

  o-------------------------o
8 |  Π  ζ  Δ  Ψ  +  Δ  ζ  Π |
7 |  o  o  o  o  o  o  o  o |  o pawn
6 |                         |  ζ knight
5 |                         |  Δ bishop
4 |                         |  Π rook
3 |                         |  Ψ queen
2 |  o  o  o  o  o  o  o  o |  + king
1 |  Π  ζ  Δ  Ψ  +  Δ  ζ  Π |
  o-------------------------o
   a  b  c  d  e  f  g  h
white to move
Enter move:

```

Moves should be entered in UCI format, e.g. `e2 e4`. Promotion is automatic to _queen_.


:suspect: _huh? not very useful, isn't it?_

if you want to play a proper game try [Chess.jl](https://github.com/abahm/Chess.jl)

## Possible speed-ups
- [ ] unmove (instead of `deepcopy`ing board)
- [ ] [magic](http://pradu.us/old/Nov27_2008/Buzz/research/magic/Bitboards.pdf) [bitboards](https://www.chessprogramming.org/Magic_Bitboards)
