#how much Ne is left after the disturbance, averaged over all runs of the 50,000 generation burn-in
#in the style of the "genetic diversity remaining" figure (WFmoments, loss with time)
#every value is a percentage of the same run's value the generation before the disturbance (tick 53999)
#then the percentages are averaged over all runs
#three measures (all for the whole metapopulation):
#  N               census size, summed over the populations
#  Ne_inb_metapop  inbreeding Ne, follows N quickly
#  Ne_het_metapop  heterozygosity Ne, the genetic diversity, changes slowly

## folders
log_folder = "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k"
results_file = file.path(log_folder, "run_results_burnin50k.csv")

## constants
tick_before = 53999  # the generation before the disturbance
tick_disturb = 54000 # the disturbance (1970)
tick_end = 54055     # 2025

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
nrow(meta) # number of runs x 57 ticks


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

#NA would only come from a missing value in a log, check there are none
colSums(is.na(meta))


## add the disturbance type of every run (0 = individuals removed, 1 = habitat lost)
run_results = read.csv(results_file)
meta = merge(meta, run_results[, c("run", "disturbance_type")], by = "run")


## average over all runs
avg = aggregate(cbind(N_pct, Ne_inb_pct, Ne_het_pct) ~ cycle, data = meta, FUN = mean)
avg

#same, split by disturbance type
avg_type = aggregate(cbind(N_pct, Ne_inb_pct, Ne_het_pct) ~ cycle + disturbance_type, data = meta, FUN = mean)

#the three numbers asked for: before, at the disturbance, 2025
avg[avg$cycle %in% c(tick_before, tick_disturb, tick_end), ]

#save the averages so the figure numbers can be checked later
write.csv(avg, file.path(log_folder, "ne_remaining_avg_all_runs.csv"), row.names = FALSE)
write.csv(avg_type, file.path(log_folder, "ne_remaining_avg_by_type.csv"), row.names = FALSE)

## x axis in years: put "before" a few years left of 1970 so it is its own point
year_of = function(cycle) {
  ifelse(cycle == tick_before, 1960, 1970 + (cycle - tick_disturb))
}
avg$year = year_of(avg$cycle)
avg_type$year = year_of(avg_type$cycle)


## the figure
col_N = "grey50"
col_inb = "firebrick"
col_het = "darkred"

#save the figure as a png in the results folder
png(file.path(log_folder, "ne_remaining_over_time.png"), width = 900, height = 750, res = 150) # one panel for now (was 1600 wide for two)

par(mfrow = c(1, 1), mar = c(5, 5, 3, 1)) # one panel for now, change back to c(1, 2) when plot B is back in

#A: all runs, the three measures
plot(NULL, xlim = c(1958, 2033), ylim = c(0, 105), xaxt = "n", yaxt = "n",
     xlab = "Year", ylab = "N Remaining (% of Population pre-disturbance)",
     main = "Ne decline over all runs")
axis(1, at = 1960, labels = "Pre-Dist")
axis(1, at = c(1970, 1990, 2010, 2025)) # two calls so R does not drop the 1970 label
axis(2, at = seq(0, 100, 20), labels = paste0(seq(0, 100, 20), "%"), las = 1)
abline(v = 1965, lty = 3, col = "grey70") # the disturbance happens here

lines(avg$year, avg$N_pct, col = col_N, lwd = 3)
lines(avg$year, avg$Ne_inb_pct, col = col_inb, lwd = 3)
lines(avg$year, avg$Ne_het_pct, col = col_het, lwd = 3, lty = 2)

#points at before, the disturbance and 2025
key = avg[avg$cycle %in% c(tick_before, tick_disturb, tick_end), ]
points(key$year, key$N_pct, pch = 19, col = col_N)
points(key$year, key$Ne_inb_pct, pch = 19, col = col_inb)
points(key$year, key$Ne_het_pct, pch = 19, col = col_het)

#the percentage in 2025 written next to the end of each line
end = avg[avg$cycle == tick_end, ]
text(2026, end$N_pct - 4, paste0(round(end$N_pct), "%"), pos = 4, col = col_N)
text(2026, end$Ne_inb_pct + 4, paste0(round(end$Ne_inb_pct), "%"), pos = 4, col = col_inb)
text(2026, end$Ne_het_pct, paste0(round(end$Ne_het_pct), "%"), pos = 4, col = col_het)

legend("bottomleft", bty = "n", lwd = 3, lty = c(1, 1, 2),
       col = c(col_N, col_inb, col_het),
       legend = c("census N", "Ne (inbreeding)", "Ne (heterozygosity, diversity)"), cex = 0.8)

#B is commented out for now, uncomment it and set mfrow back to c(1, 2) and the png width to 1600 to bring it back
##B: Ne (inbreeding) by disturbance type, like the -50% / -75% area lines
#plot(NULL, xlim = c(1958, 2033), ylim = c(0, 105), xaxt = "n", yaxt = "n",
#     xlab = "Year", ylab = "N remaining (% of Population pre-disturbance)",
#     main = "Ne by disturbance type")
#axis(1, at = 1960, labels = "Pre-Dist")
#axis(1, at = c(1970, 1990, 2010, 2025)) # two calls so R does not drop the 1970 label
#axis(2, at = seq(0, 100, 20), labels = paste0(seq(0, 100, 20), "%"), las = 1)
#abline(v = 1965, lty = 3, col = "grey70")

#type0 = avg_type[avg_type$disturbance_type == 0, ]
#type1 = avg_type[avg_type$disturbance_type == 1, ]

#lines(type0$year, type0$Ne_inb_pct, col = "firebrick", lwd = 3)
#lines(type1$year, type1$Ne_inb_pct, col = "darkred", lwd = 3, lty = 2)

#end0 = type0[type0$cycle == tick_end, ]
#end1 = type1[type1$cycle == tick_end, ]
#text(2026, end0$Ne_inb_pct + 3, paste0(round(end0$Ne_inb_pct), "%"), pos = 4, col = "firebrick")
#text(2026, end1$Ne_inb_pct - 3, paste0(round(end1$Ne_inb_pct), "%"), pos = 4, col = "darkred")

#legend("bottomleft", bty = "n", lwd = 3, lty = c(1, 2), col = c("firebrick", "darkred"),
#       legend = c("individuals removed (type 0)", "habitat lost (type 1)"), cex = 0.8)

par(mfrow = c(1, 1))
dev.off() # closes the png file, the figure is only written once this runs
