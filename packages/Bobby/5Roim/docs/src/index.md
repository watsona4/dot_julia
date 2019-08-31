# Bobby.jl

Bobby is a chess engine written in Julia

---

The documentation is generated with [Documenter.jl](https://juliadocs.github.io/Documenter.jl/stable/index.html)

```bash
$ julia make.jl
```

## Steps

- [Board representation](./board.md)
- [Valid moves generation](./moves.md)
- Evaluation

## References

### Repos

- [chess-position-evaluation](https://github.com/int8/chess-position-evaluation) with machine learning (Julia)
- [tensorflow_chessbot](https://github.com/Elucidation/tensorflow_chessbot) predicts FEN layouts from images (Python)
- [Chess.jl](https://github.com/abahm/Chess.jl) (Julia)
- [go-chess](https://github.com/alokmenghrajani/go-chess) A minimalistic chess program written in (Go)
- [LeelaChessZero](https://github.com/LeelaChessZero/lczero) is a chess adaption of GCP's Leela Zero (C++)
- [Ethereal](https://github.com/AndyGrant/Ethereal) is an UCI-compliant chess engine (C)
- [Rust Chess Library](https://jordanbray.github.io/chess/chess/index.html) (Rust)
- [Snakefish](https://github.com/cglouch/snakefish#sliding-pieces) (Python)

### Papers

- Silver et al. (2017) [Mastering Chess and Shogi by Self-Play with a General Reinforcement Learning Algorithm](https://arxiv.org/abs/1712.01815)

### Tutorials

- [Tom Kerrigan's Simple Chess Program (TSCP)](https://sites.google.com/site/tscpchess/home) is a tutorial engine (C)
- Francois Dominic Laramee's Chess Programming series (Java)
  - [Introduction](https://www.gamedev.net/articles/programming/artificial-intelligence/chess-programming-part-i-getting-started-r1014)
  - [Data Structures](https://www.gamedev.net/articles/programming/artificial-intelligence/chess-programming-part-ii-data-structures-r1046)
  - [Move Generation](https://www.gamedev.net/articles/programming/artificial-intelligence/chess-programming-part-iii-move-generation-r1126)
  - [Evaluation Function](https://www.gamedev.net/articles/programming/artificial-intelligence/chess-programming-part-vi-evaluation-functions-r1208)
  - [Advanced Search](https://www.gamedev.net/articles/programming/artificial-intelligence/chess-programming-part-v-advanced-search-r1197)
- Bruce Moreland's [Gerbil](https://web.archive.org/web/20071026090003/http://www.brucemo.com/compchess/programming/index.htm) (C)
- [Chess and Bitboards](http://pages.cs.wisc.edu/~psilord/blog/data/chess-pages/) (incomplete)
- [Efficient moves generation](https://peterellisjones.com/posts/generating-legal-chess-moves-efficiently/) (Rust)
- [Injecting a Chess Engine into Amazon Redshift](http://www.michaelburge.us/2017/09/10/injecting-shellcode-to-speed-up-amazon-redshift.html) (Rust)

### Board representation

#### Data structures

- [bitboard](http://www.frayn.net/beowulf/theory.html#bitboards)
- [0x88](https://web.archive.org/web/20071027053053/http://www.brucemo.com:80/compchess/programming/0x88.htm)