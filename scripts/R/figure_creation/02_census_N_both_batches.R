# Census size (N) year by year for BOTH cluster batches in one picture
#   batch 1: SLiM/results/ramp_v1.3.1_burnin50k_14102026 (selection 0.01 to 0.1)
#   batch 2: SLiM/results/ramp_v1.3.1_burnin50k_20112026 (selection 0.05 to 0.15)
# a more minimal version of 01_census_N_year_by_year.R:
#   - one colour per batch
#   - thick line = mean over the 1000 runs of that batch
#   - shaded band = the middle 50% of runs (25% to 75% quantile)
#   - dashed line at 500 (the Ne 500 threshold), labelled on the line
#   - mean N at Pre-Dist and 2025 written next to the points, bold, in the batch colour
#     (the grey numbers in 01 were hard to read)
#   - the step from Pre-Dist to 1970 is dotted (it is not one year)
#
# makes TWO pictures in SLiM/scripts/R/figure_creation/output/02_census_N_both_batches/:
#   census_N_year_by_year_both_batches.png              starts at Pre-Dist
#   census_N_year_by_year_both_batches_1970_2025.png    starts in 1970
#
# runs where every population died out stop early; their missing years
# count as 0 (as in 01 and in the summary, where n_2025 = 0 for those runs).
# the log files are only read, nothing in them is changed.

# folders with the log files (change these if your files move)
log_folder_1 <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k_14102026"
log_folder_2 <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k_20112026"

# the summary files, only used for the check
summary_file_1 <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k_14102026/run_summary_burnin50k.csv"
summary_file_2 <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k_20112026/run_summary_burnin50k_20112026.csv"

# folder for the picture (created if it does not exist yet)
output_dir <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/scripts/R/figure_creation/output/02_census_N_both_batches"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# names of the batches in the legend
name_1 <- "Batch 1: selection 0.01-0.10"
name_2 <- "Batch 2: selection 0.05-0.15"

# colours of the batches (blue and orange, ok for colour blindness)
col_1 <- "#0072B2"
col_2 <- "#D55E00"

# the threshold (dashed line)
threshold <- 500


# ---------------- Find the log files ----------------
# every csv with "log" in its name, for each batch

log_files_1 <- list.files(log_folder_1, pattern = "log.*\\.csv$", full.names = TRUE)
log_files_2 <- list.files(log_folder_2, pattern = "log.*\\.csv$", full.names = TRUE)
length(log_files_1)   # should be 1000
length(log_files_2)   # should be 1000

# all logs in one list, with a column saying which batch each one is from
log_files <- c(log_files_1, log_files_2)
batch <- c(rep(1, length(log_files_1)), rep(2, length(log_files_2)))
table(batch)


# ---------------- Read every log ----------------
# one row per run; column 1 = pre-disturbance, then one column per year
# pre-disturbance = the last logged tick before climate change starts
# (leaving out any "post_disturbance" ticks), same as in 01

years <- 1970:2025

# where the pre-disturbance point sits on the x axis
x_pre <- 1962
x <- c(x_pre, years)

N_raw <- matrix(NA, nrow = length(log_files), ncol = length(x))

for (i in 1:length(log_files)) {

  d <- read.csv(log_files[i])

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

# how many runs are missing a point (should all be 0)
colSums(is.na(N_raw))

# position of the last year (2025)
end <- length(x)


# ---------------- Mean and middle 50% for each batch ----------------

N_1 <- N_raw[batch == 1, ]
N_2 <- N_raw[batch == 2, ]

avg_1 <- colMeans(N_1, na.rm = TRUE)
avg_2 <- colMeans(N_2, na.rm = TRUE)

low_1 <- apply(N_1, 2, quantile, probs = 0.25, na.rm = TRUE)
high_1 <- apply(N_1, 2, quantile, probs = 0.75, na.rm = TRUE)
low_2 <- apply(N_2, 2, quantile, probs = 0.25, na.rm = TRUE)
high_2 <- apply(N_2, 2, quantile, probs = 0.75, na.rm = TRUE)

round(rbind(batch_1 = c(pre_dist = avg_1[1], y1970 = avg_1[2], y2025 = avg_1[end]),
            batch_2 = c(pre_dist = avg_2[1], y1970 = avg_2[2], y2025 = avg_2[end])))

# runs below the threshold in 2025
sum(N_1[, end] < threshold)
sum(N_2[, end] < threshold)


# ---------------- Check against the summary files ----------------
# the numbers from the logs should be the same as the summaries

if (file.exists(summary_file_1) & file.exists(summary_file_2)) {
  s1 <- read.csv(summary_file_1)
  s2 <- read.csv(summary_file_2)

  check <- data.frame(
    batch_1_logs = round(c(avg_1[1], avg_1[2], avg_1[end], sum(N_1[, end] < threshold)), 1),
    batch_1_summary = round(c(mean(s1$n_pre_dist), mean(s1$n_1970), mean(s1$n_2025),
                              sum(s1$n_2025 < threshold)), 1),
    batch_2_logs = round(c(avg_2[1], avg_2[2], avg_2[end], sum(N_2[, end] < threshold)), 1),
    batch_2_summary = round(c(mean(s2$n_pre_dist), mean(s2$n_1970), mean(s2$n_2025),
                              sum(s2$n_2025 < threshold)), 1))
  rownames(check) <- c("mean N pre-dist", "mean N 1970", "mean N 2025",
                       paste("runs below", threshold, "in 2025"))
  print(check)
} else {
  cat("summary files not found, skipping the check\n")
}


# ---------------- Picture 1: Pre-Dist to 2025 ----------------

png(file.path(output_dir, "census_N_year_by_year_both_batches.png"),
    width = 2000, height = 1500, res = 250)
par(mar = c(4.5, 5, 1, 1), bty = "l")

# y axis from 0 to a bit above the highest band (room for the legend)
y_max <- max(c(high_1[-1], high_2[-1], avg_1[1], avg_2[1])) * 1.3

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

# means: dotted from Pre-Dist to 1970, solid through the climate-change years
lines(x[1:2], avg_1[1:2], col = col_1, lwd = 2, lty = 3)
lines(x[1:2], avg_2[1:2], col = col_2, lwd = 2, lty = 3)
lines(years, avg_1[-1], col = col_1, lwd = 3)
lines(years, avg_2[-1], col = col_2, lwd = 3)

# dots at Pre-Dist and 2025
points(c(x_pre, max(years)), avg_1[c(1, end)], pch = 19, col = col_1, cex = 1.2)
points(c(x_pre, max(years)), avg_2[c(1, end)], pch = 19, col = col_2, cex = 1.2)

# numbers at Pre-Dist, to the left of the dots
# (pushed apart a little if the two means are very close)
gap <- y_max * 0.06
y_pre_1 <- avg_1[1]
y_pre_2 <- avg_2[1]
if (abs(y_pre_1 - y_pre_2) < gap) {
  middle <- (y_pre_1 + y_pre_2) / 2
  if (y_pre_1 >= y_pre_2) {
    y_pre_1 <- middle + gap / 2
    y_pre_2 <- middle - gap / 2
  } else {
    y_pre_1 <- middle - gap / 2
    y_pre_2 <- middle + gap / 2
  }
}
text(x_pre - 1, y_pre_1, round(avg_1[1]), col = col_1, font = 2, cex = 1.1, adj = 1)
text(x_pre - 1, y_pre_2, round(avg_2[1]), col = col_2, font = 2, cex = 1.1, adj = 1)

# numbers at 2025, to the right of the dots
# (pushed apart a little if the two means are very close)
y_end_1 <- avg_1[end]
y_end_2 <- avg_2[end]
if (abs(y_end_1 - y_end_2) < gap) {
  middle <- (y_end_1 + y_end_2) / 2
  if (y_end_1 >= y_end_2) {
    y_end_1 <- middle + gap / 2
    y_end_2 <- middle - gap / 2
  } else {
    y_end_1 <- middle - gap / 2
    y_end_2 <- middle + gap / 2
  }
}
text(max(years) + 1, y_end_1, round(avg_1[end]), col = col_1, font = 2, cex = 1.1, adj = 0)
text(max(years) + 1, y_end_2, round(avg_2[end]), col = col_2, font = 2, cex = 1.1, adj = 0)

legend("topright", bty = "n", lwd = 3, col = c(col_1, col_2),
       legend = c(name_1, name_2), cex = 0.9)
legend("topright", bty = "n", legend = paste("lines = mean of", nrow(N_1), "runs, bands = middle 50% of runs"),
       inset = c(0, 0.13), cex = 0.75, text.col = "grey40")

dev.off()

cat("Saved census_N_year_by_year_both_batches.png in", output_dir, "\n")


# ---------------- Picture 2: 1970 to 2025 ----------------
# the same picture without the Pre-Dist point; the numbers sit at 1970 and 2025

png(file.path(output_dir, "census_N_year_by_year_both_batches_1970_2025.png"),
    width = 2000, height = 1500, res = 250)
par(mar = c(4.5, 5, 1, 1), bty = "l")

# y axis from 0 to a bit above the highest band (only the years from 1970 on)
y_max <- max(c(high_1[-1], high_2[-1])) * 1.3

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

# means
lines(years, avg_1[-1], col = col_1, lwd = 3)
lines(years, avg_2[-1], col = col_2, lwd = 3)

# dots at 1970 and 2025 (1970 is column 2, 2025 is column end)
points(c(min(years), max(years)), avg_1[c(2, end)], pch = 19, col = col_1, cex = 1.2)
points(c(min(years), max(years)), avg_2[c(2, end)], pch = 19, col = col_2, cex = 1.2)

# numbers at 1970, to the left of the dots
# (pushed apart a little if the two means are very close)
gap <- y_max * 0.06
y_start_1 <- avg_1[2]
y_start_2 <- avg_2[2]
if (abs(y_start_1 - y_start_2) < gap) {
  middle <- (y_start_1 + y_start_2) / 2
  if (y_start_1 >= y_start_2) {
    y_start_1 <- middle + gap / 2
    y_start_2 <- middle - gap / 2
  } else {
    y_start_1 <- middle - gap / 2
    y_start_2 <- middle + gap / 2
  }
}
text(min(years) - 1, y_start_1, round(avg_1[2]), col = col_1, font = 2, cex = 1.1, adj = 1)
text(min(years) - 1, y_start_2, round(avg_2[2]), col = col_2, font = 2, cex = 1.1, adj = 1)

# numbers at 2025, to the right of the dots
y_end_1 <- avg_1[end]
y_end_2 <- avg_2[end]
if (abs(y_end_1 - y_end_2) < gap) {
  middle <- (y_end_1 + y_end_2) / 2
  if (y_end_1 >= y_end_2) {
    y_end_1 <- middle + gap / 2
    y_end_2 <- middle - gap / 2
  } else {
    y_end_1 <- middle - gap / 2
    y_end_2 <- middle + gap / 2
  }
}
text(max(years) + 1, y_end_1, round(avg_1[end]), col = col_1, font = 2, cex = 1.1, adj = 0)
text(max(years) + 1, y_end_2, round(avg_2[end]), col = col_2, font = 2, cex = 1.1, adj = 0)

legend("topright", bty = "n", lwd = 3, col = c(col_1, col_2),
       legend = c(name_1, name_2), cex = 0.9)
legend("topright", bty = "n", legend = paste("lines = mean of", nrow(N_1), "runs, bands = middle 50% of runs"),
       inset = c(0, 0.13), cex = 0.75, text.col = "grey40")

dev.off()

cat("Saved census_N_year_by_year_both_batches_1970_2025.png in", output_dir, "\n")
