# Plot inbreeding Ne, heterozygosity Ne and phenotypic variance over time
# for the grib_ramp_v1.2 Ne log.

# Read the data (change this path to where your file is)
d <- read.csv("C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.2_ne/grib_ramp_v1.2_Ne_log.csv")


# ---------------- Plot 1: whole metapopulation ----------------

png("Ne_total.png", width = 2400, height = 1100, res = 200)
par(mar = c(5, 5, 4, 6))

# phenotypic variance (red, right axis)
plot(d$cycle, d$varPheno_total, type = "l", col = "red",
     axes = FALSE, xlab = "", ylab = "")

axis(4, col = "red", col.axis = "red")

mtext("Phenotypic variance", side = 4, line = 3, col = "red")

# Ne lines on top (left axis)
par(new = TRUE)

plot(d$cycle, d$Ne_inbreeding_total, type = "l", col = "black",
     ylim = c(0, 4500), xlab = "Generation", ylab = "Ne",
     main = "Metapopulation")

lines(d$cycle, d$Ne_het_total, col = "cornflowerblue", lwd = 2)

# phase boundaries
abline(v = 4000, lty = 3)
abline(v = 8000, lty = 3)

legend("bottomright", bg = "white", lwd = 2,
       col = c("black", "cornflowerblue", "red"),
       legend = c("inbreeding Ne", "heterozygosity Ne", "phenotypic variance"))
dev.off()


# ---------------- Plot 2: each deme ----------------

png("Ne_by_deme.png", width = 2400, height = 2100, res = 200)
par(mfrow = c(2, 2), mar = c(5, 5, 4, 6))

# p0 Geneva
plot(d$cycle, d$varPheno_p0, type = "l", col = "red", axes = FALSE, xlab = "", ylab = "")
axis(4, col = "red", col.axis = "red")

mtext("Phenotypic variance", side = 4, line = 3, col = "red")
par(new = TRUE)

plot(d$cycle, d$Ne_inb_p0, type = "l", col = "black", ylim = c(0, 2300),
     xlab = "Generation", ylab = "Ne", main = "p0 (Geneva)")
lines(d$cycle, d$Ne_het_p0, col = "cornflowerblue", lwd = 2)
abline(v = 4000, lty = 3)
abline(v = 8000, lty = 3)

# p1 Bern
plot(d$cycle, d$varPheno_p1, type = "l", col = "red", axes = FALSE, xlab = "", ylab = "")
axis(4, col = "red", col.axis = "red")

mtext("Phenotypic variance", side = 4, line = 3, col = "red")
par(new = TRUE)

plot(d$cycle, d$Ne_inb_p1, type = "l", col = "black", ylim = c(0, 2300),
     xlab = "Generation", ylab = "Ne", main = "p1 (Bern)")
lines(d$cycle, d$Ne_het_p1, col = "cornflowerblue", lwd = 2)
abline(v = 4000, lty = 3)
abline(v = 8000, lty = 3)

# p2 Zurich
plot(d$cycle, d$varPheno_p2, type = "l", col = "red", axes = FALSE, xlab = "", ylab = "")
axis(4, col = "red", col.axis = "red")

mtext("Phenotypic variance", side = 4, line = 3, col = "red")
par(new = TRUE)

plot(d$cycle, d$Ne_inb_p2, type = "l", col = "black", ylim = c(0, 2300),
     xlab = "Generation", ylab = "Ne", main = "p2 (Zurich)")
lines(d$cycle, d$Ne_het_p2, col = "cornflowerblue", lwd = 2)
abline(v = 4000, lty = 3)
abline(v = 8000, lty = 3)

# p3 St. Gallen
plot(d$cycle, d$varPheno_p3, type = "l", col = "red", axes = FALSE, xlab = "", ylab = "")
axis(4, col = "red", col.axis = "red")

mtext("Phenotypic variance", side = 4, line = 3, col = "red")
par(new = TRUE)

plot(d$cycle, d$Ne_inb_p3, type = "l", col = "black", ylim = c(0, 2300),
     xlab = "Generation", ylab = "Ne", main = "p3 (St. Gallen)")
lines(d$cycle, d$Ne_het_p3, col = "cornflowerblue", lwd = 2)
abline(v = 4000, lty = 3)
abline(v = 8000, lty = 3)

legend("bottomright", bg = "white", lwd = 2,
       col = c("black", "cornflowerblue", "red"),
       legend = c("inbreeding Ne", "heterozygosity Ne", "phenotypic variance"))

dev.off()