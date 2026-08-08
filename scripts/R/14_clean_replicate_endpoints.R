### Clean the replicate output
### Make one row for each run and population
### 120 runs x 4 populations = 480 rows

library(tidyverse)


### 1. File paths

workspace <- Sys.getenv(
  "MSC_WORKSPACE",
  unset = "C:/Users/WilliamWallisch/msc_workspace"
)
workspace

input_file <- file.path(
  workspace,
  "SLiM/results/reps/all_runs.csv"
)
input_file

output_file <- file.path(
  workspace,
  "SLiM/results/reps/analysis_480_run_populations.csv"
)
output_file


### 2. Read the full dataset

d <- read.csv(
  input_file,
  na.strings = c("NA", "NAN"),
  stringsAsFactors = FALSE
)

head(d)
dim(d)
names(d)

table(d$migration_treatment)
table(d$selection_strength)
table(d$K)
table(d$location)
table(d$replicate)


### 3. Make an ID for each independent run

d <- d %>%
  mutate(
    run_number = dense_rank(seed),
    run_id = paste0("run_", sprintf("%03d", run_number)),
    extinct = as.logical(extinct)
  )

length(unique(d$run_id))
range(d$run_number)
range(d$seed)

### This should show 120 independent runs.
### run_001 has seed 8000001 and run_120 has seed 8000120.


### 4. Keep 1970, 2000 and 2025

years_to_keep <- c("1970", "2000", "2025")
years_to_keep

year_data <- d %>%
  filter(year %in% years_to_keep)

head(year_data)
dim(year_data)
table(year_data$year)

### This should be 1440 rows:
### 480 run-populations x 3 years.


### 5. Check for duplicate rows

duplicate_check <- year_data %>%
  count(run_id, pop_id, year)

table(duplicate_check$n)

### Every value above should be 1.

if (any(duplicate_check$n != 1)) {
  stop("There is more than one row for a run, population and year")
}


### 6. Information that stays the same within a run and population

run_information <- year_data %>%
  select(
    Source.Name,
    run_number,
    run_id,
    treatment_id,
    seed,
    replicate,
    migration_treatment,
    total_migration_rate,
    selection_strength,
    K,
    pop_id,
    location
  ) %>%
  distinct()

head(run_information)
dim(run_information)


### 7. Put the three years into separate columns

wide_data <- year_data %>%
  select(
    run_id,
    pop_id,
    year,
    tick,
    phase,
    N,
    temperature,
    allele_optimum,
    mean_phenotype,
    phenotype_sd,
    phenotype_lag,
    mean_climate_fitness,
    neutral_heterozygosity,
    Ne_heterozygosity_proxy,
    Ne_fecundity_preMigration,
    migrants_received,
    extinct
  ) %>%
  pivot_wider(
    names_from = year,
    values_from = c(
      tick,
      phase,
      N,
      temperature,
      allele_optimum,
      mean_phenotype,
      phenotype_sd,
      phenotype_lag,
      mean_climate_fitness,
      neutral_heterozygosity,
      Ne_heterozygosity_proxy,
      Ne_fecundity_preMigration,
      migrants_received,
      extinct
    )
  )

head(wide_data)
dim(wide_data)

### This should now be 480 rows.


### 8. Keep the pre-climate Ne values

### These values summarize the 100 generations before climate change.
### They are repeated in later years, so I only keep one copy.

preclimate_data <- year_data %>%
  filter(year == "1970") %>%
  select(
    run_id,
    pop_id,
    Ne_fecundity_preClimate100_arithmetic,
    Ne_fecundity_preClimate100_harmonic,
    mean_N_preClimate100
  )

head(preclimate_data)
dim(preclimate_data)


### 9. Join everything into one table

clean_data <- run_information %>%
  left_join(wide_data, by = c("run_id", "pop_id")) %>%
  left_join(preclimate_data, by = c("run_id", "pop_id"))

head(clean_data)
dim(clean_data)


### 10. Add simple response variables

clean_data <- clean_data %>%
  mutate(
    N_fraction_K_1970 = N_1970 / K,
    N_fraction_K_2000 = N_2000 / K,
    N_fraction_K_2025 = N_2025 / K,

    N_change_1970_2000 = N_2000 - N_1970,
    N_change_2000_2025 = N_2025 - N_2000,
    N_change_1970_2025 = N_2025 - N_1970,

    N_proportional_change_1970_2025 =
      (N_2025 - N_1970) / N_1970,

    Ne_fecundity_change_1970_2025 =
      Ne_fecundity_preMigration_2025 -
      Ne_fecundity_preMigration_1970,

    Ne_heterozygosity_change_1970_2025 =
      Ne_heterozygosity_proxy_2025 -
      Ne_heterozygosity_proxy_1970,

    temperature_change_1970_2025 =
      temperature_2025 - temperature_1970,

    allele_optimum_change_1970_2025 =
      allele_optimum_2025 - allele_optimum_1970,

    phenotype_change_1970_2025 =
      mean_phenotype_2025 - mean_phenotype_1970,

    extinct_by_2025 = extinct_2025,
    survived_to_2025 = !extinct_2025
  )


### 11. Put the rows in a readable order

clean_data <- clean_data %>%
  arrange(
    run_number,
    pop_id
  )


### 12. Check the finished dataset

head(clean_data)
dim(clean_data)
names(clean_data)

length(unique(clean_data$run_id))
table(clean_data$location)
table(clean_data$treatment_id)

table(clean_data$extinct_1970)
table(clean_data$extinct_2000)
table(clean_data$extinct_2025)

colSums(
  is.na(
    clean_data[, c(
      "N_1970",
      "N_2000",
      "N_2025",
      "Ne_fecundity_preMigration_1970",
      "Ne_fecundity_preMigration_2000",
      "Ne_fecundity_preMigration_2025",
      "extinct_1970",
      "extinct_2000",
      "extinct_2025"
    )]
  )
)

if (nrow(clean_data) != 480) {
  stop("The final dataset does not have 480 rows")
}


### 13. Save the cleaned dataset

write.csv(
  clean_data,
  output_file,
  row.names = FALSE,
  na = "NA"
)


### 14. Read the file back in to check it

written_data <- read.csv(
  output_file,
  na.strings = "NA"
)

head(written_data)
dim(written_data)

### The final dataset should have 480 rows and 71 columns.
