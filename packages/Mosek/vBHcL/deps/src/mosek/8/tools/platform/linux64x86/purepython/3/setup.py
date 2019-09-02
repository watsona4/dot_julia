from distutils.core import setup
import distutils.command.install
import platform,sys
import os,os.path
import subprocess
import ctypes

class InstallationError(Exception): pass

major,minor,_,_,_ = sys.version_info
if major != 3:
    print ("Python 3.0+ required, got %d.%d" % (major,minor))

instdir = os.path.abspath(os.path.join(__file__,'..'))
mosekinstdir = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','..','bin'))

if platform.system() == 'Darwin':
    liblist = [ 'libmosek64.8.1.dylib', 'libiomp5.dylib', 'libmosekxx8_1.dylib','libmosekscopt8_1.dylib' ]
elif platform.system() == 'Linux':
    if ctypes.sizeof(ctypes.c_void_p) == 8:
        liblist = [ 'libmosek64.so.8.1', 'libiomp5.so', 'libmosekxx8_1.so','libmosekscopt8_1.so']
    else:
        liblist = [ 'libmosek.so.8.1', 'libiomp5.so', 'libmosekxx8_1.so','libmosekscopt8_1.so']
elif platform.system() == 'Windows':
    if ctypes.sizeof(ctypes.c_void_p) == 8:
        liblist = [ 'mosek64_8_1.dll', 'mosekxx8_1.dll', 'libiomp5md.dll','mosekscopt8_1.dll'  ]
    else:
        liblist = [ 'mosek8_1.dll', 'mosekxx8_1.dll', 'libiomp5md.dll','mosekscopt8_1.dll' ]
else:
    raise InstallationError("Unsupported system")


os.chdir(os.path.abspath(os.path.dirname(__file__)))

def _post_install(sitedir):
    mskdir = os.path.join(sitedir,'mosek')
    with open(os.path.join(mskdir,'mosekorigin.py'),'wt',encoding='ascii') as f:
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



