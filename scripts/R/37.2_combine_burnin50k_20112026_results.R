#combine the 1000 logs of the 50,000 generation burn-in run into one row per run
#for every run:
#  the Ne indicator at three times: proportion of populations with Ne above 500
#  (the GBF Ne 500 indicator: 1 = every population is above 500, 0 = none are)
#  Ne is taken as census N for now: mating is random and reproduction is Poisson
#  (fecunditySkewSD = 0), so Ne is close to N (Ne_inb / N is about 1)
#    ne_indicator_pre_dist   tick 53999, the generation before the disturbance
#    ne_indicator_dist       tick 54000 (1970), right after the disturbance
#    ne_indicator_post_dist  the last tick of the run (2025)
#  extinct = TRUE only if EVERY population of the run is gone by the end (the whole metapopulation / species is extinct)
#            (changed 25.11.2026 after talking to my supervisor, before it meant at least one population was gone)
#  any_pop_extinct = TRUE if at least one population went extinct by the end (the old definition, kept as a check)
#  prop_extinct = proportion of populations that went extinct (continuous version, as a check)
#the logs only have a few ticks: every 100 ticks of the ramp, every 1000 ticks of the burn-in,
#53999 (before), 54000 (disturbance, 1970) and every year to 2025

## folders
log_folder = "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k_20112026"
run_matrix_file = "C:/Users/WilliamWallisch/msc_workspace/SLiM/input/grib_pop_index_local_adaptation/run_repo_20112026/run_matrix_1000.csv"

## constants
tick_before = 53999  # the generation before the disturbance
tick_disturb = 54000 # the disturbance (1970) and the start of the climate change, logged after the cull
ne_threshold = 500

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
burnin = all_logs[all_logs$cycle <= tick_before & all_logs$pop == 0, ]

plot(NULL, xlim = c(0, tick_disturb), ylim = c(0, max(burnin$Ne_het_metapop, na.rm = TRUE)),
     xlab = "tick", ylab = "Ne_het (metapopulation)", main = "burn-in check")
for (r in unique(burnin$run)[1:20]) {
  one = burnin[burnin$run == r, ]
  lines(one$cycle, one$Ne_het_metapop, col = "grey40")
}
abline(v = tick_disturb, col = "red", lty = 2) # where the disturbance and the climate change start


## the Ne indicator: proportion of populations with Ne (here N) above the threshold
ne_indicator = function(ne) {
  mean(ne > ne_threshold)
}


## one row per run
run_results = data.frame()

for (r in unique(all_logs$run)) {
  
  one_run = all_logs[all_logs$run == r, ]
  
  #the tick before the disturbance, the disturbance tick and the last tick of this run
  before = one_run[one_run$cycle == tick_before, ]
  disturb = one_run[one_run$cycle == tick_disturb, ]
  end = one_run[one_run$cycle == max(one_run$cycle), ]
  
  #ne indicator at the three times, with N as Ne
  ne_indicator_pre_dist = ne_indicator(before$N)
  ne_indicator_dist = ne_indicator(disturb$N)
  ne_indicator_post_dist = ne_indicator(end$N)
  
  #extinct: TRUE only if every population has no individuals left at the end = the whole metapopulation is gone
  extinct = all(end$N == 0)
  
  #the old definition, kept as a check: TRUE if at least one population has no individuals left at the end
  any_pop_extinct = any(end$N == 0)
  
  #continuous version: proportion of populations that went extinct
  prop_extinct = mean(end$N == 0)
  
  run_results = rbind(run_results, data.frame(run = r, ne_indicator_pre_dist, ne_indicator_dist,
                                              ne_indicator_post_dist, extinct, any_pop_extinct, prop_extinct,
                                              end_year = end$year[1]))
}

head(run_results)
nrow(run_results)            # should be 1000
table(run_results$extinct)   # how many runs lost the whole metapopulation
table(run_results$any_pop_extinct) # how many runs lost at least one population (old definition)
table(run_results$end_year)  # most runs end in 2025, the others had every population die out earlier

#how the indicator changes over time
summary(run_results[, c("ne_indicator_pre_dist", "ne_indicator_dist", "ne_indicator_post_dist")])


## add the run settings
run_matrix = read.csv(run_matrix_file)
run_matrix = run_matrix[, !(colnames(run_matrix) %in% c("ne_indicator", "extict", "extinct"))] #drop placeholder columns if they are in the file, the real values come from the logs
run_results = merge(run_results, run_matrix, by = "run")
head(run_results)

write.csv(run_results, file.path(log_folder, "run_results_burnin50k_20112026.csv"), row.names = FALSE)


## does the ne indicator predict extinction?
#logistic regression, because extinct is TRUE or FALSE
#expect a negative slope if more populations above Ne 500 means less extinction
m = glm(extinct ~ ne_indicator_pre_dist, family = binomial, data = run_results)
summary(m)

#how the indicator and extinction look together
boxplot(ne_indicator_pre_dist ~ extinct, data = run_results, xlab = "metapopulation extinct", ylab = "ne indicator before the disturbance (proportion of populations above Ne 500)")

#the indicator at the three times, one line per run (first 100 runs)
plot(NULL, xlim = c(1, 3), ylim = c(0, 1), xaxt = "n",
     xlab = "", ylab = "ne indicator (proportion of populations above Ne 500)", main = "indicator over time")
axis(1, at = 1:3, labels = c("before (53999)", "disturbance (1970)", "end (2025)"))
for (i in 1:min(100, nrow(run_results))) {
  lines(1:3, jitter(unlist(run_results[i, c("ne_indicator_pre_dist", "ne_indicator_dist", "ne_indicator_post_dist")]), amount = 0.01),
        col = ifelse(run_results$extinct[i], "red", "grey40"))
}
