# Year-by-year plot of the WHOLE run (all its populations together) instead of
# each population: simulated metapopulation Ne against the proxy, one line per
# run, for the logs in SLiM/results/ramp_v1.3.1_burnin50k
#
#   - simulated Ne = Ne_inb_metapop from the log (inbreeding Ne of the whole
#     metapopulation, from the pedigree). this is used instead of adding up
#     the Ne_inb of the populations, because Ne cannot simply be added up
#     (Hoban et al. 2020, Box 2)
#   - proxy Ne = 0.1 x total N of the run (all populations added up)
#   - thin lines = one per run, thick lines = mean over runs
#   - dashed line at 500
# runs where every population died out stop early; their missing years count
# as 0 (as in 47_).
#
# note: at 1970 (tick 54000) Ne_inb_metapop still comes from the parents
# BEFORE the disturbance, while N is counted after it, so the simulated Ne
# line skips 1970 and goes straight from Pre-Dist to 1971 (as in 49_).
#
# makes these files in SLiM/scripts/R/output/50_metapop_ne_vs_proxy/:
#   metapop_ne_vs_proxy_year_by_year.png          all runs
#   metapop_ne_vs_proxy_individuals_removed.png   only runs with disturbance_type 0
#   metapop_ne_vs_proxy_habitat_lost.png          only runs with disturbance_type 1
#   metapop_ne_vs_proxy_year_by_year.csv          both values for every run and time point
# the log files are only read, nothing in them is changed.

# folder with the log files (change this if your files move)
log_folder <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k"

# the summary file, for the disturbance type of each run
summary_file <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k/run_summary_burnin50k.csv"

# folder for the pictures (created if it does not exist yet)
output_dir <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/scripts/R/output/50_metapop_ne_vs_proxy"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# the threshold (dashed line)
threshold <- 500

# the proxy: Ne = proxy_ratio x N (the same 0.1 the Ne_proxy column in the log uses)
proxy_ratio <- 0.1

# colours, used in every picture
col_inb <- "#2a78d6"
col_proxy <- "#eda100"


# ---------------- Find the log files ----------------

log_files <- list.files(log_folder, pattern = "^run_[0-9]+_log\\.csv$", full.names = TRUE)
length(log_files)   # should be 1000

if (length(log_files) == 0) stop("no log files found in ", log_folder)


# ---------------- Which tick is "before the disturbance" ----------------
# same as in 47_: the last logged tick before climate change starts

find_pre_cycle <- function(d) {
  first_climate_cycle <- min(d$cycle[d$phase == "climate_change"])
  before <- d[d$cycle < first_climate_cycle & d$phase != "post_disturbance", ]
  max(before$cycle)
}


# ---------------- Read every log ----------------
# one row per run; column 1 = pre-disturbance, then one column per year

years <- 1970:2025

# where the pre-disturbance point sits on the x axis
x_pre <- 1962
x <- c(x_pre, years)

ne_meta <- matrix(0, nrow = length(log_files), ncol = length(x))   # 0 stays where the run is gone
proxy <- matrix(0, nrow = length(log_files), ncol = length(x))
runs <- rep(NA, length(log_files))

for (i in 1:length(log_files)) {

  d <- read.csv(log_files[i])
  runs[i] <- d$run[1]

  # pre-disturbance (column 1)
  # Ne_inb_metapop is the same on every row of a tick, so take the first one
  rows <- d[d$cycle == find_pre_cycle(d), ]
  ne_meta[i, 1] <- rows$Ne_inb_metapop[1]
  proxy[i, 1] <- proxy_ratio * sum(rows$N)

  # climate-change years (columns 2 to 57)
  cc <- d[d$phase == "climate_change", ]

  for (y in 1:length(years)) {
    rows <- cc[cc$year == years[y], ]
    if (nrow(rows) == 0) next
    ne_meta[i, y + 1] <- ifelse(is.na(rows$Ne_inb_metapop[1]), 0, rows$Ne_inb_metapop[1])
    proxy[i, y + 1] <- proxy_ratio * sum(rows$N)
  }

  if (i %% 100 == 0) cat("read", i, "of", length(log_files), "logs\n")
}

# Ne_inb_metapop at 1970 is from the parents before the disturbance (see the top)
ne_meta[, 2] <- NA

# disturbance type of every run
s <- read.csv(summary_file)
run_type <- s$disturbance_type[match(runs, s$run)]
table(run_type)


# ---------------- How do they compare? ----------------

end <- length(x)
show <- c(1, 3, end)

# mean over runs at pre-dist, 1971 and 2025
data.frame(time = c("pre_dist", "1971", "2025"),
           mean_Ne_inb_metapop = round(colMeans(ne_meta)[show]),
           mean_proxy = round(colMeans(proxy)[show]))

# Ne_inb_metapop / proxy for every run still alive: the proxy assumes 10
alive <- !is.na(ne_meta) & proxy > 0 & ne_meta > 0
summary(ne_meta[alive] / proxy[alive])

# how many runs are above 500 (the run-level Ne 500 indicator)
data.frame(time = c("pre_dist", "1971", "2025"),
           runs_above_500_Ne_inb_metapop = colSums(ne_meta > threshold)[show],
           runs_above_500_proxy = colSums(proxy > threshold)[show],
           runs = length(runs))

# save both values for every run (one row per run and measure)
out <- rbind(data.frame(run = runs, measure = "Ne_inb_metapop", ne_meta),
             data.frame(run = runs, measure = "proxy_0.1_total_N", proxy))
names(out) <- c("run", "measure", "pre_dist", years)
write.csv(out, file.path(output_dir, "metapop_ne_vs_proxy_year_by_year.csv"), row.names = FALSE)


# ---------------- Plotting function ----------------
# keep = which runs (rows) to use
# file_name, title = what goes on the picture

make_plot <- function(keep, file_name, title) {

  # simulated Ne without 1970
  xa <- x[-2]
  a <- ne_meta[keep, -2, drop = FALSE]
  b <- proxy[keep, , drop = FALSE]
  a_mean <- colMeans(a)
  b_mean <- colMeans(b)

  png(file.path(output_dir, file_name), width = 2000, height = 1700, res = 250)
  par(mar = c(5, 6, 4, 2))

  y_max <- max(a) * 1.15

  plot(NA, xlim = c(x_pre, max(years) + 12), ylim = c(0, y_max),
       xaxt = "n", las = 1, xlab = "Year", ylab = "Ne of the whole run", main = title)
  axis(1, at = c(x_pre, 1970, 1990, 2010, max(years)),
       labels = c("Pre-Dist", 1970, 1990, 2010, max(years)), gap.axis = 0)
  abline(v = (x_pre + 1970) / 2, col = "grey70", lty = 3)

  # one line per run, very light so the crowd shows up as a cloud
  # (make alpha.f smaller if the cloud is too dark, bigger if too faint)
  for (r in 1:nrow(a)) {
    lines(xa, a[r, ], col = adjustcolor(col_inb, alpha.f = 0.06))
    lines(x, b[r, ], col = adjustcolor(col_proxy, alpha.f = 0.06))
  }

  # the means on top
  lines(xa, a_mean, col = col_inb, lwd = 3)
  lines(x, b_mean, col = col_proxy, lwd = 3)

  # the threshold
  abline(h = threshold, lty = 2, lwd = 2)

  # numbers at the start and the end
  text(x_pre, a_mean[1], round(a_mean[1]), col = col_inb, pos = 2, xpd = TRUE)
  text(x_pre, b_mean[1], round(b_mean[1]), col = col_proxy, pos = 2, xpd = TRUE)
  text(max(years) + 1.5, a_mean[length(a_mean)], round(a_mean[length(a_mean)]), col = col_inb, adj = 0)
  text(max(years) + 1.5, b_mean[end], round(b_mean[end]), col = col_proxy, adj = 0)

  legend("topright", bty = "n", lwd = c(3, 3, 2), lty = c(1, 1, 2),
         col = c(col_inb, col_proxy, "black"),
         legend = c("simulated Ne (Ne_inb_metapop)",
                    paste0("proxy Ne = ", proxy_ratio, " x total N"),
                    paste("Ne =", threshold)))
  mtext(paste0(nrow(a), " runs: thin lines = one per run, thick lines = mean"),
        side = 3, line = 0.3, cex = 0.8)

  dev.off()
}

make_plot(1:length(runs), "metapop_ne_vs_proxy_year_by_year.png",
          "Whole-run Ne vs proxy, all runs")
make_plot(which(run_type == 0), "metapop_ne_vs_proxy_individuals_removed.png",
          "Whole-run Ne vs proxy, individuals removed")
make_plot(which(run_type == 1), "metapop_ne_vs_proxy_habitat_lost.png",
          "Whole-run Ne vs proxy, habitat lost")

cat("Saved the pictures in", output_dir, "\n")
