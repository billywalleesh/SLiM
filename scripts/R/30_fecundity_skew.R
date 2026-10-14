set.seed(1)   # same random numbers every time you run it

N <- 1000          # individuals in the population (K)
R <- 1.01          # mean litter size per individual


expected_skew0   <- rep(R, N)
expected_skew0.5 <- R * exp(rnorm(N, mean = -0.5^2 / 2, sd = 0.5))
expected_skew1   <- R * exp(rnorm(N, mean = -1.0^2 / 2, sd = 1.0))
expected_skew1.5 <- R * exp(rnorm(N, mean = -1.5^2 / 2, sd = 1.5))

mean(expected_skew0)     # all about 1.01
mean(expected_skew0.5)
mean(expected_skew1)
mean(expected_skew1.5)

max(expected_skew0)      # the best breeder in each population
max(expected_skew0.5)
max(expected_skew1)
max(expected_skew1.5)

hist(expected_skew0, breaks = seq(0, 2, by = 0.25), col = "grey50",
     main = "no skew", xlab = "expected litter size",
     ylab = "number of individuals")
abline(v = R, col = "red", lwd = 2)

hist(expected_skew0.5, breaks = seq(0, max(expected_skew0.5) + 0.25, by = 0.25),
     col = "#a1d99b", main = "skew 0.5", xlab = "expected litter size",
     ylab = "number of individuals")
abline(v = R, col = "red", lwd = 2)

hist(expected_skew1, breaks = seq(0, max(expected_skew1) + 0.25, by = 0.25),
     col = "#31a354", main = "skew 1", xlab = "expected litter size",
     ylab = "number of individuals")
abline(v = R, col = "red", lwd = 2)

hist(expected_skew1.5, breaks = seq(0, max(expected_skew1.5) + 0.25, by = 0.25),
     col = "#00441b", main = "skew 1.5", xlab = "expected litter size",
     ylab = "number of individuals")
abline(v = R, col = "red", lwd = 2)

generations <- 200

size_skew0   <- rep(0, generations + 1)
size_skew0.5 <- rep(0, generations + 1)
size_skew1   <- rep(0, generations + 1)
size_skew1.5 <- rep(0, generations + 1)

size_skew0[1]   <- N
size_skew0.5[1] <- N
size_skew1[1]   <- N
size_skew1.5[1] <- N

for (g in 1:generations) {

  # no skew
  n <- size_skew0[g]
  if (n >= 2) {
    litters <- rpois(n, R)
    size_skew0[g + 1] <- min(sum(litters), N)
  }

  # skew 0.5
  n <- size_skew0.5[g]
  if (n >= 2) {
    expected <- R * exp(rnorm(n, mean = -0.5^2 / 2, sd = 0.5))
    litters <- rpois(n, expected)
    size_skew0.5[g + 1] <- min(sum(litters), N)
  }

  # skew 1
  n <- size_skew1[g]
  if (n >= 2) {
    expected <- R * exp(rnorm(n, mean = -1.0^2 / 2, sd = 1.0))
    litters <- rpois(n, expected)
    size_skew1[g + 1] <- min(sum(litters), N)
  }

  # skew 1.5
  n <- size_skew1.5[g]
  if (n >= 2) {
    expected <- R * exp(rnorm(n, mean = -1.5^2 / 2, sd = 1.5))
    litters <- rpois(n, expected)
    size_skew1.5[g + 1] <- min(sum(litters), N)
  }
}

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


