# Year-by-year plot of census size (N) of every run, with a dashed line at 500
# (the Ne 500 threshold), for the logs in SLiM/results/ramp_v1.3.1_burnin50k
#
# unlike 45_, the y axis is the census size itself, not % of a start value.
#   - one line per run: all populations' N added up
#   - thick grey line = the mean over all runs
#   - black lines = runs with N below 500 in 2025
#   - dashed line at 500
# inbreeding Ne follows census N 1:1 in these runs, so N against 500 is
# also Ne against 500.
#
# makes TWO pictures in SLiM/scripts/R/output/47_census_N_by_year/:
#   census_N_year_by_year_climate_change_and_dist.png   starts at Pre-Dist
#   census_N_year_by_year_climate_change.png            starts in 1970
#
# runs where every population died out stop early; their missing years
# count as 0 (as in the summary, where n_2025 = 0 for those runs).
# the log files are only read, nothing in them is changed.

# folder with the log files (change this if your files move)
log_folder <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k"

# the summary file, only used for the check (change if it is elsewhere)
summary_file <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k/run_summary_burnin50k.csv"

# folder for the pictures (created if it does not exist yet)
output_dir <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/scripts/R/output/47_census_N_by_year"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# the threshold (dashed line, and runs below it in 2025 are drawn black)
threshold <- 500


# ---------------- Find the log files ----------------
# every csv with "log" in its name, also in subfolders

log_files <- list.files(log_folder, pattern = "log.*\\.csv$", full.names = TRUE,
                        recursive = TRUE)
length(log_files)   # should be 1000

if (length(log_files) == 0) stop("no log files found in ", log_folder)

# check on the first log that the phase is called "climate_change"
d <- read.csv(log_files[1])
unique(d$phase)
range(d$year[d$phase == "climate_change"])


# ---------------- Which tick is "before the disturbance" ----------------
# the last logged tick before climate change starts, leaving out any ticks
# that are already after the disturbance (phase "post_disturbance")

find_pre_cycle <- function(d) {
  first_climate_cycle <- min(d$cycle[d$phase == "climate_change"])
  before <- d[d$cycle < first_climate_cycle & d$phase != "post_disturbance", ]
  max(before$cycle)
}

# check on the first log: which tick and phase this is
pre_cycle <- find_pre_cycle(d)
pre_cycle
unique(d$phase[d$cycle == pre_cycle])


# ---------------- Read every log ----------------
# one row per run; column 1 = pre-disturbance, then one column per year

years <- 1970:2025

# where the pre-disturbance point sits on the x axis
x_pre <- 1962
x <- c(x_pre, years)

N_raw <- matrix(NA, nrow = length(log_files), ncol = length(x))

for (i in 1:length(log_files)) {

  d <- read.csv(log_files[i])

  # pre-disturbance tick (column 1)
  rows <- d[d$cycle == find_pre_cycle(d), ]
  N_raw[i, 1] <- sum(rows$N)

  # climate-change years (columns 2 to 57)
  cc <- d[d$phase == "climate_change", ]
  last_year <- max(cc$year)

  for (y in 1:length(years)) {
    rows <- cc[cc$year == years[y], ]
    if (nrow(rows) == 0) next
    N_raw[i, y + 1] <- sum(rows$N)
  }

  # the run stopped because every population died out, so later years are 0
  gone <- c(FALSE, years > last_year)
  N_raw[i, gone] <- 0

  if (i %% 100 == 0) cat("read", i, "of", length(log_files), "logs\n")
}

# how many runs are missing a point (should all be 0)
colSums(is.na(N_raw))

# position of the last year (2025)
end <- length(x)

# mean census size over all runs for every point
N_avg <- rep(NA, length(x))
for (y in 1:length(x)) {
  N_avg[y] <- mean(N_raw[, y], na.rm = TRUE)
}
round(c(pre_dist = N_avg[1], y1970 = N_avg[2], y2025 = N_avg[end]))

# runs below the threshold in 2025 (the summary file gives 150 for 500)
low_run <- N_raw[, end] < threshold
sum(low_run)

# how many runs are below the threshold in each year
below <- colSums(N_raw < threshold, na.rm = TRUE)
below


# ---------------- Check against the summary file ----------------
# the numbers from the logs should be the same as the summary

if (file.exists(summary_file)) {
  s <- read.csv(summary_file)

  check <- data.frame(
    from_logs = round(c(N_avg[1], N_avg[2], N_avg[end], sum(low_run)), 1),
    from_summary = round(c(mean(s$n_pre_dist), mean(s$n_1970), mean(s$n_2025),
                           sum(s$n_2025 < threshold)), 1))
  rownames(check) <- c("mean N pre-dist", "mean N 1970", "mean N 2025",
                       paste("runs below", threshold, "in 2025"))
  print(check)
} else {
  cat("summary file not found, skipping the check\n")
}


# ---------------- Plotting function ----------------
# first = where the picture starts: 1 = pre-disturbance, 2 = 1970
# file_name, title = what goes on the picture

make_plot <- function(first, file_name, title) {

  # only the columns from the starting point on
  cols <- first:length(x)
  xx <- x[cols]
  avg <- N_avg[cols]
  last <- length(cols)

  png(file.path(output_dir, file_name), width = 2000, height = 1700, res = 250)
  par(mar = c(5, 5, 4, 2))

  col_N <- "grey50"

  # y axis from 0 to above the biggest run (room at the top for the legend)
  y_max <- max(N_raw[, cols], na.rm = TRUE) * 1.25

  plot(NA, xlim = c(min(xx), max(years) + 12), ylim = c(0, y_max),
       xaxt = "n", las = 1, xlab = "Year", ylab = "Census size (N)", main = title)

  # x axis: with "Pre-Dist" in front if the picture starts there
  if (first == 1) {
    axis(1, at = c(x_pre, 1970, 1990, 2010, max(years)),
         labels = c("Pre-Dist", 1970, 1990, 2010, max(years)), gap.axis = 0)
    # dotted line between the pre-disturbance point and the climate years
    abline(v = (x_pre + 1970) / 2, col = "grey70", lty = 3)
  } else {
    axis(1, at = c(1970, 1990, 2010, max(years)))
  }

  # every run, very light so the crowd shows up as a grey cloud
  # (make alpha.f smaller if the cloud is too dark, bigger if too faint)
  for (r in which(!low_run)) {
    lines(xx, N_raw[r, cols], col = adjustcolor("grey40", alpha.f = 0.05))
  }

  # runs that end below the threshold, in black on top of the grey cloud
  for (r in which(low_run)) {
    lines(xx, N_raw[r, cols], col = adjustcolor("black", alpha.f = 0.25))
  }

  # the mean on top
  lines(xx, avg, col = col_N, lwd = 3)

  # the threshold
  abline(h = threshold, lty = 2, lwd = 2)

  # dots and numbers at the start and the end
  points(c(xx[1], xx[last]), c(avg[1], avg[last]), pch = 19, col = col_N)
  text(xx[1], avg[1] + y_max * 0.04, round(avg[1]), col = col_N)
  text(max(years) + 1.5, avg[last], round(avg[last]), col = col_N, adj = 0)

  legend("topright", bty = "n", lwd = c(3, 1, 2), lty = c(1, 1, 2),
         col = c(col_N, "black", "black"),
         legend = c("census N (mean over runs)",
                    paste0("runs with N < ", threshold, " in ", max(years),
                           " (", sum(low_run), " of ", length(low_run), ")"),
                    paste0("Ne ", threshold, " threshold")))

  dev.off()

  cat("Saved", file_name, "\n")
}


# ---------------- Make the pictures ----------------

# 1. from before the disturbance
make_plot(1, "census_N_year_by_year_climate_change_and_dist.png",
          paste0("Census size (Pre-Dist to ", max(years), ")"))

# 2. from 1970 (right after the disturbance)
make_plot(2, "census_N_year_by_year_climate_change.png",
          paste0("Census size (", min(years), "-", max(years), ")"))

cat("Both pictures are in", output_dir, "\n")
