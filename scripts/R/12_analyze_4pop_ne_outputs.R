# Initial analysis of the four-deme Ne and climate-response experiment.
#
# The parameterized SLiM model writes one tidy CSV per treatment replicate.
# This script combines those files and produces one row per
# treatment x replicate x seed x deme with pre-climate Ne predictors and
# observed-period demographic outcomes.

workspace <- Sys.getenv(
  "MSC_WORKSPACE",
  unset = "C:/Users/WilliamWallisch/msc_workspace"
)
default_results_directory <- file.path(
  workspace,
  "SLiM/results/4pop_ne_experiment"
)
results_directory <- Sys.getenv(
  "FOURPOP_NE_RESULTS_DIR",
  unset = default_results_directory
)
analysis_directory <- Sys.getenv(
  "FOURPOP_NE_ANALYSIS_DIR",
  unset = file.path(results_directory, "analysis")
)

dir.create(analysis_directory, recursive = TRUE, showWarnings = FALSE)

result_files <- list.files(
  results_directory,
  pattern = "^grib_4pop_ne_ramp_.*_seed_[0-9]+\\.csv$",
  full.names = TRUE
)

if (length(result_files) == 0) {
  stop(
    "No four-deme result CSVs were found in: ",
    results_directory
  )
}

read_result <- function(path) {
  result <- read.csv(
    path,
    stringsAsFactors = FALSE,
    na.strings = c("NA", "NAN", "nan")
  )
  if (!"replicate" %in% names(result)) {
    replicate_match <- regexec(
      "_rep_([0-9]+)_seed_",
      basename(path)
    )
    replicate_parts <- regmatches(
      basename(path),
      replicate_match
    )[[1]]
    result$replicate <- if (length(replicate_parts) == 2) {
      as.integer(replicate_parts[2])
    } else {
      NA_integer_
    }
  }
  result$source_file <- basename(path)
  result
}

results <- do.call(rbind, lapply(result_files, read_result))

required_columns <- c(
  "treatment_id",
  "seed",
  "replicate",
  "migration_treatment",
  "total_migration_rate",
  "selection_strength",
  "K",
  "tick",
  "phase",
  "year",
  "pop_id",
  "location",
  "N",
  "temperature",
  "allele_optimum",
  "mean_phenotype",
  "phenotype_sd",
  "phenotype_lag",
  "mean_climate_fitness",
  "neutral_heterozygosity",
  "Ne_heterozygosity_proxy",
  "Ne_fecundity_preMigration",
  "Ne_fecundity_preClimate100_arithmetic",
  "Ne_fecundity_preClimate100_harmonic",
  "mean_N_preClimate100",
  "migrants_received",
  "extinct"
)

missing_columns <- setdiff(required_columns, names(results))
if (length(missing_columns) > 0) {
  stop(
    "Result files are missing columns: ",
    paste(missing_columns, collapse = ", ")
  )
}

results$extinct <- as.logical(results$extinct)

group_id <- interaction(
  results$treatment_id,
  results$seed,
  results$pop_id,
  drop = TRUE
)

split_results <- split(results, group_id)

summarize_run_deme <- function(deme_data) {
  deme_data <- deme_data[order(deme_data$tick), ]

  pre_climate <- deme_data[deme_data$tick == 3999, ]
  if (nrow(pre_climate) == 0) {
    pre_climate <- deme_data[
      deme_data$tick == max(deme_data$tick[deme_data$tick < 4000]),
    ]
  }
  pre_climate <- pre_climate[nrow(pre_climate), ]

  climate_start <- deme_data[deme_data$tick == 4000, ]
  if (nrow(climate_start) == 0) {
    climate_start <- pre_climate
  } else {
    climate_start <- climate_start[1, ]
  }

  observed <- deme_data[deme_data$phase == "observed_climate", ]
  if (nrow(observed) == 0) {
    observed <- deme_data[0, ]
  }

  final_row <- deme_data[nrow(deme_data), ]

  observed_min_N <- if (nrow(observed) > 0) {
    min(observed$N, na.rm = TRUE)
  } else {
    NA_real_
  }

  observed_mean_abs_lag <- if (
    nrow(observed) > 0 &&
    any(!is.na(observed$phenotype_lag))
  ) {
    mean(abs(observed$phenotype_lag), na.rm = TRUE)
  } else {
    NA_real_
  }

  observed_max_abs_lag <- if (
    nrow(observed) > 0 &&
    any(!is.na(observed$phenotype_lag))
  ) {
    max(abs(observed$phenotype_lag), na.rm = TRUE)
  } else {
    NA_real_
  }

  observed_mean_fitness <- if (
    nrow(observed) > 0 &&
    any(!is.na(observed$mean_climate_fitness))
  ) {
    mean(observed$mean_climate_fitness, na.rm = TRUE)
  } else {
    NA_real_
  }

  data.frame(
    treatment_id = final_row$treatment_id,
    seed = final_row$seed,
    replicate = final_row$replicate,
    migration_treatment = final_row$migration_treatment,
    total_migration_rate = final_row$total_migration_rate,
    selection_strength = final_row$selection_strength,
    K = final_row$K,
    pop_id = final_row$pop_id,
    location = final_row$location,
    N_preclimate = pre_climate$N,
    Ne_fecundity_preClimate100_arithmetic =
      climate_start$Ne_fecundity_preClimate100_arithmetic,
    Ne_fecundity_preClimate100_harmonic =
      climate_start$Ne_fecundity_preClimate100_harmonic,
    mean_N_preClimate100 =
      pre_climate$mean_N_preClimate100,
    neutral_heterozygosity_preclimate =
      pre_climate$neutral_heterozygosity,
    Ne_heterozygosity_preclimate =
      pre_climate$Ne_heterozygosity_proxy,
    Ne_fecundity_to_N =
      climate_start$Ne_fecundity_preClimate100_harmonic /
      pre_climate$mean_N_preClimate100,
    Ne_heterozygosity_to_N =
      pre_climate$Ne_heterozygosity_proxy /
      pre_climate$N,
    final_tick = final_row$tick,
    N_final = final_row$N,
    extinct_final = final_row$N == 0,
    extinct_before_2025 = final_row$tick < 4055 ||
      final_row$N == 0,
    minimum_N_observed = observed_min_N,
    proportional_minimum_N =
      observed_min_N / pre_climate$N,
    mean_abs_phenotype_lag_observed = observed_mean_abs_lag,
    max_abs_phenotype_lag_observed = observed_max_abs_lag,
    mean_climate_fitness_observed = observed_mean_fitness,
    stringsAsFactors = FALSE
  )
}

run_deme_summary <- do.call(
  rbind,
  lapply(split_results, summarize_run_deme)
)
row.names(run_deme_summary) <- NULL

combined_output_file <- file.path(
  analysis_directory,
  "combined_tick_level_results.csv"
)
summary_output_file <- file.path(
  analysis_directory,
  "run_deme_summary.csv"
)

write.csv(results, combined_output_file, row.names = FALSE)
write.csv(run_deme_summary, summary_output_file, row.names = FALSE)

treatment_summary <- aggregate(
  cbind(
    N_final,
    extinct_final,
    minimum_N_observed,
    proportional_minimum_N,
    mean_abs_phenotype_lag_observed,
    mean_climate_fitness_observed,
    Ne_fecundity_preClimate100_arithmetic,
    Ne_fecundity_preClimate100_harmonic,
    Ne_heterozygosity_preclimate
  ) ~
    migration_treatment +
    selection_strength +
    K,
  data = run_deme_summary,
  FUN = function(x) mean(x, na.rm = TRUE)
)

treatment_summary_file <- file.path(
  analysis_directory,
  "treatment_summary.csv"
)
write.csv(treatment_summary, treatment_summary_file, row.names = FALSE)

pdf(
  file.path(
    analysis_directory,
    "Ne_preclimate_vs_final_population_size.pdf"
  ),
  width = 8,
  height = 6
)

plot(
  run_deme_summary$Ne_fecundity_preClimate100_harmonic,
  run_deme_summary$N_final,
  pch = 19,
  col = ifelse(
    run_deme_summary$migration_treatment == "strong",
    "darkorange",
    "steelblue"
  ),
  xlab = "Harmonic mean fecundity Ne, breeder cohorts 3900-3999",
  ylab = "Population size at end of observed period",
  main = "Pre-climate effective size and 2025 population size"
)

legend(
  "topleft",
  legend = c("Weak migration", "Strong migration"),
  col = c("steelblue", "darkorange"),
  pch = 19,
  bty = "n"
)
dev.off()

message("Read ", length(result_files), " result files.")
message("Combined tick-level results: ", combined_output_file)
message("Run-deme summary: ", summary_output_file)
message("Treatment summary: ", treatment_summary_file)
