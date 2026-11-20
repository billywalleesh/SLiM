# Plot census size (Nc), inbreeding Ne, heterozygosity Ne and mean fitness
# over time for the long-format logs (one row per population per tick)
# written by
#   grib_ramp_v1.2_disturbance.slim, grib_continuous_v0.1.slim,
#   ramp_v1.3.1_cluster.slim  and  ramp_v1.3.1_burnin50k.slim
#
# Based on 24_plot_ne_log.R. Fitness (red) is on the right y axis.
#
# Works for any of these logs: any number of populations (1 to 8 or more),
# any logged ticks (every tick, or sparse burn-in ticks), with or without a
# disturbance. Give it one or several runs (see "Which runs to plot").
#
# Makes FOUR pictures per run in SLiM/scripts/R/output/27_ne_inbreeding/<log folder>/:
#   Ne_fitness_total_<run>_full.png    metapopulation, whole run
#   Ne_fitness_total_<run>_zoom.png    metapopulation, disturbance + climate change
#   Ne_fitness_by_pop_<run>_full.png   each population, whole run
#   Ne_fitness_by_pop_<run>_zoom.png   each population, disturbance + climate change
# The zoom starts zoom_before generations before the disturbance (or before
# climate change if the run has no disturbance).
#
# Where the disturbance is (dashed dark-red line), in this order:
#   1. the first tick of the "post_disturbance" phase (older logs)
#   2. the first tick where a population's K changes (habitat runs)
#   3. the run matrix says this run was disturbed: the first climate-change
#      tick (the burn-in model disturbs at TclimateChange, disturbanceLag = 0)


# ---------------- Which runs to plot ----------------

# Folder with the logs, and the run numbers to plot
log_folder <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k"
runs <- c(902)

# The run numbers can also be given from the terminal:
#   Rscript 27_plot_ne_fitness_log.R 1 56 99
args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0) runs <- as.integer(args)

log_files <- file.path(log_folder, paste0("run_", runs, "_log.csv"))

# Or plot any log file directly (this replaces the runs above), e.g.
# log_files <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k/run_902_log.csv"

# Run matrix of the experiment the logs come from, for the titles and the
# disturbance. Set to NULL for logs that do not come from a run matrix.
run_matrix_file <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/input/grib_pop_index_local_adaptation/run_repo/14102026/run_matrix_1000.csv"

# How many generations before the disturbance the zoom starts
zoom_before <- 100

# Folder for the pictures: one subfolder per log folder, so run_1 of one
# experiment does not overwrite run_1 of another
output_dir <- file.path("C:/Users/WilliamWallisch/msc_workspace/SLiM/scripts/R/output/27_ne_inbreeding",
                        basename(dirname(log_files[1])))
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# City names of the city numbers in the logs and the run matrix
city_names <- c("Geneva", "Lausanne", "Neuchatel", "Bern", "Solothurn", "Lucerne", "Winterthur", "St. Gallen")

# labelled years: every decade on the wide metapopulation plot, every
# 20 years on the narrower population panels (the final year is always added)
years_metapop <- c(1970, 1980, 1990, 2000, 2010)
years_by_pop <- c(1970, 1990, 2010)

run_matrix <- NULL
if (!is.null(run_matrix_file) && file.exists(run_matrix_file))
  run_matrix <- read.csv(run_matrix_file)


# ---------------- One run ----------------

plot_log <- function(log_file) {

  d_all <- read.csv(log_file)

  # Name for the pictures: the log's file name without "_log.csv"
  run_name <- sub("_log\\.csv$", "", basename(log_file))

  # the populations in this log, in order
  pops <- sort(unique(d_all$pop))
  n_pops <- length(pops)
  first_pop <- pops[1]


  # ---------- This run's row of the run matrix ----------
  # only used if the log has a run column and its cities match pop_ids
  # (a log from another experiment can have the same run number)

  settings <- NULL
  if (!is.null(run_matrix) && "run" %in% names(d_all)) {
    row <- run_matrix[run_matrix$run == d_all$run[1], ]
    if (nrow(row) == 1) {
      matrix_cities <- as.integer(strsplit(as.character(row$pop_ids), ";")[[1]])
      log_cities <- d_all$city[d_all$cycle == min(d_all$cycle)]
      if ("city" %in% names(d_all) && setequal(matrix_cities, log_cities)) {
        settings <- row
      } else {
        cat("  ", run_name, ": the cities do not match the run matrix, so it is not used\n")
      }
    }
  }

  targeted_cities <- integer(0)
  if (!is.null(settings) && !is.na(settings$target_pops) && settings$target_pops != "")
    targeted_cities <- as.integer(strsplit(as.character(settings$target_pops), ";")[[1]])


  # ---------- Panel title of each population ----------

  pop_titles <- paste0("p", pops)
  if ("city" %in% names(d_all)) {
    pop_city <- d_all$city[match(pops, d_all$pop)]
    pop_titles <- paste0("p", pops, " ", city_names[pop_city + 1])
    pop_titles[pop_city %in% targeted_cities] <- paste(pop_titles[pop_city %in% targeted_cities], "(targeted)")
  }

  # line under the main title with the run settings
  if (!is.null(settings)) {
    run_subtitle <- paste0(run_name, " | K per pop ", settings$K_per_pop,
                           " | selection ", signif(settings$selection_strength, 2),
                           " | survival ", signif(settings$D_inds, 2),
                           " | habitat ", signif(settings$D_habitat, 2))
  } else {
    run_subtitle <- run_name
  }


  # ---------- Where the disturbance and climate change start ----------

  climate_cycles <- d_all$cycle[d_all$phase == "climate_change"]
  climate_start <- if (length(climate_cycles) > 0) min(climate_cycles) else NA

  disturbance_start <- NA
  if (any(d_all$phase == "post_disturbance")) {
    #1. older logs have their own phase
    disturbance_start <- min(d_all$cycle[d_all$phase == "post_disturbance"])
  } else {
    #2. the first tick where any population's K changes
    for (pop in pops) {
      p <- d_all[d_all$pop == pop, ]
      p <- p[order(p$cycle), ]
      changed <- which(p$K != p$K[1])
      if (length(changed) > 0)
        disturbance_start <- min(disturbance_start, p$cycle[changed[1]], na.rm = TRUE)
    }
    #3. individuals killed but K unchanged: use the run matrix
    if (is.na(disturbance_start) && !is.null(settings) && length(targeted_cities) > 0 &&
        (settings$D_inds < 1 || settings$D_habitat < 1))
      disturbance_start <- climate_start
  }

  # the zoom starts zoom_before generations before the disturbance (or the
  # climate change). If no tick is logged in that window (sparse burn-in logs),
  # it starts at the last logged tick before the disturbance instead
  zoom_target <- if (!is.na(disturbance_start)) disturbance_start else climate_start
  zoom_start <- NA
  if (!is.na(zoom_target)) {
    zoom_start <- zoom_target - zoom_before
    if (!any(d_all$cycle >= zoom_start & d_all$cycle < zoom_target)) {
      logged_before <- d_all$cycle[d_all$cycle < zoom_target]
      if (length(logged_before) > 0) zoom_start <- max(logged_before)
    }
  }


  # ---------- Generation -> calendar year ----------
  # in the climate-change phase the "year" column holds the calendar year

  year_rows <- d_all[d_all$pop == first_pop & d_all$phase == "climate_change", ]
  year_cycles <- year_rows$cycle
  year_values <- suppressWarnings(as.integer(year_rows$year))
  has_years <- length(year_values) > 0 && !all(is.na(year_values))

  if (has_years) {
    final_year <- max(year_values, na.rm = TRUE)
    # tick marks: every 10 years plus the final year
    tick_years <- unique(c(year_values[year_values %% 10 == 0], final_year))
  }

  # year labels on the top axis: years = which years get a number
  draw_year_axis <- function(years) {
    if (!has_years) return(invisible())
    axis(3, at = year_cycles[year_values %in% tick_years], labels = FALSE)
    shown <- year_values %in% unique(c(years, final_year))
    axis(3, at = year_cycles[shown], labels = year_values[shown], tick = FALSE,
         gap.axis = 0)
  }


  # ---------- Plotting function ----------
  # start_cycle = first generation to draw; label = "full" or "zoom"

  make_plots <- function(start_cycle, label) {

    d <- d_all[d_all$cycle >= start_cycle, ]
    d <- d[order(d$cycle), ]

    # first generation of each phase (dotted lines), read from the whole log
    # and only drawn if it falls inside the plotted range
    phase_starts <- suppressWarnings(c(
      min(d_all$cycle[d_all$phase == "historical_hold"]),
      climate_start
    ))
    phase_starts <- phase_starts[is.finite(phase_starts) & phase_starts > start_cycle]

    draw_phases <- function() {
      abline(v = phase_starts, lty = 3)
      if (!is.na(disturbance_start))
        abline(v = disturbance_start, lty = 2, col = "darkred")
    }

    # thicker lines when zoomed in, so single ticks are easy to follow
    zoomed <- (label == "zoom")
    lw <- if (zoomed) 2.5 else 1.5

    # zoomed plots get calendar years on the top axis, so need more room there
    top_margin <- if (zoomed && has_years) 5.5 else 4
    title_line <- if (zoomed && has_years) 3 else 1.5

    legend_labels <- c("census size (Nc)", "inbreeding Ne", "heterozygosity Ne", "mean fitness",
                       "Ne = 500 threshold", "disturbance")
    legend_colours <- c("black", "darkgreen", "cornflowerblue", "red", "grey40", "darkred")
    legend_types <- c(1, 1, 1, 1, 2, 2)

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
    meta <- d[d$pop == first_pop, c("cycle", "Ne_inb_metapop", "Ne_het_metapop")]

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
    par(mar = c(5, 5, top_margin, 6), oma = c(2, 0, 2, 0))

    # mean fitness (red, right axis)
    plot(meta$cycle, meta$fitness, type = "l", col = "red", lwd = lw,
         ylim = c(0, 1), axes = FALSE, xlab = "", ylab = "")
    axis(4, col = "red", col.axis = "red")
    mtext("Mean fitness", side = 4, line = 3, col = "red")

    # Nc and Ne lines on top (left axis)
    par(new = TRUE)
    ne_max <- max(c(meta$Ne_inb_metapop, meta$Ne_het_metapop, meta$Nc, 1), na.rm = TRUE)

    plot(meta$cycle, meta$Ne_inb_metapop, type = "l", col = "darkgreen", lwd = lw,
         ylim = c(0, ne_max * 1.05), xlab = "Generation", ylab = "Nc and Ne")
    title(main = "Metapopulation", line = title_line)
    mtext(run_subtitle, side = 3, outer = TRUE, line = 0.5, cex = 0.9)
    lines(meta$cycle, meta$Ne_het_metapop, col = "cornflowerblue", lwd = lw)
    lines(meta$cycle, meta$Nc, col = "black", lwd = lw)
    abline(h = 500, col = "grey40", lty = 2, lwd = 1.5)   # Ne 500 threshold
    draw_phases()
    if (zoomed) draw_year_axis(years_metapop)

    draw_legend()
    dev.off()


    # ---------- Plot 2: each population ----------

    # as many panels as populations: 4 pops = 2 x 2, 6 = 3 x 2, 8 = 3 x 3
    n_cols <- ceiling(sqrt(n_pops))
    n_rows <- ceiling(n_pops / n_cols)

    png(file.path(output_dir, paste0("Ne_fitness_by_pop_", run_name, "_", label, ".png")),
        width = 1200 * n_cols, height = 1050 * n_rows + 200, res = 200)
    par(mfrow = c(n_rows, n_cols), mar = c(5, 5, top_margin, 6), oma = c(2, 0, 2, 0))

    # same Nc/Ne axis on all panels so they can be compared
    pop_ne_max <- max(c(d$Ne_inb, d$Ne_het, d$N, 1), na.rm = TRUE)

    for (i in 1:n_pops) {
      p <- d[d$pop == pops[i], ]

      # mean fitness (red, right axis); NA where the population is gone
      plot(p$cycle, p$meanFitness, type = "l", col = "red", lwd = lw,
           ylim = c(0, 1), axes = FALSE, xlab = "", ylab = "")
      axis(4, col = "red", col.axis = "red")
      mtext("Mean fitness", side = 4, line = 3, col = "red")

      # Nc and Ne lines on top (left axis)
      par(new = TRUE)
      plot(p$cycle, p$Ne_inb, type = "l", col = "darkgreen", lwd = lw,
           ylim = c(0, pop_ne_max * 1.05), xlab = "Generation", ylab = "Nc and Ne")
      title(main = pop_titles[i], line = title_line)
      lines(p$cycle, p$Ne_het, col = "cornflowerblue", lwd = lw)
      lines(p$cycle, p$N, col = "black", lwd = lw)
      abline(h = 500, col = "grey40", lty = 2, lwd = 1.5)   # Ne 500 threshold
      draw_phases()
      if (zoomed) draw_year_axis(years_by_pop)
    }
    mtext(run_subtitle, side = 3, outer = TRUE, line = 0.5, cex = 0.9)

    draw_legend()
    dev.off()
  }


  # ---------- Make the pictures ----------

  make_plots(min(d_all$cycle), "full")
  if (!is.na(zoom_start)) make_plots(zoom_start, "zoom")

  cat("  ", run_name, ":", n_pops, "populations, disturbance at",
      ifelse(is.na(disturbance_start), "none", disturbance_start), "\n")
}


# ---------------- Plot every run ----------------

for (log_file in log_files) {
  if (!file.exists(log_file)) {
    cat("  not found:", log_file, "\n")
    next
  }
  plot_log(log_file)
}

cat("Saved the pictures in", output_dir, "\n")
