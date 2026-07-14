# Make a migration matrix where migration becomes harder with distance.
# Rows are source populations; columns are destination populations.

workspace <- "C:/Users/WilliamWallisch/msc_workspace"
inputDirectory <- file.path(workspace, "SLiM/input/grib_pop_index_local_adaptation")

populationFile <- file.path(inputDirectory, "population_locations/grib_population_locations_10pop.csv")
migrationFile <- file.path(inputDirectory, "migration_matrix/grib_migration_matrix_10pop_distance.csv")
migrationDetailsFile <- file.path(inputDirectory, "metadata/grib_migration_matrix_10pop_distance_details_metadata.csv")
migrationSummaryFile <- file.path(inputDirectory, "metadata/grib_migration_matrix_10pop_distance_summary_metadata.csv")

# Biological knobs:
# nearby populations have this migration rate;
# farther populations get progressively lower migration rates.
nearNeighborMigrationRate <- 0.005
nearNeighborDistanceKm <- 50
migrationDistanceScaleKm <- 75
minimumMigrationRate <- 0.00005

degreesToRadians <- function(degrees) {
  degrees * pi / 180
}

distanceKm <- function(lon1, lat1, lon2, lat2) {
  earthRadiusKm <- 6371

  lon1 <- degreesToRadians(lon1)
  lat1 <- degreesToRadians(lat1)
  lon2 <- degreesToRadians(lon2)
  lat2 <- degreesToRadians(lat2)

  dLon <- lon2 - lon1
  dLat <- lat2 - lat1

  a <- sin(dLat / 2)^2 + cos(lat1) * cos(lat2) * sin(dLon / 2)^2
  c <- 2 * atan2(sqrt(a), sqrt(1 - a))

  earthRadiusKm * c
}

distanceBasedMigrationRate <- function(distance) {
  if (distance <= nearNeighborDistanceKm) {
    rate <- nearNeighborMigrationRate
  } else {
    extraDistance <- distance - nearNeighborDistanceKm
    rate <- nearNeighborMigrationRate * exp(-extraDistance / migrationDistanceScaleKm)
  }

  if (rate < minimumMigrationRate) {
    rate <- 0
  }

  rate
}

populations <- read.csv(populationFile)
populations <- populations[order(populations$pop), ]

numPops <- nrow(populations)
migrationMatrix <- matrix(0, nrow = numPops, ncol = numPops)
migrationDetails <- data.frame()

for (source in seq_len(numPops)) {
  for (destination in seq_len(numPops)) {
    if (source == destination) {
      next
    }

    distance <- distanceKm(
      populations$lon[source],
      populations$lat[source],
      populations$lon[destination],
      populations$lat[destination]
    )

    migrationRate <- distanceBasedMigrationRate(distance)
    migrationMatrix[source, destination] <- migrationRate

    migrationDetails <- rbind(
      migrationDetails,
      data.frame(
        sourcePop = populations$pop[source],
        sourceLocation = populations$location[source],
        destinationPop = populations$pop[destination],
        destinationLocation = populations$location[destination],
        distanceKm = round(distance, 2),
        migrationRate = round(migrationRate, 6)
      )
    )
  }
}

migrationSummary <- data.frame(
  pop = populations$pop,
  location = populations$location,
  totalOutMigrationRate = round(rowSums(migrationMatrix), 6),
  expectedMigrantsAtK5000 = round(rowSums(migrationMatrix) * 5000, 1)
)

write.table(
  round(migrationMatrix, 6),
  migrationFile,
  sep = ",",
  row.names = FALSE,
  col.names = FALSE
)

write.csv(migrationDetails, migrationDetailsFile, row.names = FALSE)
write.csv(migrationSummary, migrationSummaryFile, row.names = FALSE)

print(round(migrationMatrix, 6))
print(migrationSummary)
