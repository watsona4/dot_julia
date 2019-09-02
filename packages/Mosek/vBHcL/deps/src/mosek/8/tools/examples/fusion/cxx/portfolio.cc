/*
  File : portfolio.cc

  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.

  Description :
    Presents several portfolio optimization models.
*/

#include <iostream>
#include <fstream>
#include <iomanip>
#include <string>
#include "monty.h"
#include "fusion.h"

using namespace mosek::fusion;
using namespace monty;

static double sum(std::shared_ptr<ndarray<double, 1>> x)
{
  double r = 0.0;
  for (auto v : *x) r += v;
  return r;
}

static double dot(std::shared_ptr<ndarray<double, 1>> x,
                  std::shared_ptr<ndarray<double, 1>> y)
{
  double r = 0.0;
  for (int i = 0; i < x->size(); ++i) r += (*x)[i] * (*y)[i];
  return r;
}

static double dot(std::shared_ptr<ndarray<double, 1>> x,
                  std::vector<double> & y)
{
  double r = 0.0;
  for (int i = 0; i < x->size(); ++i) r += (*x)[i] * y[i];
  return r;
}

/*
Purpose:
    Computes the optimal portfolio for a given risk

Input:
    n: Number of assets
    mu: An n dimmensional vector of expected returns
    GT: A matrix with n columns so (GT')*GT  = covariance matrix
    x0: Initial holdings
    w: Initial cash holding
    gamma: Maximum risk (=std. dev) accepted

Output:
    Optimal expected return and the optimal portfolio
*/
double BasicMarkowitz
( int                                n,
  std::shared_ptr<ndarray<double, 1>> mu,
  std::shared_ptr<ndarray<double, 2>> GT,
  std::shared_ptr<ndarray<double, 1>> x0,
  double                             w,
  double                             gamma)
{
  Model::t M = new Model("Basic Markowitz"); auto _M = finally([&]() { M->dispose(); });
  // Redirect log output from the solver to stdout for debugging.
  // M->setLogHandler([](const std::string & msg) { std::cout << msg << std::flush; } );

  // Defines the variables (holdings). Shortselling is not allowed.
  Variable::t x = M->variable("x", n, Domain::greaterThan(0.0));

  //  Maximize expected return
  M->objective("obj", ObjectiveSense::Maximize, Expr::dot(mu, x));

  // The amount invested  must be identical to intial wealth
  M->constraint("budget", Expr::sum(x), Domain::equalsTo(w + sum(x0)));

  // Imposes a bound on the risk
  M->constraint("risk", Expr::vstack(gamma, Expr::mul(GT, x)), Domain::inQCone());

  // Solves the model.
  M->solve();

  return dot(mu, x->level());
}

/*
  Purpose:
      Computes several portfolios on the optimal portfolios by

          for alpha in alphas:
              maximize   expected return - alpha * standard deviation
              subject to the constraints

  Input:
      n: Number of assets
      mu: An n dimmensional vector of expected returns
      GT: A matrix with n columns so (GT')*GT  = covariance matrix
      x0: Initial holdings
      w: Initial cash holding
      alphas: List of the alphas

  Output:
      The efficient frontier as list of tuples (alpha,expected return,risk)
 */
void EfficientFrontier
( int n,
  std::shared_ptr<ndarray<double, 1>> mu,
  std::shared_ptr<ndarray<double, 2>> GT,
  std::shared_ptr<ndarray<double, 1>> x0,
  double w,
  std::vector<double> & alphas,
  std::vector<double> & frontier_mux,
  std::vector<double> & frontier_s)
{

  Model::t M = new Model("Efficient frontier");  auto M_ = finally([&]() { M->dispose(); });

  // Defines the variables (holdings). Shortselling is not allowed.
  Variable::t x = M->variable("x", n, Domain::greaterThan(0.0)); // Portfolio variables
  Variable::t s = M->variable("s", 1, Domain::unbounded()); // Risk variable

  M->constraint("budget", Expr::sum(x), Domain::equalsTo(w + sum(x0)));

  // Computes the risk
  M->constraint("risk", Expr::vstack(s, Expr::mul(GT, x)), Domain::inQCone());

  Expression::t mudotx = Expr::dot(mu, x);

  for (double alpha : alphas)
  {
    //  Define objective as a weighted combination of return and risk
    M->objective("obj", ObjectiveSense::Maximize, Expr::sub(mudotx, Expr::mul(alpha, s)));

    M->solve();

    frontier_mux.push_back(dot(mu, x->level()));
    frontier_s.push_back((*s->level())[0]);
  }
}

/*
    Description:
        Extends the basic Markowitz model with a market cost term.

    Input:
        n: Number of assets
        mu: An n dimmensional vector of expected returns
        GT: A matrix with n columns so (GT')*GT  = covariance matrix'
        x0: Initial holdings
        w: Initial cash holding
        gamma: Maximum risk (=std. dev) accepted
        m: It is assumed that  market impact cost for the j'th asset is
           m_j|x_j-x0_j|^3/2

    Output:
       Optimal expected return and the optimal portfolio

*/
void MarkowitzWithMarketImpact
( int n,
  std::shared_ptr<ndarray<double, 1>> mu,
  std::shared_ptr<ndarray<double, 2>> GT,
  std::shared_ptr<ndarray<double, 1>> x0,
  double      w,
  double      gamma,
  std::shared_ptr<ndarray<double, 1>> m,
  std::vector<double> & xsol,
  std::vector<double> & tsol)
{
  Model::t M = new Model("Markowitz portfolio with market impact");  auto M_ = finally([&]() { M->dispose(); });

  // Defines the variables. No shortselling is allowed.
  Variable::t x = M->variable("x", n, Domain::greaterThan(0.0));

  // Addtional "helper" variables
  Variable::t t = M->variable("t", n, Domain::unbounded());
  Variable::t z = M->variable("z", n, Domain::unbounded());
  Variable::t v = M->variable("v", n, Domain::unbounded());

  //  Maximize expected return
  M->objective("obj", ObjectiveSense::Maximize, Expr::dot(mu, x));

  // Invested amount + slippage cost = initial wealth
  M->constraint("budget", Expr::add(Expr::sum(x), Expr::dot(m, t)), Domain::equalsTo(w + sum(x0)));

  // Imposes a bound on the risk
  M->constraint("risk", Expr::vstack( gamma, Expr::mul(GT, x)),
                Domain::inQCone());

  // z >= |x-x0|
  M->constraint("buy",  Expr::sub(z, Expr::sub(x, x0)), Domain::greaterThan(0.0));
  M->constraint("sell", Expr::sub(z, Expr::sub(x0, x)), Domain::greaterThan(0.0));

  // t >= z^1.5, z >= 0.0. Needs two rotated quadratic cones to model this term
  M->constraint("ta", Expr::hstack(v, t, z), Domain::inRotatedQCone());
  M->constraint("tb", Expr::hstack(z, Expr::constTerm(n, 1.0 / 8.0), v),
                Domain::inRotatedQCone());

  M->solve();

  xsol.resize(n);
  tsol.resize(n);
  auto xlvl = x->level();
  auto tlvl = t->level();

  std::copy(xlvl->flat_begin(), xlvl->flat_end(), xsol.begin());
  std::copy(tlvl->flat_begin(), tlvl->flat_end(), tsol.begin());
}

/*
    Description:
        Extends the basic Markowitz model with a market cost term.

    Input:
        n: Number of assets
        mu: An n dimmensional vector of expected returns
        GT: A matrix with n columns so (GT')*GT  = covariance matrix
        x0: Initial holdings
        w: Initial cash holding
        gamma: Maximum risk (=std. dev) accepted
        f: If asset j is traded then a fixed cost f_j must be paid
        g: If asset j is traded then a cost g_j must be paid for each unit traded

    Output:
       Optimal expected return and the optimal portfolio

*/
std::shared_ptr<ndarray<double, 1>> MarkowitzWithTransactionsCost
                                 ( int n,
                                   std::shared_ptr<ndarray<double, 1>> mu,
                                   std::shared_ptr<ndarray<double, 2>> GT,
                                   std::shared_ptr<ndarray<double, 1>> x0,
                                   double                             w,
                                   double                             gamma,
                                   std::shared_ptr<ndarray<double, 1>> f,
                                   std::shared_ptr<ndarray<double, 1>> g)
{
  // Upper bound on the traded amount
  std::shared_ptr<ndarray<double, 1>> u(new ndarray<double, 1>(shape_t<1>(n), w + sum(x0)));

  Model::t M = new Model("Markowitz portfolio with transaction costs");  auto M_ = finally([&]() { M->dispose(); });

  // Defines the variables. No shortselling is allowed.
  Variable::t x = M->variable("x", n, Domain::greaterThan(0.0));

  // Addtional "helper" variables
  Variable::t z = M->variable("z", n, Domain::unbounded());
  // Binary varables
  Variable::t y = M->variable("y", n, Domain::binary());

  //  Maximize expected return
  M->objective("obj", ObjectiveSense::Maximize, Expr::dot(mu, x));

  // Invest amount + transactions costs = initial wealth
  M->constraint("budget", Expr::add(Expr::add(Expr::sum(x), Expr::dot(f, y)), Expr::dot(g, z)),
                Domain::equalsTo(w + sum(x0)));

  // Imposes a bound on the risk
  M->constraint("risk", Expr::vstack( gamma, Expr::mul(GT, x)),
                Domain::inQCone());

  // z >= |x-x0|
  M->constraint("buy", Expr::sub(z, Expr::sub(x, x0)), Domain::greaterThan(0.0));
  M->constraint("sell", Expr::sub(z, Expr::sub(x0, x)), Domain::greaterThan(0.0));
  // Alternatively, formulate the two constraints as
  //M->constraint("trade", Expr::hstack(z,Expr::sub(x,x0)), Domain::inQCone());

  // Consraints for turning y off and on. z-diag(u)*y<=0 i.e. z_j <= u_j*y_j
  M->constraint("y_on_off", Expr::sub(z, Expr::mul(Matrix::diag(u), y)), Domain::lessThan(0.0));

  // Integer optimization problems can be very hard to solve so limiting the
  // maximum amount of time is a valuable safe guard
  M->setSolverParam("mioMaxTime", 180.0);
  M->solve();

  return x->level();
}


/*
  The example reads in data and solves the portfolio models.
 */
int main(int argc, char ** argv)
{

  int        n      = 3;
  double     w      = 1.0;
  auto       mu     = new_array_ptr<double, 1>( {0.1073, 0.0737, 0.0627} );
  auto       x0     = new_array_ptr<double, 1>({0.0, 0.0, 0.0});
  auto       gammas = new_array_ptr<double, 1>({0.035, 0.040, 0.050, 0.060, 0.070, 0.080, 0.090});
  auto       GT     = new_array_ptr<double, 2>({
    { 0.166673333200005, 0.0232190712557243 ,  0.0012599496030238 },
    { 0.0              , 0.102863378954911  , -0.00222873156550421},
    { 0.0              , 0.0                ,  0.0338148677744977 }
  });

  std::cout << std::endl << std::endl
            << "================================" << std::endl
            << "Markowitz portfolio optimization" << std::endl
            << "================================" << std::endl;

  std::cout << std::endl
            << "-----------------------------------------------------------------------------------" << std::endl
            << "Basic Markowitz portfolio optimization" << std::endl
            << "-----------------------------------------------------------------------------------" << std::endl;

  std::cout << std::setprecision(4)
            << std::setiosflags(std::ios::scientific);

  for (auto gamma : *gammas)
    std::cout << "Expected return: " << BasicMarkowitz( n, mu, GT, x0, w, gamma) << " St deviation: " << gamma << std::endl;


  {
    // Some predefined alphas are chosen
    std::vector<double> alphas{ 0.0, 0.01, 0.1, 0.25, 0.30, 0.35, 0.4, 0.45, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 10.0 };
    std::vector<double> frontier_mux;
    std::vector<double> frontier_s;

    EfficientFrontier(n, mu, GT, x0, w, alphas, frontier_mux, frontier_s);
    std::cout << "\n-----------------------------------------------------------------------------------"
              << "Efficient frontier" << std::endl
              << "-----------------------------------------------------------------------------------" << std::endl
              << std::endl;
    std::cout << std::setw(12) << "alpha" << std::setw(12) << "return" << std::setw(12) << "risk" << std::endl;
    for (int i = 0; i < frontier_mux.size(); ++i)
      std::cout << std::setw(12) << alphas[i] << std::setw(12) << frontier_mux[i] << std::setw(12) << frontier_s[i] << std::endl;
  }

  {
    // Somewhat arbirtrary choice of m
    std::shared_ptr<ndarray<double, 1>> m(new ndarray<double, 1>(shape_t<1>(n), 1.0e-2));
    std::vector<double> x;
    std::vector<double> t;

    MarkowitzWithMarketImpact(n, mu, GT, x0, w, (*gammas)[0], m, x, t);

    std::cout << std::resetiosflags(std::ios::left);
    std::cout << std::endl
              << "-----------------------------------------------------------------------------------" << std::endl
              << "Markowitz portfolio optimization with market impact cost" << std::endl
              << "-----------------------------------------------------------------------------------" << std::endl
              << std::endl
              << "Expected return: " << dot(mu, x) << " St deviation: " << (*gammas)[0] << " Market impact cost: " << dot(m, t) << std::endl;
  }

  {
    std::shared_ptr<ndarray<double, 1>> f(new ndarray<double, 1>(shape_t<1>(n), 0.01));
    std::shared_ptr<ndarray<double, 1>> g(new ndarray<double, 1>(shape_t<1>(n), 0.001));
    std::cout << std::endl
              << "-----------------------------------------------------------------------------------" << std::endl
              << "Markowitz portfolio optimization with transaction cost" << std::endl
              << "-----------------------------------------------------------------------------------" << std::endl
              << std::endl;

    auto x = MarkowitzWithTransactionsCost(n, mu, GT, x0, w, (*gammas)[0], f, g);
    std::cout << "Optimal portfolio:" << std::endl;
    for ( int i = 0; i < x->size(); ++i)
      std::cout << "\tx[" << std::setw(2) << i << "]  " << std::setw(12) << (*x)[i] << std::endl;
  }
}