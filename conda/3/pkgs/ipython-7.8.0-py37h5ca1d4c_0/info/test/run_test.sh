

set -ex



ipython -h
ipython3 -h
NOSE_EXCLUDE="test_history|recursion" iptest
exit 0
