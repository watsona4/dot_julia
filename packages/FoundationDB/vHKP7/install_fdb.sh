#!/bin/bash -e

set -x
curl -O https://www.foundationdb.org/downloads/6.0.15/ubuntu/installers/foundationdb-clients_6.0.15-1_amd64.deb
curl -O https://www.foundationdb.org/downloads/6.0.15/ubuntu/installers/foundationdb-server_6.0.15-1_amd64.deb
sudo dpkg -i foundationdb-clients_6.0.15-1_amd64.deb
sudo dpkg -i foundationdb-server_6.0.15-1_amd64.deb
