/**
  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.

  File :      production.cc

  Purpose:   Demonstrates how to solve a  linear
             optimization problem using the MOSEK API
             and modify and re-optimize the problem.
*/
#include <iostream>
#include <cmath>

#include "fusion.h"

using namespace mosek::fusion;
using namespace monty;

void printsol(const std::shared_ptr<ndarray<double, 1>> & a) {
  std::cout << "x = ";
  for(auto val : *a) std::cout << val << " ";
  std::cout << "\n";
}

int main() {
  auto c = new_array_ptr<double, 1>({ 1.5, 2.5, 3.0 });
  auto A = new_array_ptr<double, 2>({ {2, 4, 3},
                                      {3, 2, 3},
                                      {2, 3, 2} });
  auto b = new_array_ptr<double, 1>({ 100000.0, 50000.0, 60000.0 });
  int numvar = 3;
  int numcon = 3;

  // Create a model and input data
  Model::t M = new Model(); auto M_ = monty::finally([&]() { M->dispose(); });

  auto x = M->variable(numvar, Domain::greaterThan(0.0));
  auto con = M->constraint(Expr::mul(A, x), Domain::lessThan(b));
  M->objective(ObjectiveSense::Maximize, Expr::dot(c, x));
  // Solve the problem
  M->solve();
  printsol(x->level());

  /***************** Change an entry in the A matrix ********************/
  con->index(0)->add(x->index(0));
  M->solve();
  printsol(x->level());

  /*************** Add a new variable ******************************/
  // Create a variable and a compound view of all variables
  auto x3 = M->variable(Domain::greaterThan(0.0));
  auto xNew = Var::vstack(x, x3);
  // Add to the exising constraint
  con->add(Expr::mul(x3, new_array_ptr<double, 1>({ 4, 0, 1 })));
  // Change the objective to include x3
  M->objective(ObjectiveSense::Maximize, Expr::dot(new_array_ptr<double, 1>({1.5,2.5,3.0,1.0}), xNew));
  M->solve();
  printsol(xNew->level());

  /**************** Add a new constraint *****************************/
  M->constraint(Expr::dot(xNew, new_array_ptr<double, 1>({1, 2, 1, 1})), Domain::lessThan(30000.0));
  M->solve();
  printsol(xNew->level());
}
