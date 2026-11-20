# Year-by-year plot of how much of the carrying capacity (K) is occupied,
# for the logs in SLiM/results/ramp_v1.3.1_burnin50k
#
# the summary file (run_summary_burnin50k.csv) has this for two points only:
#   pct_K_occupied_pre_dist = 100 * n_pre_dist / K
#   pct_K_occupied_2025     = 100 * n_2025 / K
# where K is the run's total carrying capacity before the disturbance.
# K does not change over the run in that calculation, so it can be worked out
# for every year from the census N in the logs. the log files are only read,
# nothing in them is changed.
#
#   - one value per run: all populations' N added up, divided by the run's K
#   - K = all populations' K added up at the tick before the disturbance
#     (K_per_pop is rounded, so this can be up to 4 individuals below the K
#     in the summary; the percentages differ by at most about 0.1%)
#   - coloured line = the mean over all runs
#
# makes TWO pictures in SLiM/scripts/R/output/46_K_occupied_by_year/:
#   K_occupied_year_by_year_climate_change_and_dist.png   starts at Pre-Dist
#   K_occupied_year_by_year_climate_change.png            starts in 1970
#
# runs where every population died out stop early; their missing years
# count as 0% (as in the summary, where n_2025 = 0 for those runs).

# folder with the log files (change this if your files move)
log_folder <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k"

# the summary file, only used for the check (change if it is elsewhere)
summary_file <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k/run_summary_burnin50k.csv"

# folder for the pictures (created if it does not exist yet)
output_dir <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/scripts/R/output/46_K_occupied_by_year"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)


# ---------------- Find the log files ----------------
# every csv with "log" in its name, also in subfolders

log_files <- list.files(log_folder, pattern = "log.*\\.csv$", full.names = TRUE,
                        recursive = TRUE)
length(log_files)   # should be 1000

if (length(log_files) == 0) stop("no log files found in ", log_folder)

# check on the first log: the phases, the years, and that there is a K column
d <- read.csv(log_files[1])
unique(d$phase)
range(d$year[d$phase == "climate_change"])
if (!("K" %in% names(d))) stop("the logs have no K column")


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
K_run <- rep(NA, length(log_files))

for (i in 1:length(log_files)) {

  d <- read.csv(log_files[i])

  # pre-disturbance tick (column 1); K of the run is taken here
  rows <- d[d$cycle == find_pre_cycle(d), ]
  N_raw[i, 1] <- sum(rows$N)
  K_run[i] <- sum(rows$K)

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

# percent of K occupied, for every run and every point
K_occupied <- 100 * N_raw / K_run

# mean over all runs for every point
K_avg <- rep(NA, length(x))
for (y in 1:length(x)) {
  K_avg[y] <- mean(K_occupied[, y], na.rm = TRUE)
}

# position of the last year (2025)
end <- length(x)

# the means at Pre-Dist, 1970 and 2025
round(c(pre_dist = K_avg[1], y1970 = K_avg[2], y2025 = K_avg[end]), 1)


# ---------------- Check against the summary file ----------------
# the numbers from the logs should be (almost) the same as the summary

if (file.exists(summary_file)) {
  s <- read.csv(summary_file)

  check <- data.frame(
    from_logs = round(c(K_avg[1], K_avg[2], K_avg[end], mean(K_run)), 1),
    from_summary = round(c(mean(s$pct_K_occupied_pre_dist),
                           mean(100 * s$n_1970 / s$K),
                           mean(s$pct_K_occupied_2025),
                           mean(s$K)), 1))
  rownames(check) <- c("% K occupied pre-dist", "% K occupied 1970",
                       "% K occupied 2025", "mean K")
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
  avg <- K_avg[cols]
  last <- length(cols)

  png(file.path(output_dir, file_name), width = 2000, height = 1700, res = 250)
  par(mar = c(5, 5, 4, 2))

  col_N <- "grey50"

  plot(NA, xlim = c(min(xx), max(years) + 12), ylim = c(0, 110),
       xaxt = "n", yaxt = "n", xlab = "Year", ylab = "% of carrying capacity (K) occupied",
       main = title)

  # x axis: with "Pre-Dist" in front if the picture starts there
  if (first == 1) {
    axis(1, at = c(x_pre, 1970, 1990, 2010, max(years)),
         labels = c("Pre-Dist", 1970, 1990, 2010, max(years)), gap.axis = 0)
    # dotted line between the pre-disturbance point and the climate years
    abline(v = (x_pre + 1970) / 2, col = "grey70", lty = 3)
  } else {
    axis(1, at = c(1970, 1990, 2010, max(years)))
  }
  axis(2, at = seq(0, 100, by = 25), labels = paste0(seq(0, 100, by = 25), "%"), las = 1)

  # K itself (100% occupied)
  abline(h = 100, col = "grey70", lty = 3)

  # every run, very light so the crowd shows up as a grey cloud
  # (make alpha.f smaller if the cloud is too dark, bigger if too faint)
  for (r in 1:nrow(K_occupied)) {
    lines(xx, K_occupied[r, cols], col = adjustcolor("grey40", alpha.f = 0.05))
  }

  # the mean on top
  lines(xx, avg, col = col_N, lwd = 3)

  # dots and numbers at the start and the end
  points(c(xx[1], xx[last]), c(avg[1], avg[last]), pch = 19, col = col_N)
  text(xx[1], avg[1] + 6, paste0(round(avg[1]), "%"), col = col_N)
  text(max(years) + 1.5, avg[last], paste0(round(avg[last]), "%"), col = col_N, adj = 0)

  legend("bottomleft", bty = "n", lwd = c(3, 1), lty = c(1, 3),
         col = c(col_N, "grey70"),
         legend = c("census N as % of K (mean over runs)", "K (100% occupied)"))

  dev.off()

  cat("Saved", file_name, "\n")
}


# ---------------- Make the pictures ----------------

# 1. from before the disturbance
make_plot(1, "K_occupied_year_by_year_climate_change_and_dist.png",
          paste0("Carrying capacity occupied (Pre-Dist to ", max(years), ")"))

# 2. from 1970 (right after the disturbance)
make_plot(2, "K_occupied_year_by_year_climate_change.png",
          paste0("Carrying capacity occupied (", min(years), "-", max(years), ")"))

cat("Both pictures are in", output_dir, "\n")
