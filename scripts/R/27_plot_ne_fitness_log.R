# Plot census size (Nc), inbreeding Ne, heterozygosity Ne and mean fitness
# over time for the long-format logs (one row per population per tick)
# written by
#   grib_ramp_v1.2_disturbance.slim  and  grib_continuous_v0.1.slim
#
# Based on 24_plot_ne_log.R. Fitness (red) is on the right y axis.
#
# Makes FOUR pictures in SLiM/scripts/R/output/27_ne_fitness/:
#   Ne_fitness_total_<run>_full.png    metapopulation, whole run
#   Ne_fitness_total_<run>_zoom.png    metapopulation, disturbance + climate change
#   Ne_fitness_by_pop_<run>_full.png   each population, whole run
#   Ne_fitness_by_pop_<run>_zoom.png   each population, disturbance + climate change
# The zoom starts zoom_before generations before the disturbance (or before
# climate change if the run has no disturbance), so every tick is visible.

# Read the data (change this path to where your file is)
log_file <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/v1.2_disturbance/v1.2dist_reduce_kmult0.5_p0123_lag1_seed376928783_log.csv"
d_all <- read.csv(log_file)

# Name for the pictures: the log's file name without "_log.csv"
run_name <- sub("_log\\.csv$", "", basename(log_file))

# How many generations before the disturbance the zoom starts
zoom_before <- 100

# Folder for the pictures (created if it does not exist yet)
output_dir <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/scripts/R/output/27_ne_inbreeding"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)


# ---------------- Where the zoom starts ----------------

disturbance_cycles <- d_all$cycle[d_all$phase == "post_disturbance"]
climate_cycles <- d_all$cycle[d_all$phase == "climate_change"]

if (length(disturbance_cycles) > 0) {
  zoom_start <- min(disturbance_cycles) - zoom_before
} else {
  zoom_start <- min(climate_cycles) - zoom_before
}


# ---------------- Generation -> calendar year ----------------
# in the climate-change phase the "year" column holds the calendar year;
# the last climate year (2025) is always labelled

year_rows <- d_all[d_all$pop == d_all$pop[1] & d_all$phase == "climate_change", ]
year_cycles <- year_rows$cycle
year_values <- as.integer(year_rows$year)
final_year <- max(year_values)

# tick marks: every 10 years plus the final year
tick_years <- unique(c(year_values[year_values %% 10 == 0], final_year))

# year labels on the top axis: years = which years get a number
draw_year_axis <- function(years) {
  axis(3, at = year_cycles[year_values %in% tick_years], labels = FALSE)
  shown <- year_values %in% unique(c(years, final_year))
  axis(3, at = year_cycles[shown], labels = year_values[shown], tick = FALSE,
       gap.axis = 0)
}

# labelled years: every decade on the wide metapopulation plot, every
# 20 years on the narrower population panels (2025 is always added)
years_metapop <- c(1970, 1980, 1990, 2000, 2010)
years_by_pop <- c(1970, 1990, 2010)


# ---------------- Plotting function ----------------
# start_cycle = first generation to draw; label = "full" or "zoom"

make_plots <- function(start_cycle, label) {
  
  d <- d_all[d_all$cycle >= start_cycle, ]
  
  # first generation of each phase (dotted lines), read from the whole log
  # and only drawn if it falls inside the plotted range
  phase_starts <- suppressWarnings(c(
    min(d_all$cycle[d_all$phase == "historical_hold"]),
    min(d_all$cycle[d_all$phase == "climate_change"])
  ))
  phase_starts <- phase_starts[is.finite(phase_starts) & phase_starts > start_cycle]
  
  # the disturbance (dashed dark-red line)
  disturbance <- d$cycle[d$phase == "post_disturbance"]
  
  draw_phases <- function() {
    abline(v = phase_starts, lty = 3)
    if (length(disturbance) > 0)
      abline(v = min(disturbance), lty = 2, col = "darkred")
  }
  
  # thicker lines when zoomed in, so single ticks are easy to follow
  zoomed <- (label == "zoom")
  lw <- if (zoomed) 2.5 else 1.5
  
  # zoomed plots get calendar years on the top axis, so need more room there
  top_margin <- if (zoomed) 5.5 else 4
  title_line <- if (zoomed) 3 else 1.5
  
  legend_labels <- c("census size (Nc)", "inbreeding Ne", "heterozygosity Ne", "mean fitness",
                     "Ne = 500 threshold")
  legend_colours <- c("black", "darkgreen", "cornflowerblue", "red", "grey40")
  legend_types <- c(1, 1, 1, 1, 2)
  
  # legend in one row below the plot(s), so it never covers a line
  draw_legend <- function() {
    par(fig = c(0, 1, 0, 1), oma = c(0, 0, 0, 0), mar = c(0, 0, 0, 0), new = TRUE)
    plot.new()
    legend("bottom", horiz = TRUE, bty = "n", lwd = 2, cex = 0.9,
           col = legend_colours, lty = legend_types, legend = legend_labels,
           text.width = strwidth(legend_labels, cex = 0.9) * 1.1)
  }
  
  
  # ---------- Plot 1: whole metapopulation ----------
  
  # one row per generation for the metapopulation values
  meta <- d[d$pop == d$pop[1], c("cycle", "Ne_inb_metapop", "Ne_het_metapop")]
  
  # metapopulation census size = sum of the populations in each generation
  meta$Nc <- as.numeric(tapply(d$N, d$cycle, sum)[as.character(meta$cycle)])
  
  # metapopulation mean fitness = mean of the populations' mean fitness,
  # weighted by their size (populations with no individuals are left out)
  has_fitness <- !is.na(d$meanFitness) & d$N > 0
  weighted <- tapply(d$meanFitness[has_fitness] * d$N[has_fitness],
                     d$cycle[has_fitness], sum)
  total_N <- tapply(d$N[has_fitness], d$cycle[has_fitness], sum)
  meta$fitness <- as.numeric((weighted / total_N)[as.character(meta$cycle)])
  
  png(file.path(output_dir, paste0("Ne_fitness_total_", run_name, "_", label, ".png")),
      width = 2400, height = 1200, res = 200)
  par(mar = c(5, 5, top_margin, 6), oma = c(2, 0, 0, 0))
  
  # mean fitness (red, right axis)
  plot(meta$cycle, meta$fitness, type = "l", col = "red", lwd = lw,
       ylim = c(0, 1), axes = FALSE, xlab = "", ylab = "")
  axis(4, col = "red", col.axis = "red")
  mtext("Mean fitness", side = 4, line = 3, col = "red")
  
  # Nc and Ne lines on top (left axis)
  par(new = TRUE)
  ne_max <- max(c(meta$Ne_inb_metapop, meta$Ne_het_metapop, meta$Nc), na.rm = TRUE)
  
  plot(meta$cycle, meta$Ne_inb_metapop, type = "l", col = "darkgreen", lwd = lw,
       ylim = c(0, ne_max * 1.05), xlab = "Generation", ylab = "Nc and Ne")
  title(main = "Metapopulation", line = title_line)
  lines(meta$cycle, meta$Ne_het_metapop, col = "cornflowerblue", lwd = lw)
  lines(meta$cycle, meta$Nc, col = "black", lwd = lw)
  abline(h = 500, col = "grey40", lty = 2, lwd = 1.5)   # Ne 500 threshold
  draw_phases()
  if (zoomed) draw_year_axis(years_metapop)
  
  draw_legend()
  dev.off()
  
  
  # ---------- Plot 2: each population ----------
  
  png(file.path(output_dir, paste0("Ne_fitness_by_pop_", run_name, "_", label, ".png")),
      width = 2400, height = 2200, res = 200)
  par(mfrow = c(2, 2), mar = c(5, 5, top_margin, 6), oma = c(2, 0, 0, 0))
  
  # same Nc/Ne axis on all four panels so they can be compared
  pop_ne_max <- max(c(d$Ne_inb, d$Ne_het, d$N), na.rm = TRUE)
  
  for (pop in 0:3) {
    p <- d[d$pop == pop, ]
    
    # mean fitness (red, right axis); NA where the population is gone
    plot(p$cycle, p$meanFitness, type = "l", col = "red", lwd = lw,
         ylim = c(0, 1), axes = FALSE, xlab = "", ylab = "")
    axis(4, col = "red", col.axis = "red")
    mtext("Mean fitness", side = 4, line = 3, col = "red")
    
    # Nc and Ne lines on top (left axis)
    par(new = TRUE)
    plot(p$cycle, p$Ne_inb, type = "l", col = "darkgreen", lwd = lw,
         ylim = c(0, pop_ne_max * 1.05), xlab = "Generation", ylab = "Nc and Ne")
    title(main = paste0("p", pop, " (", p$location[1], ")"), line = title_line)
    lines(p$cycle, p$Ne_het, col = "cornflowerblue", lwd = lw)
    lines(p$cycle, p$N, col = "black", lwd = lw)
    abline(h = 500, col = "grey40", lty = 2, lwd = 1.5)   # Ne 500 threshold
    draw_phases()
    if (zoomed) draw_year_axis(years_by_pop)
  }
  
  draw_legend()
  dev.off()
}


# ---------------- Make the pictures ----------------

make_plots(1, "full")
make_plots(zoom_start, "zoom")

cat("Saved 4 pictures in", output_dir, "\n")