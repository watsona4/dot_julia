# Board representation

## bitboard

In the _bitboard_ approach, the board is represented by a binary number of 64 digits with `1` indicating the presence of a piece and `0` an empty square. For example, the board starting position in [FEN](https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation) notation looks like

```
rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR
```

and in binary notation reads

```
1111111111111111000000000000000000000000000000001111111111111111
```

this 64-bit number reports the location of empty/occupied squares. Similarly, we can have bitboards referring to white/black pawns, knights, bishops, queens, and kings

```
White pieces
0000000000000000000000000000000000000000000000001111111111111111

White pawns
0000000000000000000000000000000000000000000000001111111100000000

White rooks
0000000000000000000000000000000000000000000000000000000010000001

...
```

We may want to have a bitboard for all the white pieces, all the black pieces, and individual bitboards for each different color/piece combination and two global boards showing free and occupied squares, i.e. _6*2+2+2=16_ 64-bit numbers in total. These can be reshaped and formatted to look like a proper _8x8_ chess board

```
  o-----------------o
8 | r n b q k b n r |
7 | p p p p p p p p |
6 | ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ |
5 | ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ |
4 | ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ |
3 | ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ |
2 | P P P P P P P P |
1 | R N B Q K B N R |
  o-----------------o
    a b c d e f g h
```

The reason why bitboards are so popular is because you can operate on them with logical operators (1-cycle operations!). For instance, given the two bitboards `white_only` and `black_only`, all the free squares are given by `free_squares = ~(white_only | black_only)`.

Operations are made easier with [_lookup tables_](http://pages.cs.wisc.edu/~psilord/blog/data/chess-pages/physical.html), i.e., a set of pre-allocated bitboards wich can be `OR`ed or `AND`ed with another bitboard to remove(clear)/keep(mask) a file/rank (32 tables in total). For instance, the lookup table `mask_rank1` looks like

```
  o-----------------o
8 | 0 0 0 0 0 0 0 0 |
7 | 0 0 0 0 0 0 0 0 |
6 | 0 0 0 0 0 0 0 0 |
5 | 0 0 0 0 0 0 0 0 |
4 | 0 0 0 0 0 0 0 0 |
3 | 0 0 0 0 0 0 0 0 |
2 | 0 0 0 0 0 0 0 0 |
1 | 1 1 1 1 1 1 1 1 |
  o-----------------o
    a b c d e f g h
```

and we can use it to determine which pieces are in a specific rank/file, e.g., all the black rooks in the fifth rank are retrieved as `black_rooks_rank5 = black_rooks & mask_rank5`.