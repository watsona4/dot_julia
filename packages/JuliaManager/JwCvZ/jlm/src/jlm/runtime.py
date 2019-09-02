import textwrap

from .utils import pathstr


class JuliaRuntime:
    def __init__(self, executable, sysimage):
        self.executable = executable
        self.sysimage = sysimage

    def cmd(self):
        cmd = [pathstr(self.julia)]
        cmd.extend(["--sysimage", pathstr(self.sysimage)])
        return cmd

    def summary(self):
        summary = """
        Executable  : {self.executable}
        System image: {self.sysimage}
        """
        return textwrap.dedent(summary.format(self=self)).strip()

    def resolve(self, app):
        if not self.sysimage:
            self.sysimage = app.sysimage_for(self.executable)
        return self
