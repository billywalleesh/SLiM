#combine the 1000 logs of the 50,000 generation burn-in run into one row per run
#for every run:
#  ne_indicator = proportion of populations with Ne below 500, the tick before the disturbance (53999)
#  extinct = TRUE if at least one population went extinct by the end of the run (2025, or earlier if every population died)
#  prop_extinct = proportion of populations that went extinct (continuous version, as a check)
#the logs only have a few ticks: every 5000 ticks of the burn-in, 53999 (before), 54000 (disturbance) and the last tick

## folders
log_folder = "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k"
run_matrix_file = "C:/Users/WilliamWallisch/msc_workspace/SLiM/input/grib_pop_index_local_adaptation/run_repo/14102026/run_matrix_1000.csv"

## find the log files
log_files = list.files(log_folder, pattern = "^run_[0-9]+_log.csv$", full.names = TRUE)
length(log_files) # should be 1000

## read every log, keep all rows (they are small now)
all_logs = data.frame()

for (i in 1:length(log_files)) {
  all_logs = rbind(all_logs, read.csv(log_files[i]))
  if (i %% 100 == 0) print(paste("read", i, "of", length(log_files)))
}

table(all_logs$cycle) # the ticks in the logs


## check the burn-in: did the diversity level off before the disturbance?
#Ne_het_metapop over the burn-in for the first 20 runs, one line per run
burnin = all_logs[all_logs$cycle <= 53999 & all_logs$pop == 0, ]

plot(NULL, xlim = c(0, 54000), ylim = c(0, max(burnin$Ne_het_metapop, na.rm = TRUE)),
     xlab = "tick", ylab = "Ne_het (metapopulation)", main = "burn-in check")
for (r in unique(burnin$run)[1:20]) {
  one = burnin[burnin$run == r, ]
  lines(one$cycle, one$Ne_het_metapop, col = "grey40")
}
abline(v = 8000, col = "red", lty = 2) # where the climate started in the first 1000 runs


## one row per run
run_results = data.frame()

for (r in unique(all_logs$run)) {

  one_run = all_logs[all_logs$run == r, ]

  #the tick before the disturbance and the last tick of this run
  before = one_run[one_run$cycle == 53999, ]
  end = one_run[one_run$cycle == max(one_run$cycle), ]

  #ne indicator: proportion of populations with Ne below 500 before the disturbance
  ne_indicator = mean(before$Ne_inb < 500)

  #extinct: TRUE if at least one population has no individuals left at the end
  extinct = any(end$N == 0)

  #continuous version: proportion of populations that went extinct
  prop_extinct = mean(end$N == 0)

  run_results = rbind(run_results, data.frame(run = r, ne_indicator, extinct, prop_extinct, end_year = end$year[1]))
}

head(run_results)
nrow(run_results)            # should be 1000
table(run_results$extinct)   # how many runs had at least one population go extinct
table(run_results$end_year)  # most runs end in 2025, the others had every population die out earlier


## add the run settings
run_matrix = read.csv(run_matrix_file)
run_matrix = run_matrix[, !(colnames(run_matrix) %in% c("ne_indicator", "extict", "extinct"))] #drop placeholder columns if they are in the file, the real values come from the logs
run_results = merge(run_results, run_matrix, by = "run")
head(run_results)

write.csv(run_results, file.path(log_folder, "run_results_burnin50k.csv"), row.names = FALSE)


## does the ne indicator predict extinction?
#logistic regression, because extinct is TRUE or FALSE
m = glm(extinct ~ ne_indicator, family = binomial, data = run_results)
summary(m)

#how the indicator and extinction look together
boxplot(ne_indicator ~ extinct, data = run_results, xlab = "at least one population extinct", ylab = "ne indicator (proportion of populations below Ne 500)")
