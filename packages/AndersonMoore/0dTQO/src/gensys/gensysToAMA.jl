#function [G1,CC,impact,fmat,fwt,ywt,gev,eu]=


    function gensysToAMA(g0, g1, cc, psi, pi, div, varargin = "" )
        # function [G1,CC,impact,fmat,fwt,ywt,gev,eu]=gensysToAMA(g0,g1,cc,psi,pi,div,
        # optionalArg)
        # gensys interface to both gensys and the Anderson-Moore algorithm.
        # Just as with gensys, system given as
        #        g0*y(t)=g1*y(t-1)+c+psi*z(t)+pi*eta(t),
        # with z an exogenous variable process and eta being endogenously determined
        # one-step-ahead expectational errors.  Returned system is
        #       y(t)=G1*y(t-1)+C+impact*z(t)+ywt*inv(I-fmat*inv(L))*fwt*z(t+1) .
        # If z(t) is i.i.d., the last term drops out.
        # If div is omitted from argument list, a div>1 is calculated.
        # eu(1)=1 for existence, eu(2)=1 for uniqueness.  eu(1)=-1 for
        # existence only with not-s.c. z; eu=[-2,-2] for coincident zeros.
        # By Christopher A. Sims
        # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        # when called with no optional args,
        #        program first tries to find gensys on the matlab path
        #        if that fails, the program runs gensys2007 in the gensysToAMA directory
        #
        # an optional string argument may follow the original gensys arguments
        # 'gensys'   run gensys
        #        program first tries to find gensys on the matlab path
        #        if that fails, the program runs gensys2007 in the gensysToAMA directory
        #
        # 'gensys2007'   run gensys
        #        the program runs gensys2007 in the gensysToAMA directory
        #
        # 'ama'    run the anderson-moore algorithm with gensys inputs and outputs
        #
        # 'both'    run the anderson-moore algorithm and the gensys program
        #        verify that solutions are equivalent print out execution times
        #        


        reps = 5 #for timing tests average

        G1     = nothing #'not set';
        CC     = nothing #'not set';
        impact = nothing #'not set';
        fmat   = nothing #'not set';
        fwt    = nothing #'not set';
        ywt    = nothing #'not set';
        gev    = nothing #'not set';
        eu     = nothing #'not set';
        div    = 1.0

        if varargin == ""  #assume calling as though original gensys

            try
                println("gensysToAMA: trying gensys on your matlab path")
                (G1, CC, impact, fmat, fwt, ywt, gev, eu) = gensys(g0, g1, cc, psi, pi, div)
                sss = run(`which gensys`) # which('gensys')
                println("used gensys located at:  $sss")
            catch
                println("gensysToAMA:  that failed, using gensys2007 in gensysToAMA dir")
                (G1, CC, impact, fmat, fwt, ywt, gev, eu) = gensys2007(g0, g1, cc, psi, pi, div)
                sss = run(`which gensys`) # which('gensys2007')
                println("used gensys2007 located at:  $sss")
            end

	elseif varargin == "ama"

            println("gensysToAMA:running ama")
            println("gensysToAMA:converting gensys inputs to ama format")
            (theHM, theH0, theHP) = convertFromGensysIn(g0, g1, pi)
            condn  = 1.e-10     #AndersonMooreAlg uses this in zero tests
            uprbnd = 1 + 1.e-6  #allow unit roots
            # theH = [theHM, theH0, theHP]
            theH = hcat(theHM, theH0, theHP)
            neq = size(theHM, 1)
            println("gensysToAMA:running ama")
            (bb, rts, ia, nexact, nnumeric, lgroots, aimcode) =
                AndersonMooreAlg(theH, neq, 1, 1, condn, uprbnd)
            eu = setEu(aimcode)
            
            if aimcode == 1
                
                #    scof = SPObstruct(theH,bb,neq,1,1);not needed for generating sims output
                phi  = inv(theH0 + theHP * bb) #inv
                theF = -phi * theHP
                ncpi = size(pi, 2)
                println("gensysToAMA:converting ama output to gensys format")
                (CC, G1, impact, ywt, fmat, fwt) =
                    convertToGensysOut(bb, phi, theF, cc, g0, g1, psi, ncpi)
            else
                println("no unique solution: not bothering to try and convert to gensys output")
            end

            println("gensysToAMA:done")
	    
#####
#####  Implement below
#####
#============================================================
        elseif varargin == "gensys" #assume calling as though original gensys but with a trailing optional arg
            #arg1=varargin{1}
            #switch arg1
            #case 'gensys'

            println("gensysToAMA:running gensys")
            
            try
                println("gensysToAMA: trying gensys on your matlab path")
                (G1, CC, impact, fmat, fwt, ywt, gev, eu) = gensys(g0, g1, cc, psi, pi, div)
                sss = run(`which gensys`)  # which('gensys')
                println("used gensys located at:  $sss")
            catch
                println("gensysToAMA:  that failed, using gensys2007 in gensysToAMA dir")
                (G1, CC, impact, fmat, fwt, ywt, gev, eu) = gensys2007(g0, g1, cc, psi, pi, div)
                sss = run(`which gensys`) # which('gensys2007')
                println("used gensys2007 located at:  $sss")
                println("gensysToAMA:done")
            end

        elseif varargin == "gensys2007" # case 'gensys2007'
            
            println("gensysToAMA:running gensys2007")
            (G1, CC, impact, fmat, fwt, ywt, gev, eu) = gensys2007(g0, g1, cc, psi, pi, div)
            sss = run(`which gensys2007`) # which('gensys2007')
            println("used gensys2007 located at:  $sss")
            println("gensysToAMA:done")

        elseif varargin == "both"
            println("gensysToAMA:running both ama and gensys for comparison")
            parg1 = size(g0,1)
            parg2 = size(g0,2)
            parg3 = size(psi,1)
            parg4 = size(psi,2)
            parg5 = size(pi,1)
            parg6 = size(pi,2)
            println("problem dimensions: g0:$parg1 x $parg2, psi:$parg3 x $parg4, pi:$parg5 x $parg6")
            println("gensysToAMA: doing  $reps reps for timing averages")
            println("gensysToAMA:running gensys")
            
            try
                println("gensysToAMA: trying gensys on your matlab path")
                (sG1, sCC, simpact, sfmat, sfwt, sywt, sgev, eu) = gensys(g0, g1, cc, psi, pi, div)
                sss = run(`which gensys`) # which('gensys')
                println("used gensys located at:  $sss")
            catch
                println("gensysToAMA: that failed, using gensys2007 in gensysToAMA dir")
                (sG1, sCC, simpact, sfmat, sfwt, sywt, sgev, eu) = gensys2007(g0, g1, cc, psi, pi, div)
                sss = run(`which gensys2007`) # which('gensys2007')
                println("used gensys2007 located at:  $sss")
            end

            gensysDone=0
            for ii = 1:reps
                
                gensysStart=cputime
                try
                    (sG1, sCC, simpact, sfmat, sfwt, sywt, sgev, eu) = gensys(g0, g1, cc, psi, pi, div)
                catch
                    (sG1, sCC, simpact, sfmat, sfwt, sywt, sgev, eu) = gensys2007(g0, g1, cc, psi, pi, div)
                end
                
                gensysDone = gensysDone + (cputime - gensysStart)
            end
            
            gensysDone = gensysDone / reps
            println("gensysToAMA:running ama")
            convertToStart = cputime
            (theHM, theH0, theHP) = convertFromGensysIn(g0, g1, pi)
            theH = (theHM, theH0, theHP)
            condn  = 1.e-10 #AndersonMooreAlg uses this in zero tests
            uprbnd = 1 + 1.e-6 #allow unit roots
            neq = size(theHM, 1)
            convertToDone =cputime - convertToStart
            (bb, rts, ia, nexact, nnumeric, lgroots, aimcode) =
                SPAmalg(theH,neq,1,1,condn,uprbnd);
            AMADone=0
            
            for ii = 1:reps
                AMAStart=cputime
                (bb, rts, ia, nexact, nnumeric, lgroots, aimcode) =
                    SPAmalg(theH,neq,1,1,condn,uprbnd)
                #    scof = SPObstruct(theH,bb,neq,1,1);#not needed for generating sims output
                #phi=inv(theH0+theHP*sparse(bb));
                AMADone = AMADone + (cputime - AMAStart)
            end
            
            AMADone = AMADone / reps

            if aimcode == 1
                #NAStart=cputime;
                #[qq,bb,info,sinv]=numericAim(1,theH);
                #NADone=cputime-NAStart;

                AMAFStart = cputime
                theF = -((theH0 + theHP * sparse(bb)) \ theHP)
                AMAFDone = cputime - AMAFStart
                println("gensysToAMA:converting ama output to gensys format");
                AMAConvertStart = cputime
                x=1
                eu = setEu(x)
                phi = inv(theH0 + theHP * sparse(bb))
                #note only need column dimension of pi for conversion
                ncpi =size(pi, 2)
                (CC, G1, impact, ywt, fmat, fwt) =
                    convertToGensysOut(bb,phi,theF,cc,g0,g1,psi,ncpi)
                AMAConvertDone = cputime - AMAConvertStart
            else
                println("no unique solution: not bothering to try and convert to gensys output")
            end
            println("gensysToAMA:runs complete")
            #[newvv,newfmat,newNz]=smallF(sfmat);
            
            if aimcode == 1
                try
                    theDiffs=
                        [norm(real(sG1) -G1), norm(real(sCC) - CC), norm(real(simpact) - impact),
                         simMats(sfmat,fmat),
                         norm(real(sywt * sfwt) -ywt * fwt), norm(real(sywt * sfmat * sfwt) -ywt * fmat * fwt)]
                catch
                    println("detected a difference in sims and AMA results")
                    #println(sprintf('dims of matrices, G1''s , C''s. impact''s, fmat''s, ywt''s, fwt''s'))


                    [size(sG1) size(G1);size(sCC) size(CC);
                     size(simpact) size(impact);size(sfmat) size(fmat);
                     size(sywt) size(ywt);size(sfwt) size(fwt)]
                end
                
                if(any(theDiffs > 1e-7))
                    println("detected a difference in sims and AMA results")
                    theDiffs
                else
                    println("no difference in sims and AMA results")
                end

                println("gensysToAMA: after one primer run and   $reps reps")
                print("AMATime=$AMADone  AMAFTime=$AMAFDone  \n convertToTime=$convertToDone convertFromTime=$AMAConvertDone  \n genSysTime=$gensysDone \n")

            else
                println("did not compute conversion, no comparisons to gensys output")
                println("AMATime=$AMADone   genSysTime=$gensysDone")
            end
#####
##### Implement above
#####
==============================================================#

	else
	    println("gensysToAMA:unknown optional string")
	end
        

        return G1,CC,impact,fmat,fwt,ywt,gev,eu
    end
