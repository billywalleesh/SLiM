### Make simple symmetric migration matrices for four populations
###
### Rows are source populations and columns are destination populations.
### All off-diagonal values are equal, so migration is symmetric.
### Diagonal values are zero because a population does not migrate to itself.

### 1. File paths

workspace <- Sys.getenv(
  "MSC_WORKSPACE",
  unset = "C:/Users/WilliamWallisch/msc_workspace"
)
workspace

input_directory <- file.path(
  workspace,
  "SLiM/input/grib_pop_index_local_adaptation"
)
input_directory

population_file <- file.path(input_directory, "population_locations/grib_population_locations_4pop_swiss_plateau.csv")
weak_migration_file <- file.path(input_directory, "migration_matrix/grib_migration_matrix_4pop_weak.csv")
strong_migration_file <- file.path(input_directory, "migration_matrix/grib_migration_matrix_4pop_strong.csv")
details_metadata_file <- file.path(input_directory, "metadata/grib_migration_matrix_4pop_distance_details_metadata.csv")
summary_metadata_file <- file.path(input_directory, "metadata/grib_migration_matrix_4pop_distance_summary_metadata.csv")

### 2. Migration settings

### Weak migration: m = 0.0001 (0.01%)
### Expected migrants: 0.05 at K = 500, 0.2 at K = 2000,
### and 0.5 at K = 5000

weak_total_migration <- 0.0001
weak_total_migration

### Strong migration: m = 0.02 (2%)
### Expected migrants: 10 at K = 500, 40 at K = 2000,
### and 100 at K = 5000

strong_total_migration <- 0.02
strong_total_migration

number_of_populations <- 4
number_of_populations

### Each population can migrate to the other three populations

number_of_destinations <- number_of_populations - 1
number_of_destinations

weak_pairwise_migration <- weak_total_migration / number_of_destinations
weak_pairwise_migration

strong_pairwise_migration <- strong_total_migration / number_of_destinations
strong_pairwise_migration

### 3. Read the population information

populations <- read.csv(population_file)
populations

populations <- populations[
  order(populations$pop),
  c("pop", "location", "lon", "lat")
]
populations

### 4. Make the weak symmetric migration matrix

weak_migration_matrix <- matrix(
  weak_pairwise_migration,
  nrow = number_of_populations,
  ncol = number_of_populations
)

diag(weak_migration_matrix) <- 0

rownames(weak_migration_matrix) <- paste0("p", populations$pop)
colnames(weak_migration_matrix) <- paste0("p", populations$pop)

weak_migration_matrix

### Each row should sum to 0.0001

rowSums(weak_migration_matrix)

### 5. Make the strong symmetric migration matrix

strong_migration_matrix <- matrix(
  strong_pairwise_migration,
  nrow = number_of_populations,
  ncol = number_of_populations
)

diag(strong_migration_matrix) <- 0

rownames(strong_migration_matrix) <- paste0("p", populations$pop)
colnames(strong_migration_matrix) <- paste0("p", populations$pop)

strong_migration_matrix

### Each row should sum to 0.02

rowSums(strong_migration_matrix)

### 6. Create a simple description of the treatments

migration_details <- data.frame(
  treatment = c("weak", "strong"),
  migration_model = c("symmetric", "symmetric"),
  number_of_populations = c(4, 4),
  destinations_per_population = c(3, 3),
  pairwise_migration_rate = c(
    weak_pairwise_migration,
    strong_pairwise_migration
  ),
  total_out_migration_rate = c(
    weak_total_migration,
    strong_total_migration
  )
)
migration_details

### 7. Calculate expected migrant numbers for different population sizes

migration_summary <- data.frame(
  treatment = c("weak", "strong"),
  total_out_migration_rate = c(
    weak_total_migration,
    strong_total_migration
  ),
  expected_migrants_at_K500 = c(
    weak_total_migration * 500,
    strong_total_migration * 500
  ),
  expected_migrants_at_K2000 = c(
    weak_total_migration * 2000,
    strong_total_migration * 2000
  ),
  expected_migrants_at_K5000 = c(
    weak_total_migration * 5000,
    strong_total_migration * 5000
  )
)
migration_summary

### 8. Create the output folders

dir.create(dirname(weak_migration_file), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(details_metadata_file), recursive = TRUE, showWarnings = FALSE)

### 9. Save the migration matrices without row or column names

write.table(
  weak_migration_matrix,
  weak_migration_file,
  sep = ",",
  quote = FALSE,
  row.names = FALSE,
  col.names = FALSE
)

write.table(
  strong_migration_matrix,
  strong_migration_file,
  sep = ",",
  quote = FALSE,
  row.names = FALSE,
  col.names = FALSE
)

### Save the readable metadata tables

write.csv(migration_details, details_metadata_file, row.names = FALSE)
write.csv(migration_summary, summary_metadata_file, row.names = FALSE)

### 10. Read the matrices back in and display them

written_weak_matrix <- as.matrix(read.csv(
  weak_migration_file,
  header = FALSE
))
written_weak_matrix

written_strong_matrix <- as.matrix(read.csv(
  strong_migration_file,
  header = FALSE
))
written_strong_matrix

### Final checks

rowSums(written_weak_matrix)
rowSums(written_strong_matrix)

