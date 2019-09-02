#!/usr/bin/env python3
import sys
import os,os.path
import signal


if __name__ == '__main__':

    workdir = os.path.abspath(sys.argv[1])
    probfile = os.path.abspath(sys.argv[2])

    os.chdir(workdir)

    nopid = False
    try:
        if sys.argv[3] == '-noPID':
            nopid = True
    except:
        pass

    logfile = os.path.join(workdir,"solver.log")
    resfile = os.path.join(workdir,"result.res")
    trmfile = os.path.join(workdir,"result.trm")
    msgfile = os.path.join(workdir,"result.msg")
    pidfile = os.path.join(workdir,"PID")

    donefile = os.path.join(workdir,"done")

    jsolfile = os.path.join(workdir,"solution.jtask")
    tsolfile = os.path.join(workdir,"solution.task")
    asolfile = os.path.join(workdir,"solution.ascii")

    global_stop_optimization = 0

    def sighandler(signum, frame):
        global global_stop_optimization
        if signum == signal.SIGTERM:
            #print("GOT SIGTERM")
            with open(os.path.join(workdir,"term"),'wb') as f: pass
            global_stop_optimization = 1
        elif signum in [signal.SIGSEGV,signal.SIGKILL]: # hmm... can we even do this?!
            with open(donefile,'wt',encoding='ascii') as f:
                f.write('sig %d' % signum)
    def pgscb(*args):
        global global_stop_optimization
        if global_stop_optimization:
            #print("SEND STOP TO SOLVER")
            return 1
        return 0

    signal.signal(signal.SIGTERM,sighandler)

    if not nopid:
        with open(pidfile,'wt',encoding='ascii') as f:
            f.write(str(os.getpid()))

    try:
        try:
            import mosek
        except ImportError as e:
            import traceback
            text = traceback.format_exc()
            with open(logfile,"a",encoding='utf-8',errors="ignore") as f:
                f.write(text)
                f.write('\n')
                f.write(str(e))
        else:
            try:
                import solfmt

                with mosek.Env() as e:
                    with mosek.Task(e) as t:
                        t.readdata(probfile)
                        # Reset all string parameters. This should ensure that no rogue files are written
                        for p in mosek.sparam.members():
                            t.putstrparam(p,"")

                        t.set_Progress(pgscb)
                        t.linkfiletostream(mosek.streamtype.log,logfile,0)
                        trm = t.optimize()

                        t.writetasksolverresult_file(tsolfile)
                        t.writejsonsol(jsolfile)
                        solfmt.formatSolution(t,'ascii',asolfile)

                        with open(resfile,"wt",encoding="ascii") as f: f.write("MSK_RES_OK")
                        with open(trmfile,"wt",encoding="ascii") as f: f.write("MSK_RES_"+repr(trm).upper())
            except mosek.Exception as e:
                with open(resfile,"wt",encoding="ascii") as f:
                    f.write("MSK_RES_"+repr(e.errno).upper())
                with open(msgfile,"wt",encoding="utf-8",errors='ignore') as f:
                    f.write(str(e.msg))
            except Exception as e:
                import traceback
                text = traceback.format_exc()
                with open(logfile,"a",encoding='utf-8',errors="ignore") as f:
                    f.write(text)
                    f.write('\n')
                    f.write(str(e))
    finally:
        with open(donefile,"wt",encoding="ascii") as f:
            f.write("done")
        try: os.remove(pidfile)
        except: pass
