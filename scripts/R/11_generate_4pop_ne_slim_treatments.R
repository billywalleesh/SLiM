# Generate the 12 standalone SLiM treatment scripts for the four-deme
# effective-population-size experiment.
#
# Fixed design:
#   2 migration treatments: weak (0.001 total) and strong (0.010 total)
#   2 climate-selection strengths: 0.050 and 0.075
#   3 carrying capacities from tick 1: 500, 2000 and 5000
#
# ARCHIVED: the validated standalone scripts remain on disk, but new runs use
# grib_4pop_ne_ramp_parameterized.slim and the scripts/SLURM parameter grid.

stop(
  "This standalone-script generator is archived. ",
  "Use scripts/SLURM/make_4pop_ne_parameter_grid.sh with ",
  "grib_4pop_ne_ramp_parameterized.slim."
)

workspace <- "C:/Users/WilliamWallisch/msc_workspace"
slim_directory <- file.path(
  workspace,
  "SLiM/scripts/SLiM/4pop_ne_experiment"
)

template_file <- file.path(
  slim_directory,
  "grib_4pop_ne_ramp_template.slim.template"
)

results_directory <- file.path(
  workspace,
  "SLiM/results/4pop_ne_experiment"
)

if (!file.exists(template_file)) {
  stop("SLiM treatment template not found: ", template_file)
}

dir.create(slim_directory, recursive = TRUE, showWarnings = FALSE)
dir.create(results_directory, recursive = TRUE, showWarnings = FALSE)

migration_treatments <- data.frame(
  migration_treatment = c("weak", "strong"),
  total_migration_rate = c(0.001, 0.010),
  migration_file = c(
    "grib_migration_matrix_4pop_weak.csv",
    "grib_migration_matrix_4pop_strong.csv"
  ),
  stringsAsFactors = FALSE
)

selection_strengths <- c(0.050, 0.075)
carrying_capacities <- c(500L, 2000L, 5000L)

treatments <- merge(
  merge(
    migration_treatments,
    data.frame(selection_strength = selection_strengths)
  ),
  data.frame(K = carrying_capacities)
)

treatments <- treatments[
  order(
    treatments$migration_treatment,
    treatments$selection_strength,
    treatments$K
  ),
]

format_selection_id <- function(value) {
  sprintf("%03d", round(value * 1000))
}

format_numeric_for_eidos <- function(value) {
  format(value, scientific = FALSE, trim = TRUE, digits = 12)
}

template <- paste(readLines(template_file, warn = FALSE), collapse = "\n")

generated_files <- character(nrow(treatments))

for (row_number in seq_len(nrow(treatments))) {
  treatment <- treatments[row_number, ]

  treatment_id <- paste0(
    "grib_4pop_ne_ramp_",
    treatment$migration_treatment,
    "_sel",
    format_selection_id(treatment$selection_strength),
    "_K",
    treatment$K
  )

  script <- template
  script <- gsub(
    "__TREATMENT_ID__",
    treatment_id,
    script,
    fixed = TRUE
  )
  script <- gsub(
    "__MIGRATION_TREATMENT__",
    treatment$migration_treatment,
    script,
    fixed = TRUE
  )
  script <- gsub(
    "__TOTAL_MIGRATION_RATE__",
    format_numeric_for_eidos(treatment$total_migration_rate),
    script,
    fixed = TRUE
  )
  script <- gsub(
    "__MIGRATION_FILE__",
    treatment$migration_file,
    script,
    fixed = TRUE
  )
  script <- gsub(
    "__SELECTION_STRENGTH__",
    format_numeric_for_eidos(treatment$selection_strength),
    script,
    fixed = TRUE
  )
  script <- gsub(
    "__K__",
    as.character(treatment$K),
    script,
    fixed = TRUE
  )

  unresolved <- gregexpr("__[A-Z0-9_]+__", script, perl = TRUE)[[1]]
  if (unresolved[1] != -1) {
    stop("Unresolved template placeholder in treatment: ", treatment_id)
  }

  output_file <- file.path(slim_directory, paste0(treatment_id, ".slim"))
  writeLines(script, output_file, useBytes = TRUE)
  generated_files[row_number] <- output_file
  treatments$treatment_id[row_number] <- treatment_id
  treatments$slim_file[row_number] <- basename(output_file)
}

treatment_manifest <- treatments[
  ,
  c(
    "treatment_id",
    "migration_treatment",
    "total_migration_rate",
    "migration_file",
    "selection_strength",
    "K",
    "slim_file"
  )
]

manifest_file <- file.path(
  slim_directory,
  "grib_4pop_ne_treatment_manifest.csv"
)

write.csv(treatment_manifest, manifest_file, row.names = FALSE)

message("Generated ", length(generated_files), " standalone SLiM scripts.")
message("Treatment manifest: ", manifest_file)
print(treatment_manifest)
