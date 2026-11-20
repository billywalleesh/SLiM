# Year-by-year plot of the simulated Ne (Ne_inb) next to the field proxy
# (Ne_proxy = 0.1 x N), for the logs in SLiM/results/ramp_v1.3.1_burnin50k
#
# both are per population (the Ne 500 indicator is counted per population)
#   - one line = Ne_inb, mean over every population of every run
#   - one line = Ne_proxy, mean over the same populations
#   - shaded band = the middle 50% of populations (25% to 75%)
#   - dashed line at 500
# all three numbers come straight from the log, nothing is computed except
# means and quantiles. extinct populations count as 0 (Ne_proxy is already
# 0 in the log, Ne_inb is NA there and is set to 0 here).
# runs where every population died out stop early; their missing years
# count as 0 (as in 47_).
#
# note: at 1970 (tick 54000) Ne_inb still comes from the parents BEFORE the
# disturbance, while N (and so the proxy) is already counted after it. in
# populations that were cut down this makes Ne_inb jump far above N (up to
# tens of thousands), which wrecks the mean. so the Ne_inb line skips 1970
# and goes straight from Pre-Dist to 1971. the proxy keeps its 1970 point.
#
# makes these pictures in SLiM/scripts/R/output/49_ne_inb_vs_proxy/:
#   ne_inb_vs_proxy_year_by_year.png          all runs
#   ne_inb_vs_proxy_individuals_removed.png   only runs with disturbance_type 0
#   ne_inb_vs_proxy_habitat_lost.png          only runs with disturbance_type 1
#   ne_inb_vs_proxy_scatter.png               every population: Ne_inb against Ne_proxy
# the log files are only read, nothing in them is changed.

# folder with the log files (change this if your files move)
log_folder <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k"

# the summary file, for the disturbance type of each run
summary_file <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k/run_summary_burnin50k.csv"

# folder for the pictures (created if it does not exist yet)
output_dir <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/scripts/R/output/49_ne_inb_vs_proxy"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# the threshold (dashed line)
threshold <- 500

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
# one row per population (of every run); column 1 = pre-disturbance,
# then one column per year

years <- 1970:2025

# where the pre-disturbance point sits on the x axis
x_pre <- 1962
x <- c(x_pre, years)

inb <- c()      # Ne_inb, will become a matrix (populations x time points)
proxy <- c()    # Ne_proxy
N <- c()        # census N, only printed, not plotted
pop_run <- c()  # which run each row belongs to

for (i in 1:length(log_files)) {

  d <- read.csv(log_files[i])
  pre_cycle <- find_pre_cycle(d)
  pops <- d$pop[d$cycle == pre_cycle]
  cc <- d[d$phase == "climate_change", ]

  for (p in pops) {
    inb_p <- rep(0, length(x))      # 0 stays where the population (or the whole run) is gone
    proxy_p <- rep(0, length(x))
    N_p <- rep(0, length(x))

    # pre-disturbance (column 1)
    row <- d[d$cycle == pre_cycle & d$pop == p, ]
    inb_p[1] <- row$Ne_inb
    proxy_p[1] <- row$Ne_proxy
    N_p[1] <- row$N

    # climate-change years (columns 2 to 57)
    for (y in 1:length(years)) {
      row <- cc[cc$year == years[y] & cc$pop == p, ]
      if (nrow(row) == 0) next
      inb_p[y + 1] <- ifelse(is.na(row$Ne_inb), 0, row$Ne_inb)
      proxy_p[y + 1] <- row$Ne_proxy
      N_p[y + 1] <- row$N
    }

    inb <- rbind(inb, inb_p)
    proxy <- rbind(proxy, proxy_p)
    N <- rbind(N, N_p)
    pop_run <- c(pop_run, d$run[1])
  }

  if (i %% 100 == 0) cat("read", i, "of", length(log_files), "logs\n")
}

dim(inb)   # number of populations x 57 time points

# disturbance type of every population (from its run)
s <- read.csv(summary_file)
pop_type <- s$disturbance_type[match(pop_run, s$run)]
table(pop_type)


# ---------------- How do they compare? ----------------
# mean over all populations at pre-dist, 1970, 1971 and 2025

end <- length(x)
show <- c(1, 2, 3, end)
data.frame(time = c("pre_dist", "1970", "1971", "2025"),
           mean_Ne_inb = round(colMeans(inb)[show]),
           mean_Ne_proxy = round(colMeans(proxy)[show]),
           mean_N = round(colMeans(N)[show]))

# Ne_inb / Ne_proxy for every living population: the proxy assumes 10
alive <- proxy > 0 & inb > 0
ratio <- inb[alive] / proxy[alive]
summary(ratio)

# how many populations are above 500 at pre-dist and in 2025, by each measure
data.frame(time = c("pre_dist", "2025"),
           above_500_Ne_inb = c(sum(inb[, 1] > threshold), sum(inb[, end] > threshold)),
           above_500_Ne_proxy = c(sum(proxy[, 1] > threshold), sum(proxy[, end] > threshold)),
           populations = nrow(inb))


# ---------------- Plotting function ----------------
# keep = which populations (rows) to use
# file_name, title = what goes on the picture

make_plot <- function(keep, file_name, title) {

  a <- inb[keep, , drop = FALSE]
  b <- proxy[keep, , drop = FALSE]

  # Ne_inb leaves out 1970 (column 2), see the note at the top
  xa <- x[-2]
  a <- a[, -2, drop = FALSE]

  # mean and middle 50% for every time point
  a_mean <- colMeans(a)
  b_mean <- colMeans(b)
  a_low <- apply(a, 2, quantile, 0.25)
  a_high <- apply(a, 2, quantile, 0.75)
  b_low <- apply(b, 2, quantile, 0.25)
  b_high <- apply(b, 2, quantile, 0.75)

  png(file.path(output_dir, file_name), width = 2000, height = 1700, res = 250)
  par(mar = c(5, 6, 4, 2))

  y_max <- max(c(a_high, threshold)) * 1.25

  plot(NA, xlim = c(x_pre, max(years) + 10), ylim = c(0, y_max),
       xaxt = "n", las = 1, xlab = "Year", ylab = "Ne per population", main = title)
  axis(1, at = c(x_pre, 1970, 1990, 2010, max(years)),
       labels = c("Pre-Dist", 1970, 1990, 2010, max(years)), gap.axis = 0)
  abline(v = (x_pre + 1970) / 2, col = "grey70", lty = 3)

  # middle 50% bands
  polygon(c(xa, rev(xa)), c(a_low, rev(a_high)), col = adjustcolor(col_inb, alpha.f = 0.2), border = NA)
  polygon(c(x, rev(x)), c(b_low, rev(b_high)), col = adjustcolor(col_proxy, alpha.f = 0.3), border = NA)

  # the means
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
         legend = c("simulated Ne (Ne_inb)", "proxy Ne = 0.1 x N", paste("Ne =", threshold)))
  mtext(paste0("mean over ", nrow(a), " populations, band = middle 50%"), side = 3, line = 0.3, cex = 0.8)

  dev.off()
}

make_plot(1:nrow(inb), "ne_inb_vs_proxy_year_by_year.png",
          "Simulated Ne vs proxy Ne, all runs")
make_plot(which(pop_type == 0), "ne_inb_vs_proxy_individuals_removed.png",
          "Simulated Ne vs proxy Ne, individuals removed")
make_plot(which(pop_type == 1), "ne_inb_vs_proxy_habitat_lost.png",
          "Simulated Ne vs proxy Ne, habitat lost")


# ---------------- Scatter: every population ----------------
# Ne_proxy against Ne_inb, before the disturbance and in 2025
# solid line = the two agree (1:1), dotted line = proxy is exactly 1/10 of Ne_inb,
# dashed lines = 500 for each of them
# a population in the bottom-right corner is above 500 by Ne_inb but
# below 500 by the proxy

png(file.path(output_dir, "ne_inb_vs_proxy_scatter.png"), width = 2800, height = 1500, res = 250)
par(mfrow = c(1, 2), mar = c(5, 5, 3, 1))

lim <- c(0, max(inb[, c(1, end)]) * 1.05)

for (k in c(1, end)) {
  plot(inb[, k], proxy[, k], xlim = lim, ylim = lim, pch = 19, cex = 0.5,
       col = adjustcolor("grey30", alpha.f = 0.4), las = 1,
       xlab = "Simulated Ne (Ne_inb)", ylab = "Proxy Ne = 0.1 x N",
       main = ifelse(k == 1, "Before the disturbance", "2025"))
  abline(0, 1)
  abline(0, 0.1, lty = 3, col = "grey40")
  abline(h = threshold, v = threshold, lty = 2)
  legend("topleft", bty = "n", lty = c(1, 3, 2), col = c("black", "grey40", "black"),
         legend = c("proxy = Ne_inb", "proxy = 0.1 x Ne_inb", "Ne = 500"))
}
dev.off()

cat("Saved the pictures in", output_dir, "\n")
