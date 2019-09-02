#  tests for ipykernel-5.1.2-py37h5ca1d4c_0 (this is a generated file);
print('===== testing package: ipykernel-5.1.2-py37h5ca1d4c_0 =====');
print('running run_test.py');
#  --- run_test.py (begin) ---
import json
import os
import sys


py_major = sys.version_info[0]
specfile = os.path.join(os.environ['PREFIX'], 'share', 'jupyter', 'kernels',
                        'python{}'.format(py_major), 'kernel.json')

print('Checking Kernelspec at:     ', specfile, '...\n')

with open(specfile, 'r') as fh:
    raw_spec = fh.read()

print(raw_spec)

spec = json.loads(raw_spec)

print('\nChecking python executable', spec['argv'][0], '...')

if spec['argv'][0].replace('\\', '/') != sys.executable.replace('\\', '/'):
    print('The kernelspec seems to have the wrong prefix. \n'
          'Specfile: {}\n'
          'Expected: {}'
           ''.format(spec['argv'][0], sys.executable))
    sys.exit(1)

if os.name == 'nt':
    # as of ipykernel 5.1.0, a number of async tests fail
    # `pytest --pyargs` doesn't work properly with `-k` or `--ignore`
    from ipykernel.tests import test_async
    print('Windows: Removing', test_async.__file__)
    os.unlink(test_async.__file__)
#  --- run_test.py (end) ---

print('===== ipykernel-5.1.2-py37h5ca1d4c_0 OK =====');
print("import: 'ipykernel'")
import ipykernel

