#!/bin/sh
set -e

# Copy config files to $HOME
cp -r /Retriever.jl/cli_tools/.pgpass  ~/
cp -r /Retriever.jl/cli_tools/.my.cnf  ~/

exec "$@"
