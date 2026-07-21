### Convert raw GRIB temperature into a year-by-population climate shift matrix.
###
### Biological story:
### Each population has its own location in Switzerland.
### Each population has its own historical baseline climate.
### A climate shift asks: how much warmer or colder is this year than that population's baseline?
###
### Output for SLiM:
###   grib_climate_matrix_10pop.csv
###     rows    = climate years
###     columns = populations p0, p1, p2, ...
###     values  = degrees C away from each population's own baseline
###
###   grib_climate_years_10pop.csv
###     one year per row, matching the rows of the climate shift matrix

library(terra)

workspace <- "C:/Users/WilliamWallisch/msc_workspace"
input_directory <- file.path(workspace, "SLiM/input/grib_pop_index_local_adaptation")

grib_file <- file.path(workspace, "SLiM/data/raw/2m_temp_1940-2026.grib")
population_file <- file.path(input_directory, "population_locations/grib_population_locations_10pop.csv")

climate_matrix_file <- file.path(input_directory, "climate_matrix/grib_climate_matrix_10pop.csv")
climate_years_file <- file.path(input_directory, "climate_matrix/grib_climate_years_10pop.csv")
metadata_file <- file.path(input_directory, "metadata/grib_climate_matrix_10pop_metadata.csv")
baseline_file <- file.path(input_directory, "metadata/grib_climate_matrix_10pop_baseline_metadata.csv")

### Match the historical climate period used by SLiM before climate change begins.
### This makes each population's mean climate shift from 1940-1970 equal to zero.
baseline_years <- 1940:1970

temperature <- rast(grib_file)
population_locations <- read.csv(population_file)

required_columns <- c("pop", "lon", "lat")
if (!all(required_columns %in% names(population_locations)))
	stop("grib_population_locations_10pop.csv needs columns: pop, lon, lat")

population_locations <- population_locations[order(population_locations$pop), ]

expected_pop_ids <- 0:(nrow(population_locations) - 1)
if (!all(population_locations$pop == expected_pop_ids))
	stop("Population IDs must be sequential: 0, 1, 2, ...")

climate_dates <- time(temperature)
if (length(climate_dates) == 0 || all(is.na(climate_dates)))
	stop("No dates found in the GRIB file. Check terra::time(temperature).")

climate_years_by_layer <- as.integer(format(as.Date(climate_dates), "%Y"))
climate_years <- sort(unique(climate_years_by_layer))

baseline_rows <- climate_years %in% baseline_years
if (!any(baseline_rows))
	stop("No climate years found for baseline_years.")

population_points <- vect(
	population_locations,
	geom = c("lon", "lat"),
	crs = "EPSG:4326"
)

raster_crs <- crs(temperature)
if (!is.na(raster_crs) && raster_crs != "")
	population_points <- project(population_points, raster_crs)

temperature_by_pop <- extract(temperature, population_points)
temperature_by_pop <- as.matrix(temperature_by_pop[, -1, drop = FALSE])

### ERA5-style 2m temperature is commonly stored in Kelvin.
### If the values look like Kelvin, convert them to Celsius before averaging.
if (median(temperature_by_pop, na.rm = TRUE) > 100)
	temperature_by_pop <- temperature_by_pop - 273.15

annual_temperature_c <- matrix(
	NA_real_,
	nrow = length(climate_years),
	ncol = nrow(population_locations)
)

for (year_number in seq_along(climate_years))
{
	this_year <- climate_years[year_number]
	layers_this_year <- climate_years_by_layer == this_year
	annual_temperature_c[year_number, ] <- rowMeans(
		temperature_by_pop[, layers_this_year, drop = FALSE],
		na.rm = TRUE
	)
}

colnames(annual_temperature_c) <- paste0("p", population_locations$pop)

baseline_temperature_c <- colMeans(
	annual_temperature_c[baseline_rows, , drop = FALSE],
	na.rm = TRUE
)

climate_shift_c <- sweep(annual_temperature_c, 2, baseline_temperature_c, "-")
colnames(climate_shift_c) <- paste0("p", population_locations$pop)

write.table(
	round(climate_shift_c, 4),
	file = climate_matrix_file,
	sep = ",",
	row.names = FALSE,
	col.names = FALSE
)

write.table(
	climate_years,
	file = climate_years_file,
	sep = ",",
	row.names = FALSE,
	col.names = FALSE
)

metadata <- data.frame(
	year = climate_years,
	round(climate_shift_c, 4)
)

write.csv(metadata, metadata_file, row.names = FALSE)

baseline_metadata <- data.frame(
	pop = population_locations$pop,
	location = population_locations$location,
	lon = population_locations$lon,
	lat = population_locations$lat,
	baseline_temp_c = round(baseline_temperature_c, 4)
)

write.csv(baseline_metadata, baseline_file, row.names = FALSE)

print(head(metadata))
message("Wrote climate matrix to: ", climate_matrix_file)
message("Wrote climate years to: ", climate_years_file)
message("Wrote climate shift metadata to: ", metadata_file)
message("Wrote baseline metadata to: ", baseline_file)
