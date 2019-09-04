# A Julia interface to the XPA messaging system

This [Julia](http://julialang.org/) package provides an interface to the
[XPA Messaging System](https://github.com/ericmandel/xpa) which provides
seamless communication between many kinds of Unix/Windows programs, including X
programs and Tcl/Tk programs.

The Julia interface to the XPA message system can be used as a client to send
or query data from one or more XPA servers or to implement an XPA server.  The
interface exploits the power of `ccall` to directly call the routines of the
compiled XPA library.


## Prerequisites and installation

### Installation of the XPA library

To use this package, **XPA** must be installed on your computer.
If this is not the case, they are available for different operating systems.
For example, on Ubuntu, just do:

```sh
sudo apt-get install xpa-tools libxpa-dev
```

If XPA is not provided by your system, you may install it manually.  That's
easy but make sure that you compile and install the shared library of XPA since
this is the one that will be used by Julia.

Download the source archive at
https://github.com/ericmandel/xpa/releases/latest, then unpack it in some
directory, build and install it.  For instance:

```sh
cd "$SRCDIR"
wget -O xpa-2.1.18.tar.gz https://github.com/ericmandel/xpa/archive/v2.1.18.tar.gz
tar -zxvf xpa-2.1.18.tar.gz
cd xpa-2.1.18
./configure --prefix="$PREFIX" --enable-shared
mkdir -p "$PREFIX/lib" "$PREFIX/include" "$PREFIX/bin"
make install
```

where `$SRCDIR` is the directory where to download the archive and extract the
source while `$PREFIX` is the directory to install XPA library, header file(s)
and executables.  You may consider other configuration options (run
`./configure --help` for a list) but make sure to have `--enable-shared` for
building the shared library.  As of the current version of XPA (2.1.18), the
installation script does not automatically build some destination directories,
hence the `mkdir -p ...` command above.


### Installation of the XPA Julia package

The easiest way to install the package is to do it from Julia:

```julia
Pkg.clone("https://github.com/emmt/XPA.jl")
Pkg.build("XPA")
```

To upgrade the package:

```julia
Pkg.update("XPA")
Pkg.build("XPA")
```

If you have a custom XPA installation, you may define the environment variables
`XPA_DEFS` and `XPA_LIBS` to suitable values before building XPA package.  The
environment variable `XPA_DEFS` specifies the C-preprocessor flags for finding
the headers `"xpa.h"` and `"prsetup.h"` while the environment variable
`XPA_LIBS` specifies the linker flags for linking with the XPA dynamic library.
If you have installed XPA as explained above, do:

```sh
export XPA_DEFS="-I$PREFIX/include"
export XPA_LIBS="-L$PREFIX/lib -lxpa"
```

It may also be the case that you want to use a specific XPA dynamic library
even though your sustem provides one.  Then define the environment variable
`XPA_DEFS` as explained above and define the environment variable `XPA_DLL`
with the full path to the dynamic library to use.  For instance:

```sh
export XPA_DEFS="-I$PREFIX/include"
export XPA_DLL="$PREFIX/lib/libxpa.so"
```

Note that if both `XPA_LIBS` and `XPA_DLL` are defined, the latter has
precedence.

These variables must be defined before launching Julia and cloning/building the
XPA package.  You may also add the following lines in
`~/.julia/config/startup.jl`:

```julia
ENV["XPA_DEFS"] = "-I/InstallDir/include"
ENV["XPA_LIBS"] = "-L/InstallDir/lib -lxpa"
```

or (depending on the situation):

```julia
ENV["XPA_DEFS"] = "-I/InstallDir/include"
ENV["XPA_DLL"] = "/InstallDir/lib/libxpa.so"
```

where `InstallDir` should be modified according to your specific installation.


## Using the XPA message system

In your Julia code/session, it is sufficient to do:

```julia
import XPA
```

or:

```julia
using XPA
```

This makes no differences as nothing is exported by the `XPA` module.  This
means that all methods or constants are prefixed by `XPA.`.  You may change the
suffix, for instance:

```julia
using XPA
const xpa = XPA
```

The implemented methods are described in what follows, first the client side,
then the server side and finally some utilities.  More extensive XPA
documentation can be found [here](http://hea-www.harvard.edu/RD/xpa/help.html).


### Using the XPA message system as a client

#### Persistent XPA client connection

For each client request, XPA is able to automatically establish a temporary
connection to the server.  This however implies some overheads and, to speed up
the connection, a persistent XPA client can be created by calling
`XPA.Client()` which returns an opaque object.  The connection is automatically
shutdown and related resources freed when the client object is garbage
collected.  The `close()` method can also by applied to the client object, in
that case all subsequent requests with the object will establish a (slow)
temporary connection.


#### Get data from one or more XPA servers

To query something from one or more XPA servers, the most general method is:

```julia
XPA.get([xpa,] src [, params...]) -> tup
```

which retrieves data from one or more XPA access points identified by `src` (a
template name, a `host:port` string or the name of a Unix socket file) with
parameters `params...` (automatically converted into a single string where the
parameters are separated by a single space).  The result is a tuple of tuples
`(data,name,mesg)` where `data` is a vector of bytes (`UInt8`), `name` is a
string identifying the server which answered the request and `mesg` is an empty
string or a meaasge (either an error or an informative message).  Optional
argument `xpa` specifies a persistent XPA client (created by `XPA.Client()`)
for faster connections.

The `XPA.get()` method recognizes the following keywords:

* Keyword `nmax` specifies the maximum number of answers, `nmax=1` by default.
  Use `nmax=-1` to use the maximum number of XPA hosts.  Note that there are as
  many tuples as answers in the result.

* `mode` specifies options in the form `"key1=value1,key2=value2"`.

There are simpler methods which return only the data part of the answer,
possibly after conversion.  These methods limit the number of answers to be at
most one and throw an error if `XPA.get()` returns a non-empty error message.
To retrieve the `data` part of the answer received by an `XPA.get()` request as
a vector of bytes, call the method:

```julia
XPA.get_bytes([xpa,] src [, params...]; mode="") -> buf
```

where arguments `xpa`, `src` and `params...` and keyword `mode` are passed to
`XPA.get()`.  To convert the result of `XPA.get_bytes()` into a single string,
call the method:

```julia
XPA.get_text([xpa,] src [, params...]; mode="") -> str
```

To split the result of `XPA.get_text` into an array of strings, one for each
line, call the method:

```julia
XPA.get_lines([xpa,] src [, params...]; keep=false, mode="") -> arr
```

where keyword `keep` can be set `true` to keep empty lines.  Finally, to split
the result of `XPA.get_text()` into an array of words, call the method:

```julia
XPA.get_words([xpa,] src [, params...]; mode="") -> arr
```


#### Send data to one or more XPA servers

The `XPA.set()` method recognizes the following keywords:

```julia
XPA.set([xpa,] dest [, params...]; data=nothing) -> tup
```

send `data` to one or more XPA access points identified by `dest` with
parameters `params...` (automatically converted into a single string where the
parameters are separated by a single space).  The result is a tuple of tuples
`(name,mesg)` where `name` is a string identifying the server which received
the request and `mesg` is an empty string or a message.  Optional argument
`xpa` specifies a persistent XPA client (created by `XPA.Client()`) for faster
connections.

The following keywords are accepted:

* `data` the data to send, may be `nothing` or an array.  If it is an array, it
  must be an instance of a sub-type of `DenseArray` which implements the
  `pointer` method.

* `nmax` specifies the maximum number of recipients, `nmax=1` by default.
  Specify `nmax=-1` to use the maximum possible number of XPA hosts.

* `mode` specifies options in the form `"key1=value1,key2=value2"`.

* `check` specifies whether to check for errors.  If this keyword is set
  `true`, an error is thrown for the first non-empty error message `mesg`
  encountered in the list of answers.


### Messages

The returned messages string are of the form:

```julia
XPA$ERROR message (class:name ip:port)
```

or

```julia
XPA$MESSAGE message (class:name ip:port)
```

depending whether an error or an informative message has been set (with
`XPA.seterror()` or `XPA.setmessage()` respectively).  Note that when there is
an error stored in an messages entry, the corresponding data buffers may or may
not be empty, depending on the particularities of the server.


### Implementing an XPA server

#### Create an XPA server

The simplest way to create a new XPA server is to do:

```julia
server = XPA.Server(class, name, help, send, recv)
```

where `class`, `name` and `help` are strings while `send` and `recv` are
callbacks created by:

```julia
send = XPA.SendCallback(sendfunc, senddata)
recv = XPA.ReceiveCallback(recvfunc, recvdata)
```

where `sendfunc` and `recvfunc` are the Julia methods to call while `senddata`
and `recvdata` are any data needed by the callback other than what is specified
by the client request (if omitted, `nothing` is assumed).  The callbacks
have the following forms:

```julia
function sendfunc(senddata, xpa::Server, params::String,
                  buf::Ptr{Ptr{UInt8}}, len::Ptr{Csize_t})
    ...
    return XPA.SUCCESS
end
```

The callbacks must return an integer status (of type `Cint`): either
`XPA.SUCCESS` or `XPA.ERROR`.  The methods `XPA.seterror()` and
`XPA.setmessage()` can be used to specify a message accompanying the result.


```julia
XPA.setbuf!(...)
XPA.get_send_mode(xpa)
XPA.get_recv_mode(xpa)
XPA.get_name(xpa)
XPA.get_class(xpa)
XPA.get_method(xpa)
XPA.get_sendian(xpa)
XPA.get_cmdfd(xpa)
XPA.get_datafd(xpa)
XPA.get_ack(xpa)
XPA.get_status(xpa)
XPA.get_cendian(xpa)
```


#### Manage XPA requests


```julia
XPA.poll(msec, maxreq)
```

or

```julia
XPA.mainloop()
```


### Utilities

The method:

```julia
XPA.list([xpa]) -> arr
```

returns a list of the existing XPA access points as an array of structured
elements of type `XPA.AccessPoint` such that:

```julia
arr[i].class    # class of the access point
arr[i].name     # name of the access point
arr[i].addr     # socket address
arr[i].user     # user name of access point owner
arr[i].access   # allowed access (g=xpaget,s=xpaset,i=xpainfo)
```

all fields but `access` are strings, the `addr` field is the name of the socket
used for the connection (either `host:port` for internet socket, or a file path
for local unix socket), `access` is a combination of the bits `XPA.GET`,
`XPA.SET` and/or `XPA.INFO` depending whether `XPA.get()`, `XPA.set()` and/or
`XPA.info()` access are granted.  Note that `XPA.info()` is not yet implemented.

XPA messaging system can be configured via environment variables.  The
method `XPA.config` provides means to get or set XPA settings:

```julia
XPA.config(key) -> val
```

yields the current value of the XPA parameter `key` which is one of:

```julia
"XPA_MAXHOSTS"
"XPA_SHORT_TIMEOUT"
"XPA_LONG_TIMEOUT"
"XPA_CONNECT_TIMEOUT"
"XPA_TMPDIR"
"XPA_VERBOSITY"
"XPA_IOCALLSXPA"
```

The key may be a symbol or a string, the value of a parameter may be a boolean,
an integer or a string.  To set an XPA parameter, call the method:

```julia
XPA.config(key, val) -> old
```

which returns the previous value of the parameter.
