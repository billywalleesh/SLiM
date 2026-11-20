#how much Ne is left after the disturbance, split by every grouping from the EDA
#same idea as 40_plot_ne_remaining_over_time.R: every value is a percentage of the
#same run's value the generation before the disturbance (tick 53999), then averaged
#over the runs in each group
#groups (all set per run, from run_results_burnin50k.csv):
#  disturbance type    0 = individuals removed, 1 = habitat lost
#  K per pop           carrying capacity per deme, 4 groups
#  selection strength  weak / medium / strong
#  migration           from slope_decay, more negative = migration drops faster with distance = less migration
#  n populations       4 to 8 demes
#  pop 5 included      the one site that stood out in the glm with one yes/no column per site
#the measure plotted is Ne_inb_metapop (inbreeding Ne of the whole metapopulation)
#change plot_measure below to "N_pct" or "Ne_het_pct" to plot census N or heterozygosity Ne instead

## folders
log_folder = "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k"
results_file = file.path(log_folder, "run_results_burnin50k.csv")
output_folder = log_folder

## constants
tick_before = 53999  # the generation before the disturbance
tick_disturb = 54000 # the disturbance (1970)
tick_end = 54055     # 2025
plot_measure = "Ne_inb_pct" # which measure the figure shows, used in the figure and the file names

## find the log files
log_files = list.files(log_folder, pattern = "^run_[0-9]+_log.csv$", full.names = TRUE)
length(log_files) # should be 1000

## read every log, only keep the ticks from just before the disturbance to 2025
all_logs = data.frame()

for (i in 1:length(log_files)) {
  one = read.csv(log_files[i])
  one = one[one$cycle >= tick_before, ]
  all_logs = rbind(all_logs, one)
  if (i %% 100 == 0) print(paste("read", i, "of", length(log_files)))
}

head(all_logs)


## one row per run per tick, for the whole metapopulation
ticks = c(tick_before, tick_disturb:tick_end)
meta = data.frame()

for (r in unique(all_logs$run)) {

  one_run = all_logs[all_logs$run == r, ]

  for (t in ticks) {
    one_tick = one_run[one_run$cycle == t, ]

    if (nrow(one_tick) == 0) {
      #the run died out before this tick, so nothing is left
      N = 0
      Ne_inb = 0
      Ne_het = 0
    } else {
      N = sum(one_tick$N)
      Ne_inb = one_tick$Ne_inb_metapop[1]
      Ne_het = one_tick$Ne_het_metapop[1]
    }

    meta = rbind(meta, data.frame(run = r, cycle = t, N, Ne_inb, Ne_het))
  }
}

head(meta)


## percentage of the value before the disturbance, for every run
meta$N_pct = NA
meta$Ne_inb_pct = NA
meta$Ne_het_pct = NA

for (r in unique(meta$run)) {
  rows = meta$run == r
  before = meta[rows & meta$cycle == tick_before, ]

  meta$N_pct[rows] = 100 * meta$N[rows] / before$N
  meta$Ne_inb_pct[rows] = 100 * meta$Ne_inb[rows] / before$Ne_inb
  meta$Ne_het_pct[rows] = 100 * meta$Ne_het[rows] / before$Ne_het
}

colSums(is.na(meta)) # should all be 0


## make the groups, one value per run
run_results = read.csv(results_file)

run_results$dist_group = factor(run_results$disturbance_type, levels = c(0, 1),
                                labels = c("individuals removed", "habitat lost"))

run_results$K_group = cut(run_results$K_per_pop, breaks = c(0, 500, 700, 900, 1300),
                          labels = c("K <= 500", "500-700", "700-900", "> 900"))

run_results$sel_group = cut(run_results$selection_strength, breaks = c(0, 0.04, 0.07, 0.1),
                            labels = c("weak", "medium", "strong"))

run_results$mig_group = cut(run_results$slope_decay,
                            breaks = c(-0.00002, -0.000015, -0.00001, -0.000005),
                            labels = c("less migration", "medium", "more migration"),
                            include.lowest = TRUE)

run_results$npop_group = factor(run_results$n_populations)

#is site 5 one of the populations in this run? pop_ids looks like "0;1;4;5"
site_list = strsplit(run_results$pop_ids, ";")
run_results$pop5_group = factor(sapply(site_list, function(x) "5" %in% x),
                                levels = c(FALSE, TRUE), labels = c("pop 5 not in run", "pop 5 in run"))

#check every group has a sensible number of runs, and no NA
table(run_results$dist_group, useNA = "ifany")
table(run_results$K_group, useNA = "ifany")
table(run_results$sel_group, useNA = "ifany")
table(run_results$mig_group, useNA = "ifany")
table(run_results$npop_group, useNA = "ifany")
table(run_results$pop5_group, useNA = "ifany")

group_cols = c("dist_group", "K_group", "sel_group", "mig_group", "npop_group", "pop5_group")
meta = merge(meta, run_results[, c("run", group_cols)], by = "run")


## x axis in years: put "before" a few years left of 1970 so it is its own point
year_of = function(cycle) {
  ifelse(cycle == tick_before, 1960, 1970 + (cycle - tick_disturb))
}
meta$year = year_of(meta$cycle)


## average per tick for every group, and save the numbers
all_avg = data.frame()

for (g in group_cols) {
  avg_g = aggregate(meta[[plot_measure]], by = list(year = meta$year, group = meta[[g]]), FUN = mean)
  colnames(avg_g)[3] = plot_measure
  avg_g$grouping = g
  all_avg = rbind(all_avg, avg_g)
}

head(all_avg)
write.csv(all_avg, file.path(output_folder, paste0("ne_remaining_by_group_", plot_measure, ".csv")), row.names = FALSE)

#the 2025 value of every group
all_avg[all_avg$year == 2025, ]


## the figure: one panel per grouping, one line per group
panel_titles = c(dist_group = "Disturbance type", K_group = "K per population",
                 sel_group = "Selection strength", mig_group = "Migration",
                 npop_group = "Number of populations", pop5_group = "Site 5 included")

#colours from light to dark, so ordered groups (weak to strong, small to large) read in order
group_colours = function(n) {
  colorRampPalette(c("#F4A582", "#B2182B", "#3B0A0A"))(n)
}

png(file.path(output_folder, paste0("ne_remaining_by_group_", plot_measure, ".png")),
    width = 2100, height = 1300, res = 150)

par(mfrow = c(2, 3), mar = c(4.5, 4.5, 3, 1))

for (g in group_cols) {

  one_grouping = all_avg[all_avg$grouping == g, ]
  levels_g = levels(meta[[g]])
  cols = group_colours(length(levels_g))

  plot(NULL, xlim = c(1958, 2033), ylim = c(0, 105), xaxt = "n", yaxt = "n",
       xlab = "Year", ylab = "Ne remaining (% of pre-disturbance)",
       main = panel_titles[g])
  axis(1, at = 1960, labels = "Pre-Dist")
  axis(1, at = c(1970, 1990, 2010, 2025)) # two calls so R does not drop the 1970 label
  axis(2, at = seq(0, 100, 20), labels = paste0(seq(0, 100, 20), "%"), las = 1)
  abline(v = 1965, lty = 3, col = "grey70") # the disturbance happens here

  for (k in 1:length(levels_g)) {
    one_group = one_grouping[one_grouping$group == levels_g[k], ]
    one_group = one_group[order(one_group$year), ]
    lines(one_group$year, one_group[[plot_measure]], col = cols[k], lwd = 2.5)

    #number at the end of each line (labels can overlap when lines end close together)
    end = one_group[one_group$year == 2025, ]
    text(2026, end[[plot_measure]], paste0(round(end[[plot_measure]]), "%"),
         pos = 4, col = cols[k], cex = 0.75)
  }

  #how many runs are in each group, for the legend
  runs_used = run_results[run_results$run %in% unique(meta$run), ] # only the runs whose logs were read
  n_runs = table(runs_used[[g]])
  legend("bottomleft", bty = "n", lwd = 2.5, col = cols, cex = 0.8,
         legend = paste0(levels_g, " (n = ", n_runs[levels_g], ")"))
}

par(mfrow = c(1, 1))
dev.off() # closes the png file, the figure is only written once this runs


## health in absolute terms: deme size and the Ne 500 indicator over time, by K group
#the % remaining above shows how big a SHARE was lost, not how healthy a run is.
#a run of small demes can keep a big share and still never reach Ne 500.
#so here: the mean deme size, and the proportion of demes above 500, every year
#Ne is taken as census N here, the same as for the indicator in 37.1_combine_burnin50k_results.R
ne_threshold = 500

deme = data.frame()

for (r in unique(all_logs$run)) {

  one_run = all_logs[all_logs$run == r, ]
  n_pop_run = run_results$n_populations[run_results$run == r]

  for (t in ticks) {
    one_tick = one_run[one_run$cycle == t, ]

    if (nrow(one_tick) == 0) {
      #the run died out before this tick: every deme is 0
      mean_N = 0
      indicator = 0
    } else {
      mean_N = sum(one_tick$N) / n_pop_run    # extinct demes count as 0
      indicator = sum(one_tick$N > ne_threshold) / n_pop_run
    }

    deme = rbind(deme, data.frame(run = r, cycle = t, mean_N, indicator))
  }
}

deme = merge(deme, run_results[, c("run", "K_group")], by = "run")
deme$year = year_of(deme$cycle)

avg_deme = aggregate(cbind(mean_N, indicator) ~ year + K_group, data = deme, FUN = mean)
avg_deme[avg_deme$year %in% c(1960, 1970, 2025), ]
write.csv(avg_deme, file.path(output_folder, "deme_size_and_indicator_by_K_group.csv"), row.names = FALSE)

png(file.path(output_folder, "deme_size_and_indicator_by_K_group.png"), width = 1800, height = 750, res = 150)
par(mfrow = c(1, 2), mar = c(4.5, 4.5, 3, 1))

levels_K = levels(run_results$K_group)
cols_K = group_colours(length(levels_K))
runs_used = run_results[run_results$run %in% unique(deme$run), ]
n_runs_K = table(runs_used$K_group)

#left: mean deme size, with the 500 line
plot(NULL, xlim = c(1958, 2033), ylim = c(0, max(avg_deme$mean_N) * 1.05), xaxt = "n",
     xlab = "Year", ylab = "Mean deme size (N, used as Ne)", main = "Deme size by K per population")
axis(1, at = 1960, labels = "Pre-Dist")
axis(1, at = c(1970, 1990, 2010, 2025))
abline(v = 1965, lty = 3, col = "grey70")
abline(h = ne_threshold, lty = 2, col = "grey40")
text(1958, ne_threshold, "Ne 500", pos = 3, cex = 0.75, col = "grey40", adj = 0)

for (k in 1:length(levels_K)) {
  one_group = avg_deme[avg_deme$K_group == levels_K[k], ]
  one_group = one_group[order(one_group$year), ]
  lines(one_group$year, one_group$mean_N, col = cols_K[k], lwd = 2.5)
}
legend("topright", bty = "n", lwd = 2.5, col = cols_K, cex = 0.8,
       legend = paste0(levels_K, " (n = ", n_runs_K[levels_K], ")"))

#right: the Ne 500 indicator, proportion of demes above 500
plot(NULL, xlim = c(1958, 2033), ylim = c(0, 1), xaxt = "n",
     xlab = "Year", ylab = "Proportion of demes with Ne > 500", main = "Ne 500 indicator by K per population")
axis(1, at = 1960, labels = "Pre-Dist")
axis(1, at = c(1970, 1990, 2010, 2025))
abline(v = 1965, lty = 3, col = "grey70")

for (k in 1:length(levels_K)) {
  one_group = avg_deme[avg_deme$K_group == levels_K[k], ]
  one_group = one_group[order(one_group$year), ]
  lines(one_group$year, one_group$indicator, col = cols_K[k], lwd = 2.5)
}

par(mfrow = c(1, 1))
dev.off()
