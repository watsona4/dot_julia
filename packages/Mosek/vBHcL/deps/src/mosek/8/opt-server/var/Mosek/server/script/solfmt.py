import mosek
import urllib.parse


class UnknownFormat(Exception):
    pass

def formatSolution(task,fmt,fname):
    if fmt == 'ascii':
        with open(fname,'wt',encoding='ascii') as f:
            asciiSolution(task,f)
    else:
        raise UnknownFormat(fmt)





def asciiSolution(t,f):
    numvar = t.getnumvar()
    numcon = t.getnumcon()
    numbarvar = t.getnumbarvar()

    sol = mosek.soltype.bas
    if t.solutiondef(sol):# sol bas
        xx  = [0]*numvar
        slx = [0]*numvar
        sux = [0]*numvar
        xc  = [0]*numcon
        slc = [0]*numcon
        suc = [0]*numcon
        y   = [0]*numcon
        skx = [None]*numvar
        skc = [None]*numcon

        t.getxx(sol,xx)
        t.getslx(sol,slx)
        t.getsux(sol,sux)
        t.getskx(sol,skx)
        t.getxc(sol,xc)
        t.getslc(sol,slc)
        t.getsuc(sol,suc)
        t.gety(sol,y)
        t.getskc(sol,skc)

        f.write("Solution:%s solsta:%s prosta:%s\n" % (repr(sol),repr(t.getsolsta(sol)),repr(t.getprosta(sol))))

        f.write("\tVariables\n")
        f.write("\t\t# %-6s %-15s %6s %24s %24s %24s\n" % ("item",'name','sta','xx','slx','sux'))
        for j in range(numvar):
            f.write('\t\tvar%04d: %-15s %6s %24.16e %24.16e %24.16e\n' % (j,urllib.parse.quote(t.getvarname(j)),repr(skx[j]),xx[j],slx[j],sux[j]))

        f.write("\tConstraints\n")
        f.write("\t\t# %-6s %-15s %6s %24s %24s %24s %24s\n" % ("item",'name','sta','xc','slc','suc','y'))
        for i in range(numcon):
            f.write('\t\tcon%04d: %-15s %6s %24.16e %24.16e %24.16e %24.16e\n' % (i,urllib.parse.quote(t.getconname(i)),repr(skc[i]),xc[i],slc[i],suc[i],y[i]))

    sol = mosek.soltype.itr
    if t.solutiondef(sol):
        xx  = [0]*numvar
        slx = [0]*numvar
        sux = [0]*numvar
        snx = [0]*numvar
        xc  = [0]*numcon
        slc = [0]*numcon
        suc = [0]*numcon
        y   = [0]*numcon
        skx = [None]*numvar
        skc = [None]*numcon

        t.getxx(sol,xx)
        t.getslx(sol,slx)
        t.getsux(sol,sux)
        t.getsnx(sol,snx)
        t.getskx(sol,skx)
        t.getxc(sol,xc)
        t.getslc(sol,slc)
        t.getsuc(sol,suc)
        t.gety(sol,y)
        t.getskc(sol,skc)

        f.write("Solution:%s solsta:%s prosta:%s\n" % (repr(sol),repr(t.getsolsta(sol)),repr(t.getprosta(sol))))

        f.write("\tVariables\n")
        f.write("\t\t# %-6s %-15s %6s %24s %24s %24s %24s\n" % ("item",'name','sta','xx','slx','sux','snx'))
        for j in range(numvar):
            f.write('\t\tvar%04d: %-15s %6s %24.16e %24.16e %24.16e %24.16e\n' % (j,repr(urllib.parse.quote(t.getvarname(j))),repr(skx[j]),xx[j],slx[j],sux[j],snx[j]))

        if numbarvar > 0:
            f.write("\tBarVariables\n")
            f.write("\t\t#item name status xx slx sux snx\n")
            for j in range(numbarvar):
                        
                dim = t.getdimbarvarj(j)
                barxj = [0]*(dim*(dim+1)//2)
                barsj = [0]*(dim*(dim+1)//2)

                f.write("\t\tbarvar%04d(%d): %s\n" % (j,dim,repr(urllib.parse.quote(t.getbarvarname(j)))))
                f.write("\t\t\t#%-10s %24s %24s\n" % ('index','barx','bars'))

                i = 0
                for jj in range(dim):
                    for ii in range(jj,dim):
                        idx = '[%d,%d]'% (ii,jj)
                        f.write('\t\t\t%-11s %24.16e %24.16e\n' % (idx,barxj[i],barsj[i]))
                        i += 1

        f.write("\tConstraints\n")
        f.write("\t\t# %-6s %-15s %6s %24s %24s %24s %24s\n" % ("item",'name','sta','xc','slc','suc','y'))
        for i in range(numcon):
            f.write('\t\tcon%04d: %-15s %6s %24.16e %24.16e %24.16e %24.16e\n' % (i,repr(urllib.parse.quote(t.getconname(i))),repr(skc[i]),xc[i],slc[i],suc[i],y[i]))

    sol = mosek.soltype.itg
    if t.solutiondef(sol):
        xx  = [0]*numvar
        xc  = [0]*numcon
        skx = [None]*numvar
        skc = [None]*numcon

        t.getxx(sol,xx)
        t.getskx(sol,skx)
        t.getxc(sol,xc)
        t.getskc(sol,skc)

        f.write("Solution:%s solsta:%s prosta:%s\n" % (repr(sol),repr(t.getsolsta(sol)),repr(t.getprosta(sol))))

        f.write("\tVariables\n")
        f.write("\t\t# %-6s %-15s %6s %24s\n" % ("item",'name','sta','xx'))
        f.write("\t\t#item name status xx\n")
        for j in range(numvar):
            f.write('\t\tvar%04d: %-15s %6s %24.16e\n' % (j,repr(urllib.parse.quote(t.getvarname(j))),repr(skx[j]),xx[j]))

        if numbarvar > 0:
            f.write("\tBarVariables\n")
            f.write("\t\t#item name status xx slx sux snx\n")
            for j in range(numbarvar):
                dim = t.getdimbarvarj(j)
                barxj = [0]*(dim*(dim+1)//2)

                f.write("\t\tbarvar%04d(%d): %s\n" % (j,dim,repr(urllib.parse.quote(t.getbarvarname(j)))))
                f.write("\t\t\t#%-10s %24s\n" % ('index','barx'))


                i = 0
                for jj in range(dim):
                    for ii in range(jj,dim):
                        idx = '[%d,%d]'% (ii,jj)
                        f.write('\t\t\t%-11s %24.16e\n' % (idx,barxj[i]))
                        i += 1

        f.write("\tConstraints\n")
        f.write("\t\t# %-6s %-15s %6s %24s\n" % ("item",'name','sta','xc'))
        f.write("\t\t#item name status xc\n")
        for i in range(numcon):
            f.write('\t\tcon%04d: %-15s %ss %24.16e\n' % (i,repr(urllib.parse.quote(t.getconname(i))),repr(skc[i]),xc[i]))

if __name__ == '__main__':
    import sys
    with mosek.Env() as e:
        with mosek.Task(e) as t:
            t.readdata(sys.argv[1])
            t.optimize()
            asciiSolution(t,sys.stdout)
            sys.stdout.flush()
