##
# Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
#
# File:      portfolio.py
#
# Purpose:   Presents several portfolio problems.
#
##

from   mosek.fusion import *

# Computes the inner product between two vectors.
def dot(x,y):
    return sum([ xx*yy for xx,yy in zip(x,y) ]) + 0.    

"""
Purpose:
    Computes the optimal portfolio for a given risk 
 
Input:
    n: Number of assets
    mu: An n dimensional vector of expected returns
    GT: A matrix with n columns so (GT')*GT  = covariance matrix
    x0: Initial holdings 
    w: Initial cash holding
    gamma: Maximum risk (=std. dev) accepted
 
Output:
    Optimal expected return and the optimal portfolio     
""" 
def BasicMarkowitz(n,mu,GT,x0,w,gamma):
    
    with  Model("Basic Markowitz") as M:

        # Redirect log output from the solver to stdout for debugging. 
        # if uncommented.
        # M.setLogHandler(sys.stdout) 
        
        # Defines the variables (holdings). Shortselling is not allowed.
        x = M.variable("x", n, Domain.greaterThan(0.0))
        
        #  Maximize expected return
        M.objective('obj', ObjectiveSense.Maximize, Expr.dot(mu,x))
        
        # The amount invested  must be identical to initial wealth
        M.constraint('budget', Expr.sum(x), Domain.equalsTo(w+sum(x0)))
        
        # Imposes a bound on the risk
        M.constraint('risk', Expr.vstack( gamma,Expr.mul(GT,x)), Domain.inQCone())

        # Solves the model.
        M.solve()

        return dot(mu,x.level())

"""
Purpose:
    Computes several portfolios on the optimal portfolios by 

        for alpha in alphas: 
            maximize   expected return - alpha * standard deviation
            subject to the constraints  
    
Input:
    n: Number of assets
    mu: An n dimensional vector of expected returns
    GT: A matrix with n columns so (GT')*GT  = covariance matrix
    x0: Initial holdings 
    w: Initial cash holding
    alphas: List of the alphas
                
Output:
    The efficient frontier as list of tuples (alpha,expected return,risk)
""" 
def EfficientFrontier(n,mu,GT,x0,w,alphas):

    with Model("Efficient frontier") as M:
    
        # M.setLogHandler(sys.stdout) 
 
        # Defines the variables (holdings). Shortselling is not allowed.
        x = M.variable("x", n, Domain.greaterThan(0.0)) # Portfolio variables
        s = M.variable("s", 1, Domain.unbounded()) # Risk variable
        
        M.constraint('budget', Expr.sum(x), Domain.equalsTo(w+sum(x0)))
        
        # Computes the risk
        M.constraint('risk', Expr.vstack(s,Expr.mul(GT,x)),Domain.inQCone())
        
        frontier = []
        
        mudotx = Expr.dot(mu,x)

        for i,alpha in enumerate(alphas):
            
            #  Define objective as a weighted combination of return and risk
            M.objective('obj', ObjectiveSense.Maximize, Expr.sub(mudotx,Expr.mul(alpha,s)))
            
            M.solve()
            
            frontier.append((alpha,dot(mu,x.level()),s.level()[0]))
            
        return frontier

"""
    Description:
        Extends the basic Markowitz model with a market cost term.

    Input:
        n: Number of assets
        mu: An n dimensional vector of expected returns
        GT: A matrix with n columns so (GT')*GT  = covariance matrix
        x0: Initial holdings 
        w: Initial cash holding
        gamma: Maximum risk (=std. dev) accepted
        m: It is assumed that  market impact cost for the j'th asset is
           m_j|x_j-x0_j|^3/2

    Output:
       Optimal expected return and the optimal portfolio     

"""
def MarkowitzWithMarketImpact(n,mu,GT,x0,w,gamma,m):
    """
        Description:
            Extends the basic Markowitz model with a market cost term.

        Input:
            n: Number of assets
            mu: An n dimensional vector of expected returns
            GT: A matrix with n columns so (GT')*GT  = covariance matrix
            x0: Initial holdings 
            w: Initial cash holding
            gamma: Maximum risk (=std. dev) accepted
            m: It is assumed that  market impact cost for the j'th asset is
               m_j|x_j-x0_j|^3/2

        Output:
           Optimal expected return and the optimal portfolio     

    """
            
    with  Model("Markowitz portfolio with market impact") as M:

        #M.setLogHandler(sys.stdout) 
    
        # Defines the variables. No shortselling is allowed.
        x = M.variable("x", n, Domain.greaterThan(0.0))
        
        # Additional "helper" variables 
        t = M.variable("t", n, Domain.unbounded())
        z = M.variable("z", n, Domain.unbounded())   
        v = M.variable("v", n, Domain.unbounded())        

        #  Maximize expected return
        M.objective('obj', ObjectiveSense.Maximize, Expr.dot(mu,x))

        # Invested amount + slippage cost = initial wealth
        M.constraint('budget', Expr.add(Expr.sum(x),Expr.dot(m,t)), Domain.equalsTo(w+sum(x0)))

        # Imposes a bound on the risk
        M.constraint('risk', Expr.vstack(gamma,Expr.mul(GT,x)), Domain.inQCone())

        # z >= |x-x0| 
        M.constraint('buy', Expr.sub(z,Expr.sub(x,x0)),Domain.greaterThan(0.0))
        M.constraint('sell', Expr.sub(z,Expr.sub(x0,x)),Domain.greaterThan(0.0))

        # t >= z^1.5, z >= 0.0. Needs two rotated quadratic cones to model this term
        M.constraint('ta', Expr.hstack(v,t,z),Domain.inRotatedQCone())
        M.constraint('tb', Expr.hstack(z,Expr.constTerm(n,1.0/8.0),v),\
                         Domain.inRotatedQCone())

        M.solve()

        print("\n-----------------------------------------------------------------------------------");
        print('Markowitz portfolio optimization with market impact cost')
        print("-----------------------------------------------------------------------------------\n");
        print('Expected return: %.4e Std. deviation: %.4e Market impact cost: %.4e' % \
              (dot(mu,x.level()),gamma,dot(m,t.level())))

        return (dot(mu,x.level()), x.level())

"""
    Description:
        Extends the basic Markowitz model with a market cost term.

    Input:
        n: Number of assets
        mu: An n dimensional vector of expected returns
        GT: A matrix with n columns so (GT')*GT  = covariance matrix
        x0: Initial holdings 
        w: Initial cash holding
        gamma: Maximum risk (=std. dev) accepted
        f: If asset j is traded then a fixed cost f_j must be paid
        g: If asset j is traded then a cost g_j must be paid for each unit traded

    Output:
       Optimal expected return and the optimal portfolio     

"""
def MarkowitzWithTransactionsCost(n,mu,GT,x0,w,gamma,f,g):
    # Upper bound on the traded amount
    w0 = w+sum(x0)
    u = n*[w0]

    with Model("Markowitz portfolio with transaction costs") as M:
        #M.setLogHandler(sys.stdout)

        # Defines the variables. No shortselling is allowed.
        x = M.variable("x", n, Domain.greaterThan(0.0))

        # Additional "helper" variables 
        z = M.variable("z", n, Domain.unbounded())   
        # Binary variables
        y = M.variable("y", n, Domain.binary())

        #  Maximize expected return
        M.objective('obj', ObjectiveSense.Maximize, Expr.dot(mu,x))

        # Invest amount + transactions costs = initial wealth
        M.constraint('budget', Expr.add([ Expr.sum(x), Expr.dot(f,y),Expr.dot(g,z)] ), Domain.equalsTo(w0))

        # Imposes a bound on the risk
        M.constraint('risk', Expr.vstack( gamma,Expr.mul(GT,x)), Domain.inQCone())

        # z >= |x-x0| 
        M.constraint('buy', Expr.sub(z,Expr.sub(x,x0)),Domain.greaterThan(0.0))
        M.constraint('sell', Expr.sub(z,Expr.sub(x0,x)),Domain.greaterThan(0.0))
        # Alternatively, formulate the two constraints as
        #M.constraint('trade', Expr.hstack(z,Expr.sub(x,x0)), Domain.inQcone())

        # Constraints for turning y off and on. z-diag(u)*y<=0 i.e. z_j <= u_j*y_j
        M.constraint('y_on_off', Expr.sub(z,Expr.mulElm(u,y)), Domain.lessThan(0.0))

        # Integer optimization problems can be very hard to solve so limiting the 
        # maximum amount of time is a valuable safe guard
        M.setSolverParam('mioMaxTime', 180.0) 
        M.solve()

        print("\n-----------------------------------------------------------------------------------");
        print('Markowitz portfolio optimization with transactions cost')
        print("-----------------------------------------------------------------------------------\n");
        print('Expected return: %.4e Std. deviation: %.4e Transactions cost: %.4e' % \
              (dot(mu,x.level()),gamma,dot(f,y.level())+dot(g,z.level())))

        return (dot(mu,x.level()), x.level())

if __name__ == '__main__':    
    """
    The example
    
        python portfolio.py

    solves the portfolio models.
    """

    n      = 3;
    w      = 1.0;   
    mu     = [0.1073,0.0737,0.0627]
    x0     = [0.0,0.0,0.0]
    gammas = [0.035,0.040,0.050,0.060,0.070,0.080,0.090]
    GT     = [
        [ 0.166673333200005, 0.0232190712557243 ,  0.0012599496030238 ],
        [ 0.0              , 0.102863378954911  , -0.00222873156550421],
        [ 0.0              , 0.0                ,  0.0338148677744977 ]
    ]


    print("\n-----------------------------------------------------------------------------------");
    print('Basic Markowitz portfolio optimization')
    print("-----------------------------------------------------------------------------------\n");
    for gamma in gammas:
        er = BasicMarkowitz(n,mu,GT,x0,w,gamma)
        print('Expected return: %.4e Std. deviation: %.4e' % (er,gamma))

    # Some predefined alphas are chosen
    alphas = [0.0, 0.01, 0.1, 0.25, 0.30, 0.35, 0.4, 0.45, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 10.0] 
    frontier= EfficientFrontier(n,mu,GT,x0,w,alphas)
    print("\n-----------------------------------------------------------------------------------");
    print('Efficient frontier') 
    print("-----------------------------------------------------------------------------------\n");
    print('%-12s  %-12s  %-12s' % ('alpha','return','risk')) 
    for i in frontier:
        print('%-12.4f  %-12.4e  %-12.4e' % (i[0],i[1],i[2]))   
                    

    # Somewhat arbitrary choice of m
    m = n*[1.0e-2]
    MarkowitzWithMarketImpact(n,mu,GT,x0,w,gammas[0],m)

    f = n*[0.01]
    g = n*[0.001]
    MarkowitzWithTransactionsCost(n,mu,GT,x0,w,gammas[0],f,g)
