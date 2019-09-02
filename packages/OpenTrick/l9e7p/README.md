# OpenTrick

- [Examples](#examples)
- [Supported Interfaces in Base](#supported-interfaces-in-base)
- [OpenTrick.jl Documentation](#opentrickjl-documentation)

There are some `open` methods which only support the `open() do io ... end` conventions. This module provides a trick to enable keeping `io` for later usage. This is convenient for interactive programming.

## Examples

using WebSockets as an example.

```julia
using OpenTrick
using WebSockets

io = opentrick(WebSockets.open, "ws//echo.websocket.org");
write(io, "Hello");
println(String(read(io)));

close(io)  # you can close io manually
io = nothing; # or leave it to GC
unsafe_clear() # or you can clear all ios opened by opentrick manually
```

## Supported Interfaces in Base

- read, read!, readbytes!, unsafe_read, readavailable,    readline, readlines, eachline, readchomp, readuntil, bytesavailable
- write, unsafe_write, truncate, flush,    print, println, printstyled, showerror
- seek, seekstart, seekend, skip, skipchars, position
- mark, unmark, reset, ismarked
- isreadonly, iswritable, isreadable, isopen, eof
- countlines, displaysize


<a id='OpenTrick.jl-Documentation-1'></a>

## OpenTrick.jl Documentation

<a id='OpenTrick.opentrick' href='#OpenTrick.opentrick'>#</a>
**`OpenTrick.opentrick`** &mdash; *Function*.



```
opentrick(openfn[, args... [; <keyword arguments>]])
```

Call `openfn` with `(handlefn, args... ,kwargs ...)` as arguments, return an `IOWrapper` instance. (NB:`handlefn` is provided by `opentrick`.)

**Arguments**

  * `openfn::Function` function actually called to obtain a `IO` instance. `openfn` must take a `Function(::IO)` instance as its first argument
  * `args` optional arguments that will be passed to `openfn`
  * `kwargs` optional keyword arguments that will be passed to `openfn`

**Examples**

```julia-repl
julia> using OpenTrick

julia> filename = tempname();

julia> io = opentrick(open, filename, "w+");

julia> write(io, "hello world!")
12

julia> seek(io, 0);

julia> readline(io)
"hello world!"

```


<a target='_blank' href='https://github.com/zhanglix/OpenTrick.jl/blob/aaa229d239668168f255f4c518a45d1c6ddc1e8a/src/OpenTrick.jl#L18-L47' class='documenter-source'>source</a><br>

<a id='OpenTrick.rawio' href='#OpenTrick.rawio'>#</a>
**`OpenTrick.rawio`** &mdash; *Function*.



```
rawio(io)
```

Return the actual `io` instance


<a target='_blank' href='https://github.com/zhanglix/OpenTrick.jl/blob/aaa229d239668168f255f4c518a45d1c6ddc1e8a/src/OpenTrick.jl#L100-L104' class='documenter-source'>source</a><br>

<a id='OpenTrick.blockingtask' href='#OpenTrick.blockingtask'>#</a>
**`OpenTrick.blockingtask`** &mdash; *Function*.



```
blockingtask(io)
```

Return the task blocking which prevents the `handlefn` passed to `openfn` from returning


<a target='_blank' href='https://github.com/zhanglix/OpenTrick.jl/blob/aaa229d239668168f255f4c518a45d1c6ddc1e8a/src/OpenTrick.jl#L107-L111' class='documenter-source'>source</a><br>

<a id='OpenTrick.unsafe_clear' href='#OpenTrick.unsafe_clear'>#</a>
**`OpenTrick.unsafe_clear`** &mdash; *Function*.



```
unsafe_clear()
```

Unblock all blocking tasks. All `io`s returned by `opentrick` will be closed as a consequence.


<a target='_blank' href='https://github.com/zhanglix/OpenTrick.jl/blob/aaa229d239668168f255f4c518a45d1c6ddc1e8a/src/OpenTrick.jl#L87-L92' class='documenter-source'>source</a><br>

