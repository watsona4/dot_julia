#!/bin/bash

# Status script which traverses the subdirectories of the current folder for 
# simulations.  You may want to add this to your shell's PATH variable.

set -e
cmd_single='julia --color=yes -e "import Granular; Granular.status()"'
cmd_loop='julia --color=yes -e "import Granular; Granular.status(loop=true, t_int=10)"'
cmd_render='julia --color=yes -e "import Granular; Granular.status(visualize=true)"'

if [[ "$1" == "loop" ]]; then
    eval $cmd_loop
elif [[ "$1" == "-l" ]]; then
    eval $cmd_loop
elif [[ "$1" == "--loop" ]]; then
    eval $cmd_loop
elif [[ "$1" == "render" ]]; then
    eval $cmd_render
elif [[ "$1" == "visualize" ]]; then
    eval $cmd_render
else
    eval $cmd_single
fi
