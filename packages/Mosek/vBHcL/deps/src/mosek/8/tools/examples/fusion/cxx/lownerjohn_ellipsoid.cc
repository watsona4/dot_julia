/*
  Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.

  File:      lownerjohn_ellipsoid.cc

  Purpose:
  Computes the Lowner-John inner and outer ellipsoidal
  approximations of a polytope.

  References:
    [1] "Lectures on Modern Optimization", Ben-Tal and Nemirovski, 2000.
    [2] "MOSEK modeling manual", 2013
*/

#include <string>
#include <iostream>
#include <iomanip>
#include <cmath>
#include "fusion.h"
#include <cassert>

using namespace mosek::fusion;
using namespace monty;

std::shared_ptr<ndarray<int, 1>> range (int start, int stop)
{
  if (start < stop)
    return std::shared_ptr<ndarray<int, 1>>(new ndarray<int, 1>(shape_t<1>(stop - start), iterable(range_t<int>(start, stop))));
  else
    return new_array_ptr<int, 1>(0);
}


int pow2(int n) { return (int) (1 << n); }
/**
Models the convex set

  S = { (x, t) \in R^n x R | x >= 0, t <= (x1 * x2 * ... * xn)^(1/n) }

as  the intersection of rotated quadratic cones and affine hyperplanes.
see [1, p. 105] or [2, p. 21].  This set can be interpreted as the hypograph of the
geometric mean of x.

We illustrate the modeling procedure using the following example.
Suppose we have

   t <= (x1 * x2 * x3)^(1/3)

for some t >= 0, x >= 0. We rewrite it as

   t^4 <= x1 * x2 * x3 * x4,   x4 = t

which is equivalent to (see [1])

   x11^2 <= 2*x1*x2,   x12^2 <= 2*x3*x4,

   x21^2 <= 2*x11*x12,

   sqrt(8)*x21 = t, x4 = t.
*/
void geometric_mean(Model::t M, Variable::t x, Variable::t t)
{
  int n = (int) x->size();
  int l = (int)std::ceil(std::log(n) / std::log(2));
  int m = pow2(l) - n;

  Variable::t x0 =
    m == 0 ? x : Var::vstack(x, M->variable(m, Domain::greaterThan(0.0)));

  Variable::t z = x0;

  for (int i = 0; i < l - 1; ++i)
  {
    Variable::t xi = M->variable(pow2(l - i - 1), Domain::greaterThan(0.0));
    for (int k = 0; k < pow2(l - i - 1); ++k)
      M->constraint(Var::vstack(z->index(2 * k), z->index(2 * k + 1), xi->index(k)),
                    Domain::inRotatedQCone());
    z = xi;
  }

  Variable::t t0 = M->variable(1, Domain::greaterThan(0.0));
  M->constraint(Var::vstack(z, t0), Domain::inRotatedQCone());

  M->constraint(Expr::sub(Expr::mul(std::pow(2, 0.5 * l), t), t0), Domain::equalsTo(0.0));

  for (int i = pow2(l - m); i < pow2(l); ++i)
    M->constraint(Expr::sub(x0->index(i), t), Domain::equalsTo(0.0));
}

/**
 Purpose: Models the hypograph of the n-th power of the
 determinant of a positive definite matrix. See [1,2] for more details.

   The convex set (a hypograph)

   C = { (X, t) \in S^n_+ x R |  t <= det(X)^{1/n} },

   can be modeled as the intersection of a semidefinite cone

   [ X, Z; Z^T Diag(Z) ] >= 0

   and a number of rotated quadratic cones and affine hyperplanes,

   t <= (Z11*Z22*...*Znn)^{1/n}  (see geometric_mean).
*/
void det_rootn(Model::t M, int n, Variable::t X, Variable::t t)
{
  // Setup variables
  Variable::t Y = M->variable(Domain::inPSDCone(2 * n));

  // Setup Y = [X, Z; Z^T diag(Z)]
  Variable::t Y11 = Y->slice(new_array_ptr<int, 1>({0, 0}), new_array_ptr<int, 1>({n, n}));
  Variable::t Y21 = Y->slice(new_array_ptr<int, 1>({n, 0}), new_array_ptr<int, 1>({2 * n, n}));
  Variable::t Y22 = Y->slice(new_array_ptr<int, 1>({n, n}), new_array_ptr<int, 1>({2 * n, 2 * n}));

  M->constraint( Expr::sub(Y21->diag(), Y22->diag()), Domain::equalsTo(0.0) );
  M->constraint( Expr::sub(X, Y11), Domain::equalsTo(0.0) );

  // t^n <= (Z11*Z22*...*Znn)
  geometric_mean(M, Y22->diag(), t);
}

/**
  The inner ellipsoidal approximation to a polytope

     S = { x \in R^n | Ax < b }.

  maximizes the volume of the inscribed ellipsoid,

     { x | x = C*u + d, || u ||_2 <= 1 }.

  The volume is proportional to det(C)^(1/n), so the
  problem can be solved as

    maximize         t
    subject to       t       <= det(C)^(1/n)
                || C*ai ||_2 <= bi - ai^T * d,  i=1,...,m
                C is PSD

  which is equivalent to a mixed conic quadratic and semidefinite
  programming problem.
*/
std::pair<std::shared_ptr<ndarray<double, 1>>, std::shared_ptr<ndarray<double, 1>>>
    lownerjohn_inner
    ( std::shared_ptr<ndarray<double, 2>> A,
      std::shared_ptr<ndarray<double, 1>> b)
{
  Model::t M = new Model("lownerjohn_inner"); auto _M = finally([&]() { M->dispose(); });
  int m = A->size(0);
  int n = A->size(1);

  // Setup variables
  Variable::t t = M->variable("t", 1, Domain::greaterThan(0.0));
  Variable::t C = M->variable("C", Domain::inPSDCone(n));
  Variable::t d = M->variable("d", n, Domain::unbounded());

  // quadratic cones
  M->constraint(Expr::hstack(Expr::sub(b, Expr::mul(A, d)), Expr::mul(A, C)),
                Domain::inQCone());

  // t <= det(C)^{1/n}
  //model_utils.det_rootn(M, C, t);
  det_rootn(M, n, C, t);

  // Objective: Maximize t
  M->objective(ObjectiveSense::Maximize, t);
  M->solve();

  return std::make_pair(C->level(), d->level());
}

/**
  The outer ellipsoidal approximation to a polytope given
  as the convex hull of a set of points

    S = conv{ x1, x2, ... , xm }

  minimizes the volume of the enclosing ellipsoid,

    { x | || P*x-c ||_2 <= 1 }

  The volume is proportional to det(P)^{-1/n}, so the problem can
  be solved as

    maximize         t
    subject to       t       <= det(P)^(1/n)
                || P*xi - c ||_2 <= 1,  i=1,...,m
                P is PSD.
*/
std::pair<std::shared_ptr<ndarray<double, 1>>, std::shared_ptr<ndarray<double, 1>>>
    lownerjohn_outer(std::shared_ptr<ndarray<double, 2>> x)
{
  Model::t M = new Model("lownerjohn_outer");
  int m = x->size(0);
  int n = x->size(1);

  // Setup variables
  Variable::t t = M->variable("t", 1, Domain::greaterThan(0.0));
  Variable::t P = M->variable("P", Domain::inPSDCone(n));
  Variable::t c = M->variable("c", n, Domain::unbounded());

  // (1, Px-c) \in Q
  M->constraint(Expr::hstack(
                  Expr::ones(m), Expr::sub(Expr::mul(x, P),
                      Var::reshape(Var::repeat(c, m), new_array_ptr<int, 1>({m, n}))) ),
                Domain::inQCone());

  // t <= det(P)^{1/n}
  //model_utils.det_rootn(M, P, t);
  det_rootn(M, n, P, t);

  // Objective: Maximize t
  M->objective(ObjectiveSense::Maximize, t);
  M->solve();

  return std::make_pair(P->level(), c->level());
}

std::ostream & operator<<(std::ostream & os, ndarray<double, 1> & a)
{
  os << "[ ";
  if (a.size() > 0)
  {
    os << a[0];
    for (int i = 1; i < a.size(); ++i)
      os << "," << a[i];
  }
  os << " ]";
  return os;
}

/******************************************************************************************/
int main(int argc, char ** argv)
{
  //Vertices of a pentagon in 2D
  int n = 6;
  std::shared_ptr<ndarray<double, 2>> p =
  new_array_ptr<double, 2>({ {0., 0.}, {1., 3.}, {5.5, 4.5}, {7., 4.}, {7., 1.}, {3., -2.} });

  //The h-representation of that polygon
  std::shared_ptr<ndarray<double, 2>> A(
                                     new ndarray<double, 2>(shape_t<2>(n, 2), std::function<double(const shape_t<2> &)>(
                                         [&](const shape_t<2> & ij)
  { int i = ij[0], j = ij[1];
    if (j == 0)
      return -((*p)(i, 1)) + (*p)((i - 1 + n) % n, 1);
    else
      return  ((*p)(i, 0)) - (*p)((i - 1 + n) % n, 0);
  })));
  std::shared_ptr<ndarray<double, 1>> b(
                                     new ndarray<double, 1>(n, std::function<double(ptrdiff_t)>( [&](ptrdiff_t i)
  { return (*A)(i, 0) * (*p)(i, 0) + (*A)(i, 1) * (*p)(i, 1); } )));

  auto Cd = lownerjohn_inner(A, b);
  auto Pc = lownerjohn_outer(p);

  std::cout << "Inner:" << std::endl;
  std::cout << "  C = " << *Cd.first << std::endl;
  std::cout << "  d = " << *Cd.second << std::endl;
  std::cout << "Outer:" << std::endl;
  std::cout << "  P = " << *Pc.first << std::endl;
  std::cout << "  c = " << *Pc.second << std::endl;
}