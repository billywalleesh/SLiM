# A simple example of when migrants from p0 could help p1

# Possible integer phenotype values in the SLiM model
phenotypes <- 6:17

# Temperature optima
p1_historical <- 10.3914
p0_historical <- 11.6529
p1_2025 <- 13.0721

# Three possible strengths of climate selection
selection_strengths <- c(0.01, 0.05, 0.15)
plot_titles <- c(
  "Weak selection: 0.01",
  "Current model: 0.05",
  "Strong selection: 0.15"
)

# Compare the three strengths on the same scale
par(mfrow = c(1, 3))

for (i in 1:3)
{
  selection_strength <- selection_strengths[i]

  # Fitness in the three environments
  p1_historical_fitness <- 1.0 -
    (phenotypes - p1_historical)^2 * selection_strength
  p0_historical_fitness <- 1.0 -
    (phenotypes - p0_historical)^2 * selection_strength
  p1_2025_fitness <- 1.0 -
    (phenotypes - p1_2025)^2 * selection_strength

  # Fitness cannot be below zero in the SLiM model
  p1_historical_fitness[p1_historical_fitness < 0.0] <- 0.0
  p0_historical_fitness[p0_historical_fitness < 0.0] <- 0.0
  p1_2025_fitness[p1_2025_fitness < 0.0] <- 0.0

  plot(
    phenotypes,
    p1_historical_fitness,
    type = "b",
    pch = 16,
    lwd = 2,
    col = "steelblue",
    ylim = c(0, 1),
    xlab = "Phenotype",
    ylab = "Survival probability",
    main = plot_titles[i]
  )

  lines(
    phenotypes,
    p0_historical_fitness,
    type = "b",
    pch = 17,
    lwd = 2,
    col = "darkorange"
  )

  lines(
    phenotypes,
    p1_2025_fitness,
    type = "b",
    pch = 15,
    lwd = 2,
    lty = 2,
    col = "firebrick"
  )

  # Compare a p1 resident with phenotype 10 to a warmer-adapted
  # p0 migrant with phenotype 12 in p1's 2025 environment
  resident_fitness <- 1.0 -
    (10 - p1_2025)^2 * selection_strength
  migrant_fitness <- 1.0 -
    (12 - p1_2025)^2 * selection_strength

  if (resident_fitness < 0.0)
    resident_fitness <- 0.0
  if (migrant_fitness < 0.0)
    migrant_fitness <- 0.0

  points(10, resident_fitness, pch = 21, bg = "steelblue", cex = 1.7)
  points(12, migrant_fitness, pch = 21, bg = "darkorange", cex = 1.7)

  text(
    10,
    resident_fitness,
    labels = paste0("resident\n", round(resident_fitness, 2)),
    pos = 2,
    cex = 0.7
  )

  text(
    12,
    migrant_fitness,
    labels = paste0("migrant\n", round(migrant_fitness, 2)),
    pos = 4,
    cex = 0.7
  )

  if (i == 1)
  {
    legend(
      "bottomleft",
      legend = c(
        "p1 historical environment",
        "p0 historical environment",
        "p1 environment in 2025"
      ),
      col = c("steelblue", "darkorange", "firebrick"),
      lty = c(1, 1, 2),
      pch = c(16, 17, 15),
      lwd = 2,
      cex = 0.65,
      bty = "n"
    )
  }
}

par(mfrow = c(1, 1))
