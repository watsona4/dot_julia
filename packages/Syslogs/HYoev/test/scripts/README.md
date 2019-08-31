# Python SysLogHandler Output

This directory contains a python script (`client.py`) which uses the python
`SysLogHandler` to log UDP messages to localhost:8080.
The julia script (`server.jl`) binds to localhost:8080 and writes the UPD
messages received to a log file (`output.log`).
The purpose of these scripts is to confirm that our `Syslog` type produces the same
UDP messages as the python `SysLogHandler`.


## Usage

In one terminal session run the server script.

```shell
scripts> julia server.jl
INFO: Receiving data...
```

NOTE: The script will block waiting for input.

In another terminal session run the client script.

```shell
scripts> python client.py
```

Now ctrl-c the server script and inspect the output written to output.log.

```shell
scripts> cat output.log
<14>MyLogger INFO:I'm nobody! Who are you?
<15>MyLogger DEBUG:Are you nobody, too?
<14>MyLogger INFO:Then there's a pair of us -- don't tell!
<12>MyLogger WARNING:They'd advertise -- you know!
<14>MyLogger INFO:
<14>MyLogger INFO:How dreary to be somebody!
<14>MyLogger INFO:How public like a frog
<14>MyLogger INFO:To tell one's name the livelong day
<14>MyLogger INFO:To an admiring bog!
```