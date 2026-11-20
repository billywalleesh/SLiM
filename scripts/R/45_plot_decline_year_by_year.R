# Year-by-year version of the "Decline during climate change (1970-2025)" plot,
# for the logs in SLiM/results/ramp_v1.3.1_burnin50k
#
# the summary plot only has a few points per run (from
# run_summary_burnin50k.csv). this script reads the log of every run and
# draws every climate year, worked out the same way:
#   - one value per run (not per population)
#   - census N    = all populations of the run added up
#   - Ne          = the metapopulation columns Ne_inb_metapop and Ne_het_metapop
#   - coloured lines = the mean over all runs
#
# it makes TWO pictures in SLiM/scripts/R/output/45_decline_by_year/:
#   decline_year_by_year_climate_change_and_dist.png
#       starts at the tick before the disturbance ("Pre-Dist" = 100%),
#       so the disturbance itself is in the picture
#   decline_year_by_year_climate_change.png
#       starts in 1970, right after the disturbance (1970 = 100%)
# the script prints the 2025 values of both next to the summary file so you
# can check them.
#
# runs where every population died out stop early; their missing years
# count as 0 (as in the summary, where n_2025 = 0 for those runs).

# folder with the log files (change this if your files move)
log_folder <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k"

# the summary file, only used for the check (change if it is elsewhere)
summary_file <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k/run_summary_burnin50k.csv"

# folder for the pictures (created if it does not exist yet)
output_dir <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/scripts/R/output/45_decline_by_year"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)


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
Ne_inb_raw <- matrix(NA, nrow = length(log_files), ncol = length(x))
Ne_het_raw <- matrix(NA, nrow = length(log_files), ncol = length(x))

for (i in 1:length(log_files)) {
  
  d <- read.csv(log_files[i])
  
  # pre-disturbance tick (column 1)
  rows <- d[d$cycle == find_pre_cycle(d), ]
  N_raw[i, 1] <- sum(rows$N)
  Ne_inb_raw[i, 1] <- rows$Ne_inb_metapop[1]
  Ne_het_raw[i, 1] <- rows$Ne_het_metapop[1]
  
  # climate-change years (columns 2 to 57)
  cc <- d[d$phase == "climate_change", ]
  last_year <- max(cc$year)
  
  for (y in 1:length(years)) {
    rows <- cc[cc$year == years[y], ]
    if (nrow(rows) == 0) next
    
    # census N of the run = all populations added up
    N_raw[i, y + 1] <- sum(rows$N)
    
    # the metapopulation Ne is the same on every population row, take the first
    Ne_inb_raw[i, y + 1] <- rows$Ne_inb_metapop[1]
    Ne_het_raw[i, y + 1] <- rows$Ne_het_metapop[1]
    
    # Ne of an empty run is NA in the log, count it as 0
    if (N_raw[i, y + 1] == 0) {
      Ne_inb_raw[i, y + 1] <- 0
      Ne_het_raw[i, y + 1] <- 0
    }
  }
  
  # the run stopped because every population died out, so later years are 0
  gone <- c(FALSE, years > last_year)
  N_raw[i, gone] <- 0
  Ne_inb_raw[i, gone] <- 0
  Ne_het_raw[i, gone] <- 0
  
  if (i %% 100 == 0) cat("read", i, "of", length(log_files), "logs\n")
}

# how many runs are missing a point (should all be 0)
colSums(is.na(N_raw))

# position of the last year (2025)
end <- length(x)


# ---------------- Check against the summary file ----------------
# column 1 = pre-disturbance, column 2 = 1970; the numbers from the logs
# should be the same as the ones from the summary file

if (file.exists(summary_file)) {
  s <- read.csv(summary_file)
  
  check <- data.frame(
    from_logs = round(c(
      mean(100 * N_raw[, end] / N_raw[, 1]),
      mean(100 * Ne_inb_raw[, end] / Ne_inb_raw[, 1]),
      mean(100 * Ne_het_raw[, end] / Ne_het_raw[, 1]),
      mean(100 * N_raw[, end] / N_raw[, 2]),
      mean(100 * Ne_inb_raw[, end] / Ne_inb_raw[, 2]),
      mean(100 * Ne_het_raw[, end] / Ne_het_raw[, 2])), 1),
    from_summary = round(c(
      mean(100 * s$n_2025 / s$n_pre_dist),
      mean(100 * s$ne_inb_2025 / s$ne_inb_pre_dist),
      mean(100 * s$ne_het_2025 / s$ne_het_pre_dist),
      mean(100 * s$n_2025 / s$n_1970),
      mean(100 * s$ne_inb_2025 / s$ne_inb_dist),
      mean(100 * s$ne_het_2025 / s$ne_het_dist)), 1))
  rownames(check) <- c("N 2025 (% of pre-dist)", "Ne_inb 2025 (% of pre-dist)",
                       "Ne_het 2025 (% of pre-dist)", "N 2025 (% of 1970)",
                       "Ne_inb 2025 (% of 1970)", "Ne_het 2025 (% of 1970)")
  print(check)
} else {
  cat("summary file not found, skipping the check\n")
}


# ---------------- Plotting function ----------------
# first = which column is 100%: 1 = pre-disturbance, 2 = 1970
# file_name, title, y_label = what goes on the picture

make_plot <- function(first, file_name, title, y_label) {
  
  # only the columns from the starting point on
  cols <- first:length(x)
  xx <- x[cols]
  
  # percent of the starting point
  N_change <- 100 * N_raw[, cols] / N_raw[, first]
  Ne_inb_change <- 100 * Ne_inb_raw[, cols] / Ne_inb_raw[, first]
  Ne_het_change <- 100 * Ne_het_raw[, cols] / Ne_het_raw[, first]
  
  # mean for every point
  N_avg <- rep(NA, length(cols))
  Ne_inb_avg <- rep(NA, length(cols))
  Ne_het_avg <- rep(NA, length(cols))
  
  for (y in 1:length(cols)) {
    N_avg[y] <- mean(N_change[, y], na.rm = TRUE)
    Ne_inb_avg[y] <- mean(Ne_inb_change[, y], na.rm = TRUE)
    Ne_het_avg[y] <- mean(Ne_het_change[, y], na.rm = TRUE)
  }
  last <- length(cols)
  
  png(file.path(output_dir, file_name), width = 2000, height = 1700, res = 250)
  par(mar = c(5, 5, 4, 2))
  
  col_N <- "grey50"
  col_inb <- "firebrick3"
  col_het <- "darkred"
  
  plot(NA, xlim = c(min(xx), max(years) + 12), ylim = c(0, 150),
       xaxt = "n", yaxt = "n", xlab = "Year", ylab = y_label, main = title)
  
  # x axis: with "Pre-Dist" in front if the picture starts there
  if (first == 1) {
    axis(1, at = c(x_pre, 1970, 1990, 2010, max(years)),
         labels = c("Pre-Dist", 1970, 1990, 2010, max(years)), gap.axis = 0)
    # dotted line between the pre-disturbance point and the climate years
    abline(v = (x_pre + 1970) / 2, col = "grey70", lty = 3)
  } else {
    axis(1, at = c(1970, 1990, 2010, max(years)))
  }
  axis(2, at = seq(0, 150, by = 25), labels = paste0(seq(0, 150, by = 25), "%"), las = 1)
  abline(h = 100, col = "grey70", lty = 3)
  
  # census N of every run, very light so the crowd shows up as a grey cloud
  # (make alpha.f smaller if the cloud is too dark, bigger if too faint)
  for (r in 1:nrow(N_change)) {
    lines(xx, N_change[r, ], col = adjustcolor("grey40", alpha.f = 0.05))
  }
  
  # the means on top
  lines(xx, N_avg, col = col_N, lwd = 3)
  lines(xx, Ne_inb_avg, col = col_inb, lwd = 3)
  lines(xx, Ne_het_avg, col = col_het, lwd = 3, lty = 2)
  
  # dots and numbers at the end
  points(min(xx), 100, pch = 19)
  end_values <- c(N_avg[last], Ne_inb_avg[last], Ne_het_avg[last])
  points(rep(max(years), 3), end_values, pch = 19, col = c(col_N, col_inb, col_het))
  
  # if two numbers are closer than 6% they would overlap, so push them apart
  label_y <- end_values
  o <- order(label_y)
  for (k in 2:3) {
    if (label_y[o[k]] - label_y[o[k - 1]] < 6) label_y[o[k]] <- label_y[o[k - 1]] + 6
  }
  text(rep(max(years) + 1.5, 3), label_y, paste0(round(end_values), "%"),
       col = c(col_N, col_inb, col_het), adj = 0)
  
  legend("bottomleft", bty = "n", lwd = 3, lty = c(1, 1, 2),
         col = c(col_N, col_inb, col_het),
         legend = c("census N", "Ne (inbreeding)", "Ne (heterozygosity, diversity)"))
  
  dev.off()
  
  cat("Saved", file_name, "\n")
}


# ---------------- Make the pictures ----------------

# 1. from before the disturbance
make_plot(1, "decline_year_by_year_climate_change_and_dist.png",
          paste0("Decline during disturbance and climate change (", min(years), "-", max(years), ")"),
          "% of pre-disturbance value")

# 2. from 1970 (right after the disturbance)
make_plot(2, "decline_year_by_year_climate_change.png",
          paste0("Decline during climate change (", min(years), "-", max(years), ")"),
          "% of 1970 value")

cat("Both pictures are in", output_dir, "\n")
