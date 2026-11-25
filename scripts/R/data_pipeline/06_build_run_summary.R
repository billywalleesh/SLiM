#build one summary file for ramp_v1.3.1_burnin50k: one row per run (1000 rows)
#= everything in run_results_burnin50k.csv, plus new columns taken from the run logs
#run this once, then the analysis scripts only need to read the new csv
#run_results_burnin50k.csv itself is not changed
#
#new columns (all for the whole metapopulation, N summed over the demes):
#  n_pre_dist, n_1970, n_2025         census size before the disturbance (tick_before), just after it (tick_disturb), and in 2025 (tick_end)
#                                     (53999, 54000 and 54055 with the 4000-tick ramp, 59999, 60000 and 60055 with the 10,000-tick ramp)
#                                     tick_disturb is logged AFTER the disturbance is applied, so n_1970 already has the hit in it
#  ne_inb_pre_dist, ne_inb_dist, ne_inb_2025
#                                     inbreeding Ne of the metapopulation at the same three ticks
#  ne_het_pre_dist, ne_het_dist, ne_het_2025
#                                     heterozygosity Ne of the metapopulation (genetic diversity) at the same three ticks
#  pct_n_kept_post_dist_2025          % of the post-disturbance n (1970) still there in 2025 = the climate change period only
#                                     (can be above 100 if the run grew back)
#  pct_n_kept_pre_dist_2025           % of the pre-disturbance n still there in 2025 (disturbance + climate change together)
#  pct_ne_het_kept_pre_dist_2025      % of the pre-disturbance diversity Ne still there in 2025
#  pct_K_occupied_pre_dist, pct_K_occupied_2025
#                                     n as % of the run's ORIGINAL total carrying capacity K = how full the habitat is
#                                     (K itself is not reduced here, so habitat-loss runs are compared to their K before the loss)
#a run that died out before 2025 gets 0 for its 2025 values

## folders
log_folder = "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k"
results_file = file.path(log_folder, "run_results_burnin50k.csv")
summary_file = file.path(log_folder, "run_summary_burnin50k.csv")

## constants
#the ticks depend on how long the ramp is in the model that made the logs:
#  ramp_v1.3.1_burnin50k.slim (batches 1 to 4):          ramp_length = 4000  -> ticks 53999, 54000, 54055
#  ramp_v1.3.1_burnin50k_ramp10k.slim (10,000-tick ramp): ramp_length = 10000 -> ticks 59999, 60000, 60055
ramp_length = 4000
burnin_length = 50000 # the same in both models
tick_disturb = ramp_length + burnin_length # the disturbance (1970), logged after it is applied
tick_before = tick_disturb - 1                # the generation before the disturbance
tick_end = tick_disturb + 55                  # 2025

## find the log files
log_files = list.files(log_folder, pattern = "^run_[0-9]+_log.csv$", full.names = TRUE)
length(log_files) # should be 1000

## one row per run from the logs
from_logs = data.frame()

for (i in 1:length(log_files)) {

  one = read.csv(log_files[i])
  r = one$run[1]

  pre = one[one$cycle == tick_before, ]
  dist = one[one$cycle == tick_disturb, ]
  end = one[one$cycle == tick_end, ]

  n_pre_dist = sum(pre$N)
  n_1970 = sum(dist$N)
  n_2025 = sum(end$N) # sum of nothing is 0, so a run that died out gets 0

  ne_inb_pre_dist = pre$Ne_inb_metapop[1]
  ne_inb_dist = dist$Ne_inb_metapop[1]
  ne_het_pre_dist = pre$Ne_het_metapop[1]
  ne_het_dist = dist$Ne_het_metapop[1]

  if (nrow(end) == 0) {
    ne_inb_2025 = 0
    ne_het_2025 = 0
  } else {
    ne_inb_2025 = end$Ne_inb_metapop[1]
    ne_het_2025 = end$Ne_het_metapop[1]
  }

  from_logs = rbind(from_logs, data.frame(run = r, n_pre_dist, n_1970, n_2025,
                                          ne_inb_pre_dist, ne_inb_dist, ne_inb_2025,
                                          ne_het_pre_dist, ne_het_dist, ne_het_2025))

  if (i %% 100 == 0) print(paste("read", i, "of", length(log_files)))
}

head(from_logs)
colSums(is.na(from_logs)) # should all be 0


## add to the run results
run_results = read.csv(results_file)
s = merge(run_results, from_logs, by = "run")
nrow(s) # should be 1000

## the new percentage columns
s$pct_n_kept_post_dist_2025 = 100 * s$n_2025 / s$n_1970
s$pct_n_kept_pre_dist_2025 = 100 * s$n_2025 / s$n_pre_dist
s$pct_ne_het_kept_pre_dist_2025 = 100 * s$ne_het_2025 / s$ne_het_pre_dist

#K is the run's total carrying capacity before any habitat loss
#(K_per_pop is just K / n_populations, so a "per pop" version would give the same %)
s$pct_K_occupied_pre_dist = 100 * s$n_pre_dist / s$K
s$pct_K_occupied_2025 = 100 * s$n_2025 / s$K

summary(s[, c("pct_n_kept_post_dist_2025", "pct_n_kept_pre_dist_2025", "pct_ne_het_kept_pre_dist_2025",
              "pct_K_occupied_pre_dist", "pct_K_occupied_2025")])

## save
write.csv(s, summary_file, row.names = FALSE)
print(paste("saved", nrow(s), "runs to", summary_file))
