### Convert raw GRIB temperature data into the small climate matrix used by SLiM.
###
### Why this script exists:
### SLiM/Eidos reads simple text tables very well, but GRIB is a binary climate-data format.
### This R script does the spatial climate work before SLiM starts.
###
### Output for SLiM:
###   row 1 = baseline climate optimum for each population
###   row 2 = shifted climate optimum for each population
###   columns = p0, p1, p2, ... in the same order as the migration matrix

library(terra)

workspace <- "C:/Users/WilliamWallisch/msc_workspace"

grib_file <- file.path(workspace, "SLiM/data/raw/2m_temp_1940-2026.grib")
population_file <- file.path(workspace, "SLiM/input/population_locations_from_grib.csv")

slim_climate_file <- file.path(workspace, "SLiM/input/climate_matrix_from_grib.csv")
metadata_file <- file.path(workspace, "SLiM/input/climate_matrix_from_grib_metadata.csv")

baseline_years <- 1940:1970
shifted_years <- 2000:2026

### These are model units, not degrees Celsius.
### The GRIB temperatures are scaled onto this range so they match the phenotype scale in SLiM.
optimum_min <- 2.0
optimum_max <- 10.0

temperature <- rast(grib_file)
population_locations <- read.csv(population_file)

required_columns <- c("pop", "lon", "lat")

population_locations <- population_locations[order(population_locations$pop), ]

expected_pop_ids <- 0:(nrow(population_locations) - 1)

climate_dates <- time(temperature)

climate_years <- as.integer(format(as.Date(climate_dates), "%Y"))

baseline_layers <- climate_years %in% baseline_years
shifted_layers <- climate_years %in% shifted_years

population_points <- vect(
	population_locations,
	geom = c("lon", "lat"),
	crs = "EPSG:4326"
)

raster_crs <- crs(temperature)

temperature_by_pop <- extract(temperature, population_points)
temperature_by_pop <- as.matrix(temperature_by_pop[, -1, drop = FALSE])

### ERA5-style 2m temperature is commonly stored in Kelvin.
### If the values look like Kelvin, convert them to Celsius before averaging.

baseline_temp_c <- rowMeans(temperature_by_pop[, baseline_layers, drop = FALSE], na.rm = TRUE)
shifted_temp_c <- rowMeans(temperature_by_pop[, shifted_layers, drop = FALSE], na.rm = TRUE)

temperature_stages_c <- rbind(baseline_temp_c, shifted_temp_c)

temp_min <- min(temperature_stages_c, na.rm = TRUE)
temp_max <- max(temperature_stages_c, na.rm = TRUE)

if (temp_min == temp_max)
{
	climate_matrix <- matrix(
		(optimum_min + optimum_max) / 2,
		nrow = 2,
		ncol = nrow(population_locations)
	)
} else
{
	climate_matrix <- optimum_min +
		(temperature_stages_c - temp_min) *
		(optimum_max - optimum_min) /
		(temp_max - temp_min)
}

write.table(
	round(climate_matrix, 4),
	file = slim_climate_file,
	sep = ",",
	row.names = FALSE,
	col.names = FALSE
)

metadata <- data.frame(
	pop = population_locations$pop,
	lon = population_locations$lon,
	lat = population_locations$lat,
	baseline_temp_c = baseline_temp_c,
	shifted_temp_c = shifted_temp_c,
	baseline_optimum = climate_matrix[1, ],
	shifted_optimum = climate_matrix[2, ]
)

write.csv(metadata, metadata_file, row.names = FALSE)

print(climate_matrix)

