#!/bin/bash
REPO_TOKEN=b859c379-5a98-4729-82cf-c9b51e7310e7 julia -e 'cd(Pkg.dir("GenomicVectors")); using Coverage; Codecov.submit_token(process_folder())'
