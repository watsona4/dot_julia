#!/bin/bash


# This script can be used to offload a job to the Condor batch
# system. It assumes that all nodes that may recieve a job share the
# relevant part of the file system with the node where Mosek Server
# runs. This means that:

# - The absolute path of the working directory and problem file must be
#   the same on the recieving Condir node and the sending Condor node.
# - The script directory (containing this file, the script being run,
#   extra modules etc.) must be the same on the recieving node.

# Sending SIGTERM to this process should cause it to propagate to the
# child process (condor_run), which should propagate it to the process
# that runs the actual job (remote or local). This should happen
# automatically (I hope).

echo $BASHPID > "$1/PID"
condor_run "$(dirname $0)/solve.py" "$1" "$2" "-noPID"
rm -rf $BASHPID > "$1/PID"
