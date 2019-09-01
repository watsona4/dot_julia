#!/bin/sh
mv docs/build docs/DutyCycles.jl
echo 'put -r docs/DutyCycles.jl' |sftp -P $SSH_PORT $SSH_USER@$SSH_HOST:docs/github.com/Quantum-Factory
