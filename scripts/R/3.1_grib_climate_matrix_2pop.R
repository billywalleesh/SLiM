### Convert raw GRIB temperature into a year-by-population climate matrix.
###
### Biological story:
### Populations p0 and p1 occupy two connected regions north of the Swiss Alps.
### Each population first adapts to its mean local temperature from 1940-1970.
### Climate change then follows the actual annual temperatures through time.
###
### Output for SLiM:
###   grib_climate_matrix_2pop_degrees_c.csv
###     rows    = climate years
###     columns = populations p0 and p1
###     values  = annual mean temperature in degrees Celsius
###
###   grib_climate_years_2pop_degrees_c.csv
###     one year per row, matching the rows of the climate matrix

library(terra)

workspace <- "C:/Users/WilliamWallisch/msc_workspace"
input_directory <- file.path(workspace, "SLiM/input/grib_pop_index_local_adaptation")

grib_file <- file.path(workspace, "SLiM/data/raw/2m_temp_1940-2026.grib")
population_file <- file.path(input_directory, "population_locations/grib_population_locations_2pop_swiss_plateau.csv")

climate_matrix_file <- file.path(input_directory, "climate_matrix/grib_climate_matrix_2pop_degrees_c.csv")
climate_years_file <- file.path(input_directory, "climate_matrix/grib_climate_years_2pop_degrees_c.csv")
metadata_file <- file.path(input_directory, "metadata/grib_climate_matrix_2pop_degrees_c_metadata.csv")
baseline_file <- file.path(input_directory, "metadata/grib_climate_matrix_2pop_degrees_c_baseline_metadata.csv")

### Historical climate period used by SLiM before annual climate change begins.
baseline_start_year <- 1940
baseline_end_year <- 1970

### The 2026 GRIB data end in July, so 2025 is the last complete climate year.
last_complete_year <- 2025

### Read the temperature maps and population locations.
temperature_maps <- rast(grib_file)
population_locations <- read.csv(population_file)

population_locations <- population_locations[order(population_locations$pop), ]

### Find the year belonging to each daily temperature map.
climate_dates <- as.Date(time(temperature_maps))
daily_years <- as.integer(format(climate_dates, "%Y"))
climate_years <- sort(unique(daily_years[daily_years <= last_complete_year]))

### Turn the population coordinates into points on the temperature maps.
population_points <- vect(
	population_locations,
	geom = c("lon", "lat"),
	crs = "EPSG:4326"
)

### Put the population points into the same coordinate system as the maps.
population_points <- project(population_points, crs(temperature_maps))

### Extract daily temperature for each population and remove terra's ID column.
daily_temperature <- extract(temperature_maps, population_points)
daily_temperature <- as.matrix(daily_temperature[, -1])

### ERA5 temperature is stored in Kelvin; convert it to degrees Celsius.
daily_temperature <- daily_temperature - 273.15

### Create an empty matrix for one annual temperature per population.
annual_temperature <- matrix(
	NA,
	nrow = length(climate_years),
	ncol = nrow(population_locations)
)
annual_temperature

### Average the daily temperatures within each complete year.
for (year_position in 1:length(climate_years))
{
	this_year <- climate_years[year_position]
	days_this_year <- daily_years == this_year
	
	annual_temperature[year_position, ] <-
		rowMeans(daily_temperature[, days_this_year], na.rm = TRUE)
}
annual_temperature
annual_temperature

colnames(annual_temperature) <- paste0("p", population_locations$pop)

### Calculate the historical mean temperature for each population.
years_in_baseline <- climate_years >= baseline_start_year &
	climate_years <= baseline_end_year

baseline_temperature <- colMeans(
	annual_temperature[years_in_baseline, ],
	na.rm = TRUE
)
baseline_temperature

### Write the actual annual temperatures for SLiM. No baseline is subtracted.
write.table(
	round(annual_temperature, 4),
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
	round(annual_temperature, 4)
)

write.csv(metadata, metadata_file, row.names = FALSE)

baseline_metadata <- data.frame(
	pop = population_locations$pop,
	location = population_locations$location,
	lon = population_locations$lon,
	lat = population_locations$lat,
	baseline_start_year = baseline_start_year,
	baseline_end_year = baseline_end_year,
	baseline_temp_c = round(baseline_temperature, 4)
)
baseline_metadata

write.csv(baseline_metadata, baseline_file, row.names = FALSE)

print(head(metadata))
print(baseline_metadata)

