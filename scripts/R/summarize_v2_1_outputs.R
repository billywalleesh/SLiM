library(tidyverse)

# Set SLIM_V2_1_OUTBASE before running on the cluster, or edit this default path.
outbase <- Sys.getenv("SLIM_V2_1_OUTBASE", unset = "/scratch/wwalli/TMP/slim_v2_1")
csv_dir <- file.path(outbase, "csv")
summary_dir <- file.path(outbase, "summary")

dir.create(summary_dir, recursive = TRUE, showWarnings = FALSE)

files <- list.files(csv_dir, pattern = "\\.csv$", full.names = TRUE)

if (length(files) == 0) {
  stop("No CSV files found in: ", csv_dir)
}

logs <- files |>
  set_names(basename(files)) |>
  map_dfr(read_csv, .id = "source_file", show_col_types = FALSE) |>
  mutate(
    phase = factor(
      phase,
      levels = c("shared_burnin", "gradient_burnin", "climate_shift")
    ),
    abs_phenotype_lag = abs(phenotype_lag)
  )

write_csv(logs, file.path(summary_dir, "combined_population_logs.csv"))

run_summary <- logs |>
  group_by(
    run_id,
    seed,
    target_Ne,
    num_pops,
    migration_rate,
    opt_step,
    shift_size,
    fitness_width,
    min_fitness,
    Tburn_shared,
    Tburn_gradient,
    Tdelta,
    Tend
  ) |>
  summarise(
    any_extinction = any(extinct == 1),
    extinct_pop_records = sum(extinct == 1),
    min_pop_size = min(pop_size, na.rm = TRUE),
    final_total_pop_size = sum(pop_size[tick == max(tick)], na.rm = TRUE),
    final_mean_pop_size = mean(pop_size[tick == max(tick)], na.rm = TRUE),
    final_mean_phenotype_match = mean(
      mean_phenotype_match[tick == max(tick)],
      na.rm = TRUE
    ),
    final_mean_abs_lag = mean(
      abs_phenotype_lag[tick == max(tick)],
      na.rm = TRUE
    ),
    post_shift_mean_pop_size = mean(
      pop_size[phase == "climate_shift"],
      na.rm = TRUE
    ),
    post_shift_mean_phenotype_match = mean(
      mean_phenotype_match[phase == "climate_shift"],
      na.rm = TRUE
    ),
    post_shift_mean_abs_lag = mean(
      abs_phenotype_lag[phase == "climate_shift"],
      na.rm = TRUE
    ),
    post_shift_mean_allelic_richness = mean(
      allelic_richness[phase == "climate_shift"],
      na.rm = TRUE
    ),
    .groups = "drop"
  )

write_csv(run_summary, file.path(summary_dir, "run_summary.csv"))

print(run_summary)

# Starter models: response variables as functions of explanatory variables.
extinction_model <- glm(
  any_extinction ~ target_Ne + num_pops + migration_rate + shift_size,
  data = run_summary,
  family = binomial()
)

match_model <- lm(
  post_shift_mean_phenotype_match ~
    target_Ne + num_pops + migration_rate + shift_size + fitness_width,
  data = run_summary
)

lag_model <- lm(
  post_shift_mean_abs_lag ~
    target_Ne + num_pops + migration_rate + shift_size + fitness_width,
  data = run_summary
)

capture.output(
  summary(extinction_model),
  file = file.path(summary_dir, "extinction_model.txt")
)

capture.output(
  summary(match_model),
  file = file.path(summary_dir, "phenotype_match_model.txt")
)

capture.output(
  summary(lag_model),
  file = file.path(summary_dir, "phenotype_lag_model.txt")
)

logs |>
  group_by(tick, target_Ne, num_pops, migration_rate, shift_size) |>
  summarise(
    mean_pop_size = mean(pop_size, na.rm = TRUE),
    mean_phenotype_match = mean(mean_phenotype_match, na.rm = TRUE),
    mean_abs_lag = mean(abs_phenotype_lag, na.rm = TRUE),
    .groups = "drop"
  ) |>
  ggplot(aes(tick, mean_pop_size, colour = factor(target_Ne))) +
  geom_line() +
  facet_grid(num_pops ~ shift_size, labeller = label_both) +
  theme_minimal() +
  labs(colour = "Target Ne")

ggsave(
  file.path(summary_dir, "mean_population_size_timeseries.png"),
  width = 10,
  height = 7
)

run_summary |>
  ggplot(aes(factor(target_Ne), post_shift_mean_phenotype_match)) +
  geom_boxplot() +
  facet_grid(num_pops ~ shift_size, labeller = label_both) +
  theme_minimal() +
  labs(
    x = "Target Ne",
    y = "Post-shift mean phenotype match"
  )

ggsave(
  file.path(summary_dir, "post_shift_phenotype_match.png"),
  width = 10,
  height = 7
)
