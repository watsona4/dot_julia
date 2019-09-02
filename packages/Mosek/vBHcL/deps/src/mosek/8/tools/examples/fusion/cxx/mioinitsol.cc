//
//    Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
//
//    File:    mioinitsol.cc
//
//    Purpose:  Demonstrates how to solve a small mixed
//              integer linear optimization problem
//              providing an initial feasible solution.
//
#include <memory>
#include <iostream>


#include "fusion.h"

using namespace mosek::fusion;
using namespace monty;

int main(int argc, char ** argv)
{

  auto c  = new_array_ptr<double, 1>({7.0, 10.0, 1.0, 5.0});

  Model::t M = new Model("lo1"); auto _M = finally([&]() { M->dispose(); });

  M->setLogHandler([ = ](const std::string & msg) { std::cout << msg << std::flush; } );

  int n = c->size();

  auto x = M->variable("x", n, Domain::integral(Domain::greaterThan(0.0)));

  M->constraint( Expr::sum(x), Domain::lessThan(2.5));

  M->setSolverParam("mioMaxTime", 60.0);
  M->setSolverParam("mioTolRelGap", 1e-4);
  M->setSolverParam("mioTolAbsGap", 0.0);

  M->objective("obj", ObjectiveSense::Maximize, Expr::dot(c, x));

  auto init_sol = new_array_ptr<double, 1>({ 0.0, 2.0, 0.0, 0.0 });
  x->setLevel( init_sol );

  M->solve();

  auto ss = M->getPrimalSolutionStatus();
  std::cout << ss << std::endl;
  auto sol = x->level();
  std::cout << "x = ";

  for (auto s : *sol)
    std::cout << s << ", ";

  std::cout << "\nMIP rel gap = " << M->getSolverDoubleInfo("mioObjRelGap") << "(" << M->getSolverDoubleInfo("mioObjAbsGap") << ")\n";
}