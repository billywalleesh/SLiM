# Census size (N) year by year for ALL finished cluster batches in one picture
#   batch 1: SLiM/results/ramp_v1.3.1_burnin50k_14102026  (selection 0.01 to 0.10)
#   batch 2: SLiM/results/ramp_v1.3.1_burnin50k_20112026  (selection 0.05 to 0.15)
#   batch 3: SLiM/results/ramp_v1.3.1_burnin50k_251120261 (selection 0.17 to 0.23)
#   batch 4: SLiM/results/ramp_v1.3.1_burnin50k_251120262 (selection 0.17 to 0.20)
# the same picture as 02_census_N_both_batches.R, with two more batches:
#   - one colour per batch
#   - thick line = mean over the runs of that batch
#   - shaded band = the middle 50% of runs (25% to 75% quantile)
#   - dashed line at 500 (the Ne 500 threshold), labelled on the line
#   - mean N at Pre-Dist and 2025 written next to the points, bold, in the batch colour
#   - the step from Pre-Dist to 1970 is dotted (it is not one year)
#
# makes TWO pictures in SLiM/scripts/R/figure_creation/output/03_census_N_all_batches/:
#   census_N_year_by_year_all_batches.png              starts at Pre-Dist
#   census_N_year_by_year_all_batches_1970_2025.png    starts in 1970
#
# runs where every population died out after 1970 stop early; their missing years
# count as 0 (as in 01, 02 and in the summary, where n_2025 = 0 for those runs).
# runs where every population died BEFORE 1970 (in the ramp, batch 3 has 12 of them, batch 4 should have none)
# never reached the disturbance, so they are left out here (as in 05, where they get dead_before_1970 = TRUE).
# the log files are only read, nothing in them is changed.

# folders with the log files (change these if your files move)
log_folder_1 <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k_14102026"
log_folder_2 <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k_20112026"
log_folder_3 <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k_251120261"
log_folder_4 <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k_251120262"

# folder for the picture (created if it does not exist yet)
output_dir <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/scripts/R/figure_creation/output/03_census_N_all_batches"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# names of the batches in the legend (the number of runs is added further down)
name_1 <- "Batch 1: selection 0.01-0.10"
name_2 <- "Batch 2: selection 0.05-0.15"
name_3 <- "Batch 3: selection 0.17-0.23"
name_4 <- "Batch 4: selection 0.17-0.20"

# colours of the batches (blue, orange, green and pink, ok for colour blindness)
col_1 <- "#0072B2"
col_2 <- "#D55E00"
col_3 <- "#009E73"
col_4 <- "#CC79A7"

# the threshold (dashed line)
threshold <- 500


# ---------------- Find the log files ----------------
# every csv with "log" in its name, for each batch

log_files_1 <- list.files(log_folder_1, pattern = "log.*\\.csv$", full.names = TRUE)
log_files_2 <- list.files(log_folder_2, pattern = "log.*\\.csv$", full.names = TRUE)
log_files_3 <- list.files(log_folder_3, pattern = "log.*\\.csv$", full.names = TRUE)
log_files_4 <- list.files(log_folder_4, pattern = "log.*\\.csv$", full.names = TRUE)
length(log_files_1)   # should be 1000
length(log_files_2)   # should be 1000
length(log_files_3)   # should be 1000
length(log_files_4)   # should be 1000

# all logs in one list, with a column saying which batch each one is from
log_files <- c(log_files_1, log_files_2, log_files_3, log_files_4)
batch <- c(rep(1, length(log_files_1)), rep(2, length(log_files_2)), rep(3, length(log_files_3)),
           rep(4, length(log_files_4)))
table(batch)


# ---------------- Read every log ----------------
# one row per run; column 1 = pre-disturbance, then one column per year
# pre-disturbance = the last logged tick before climate change starts
# (leaving out any "post_disturbance" ticks), same as in 01 and 02

years <- 1970:2025

# where the pre-disturbance point sits on the x axis
x_pre <- 1962
x <- c(x_pre, years)

N_raw <- matrix(NA, nrow = length(log_files), ncol = length(x))

# TRUE for runs that died before the climate change started (no climate_change rows in the log)
dead_before_1970 <- rep(FALSE, length(log_files))

for (i in 1:length(log_files)) {

  d <- read.csv(log_files[i])

  # the run died in the ramp or the burn-in: leave its row empty and go to the next log
  if (sum(d$phase == "climate_change") == 0) {
    dead_before_1970[i] <- TRUE
    next
  }

  # pre-disturbance tick (column 1)
  first_climate_cycle <- min(d$cycle[d$phase == "climate_change"])
  before <- d[d$cycle < first_climate_cycle & d$phase != "post_disturbance", ]
  N_raw[i, 1] <- sum(before$N[before$cycle == max(before$cycle)])

  # climate-change years (columns 2 to 57), N of all populations added up
  cc <- d[d$phase == "climate_change", ]
  N_year <- tapply(cc$N, cc$year, sum)
  N_raw[i, 2:length(x)] <- N_year[as.character(years)]

  # the run stopped because every population died out, so later years are 0
  gone <- c(FALSE, years > max(cc$year))
  N_raw[i, gone] <- 0

  if (i %% 100 == 0) cat("read", i, "of", length(log_files), "logs\n")
}

# how many runs died before 1970 in each batch (batch 3 should have 12, batch 4 none)
table(batch, dead_before_1970)

# how many runs are missing a point, leaving out the runs that died before 1970 (should all be 0)
colSums(is.na(N_raw[!dead_before_1970, ]))

# position of the last year (2025)
end <- length(x)


# ---------------- Mean and middle 50% for each batch ----------------
# only the runs that reached 1970

N_1 <- N_raw[batch == 1 & !dead_before_1970, ]
N_2 <- N_raw[batch == 2 & !dead_before_1970, ]
N_3 <- N_raw[batch == 3 & !dead_before_1970, ]
N_4 <- N_raw[batch == 4 & !dead_before_1970, ]

avg_1 <- colMeans(N_1)
avg_2 <- colMeans(N_2)
avg_3 <- colMeans(N_3)
avg_4 <- colMeans(N_4)

low_1 <- apply(N_1, 2, quantile, probs = 0.25)
high_1 <- apply(N_1, 2, quantile, probs = 0.75)
low_2 <- apply(N_2, 2, quantile, probs = 0.25)
high_2 <- apply(N_2, 2, quantile, probs = 0.75)
low_3 <- apply(N_3, 2, quantile, probs = 0.25)
high_3 <- apply(N_3, 2, quantile, probs = 0.75)
low_4 <- apply(N_4, 2, quantile, probs = 0.25)
high_4 <- apply(N_4, 2, quantile, probs = 0.75)

round(rbind(batch_1 = c(pre_dist = avg_1[1], y1970 = avg_1[2], y2025 = avg_1[end]),
            batch_2 = c(pre_dist = avg_2[1], y1970 = avg_2[2], y2025 = avg_2[end]),
            batch_3 = c(pre_dist = avg_3[1], y1970 = avg_3[2], y2025 = avg_3[end]),
            batch_4 = c(pre_dist = avg_4[1], y1970 = avg_4[2], y2025 = avg_4[end])))

# runs below the threshold in 2025
sum(N_1[, end] < threshold)
sum(N_2[, end] < threshold)
sum(N_3[, end] < threshold)
sum(N_4[, end] < threshold)

# runs where the whole metapopulation was gone by 2025
sum(N_1[, end] == 0)
sum(N_2[, end] == 0)
sum(N_3[, end] == 0)
sum(N_4[, end] == 0)

# the legend names with the number of runs in each batch
legend_names <- c(paste0(name_1, " (", nrow(N_1), " runs)"),
                  paste0(name_2, " (", nrow(N_2), " runs)"),
                  paste0(name_3, " (", nrow(N_3), " runs)"),
                  paste0(name_4, " (", nrow(N_4), " runs)"))
legend_names

# all the colours together, in batch order (for the numbers and the legend)
cols <- c(col_1, col_2, col_3, col_4)


# ---------------- Picture 1: Pre-Dist to 2025 ----------------

png(file.path(output_dir, "census_N_year_by_year_all_batches.png"),
    width = 2000, height = 1500, res = 250)
par(mar = c(4.5, 5, 1, 1), bty = "l")

# y axis from 0 to a bit above the highest band (room for the legend)
y_max <- max(c(high_1[-1], high_2[-1], high_3[-1], high_4[-1], avg_1[1], avg_2[1], avg_3[1], avg_4[1])) * 1.5

plot(NA, xlim = c(x_pre - 9, max(years) + 8), ylim = c(0, y_max),
     xaxt = "n", las = 1, xlab = "Year", ylab = "Census size (N)")
axis(1, at = c(x_pre, 1970, 1990, 2010, max(years)),
     labels = c("Pre-Dist", 1970, 1990, 2010, max(years)), gap.axis = 0)

# the threshold, with its label on the line
abline(h = threshold, lty = 2, col = "grey40")
text(max(years) + 8, threshold, paste("Ne", threshold), pos = 3, col = "grey40",
     cex = 0.9, adj = 1, offset = 0.3)

# bands: middle 50% of runs (from 1970 on, Pre-Dist only gets the mean)
polygon(c(years, rev(years)), c(low_1[-1], rev(high_1[-1])),
        col = adjustcolor(col_1, alpha.f = 0.2), border = NA)
polygon(c(years, rev(years)), c(low_2[-1], rev(high_2[-1])),
        col = adjustcolor(col_2, alpha.f = 0.2), border = NA)
polygon(c(years, rev(years)), c(low_3[-1], rev(high_3[-1])),
        col = adjustcolor(col_3, alpha.f = 0.2), border = NA)
polygon(c(years, rev(years)), c(low_4[-1], rev(high_4[-1])),
        col = adjustcolor(col_4, alpha.f = 0.2), border = NA)

# means: dotted from Pre-Dist to 1970, solid through the climate-change years
lines(x[1:2], avg_1[1:2], col = col_1, lwd = 2, lty = 3)
lines(x[1:2], avg_2[1:2], col = col_2, lwd = 2, lty = 3)
lines(x[1:2], avg_3[1:2], col = col_3, lwd = 2, lty = 3)
lines(x[1:2], avg_4[1:2], col = col_4, lwd = 2, lty = 3)
lines(years, avg_1[-1], col = col_1, lwd = 3)
lines(years, avg_2[-1], col = col_2, lwd = 3)
lines(years, avg_3[-1], col = col_3, lwd = 3)
lines(years, avg_4[-1], col = col_4, lwd = 3)

# dots at Pre-Dist and 2025
points(c(x_pre, max(years)), avg_1[c(1, end)], pch = 19, col = col_1, cex = 1.2)
points(c(x_pre, max(years)), avg_2[c(1, end)], pch = 19, col = col_2, cex = 1.2)
points(c(x_pre, max(years)), avg_3[c(1, end)], pch = 19, col = col_3, cex = 1.2)
points(c(x_pre, max(years)), avg_4[c(1, end)], pch = 19, col = col_4, cex = 1.2)

# the numbers next to the dots are pushed apart if two of them are too close:
# going from the lowest number up, a number that sits less than "gap" above the one
# below it is moved up to exactly "gap" above it
gap <- y_max * 0.06

# numbers at Pre-Dist, to the left of the dots
y_value <- c(avg_1[1], avg_2[1], avg_3[1], avg_4[1])
y_label <- y_value
o <- order(y_label)
for (k in 2:length(o)) {
  if (y_label[o[k]] - y_label[o[k - 1]] < gap) y_label[o[k]] <- y_label[o[k - 1]] + gap
}
text(x_pre - 1, y_label, round(y_value), col = cols, font = 2, cex = 1.1, adj = 1)

# numbers at 2025, to the right of the dots
y_value <- c(avg_1[end], avg_2[end], avg_3[end], avg_4[end])
y_label <- y_value
o <- order(y_label)
for (k in 2:length(o)) {
  if (y_label[o[k]] - y_label[o[k - 1]] < gap) y_label[o[k]] <- y_label[o[k - 1]] + gap
}
text(max(years) + 1, y_label, round(y_value), col = cols, font = 2, cex = 1.1, adj = 0)

legend("topright", bty = "n", lwd = 3, col = cols, legend = legend_names, cex = 0.85)
legend("topright", bty = "n", legend = "lines = mean of the runs, bands = middle 50% of runs",
       inset = c(0, 0.24), cex = 0.75, text.col = "grey40")

dev.off()

cat("Saved census_N_year_by_year_all_batches.png in", output_dir, "\n")


# ---------------- Picture 2: 1970 to 2025 ----------------
# the same picture without the Pre-Dist point; the numbers sit at 1970 and 2025

png(file.path(output_dir, "census_N_year_by_year_all_batches_1970_2025.png"),
    width = 2000, height = 1500, res = 250)
par(mar = c(4.5, 5, 1, 1), bty = "l")

# y axis from 0 to a bit above the highest band (only the years from 1970 on)
y_max <- max(c(high_1[-1], high_2[-1], high_3[-1], high_4[-1])) * 1.5

plot(NA, xlim = c(min(years) - 7, max(years) + 8), ylim = c(0, y_max),
     xaxt = "n", las = 1, xlab = "Year", ylab = "Census size (N)")
axis(1, at = c(1970, 1990, 2010, max(years)))

# the threshold, with its label on the line
abline(h = threshold, lty = 2, col = "grey40")
text(max(years) + 8, threshold, paste("Ne", threshold), pos = 3, col = "grey40",
     cex = 0.9, adj = 1, offset = 0.3)

# bands: middle 50% of runs
polygon(c(years, rev(years)), c(low_1[-1], rev(high_1[-1])),
        col = adjustcolor(col_1, alpha.f = 0.2), border = NA)
polygon(c(years, rev(years)), c(low_2[-1], rev(high_2[-1])),
        col = adjustcolor(col_2, alpha.f = 0.2), border = NA)
polygon(c(years, rev(years)), c(low_3[-1], rev(high_3[-1])),
        col = adjustcolor(col_3, alpha.f = 0.2), border = NA)
polygon(c(years, rev(years)), c(low_4[-1], rev(high_4[-1])),
        col = adjustcolor(col_4, alpha.f = 0.2), border = NA)

# means
lines(years, avg_1[-1], col = col_1, lwd = 3)
lines(years, avg_2[-1], col = col_2, lwd = 3)
lines(years, avg_3[-1], col = col_3, lwd = 3)
lines(years, avg_4[-1], col = col_4, lwd = 3)

# dots at 1970 and 2025 (1970 is column 2, 2025 is column end)
points(c(min(years), max(years)), avg_1[c(2, end)], pch = 19, col = col_1, cex = 1.2)
points(c(min(years), max(years)), avg_2[c(2, end)], pch = 19, col = col_2, cex = 1.2)
points(c(min(years), max(years)), avg_3[c(2, end)], pch = 19, col = col_3, cex = 1.2)
points(c(min(years), max(years)), avg_4[c(2, end)], pch = 19, col = col_4, cex = 1.2)

gap <- y_max * 0.06

# numbers at 1970, to the left of the dots (pushed apart as in picture 1)
y_value <- c(avg_1[2], avg_2[2], avg_3[2], avg_4[2])
y_label <- y_value
o <- order(y_label)
for (k in 2:length(o)) {
  if (y_label[o[k]] - y_label[o[k - 1]] < gap) y_label[o[k]] <- y_label[o[k - 1]] + gap
}
text(min(years) - 1, y_label, round(y_value), col = cols, font = 2, cex = 1.1, adj = 1)

# numbers at 2025, to the right of the dots
y_value <- c(avg_1[end], avg_2[end], avg_3[end], avg_4[end])
y_label <- y_value
o <- order(y_label)
for (k in 2:length(o)) {
  if (y_label[o[k]] - y_label[o[k - 1]] < gap) y_label[o[k]] <- y_label[o[k - 1]] + gap
}
text(max(years) + 1, y_label, round(y_value), col = cols, font = 2, cex = 1.1, adj = 0)

legend("topright", bty = "n", lwd = 3, col = cols, legend = legend_names, cex = 0.85)
legend("topright", bty = "n", legend = "lines = mean of the runs, bands = middle 50% of runs",
       inset = c(0, 0.24), cex = 0.75, text.col = "grey40")

dev.off()

cat("Saved census_N_year_by_year_all_batches_1970_2025.png in", output_dir, "\n")
