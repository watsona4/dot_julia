import functools
import sys
import warnings


instruction_template = """

Python package "{package}" cannot be imported from Python interpreter
{python}.
{additional_message}
Use your favorite method to install "{need_install}" or run the following
command in Julia (which *tries* to the right thing):

    IPython.install_dependency("{need_install}")

It prints the installation command to be executed and prompts your
input (yes/no) before really executing it.
"""

ipython_dependency_missing = """
IPython (version: {IPython.__version__}) is importable but {dependency}
cannot be imported.  It is very strange and I'm not sure what is the
best instruction here.  Updating IPython could help.
"""


def make_instruction(package, need_install=None, **kwargs):
    return instruction_template.format(**dict(dict(
        package=package,
        need_install=need_install or package.lower(),
        python=sys.executable,
        additional_message='',
    ), **kwargs))


def make_dependency_missing_instruction(IPython, dependency):
    return make_instruction(
        dependency,
        need_install='ipython',
        additional_message=ipython_dependency_missing.format(
            IPython=IPython,
            dependency=dependency,
        ))


def package_name(err):
    try:
        return err.name
    except AttributeError:
        # Python 2 support:
        prefix = 'No module named '
        message = str(err)
        if message.startswith(prefix):
            return message[len(prefix):].rstrip()
    raise ValueError('Cannot determine missing package for error {}'
                     .format(err))


def print_instruction_on_import_error(f):
    @functools.wraps(f)
    def wrapped(*args, **kwargs):
        try:
            return f(*args, **kwargs)
        except ImportError as err:
            name = package_name(err)
            if name in ('IPython', 'julia'):
                print(make_instruction(name))
                return
            if name == 'traitlets':
                try:
                    import IPython
                except ImportError:
                    print(make_instruction('IPython'))
                    return
                print(make_dependency_missing_instruction(IPython, name))
                return
            raise
    return wrapped


segfault_warning = """\
Segmentation fault warning.

You are using IPython version {IPython.__version__} which is known to
cause segmentation fault with tab completion.  For segfault-free
IPython, upgrade to version 7 or above.
Note also that IPython releases after 5.x do not support Python 2.

If you want to upgrade IPython, executing the following command in
Julia may help:

    IPython.install_dependency("ipython")      # or
    IPython.install_dependency("ipython-pre")  # or
    IPython.install_dependency("ipython-dev")

It prints the installation command to be executed and prompts your
input (yes/no) before really executing it.
"""

segfault_warned = False


def maybe_warn_segfault():
    global segfault_warned
    import IPython
    if int(IPython.__version__.split('.', 1)[0]) < 7 and not segfault_warned:
        warnings.warn(segfault_warning.format(**vars()))
        segfault_warned = True


def with_message(func):
    @functools.wraps(func)
    def wrapper(*args, **kwds):
        maybe_warn_segfault()
        return func(*args, **kwds)
    return print_instruction_on_import_error(wrapper)
