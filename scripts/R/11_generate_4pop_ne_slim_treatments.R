### Generate 12 SLiM scripts for the four-population Ne experiment
###
### Experimental design:
###   2 migration treatments: weak and strong
###   2 selection strengths: 0.050 and 0.075
###   3 carrying capacities: 500, 2000 and 5000
###
### Total number of treatments: 2 * 2 * 3 = 12

### This generator is archived and should not be used for new simulations.
### New simulations use the parameterized SLiM script and SLURM grid.

stop(
  "This script is archived. Use ",
  "scripts/SLURM/make_4pop_ne_parameter_grid.sh with ",
  "grib_4pop_ne_ramp_parameterized.slim instead."
)

### The archived generator code is kept below for reference.

### 1. File paths

workspace <- "C:/Users/WilliamWallisch/msc_workspace"
workspace

slim_directory <- file.path(
  workspace,
  "SLiM/scripts/SLiM/4pop_ne_experiment"
)
slim_directory

template_file <- file.path(
  slim_directory,
  "grib_4pop_ne_ramp_template.slim.template"
)
template_file

results_directory <- file.path(
  workspace,
  "SLiM/results/4pop_ne_experiment"
)
results_directory

if (!file.exists(template_file)) {
  stop("SLiM treatment template not found: ", template_file)
}

### 2. Create the output folders

dir.create(slim_directory, recursive = TRUE, showWarnings = FALSE)
dir.create(results_directory, recursive = TRUE, showWarnings = FALSE)

### 3. Define the treatment values

migration_treatments <- c("strong", "weak")
migration_treatments

total_migration_rates <- c(0.010, 0.001)
total_migration_rates

migration_files <- c(
  "grib_migration_matrix_4pop_strong.csv",
  "grib_migration_matrix_4pop_weak.csv"
)
migration_files

selection_strengths <- c(0.050, 0.075)
selection_strengths

carrying_capacities <- c(500, 2000, 5000)
carrying_capacities

### 4. Create an empty treatment table

number_of_treatments <- length(migration_treatments) *
  length(selection_strengths) *
  length(carrying_capacities)
number_of_treatments

treatments <- data.frame(
  treatment_id = character(number_of_treatments),
  migration_treatment = character(number_of_treatments),
  total_migration_rate = numeric(number_of_treatments),
  migration_file = character(number_of_treatments),
  selection_strength = numeric(number_of_treatments),
  K = integer(number_of_treatments),
  slim_file = character(number_of_treatments)
)
treatments

### 5. Read the SLiM template

template_lines <- readLines(template_file, warn = FALSE)
template_lines

template <- paste(template_lines, collapse = "\n")

### 6. Make one SLiM script for every treatment combination

row_number <- 1

for (migration_number in 1:length(migration_treatments)) {
  for (selection_strength in selection_strengths) {
    for (K in carrying_capacities) {

      migration_treatment <- migration_treatments[migration_number]
      total_migration_rate <- total_migration_rates[migration_number]
      migration_file <- migration_files[migration_number]

      selection_id <- sprintf("%03d", round(selection_strength * 1000))

      treatment_id <- paste0(
        "grib_4pop_ne_ramp_",
        migration_treatment,
        "_sel",
        selection_id,
        "_K",
        K
      )

      slim_script <- template

      slim_script <- gsub(
        "__TREATMENT_ID__",
        treatment_id,
        slim_script,
        fixed = TRUE
      )

      slim_script <- gsub(
        "__MIGRATION_TREATMENT__",
        migration_treatment,
        slim_script,
        fixed = TRUE
      )

      slim_script <- gsub(
        "__TOTAL_MIGRATION_RATE__",
        format(total_migration_rate, scientific = FALSE),
        slim_script,
        fixed = TRUE
      )

      slim_script <- gsub(
        "__MIGRATION_FILE__",
        migration_file,
        slim_script,
        fixed = TRUE
      )

      slim_script <- gsub(
        "__SELECTION_STRENGTH__",
        format(selection_strength, scientific = FALSE),
        slim_script,
        fixed = TRUE
      )

      slim_script <- gsub(
        "__K__",
        as.character(K),
        slim_script,
        fixed = TRUE
      )

      if (grepl("__[A-Z0-9_]+__", slim_script)) {
        stop("Unresolved template placeholder in treatment: ", treatment_id)
      }

      output_file <- file.path(
        slim_directory,
        paste0(treatment_id, ".slim")
      )

      writeLines(slim_script, output_file, useBytes = TRUE)

      treatments[row_number, ] <- list(
        treatment_id,
        migration_treatment,
        total_migration_rate,
        migration_file,
        selection_strength,
        K,
        basename(output_file)
      )

      row_number <- row_number + 1
    }
  }
}

treatments

### 7. Save the treatment manifest

manifest_file <- file.path(
  slim_directory,
  "grib_4pop_ne_treatment_manifest.csv"
)
manifest_file

write.csv(treatments, manifest_file, row.names = FALSE)

message("Generated ", nrow(treatments), " standalone SLiM scripts.")
message("Treatment manifest: ", manifest_file)
