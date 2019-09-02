from distutils.core import setup
from distutils.command.install import INSTALL_SCHEMES
import distutils.cmd
import platform,sys
import os,os.path
import subprocess
import ctypes

class InstallationError(Exception): pass

major,minor,_,_,_ = sys.version_info
if major != 2 or minor < 5:
    print "Python 2.5+ required, got %d.%d" % (major,minor)

instdir = os.path.abspath(os.path.join(__file__,'..'))
mosekinstdir = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','..','bin'))

if platform.system() == 'Darwin':
    liblist = [ 'libmosek64.8.0.dylib', 'libiomp5.dylib', 'libmosekxx8_0.dylib','libmosekscopt8_0.dylib' ]
elif platform.system() == 'Linux':
    if ctypes.sizeof(ctypes.c_void_p) == 8:
        liblist = [ 'libmosek64.so.8.0', 'libiomp5.so', 'libmosekxx8_0.so','libmosekscopt8_0.so']
    else:
        liblist = [ 'libmosek.so.8.0', 'libiomp5.so', 'libmosekxx8_0.so','libmosekscopt8_0.so']
elif platform.system() == 'Windows':
    if ctypes.sizeof(ctypes.c_void_p) == 8:
        liblist = [ 'mosek64_8_0.dll', 'mosekxx8_0.dll', 'libiomp5md.dll','mosekscopt8_0.dll'  ]
    else:
        liblist = [ 'mosek8_0.dll', 'mosekxx8_0.dll', 'libiomp5md.dll','mosekscopt8_0.dll' ]
else:
    raise InstallationError("Unsupported system")

# hack so data files are copied to the module directory
for k in INSTALL_SCHEMES.keys():
  INSTALL_SCHEMES[k]['data'] = INSTALL_SCHEMES[k]['purelib']

os.chdir(os.path.abspath(os.path.dirname(__file__)))

def _post_install(sitedir):
    mskdir = os.path.join(sitedir,'mosek')
    with open(os.path.join(mskdir,'mosekorigin.py'),'wt') as f:
        f.write('__mosekinstpath__ = {0}\n'.format(repr(mosekinstdir)))

class install(distutils.command.install.install):
    def run(self):
        distutils.command.install.install.run(self)
        self.execute(_post_install,
                     (self.install_lib,),
                     msg="Fixing library paths")

setup( name             = 'Mosek',
       cmdclass         = { 'install' : install },
       version          = '8.1.81',
       description      = 'Mosek/Python APIs',
       long_description = 'Interface for MOSEK',
       author           = 'Mosek ApS',
       author_email     = "support@mosek.com",
       license          = "See license.pdf in the MOSEK distribution",
       url              = 'http://www.mosek.com',
       packages         = [ 'mosek', 'mosek.fusion','mosek.fusion.impl' ],
       )

