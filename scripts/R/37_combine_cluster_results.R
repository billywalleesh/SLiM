#combine the 1000 cluster logs into one table for the analysis
#one row per population per run, with:
#  the values just before the disturbance and climate change (tick 7999)
#  the values at the end of the run (2025, or earlier if every population went extinct)
#  all the run settings from run_matrix_1000.csv

## folders
log_folder = "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_cluster"
run_matrix_file = "C:/Users/WilliamWallisch/msc_workspace/SLiM/input/grib_pop_index_local_adaptation/run_repo/14102026/run_matrix_1000.csv"

## find the log files
log_files = list.files(log_folder, pattern = "^run_[0-9]+_log.csv$", full.names = TRUE)
length(log_files) # should be 1000

## read every log and keep two moments
before_list = list()
end_list = list()

for (i in 1:length(log_files)) {

  one_run = read.csv(log_files[i])

  # just before the disturbance and climate change
  before_list[[i]] = one_run[one_run$cycle == 7999, ]

  # the last tick of the run (2025, or the tick everything went extinct)
  end_list[[i]] = one_run[one_run$cycle == max(one_run$cycle), ]

  if (i %% 100 == 0) print(paste("read", i, "of", length(log_files)))
}

before = do.call(rbind, before_list)
end = do.call(rbind, end_list)

## checks: every run should be there once
length(unique(before$run)) # should be 1000
length(unique(end$run))    # should be 1000
table(end$year)            # most runs end in 2025; the others went extinct earlier

## keep the columns we need and give them clear names
before = before[, c("run", "pop", "city", "N", "Ne_het", "Ne_inb", "Ne_inb_metapop", "meanFitness", "varPheno")]
colnames(before) = c("run", "pop", "city", "N_before", "Ne_het_before", "Ne_inb_before", "Ne_inb_metapop_before", "fitness_before", "varPheno_before")

end = end[, c("run", "pop", "year", "N", "K", "Ne_het", "Ne_inb", "Ne_inb_metapop", "meanFitness")]
colnames(end) = c("run", "pop", "end_year", "N_end", "K_end", "Ne_het_end", "Ne_inb_end", "Ne_inb_metapop_end", "fitness_end")

## one row per population per run: before and end side by side
results = merge(before, end, by = c("run", "pop"))

## extinct = no individuals left at the end of the run
results$extinct = results$N_end == 0

## add the run settings
run_matrix = read.csv(run_matrix_file)
dat = merge(results, run_matrix, by = "run")

## was this population hit by the disturbance?
dat$targeted = mapply(function(city, t) city %in% as.integer(strsplit(t, ";")[[1]]),
                      dat$city, dat$target_pops)

## check
nrow(dat)                       # number of populations over all runs
length(unique(dat$run))         # should be 1000
table(dat$targeted, dat$extinct, dnn = c("targeted", "extinct"))
head(dat)

## save
write.csv(dat, file.path(log_folder, "analysis_table_1000.csv"), row.names = FALSE)
