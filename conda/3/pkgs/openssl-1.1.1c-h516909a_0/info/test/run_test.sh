

set -ex



touch checksum.txt
openssl sha256 checksum.txt
exit 0
