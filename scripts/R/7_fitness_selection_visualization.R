# Fitness curves used in the current SLiM model

# Possible phenotype values to show on the x-axis
phenotypes <- seq(5, 19, by = 0.01)

# Historical mean temperatures, 1940-1970
p0_historical <- 11.6529
p1_historical <- 10.3914

# Observed temperatures in 2025
p0_2025 <- 13.9782
p1_2025 <- 13.0721

# Calculate fitness around each temperature optimum
p0_historical_fitness <- 1.0 - (phenotypes - p0_historical)^2 * 0.001
p1_historical_fitness <- 1.0 - (phenotypes - p1_historical)^2 * 0.001
p0_2025_fitness <- 1.0 - (phenotypes - p0_2025)^2 * 0.001
p1_2025_fitness <- 1.0 - (phenotypes - p1_2025)^2 * 0.001

# Fitness cannot be below zero in the SLiM model
p0_historical_fitness[p0_historical_fitness < 0.0] <- 0.0
p1_historical_fitness[p1_historical_fitness < 0.0] <- 0.0
p0_2025_fitness[p0_2025_fitness < 0.0] <- 0.0
p1_2025_fitness[p1_2025_fitness < 0.0] <- 0.0

# Plot the first curve
plot(
  phenotypes,
  p0_historical_fitness,
  type = "l",
  lwd = 3,
  col = "black",
  ylim = c(0, 1),
  xlab = "Phenotype / temperature optimum (degrees C)",
  ylab = "Probability of survival",
  main = "Current climate-selection function"
)

# Add the other three curves
lines(phenotypes, p1_historical_fitness,
      lwd = 3, col = "grey")
lines(phenotypes, p0_2025_fitness,
      lwd = 3, col = "black", lty = 2)
lines(phenotypes, p1_2025_fitness,
      lwd = 3, col = "grey", lty = 2)

# Show the optimum at the center of every curve
abline(v = p0_historical, col = "black", lty = 3)
abline(v = p1_historical, col = "black", lty = 3)
abline(v = p0_2025, col = "black", lty = 3)
abline(v = p1_2025, col = "black", lty = 3)


legend(
 "topleft",
  legend = c(
    "p0 historical mean (11.65 C)",
    "p1 historical mean (10.39 C)",
    "p0 2025 (13.98 C)",
    "p1 2025 (13.07 C)"
  ),
  col = c("black", "grey", "black", "grey"),
  lty = c(1, 1, 2, 2),
  lwd = 3,
  bty = "n"
)

