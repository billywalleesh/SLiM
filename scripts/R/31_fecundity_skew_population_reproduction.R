set.seed(1)   # same random numbers every time you run it

N <- 1000          # individuals in the population (K)
R <- 1.01          # mean offspring per individual

# New reproduction (v1.5): the population first produces its offspring,
# about R x N of them, no matter how skewed fecundity is. Then each
# offspring gets a first parent, chosen in proportion to fecundity, and a
# mate, chosen in proportion to fecundity too (skewMatingSuccess = T).


fecundity_skew0   <- rep(1, N)
fecundity_skew0.5 <- exp(rnorm(N, mean = -0.5^2 / 2, sd = 0.5))
fecundity_skew1   <- exp(rnorm(N, mean = -1.0^2 / 2, sd = 1.0))
fecundity_skew1.5 <- exp(rnorm(N, mean = -1.5^2 / 2, sd = 1.5))

births <- rpois(1, R * N)   # one number for the whole population
births                      # about 1010, the same for every skew


# no skew
first_parent <- sample(1:N, births, replace = TRUE, prob = fecundity_skew0)
mate <- sample(1:N, births, replace = TRUE, prob = fecundity_skew0)
offspring_skew0 <- tabulate(first_parent, N) + tabulate(mate, N)

# skew 0.5
first_parent <- sample(1:N, births, replace = TRUE, prob = fecundity_skew0.5)
mate <- sample(1:N, births, replace = TRUE, prob = fecundity_skew0.5)
offspring_skew0.5 <- tabulate(first_parent, N) + tabulate(mate, N)

# skew 1
first_parent <- sample(1:N, births, replace = TRUE, prob = fecundity_skew1)
mate <- sample(1:N, births, replace = TRUE, prob = fecundity_skew1)
offspring_skew1 <- tabulate(first_parent, N) + tabulate(mate, N)

# skew 1.5
first_parent <- sample(1:N, births, replace = TRUE, prob = fecundity_skew1.5)
mate <- sample(1:N, births, replace = TRUE, prob = fecundity_skew1.5)
offspring_skew1.5 <- tabulate(first_parent, N) + tabulate(mate, N)

sum(offspring_skew0) / 2     # every population has the same number of births
sum(offspring_skew0.5) / 2
sum(offspring_skew1) / 2
sum(offspring_skew1.5) / 2

sum(offspring_skew0 == 0)    # individuals with no offspring at all
sum(offspring_skew0.5 == 0)
sum(offspring_skew1 == 0)
sum(offspring_skew1.5 == 0)

max(offspring_skew0)         # offspring of the best breeder
max(offspring_skew0.5)
max(offspring_skew1)
max(offspring_skew1.5)

hist(offspring_skew0, breaks = seq(-0.5, max(offspring_skew0) + 0.5, by = 1),
     col = "grey50", main = "no skew", xlab = "offspring per individual",
     ylab = "number of individuals")

hist(offspring_skew0.5, breaks = seq(-0.5, max(offspring_skew0.5) + 0.5, by = 1),
     col = "#a1d99b", main = "skew 0.5", xlab = "offspring per individual",
     ylab = "number of individuals")

hist(offspring_skew1, breaks = seq(-0.5, max(offspring_skew1) + 0.5, by = 1),
     col = "#31a354", main = "skew 1", xlab = "offspring per individual",
     ylab = "number of individuals")

hist(offspring_skew1.5, breaks = seq(-0.5, max(offspring_skew1.5) + 0.5, by = 1),
     col = "#00441b", main = "skew 1.5", xlab = "offspring per individual",
     ylab = "number of individuals")


# inbreeding Ne from the offspring numbers (Waples 2002, as in the model)
Ne_skew0   <- (N * mean(offspring_skew0) - 2) /
  (mean(offspring_skew0) - 1 + var(offspring_skew0) / mean(offspring_skew0))
Ne_skew0.5 <- (N * mean(offspring_skew0.5) - 2) /
  (mean(offspring_skew0.5) - 1 + var(offspring_skew0.5) / mean(offspring_skew0.5))
Ne_skew1   <- (N * mean(offspring_skew1) - 2) /
  (mean(offspring_skew1) - 1 + var(offspring_skew1) / mean(offspring_skew1))
Ne_skew1.5 <- (N * mean(offspring_skew1.5) - 2) /
  (mean(offspring_skew1.5) - 1 + var(offspring_skew1.5) / mean(offspring_skew1.5))

Ne_skew0 / N      # about 1
Ne_skew0.5 / N
Ne_skew1 / N
Ne_skew1.5 / N    # about 0.1 - 0.2

barplot(c(Ne_skew0, Ne_skew0.5, Ne_skew1, Ne_skew1.5) / N,
        col = c("grey50", "#a1d99b", "#31a354", "#00441b"),
        names.arg = c("no skew", "skew 0.5", "skew 1", "skew 1.5"),
        ylim = c(0, 1.1), ylab = "Ne / N", main = "Ne relative to census size")
abline(h = 0.1, lty = 2, col = "red")


generations <- 200

size_skew0   <- rep(0, generations + 1)
size_skew0.5 <- rep(0, generations + 1)
size_skew1   <- rep(0, generations + 1)
size_skew1.5 <- rep(0, generations + 1)

Ne_time_skew0   <- rep(NA, generations)
Ne_time_skew0.5 <- rep(NA, generations)
Ne_time_skew1   <- rep(NA, generations)
Ne_time_skew1.5 <- rep(NA, generations)

size_skew0[1]   <- N
size_skew0.5[1] <- N
size_skew1[1]   <- N
size_skew1.5[1] <- N

for (g in 1:generations) {

  # no skew
  n <- size_skew0[g]
  if (n >= 2) {
    births <- min(rpois(1, R * n), N)
    fecundity <- rep(1, n)
    first_parent <- sample(1:n, births, replace = TRUE, prob = fecundity)
    mate <- sample(1:n, births, replace = TRUE, prob = fecundity)
    k <- tabulate(first_parent, n) + tabulate(mate, n)
    Ne_time_skew0[g] <- (n * mean(k) - 2) / (mean(k) - 1 + var(k) / mean(k))
    size_skew0[g + 1] <- births
  }

  # skew 0.5
  n <- size_skew0.5[g]
  if (n >= 2) {
    births <- min(rpois(1, R * n), N)
    fecundity <- exp(rnorm(n, mean = -0.5^2 / 2, sd = 0.5))
    first_parent <- sample(1:n, births, replace = TRUE, prob = fecundity)
    mate <- sample(1:n, births, replace = TRUE, prob = fecundity)
    k <- tabulate(first_parent, n) + tabulate(mate, n)
    Ne_time_skew0.5[g] <- (n * mean(k) - 2) / (mean(k) - 1 + var(k) / mean(k))
    size_skew0.5[g + 1] <- births
  }

  # skew 1
  n <- size_skew1[g]
  if (n >= 2) {
    births <- min(rpois(1, R * n), N)
    fecundity <- exp(rnorm(n, mean = -1.0^2 / 2, sd = 1.0))
    first_parent <- sample(1:n, births, replace = TRUE, prob = fecundity)
    mate <- sample(1:n, births, replace = TRUE, prob = fecundity)
    k <- tabulate(first_parent, n) + tabulate(mate, n)
    Ne_time_skew1[g] <- (n * mean(k) - 2) / (mean(k) - 1 + var(k) / mean(k))
    size_skew1[g + 1] <- births
  }

  # skew 1.5
  n <- size_skew1.5[g]
  if (n >= 2) {
    births <- min(rpois(1, R * n), N)
    fecundity <- exp(rnorm(n, mean = -1.5^2 / 2, sd = 1.5))
    first_parent <- sample(1:n, births, replace = TRUE, prob = fecundity)
    mate <- sample(1:n, births, replace = TRUE, prob = fecundity)
    k <- tabulate(first_parent, n) + tabulate(mate, n)
    Ne_time_skew1.5[g] <- (n * mean(k) - 2) / (mean(k) - 1 + var(k) / mean(k))
    size_skew1.5[g + 1] <- births
  }
}

# census size: skew no longer changes it
plot(0:generations, size_skew0, type = "l", lwd = 2, col = "grey50",
     ylim = c(0, 1100), xlab = "generation", ylab = "number of individuals",
     main = "Population size")
lines(0:generations, size_skew0.5, lwd = 2, col = "#a1d99b")
lines(0:generations, size_skew1,   lwd = 2, col = "#31a354")
lines(0:generations, size_skew1.5, lwd = 2, col = "#00441b")
abline(h = N, lty = 2)
legend("bottomleft", lwd = 2, bty = "n",
       col = c("grey50", "#a1d99b", "#31a354", "#00441b"),
       legend = c("no skew", "skew 0.5", "skew 1", "skew 1.5"))

# effective size: skew lowers it, every generation
plot(1:generations, Ne_time_skew0, type = "l", lwd = 2, col = "grey50",
     ylim = c(0, 1300), xlab = "generation", ylab = "inbreeding Ne",
     main = "Effective population size")
lines(1:generations, Ne_time_skew0.5, lwd = 2, col = "#a1d99b")
lines(1:generations, Ne_time_skew1,   lwd = 2, col = "#31a354")
lines(1:generations, Ne_time_skew1.5, lwd = 2, col = "#00441b")
abline(h = N, lty = 2)
abline(h = 500, lty = 2, col = "red")   # Ne 500
legend("top", lwd = 2, bty = "n", horiz = TRUE, cex = 0.8,
       col = c("grey50", "#a1d99b", "#31a354", "#00441b"),
       legend = c("no skew", "skew 0.5", "skew 1", "skew 1.5"))
