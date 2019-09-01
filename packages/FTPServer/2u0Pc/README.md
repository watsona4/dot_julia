# FTPServer

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://invenia.github.io/FTPServer.jl/stable)
[![Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://invenia.github.io/FTPServer.jl/latest)
[![Build Status](https://travis-ci.com/invenia/FTPServer.jl.svg?branch=master)](https://travis-ci.com/invenia/FTPServer.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/invenia/FTPServer.jl?svg=true)](https://ci.appveyor.com/project/invenia/FTPServer-jl)
[![Codecov](https://codecov.io/gh/invenia/FTPServer.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/invenia/FTPServer.jl)

A Julia interface for running a test FTP server with [pyftpdlib](https://pyftpdlib.readthedocs.io/en/latest/index.html).

## Usage

Since this package is primarily intended for test ftp logic, we recommend using the `FTPServer.serve`
do-block syntax to handle cleaning your test ftp server.
```
using FTPClient
using FTPServer

# Initialize a root directory to run servers from
FTPServer.init()

# Run some tests
FTPServer.serve() do server
    opts = (
        :hostname => FTPServer.hostname(server),
        :port => FTPServer.port(server),
        :username => FTPServer.username(server),
        :password => FTPServer.password(server),
    )

    options = RequestOptions(; opts..., ssl=false)
    ctxt, resp = ftp_connect(options)
    ...
end

# Cleanup the shared FTP directory
FTPServer.cleanup()
```
