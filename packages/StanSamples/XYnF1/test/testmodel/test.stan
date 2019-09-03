data {
  int<lower=0> M1;              // number of groups, dim 1
  int<lower=0> M2;              // number of groups, dim 2
  int<lower=0> N;               // number observations by group
  vector[N] X[M1, M2];          // observations
}
parameters {
  real mu;                      // mean hyperparameter
  real<lower=0> sigma;          // std hyperparameter
  matrix[M1,M2] alpha;          // group means
  real<lower=0> nu;             // inter-group variances
}
model {
  mu ~ normal(0, 10);
  sigma ~ uniform(0, 10);
  for (m1 in 1:M1) {
    alpha[m1, :] ~ normal(mu, sigma);
    for (m2 in 1:M2) {
      X[m1, m2, :] ~ normal(alpha[m1, m2], nu);
    }
  }
}
