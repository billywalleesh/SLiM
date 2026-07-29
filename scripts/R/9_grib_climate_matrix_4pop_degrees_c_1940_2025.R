### Extract annual mean temperature for four Swiss Plateau populations.
###
### Populations:
###   p0 Geneva, p1 Bern, p2 Zurich, p3 St_Gallen
###
### Outputs for SLiM:
###   grib_climate_matrix_4pop_degrees_c_1940_2025.csv
###     rows    = years 1940-2025
###     columns = p0, p1, p2, p3
###     values  = annual mean temperature in degrees Celsius
###
###   grib_climate_years_4pop_1940_2025.csv
###     one year per row, aligned with the climate matrix

library(terra)

workspace <- Sys.getenv(
	"MSC_WORKSPACE",
	unset = "C:/Users/WilliamWallisch/msc_workspace"
)
input_directory <- file.path(
	workspace,
	"SLiM/input/grib_pop_index_local_adaptation"
)

grib_file <- file.path(
	workspace,
	"SLiM/data/raw/2m_temp_1940-2026.grib"
)
population_file <- file.path(
	input_directory,
	"population_locations/grib_population_locations_4pop_swiss_plateau.csv"
)

climate_matrix_file <- file.path(
	input_directory,
	"climate_matrix/grib_climate_matrix_4pop_degrees_c_1940_2025.csv"
)
climate_years_file <- file.path(
	input_directory,
	"climate_matrix/grib_climate_years_4pop_1940_2025.csv"
)
metadata_file <- file.path(
	input_directory,
	"metadata/grib_climate_matrix_4pop_degrees_c_1940_2025_metadata.csv"
)
baseline_file <- file.path(
	input_directory,
	"metadata/grib_climate_matrix_4pop_degrees_c_1940_2025_baseline_metadata.csv"
)

first_climate_year <- 1940L
last_climate_year <- 2025L
baseline_start_year <- 1940L
baseline_end_year <- 1970L
requested_years <- first_climate_year:last_climate_year

if (!file.exists(grib_file))
	stop("GRIB file not found: ", grib_file)

population_locations <- read.csv(
	population_file,
	stringsAsFactors = FALSE
)

required_columns <- c("pop", "location", "lon", "lat")
if (!all(required_columns %in% names(population_locations)))
	stop("Population file needs columns: pop, location, lon, lat.")

population_locations <- population_locations[
	order(population_locations$pop),
	required_columns
]

if (nrow(population_locations) != 4L)
	stop("Expected exactly four population locations.")

if (!identical(
	as.integer(population_locations$pop),
	0:3
))
	stop("Population IDs must be sequential integers 0, 1, 2, 3.")

expected_locations <- c("Geneva", "Bern", "Zurich", "St_Gallen")
if (!identical(
	as.character(population_locations$location),
	expected_locations
))
	stop(
		"Locations must be ordered: ",
		paste(expected_locations, collapse = ", "),
		"."
	)

temperature_maps <- rast(grib_file)
climate_dates <- as.Date(time(temperature_maps))

if (length(climate_dates) == 0L || all(is.na(climate_dates)))
	stop("No dates were found in terra::time(temperature_maps).")

years_by_layer <- as.integer(format(climate_dates, "%Y"))
available_years <- sort(unique(years_by_layer))
missing_years <- setdiff(requested_years, available_years)

if (length(missing_years) > 0L)
	stop(
		"GRIB file is missing requested years: ",
		paste(missing_years, collapse = ", "),
		"."
	)

population_points <- vect(
	population_locations,
	geom = c("lon", "lat"),
	crs = "EPSG:4326"
)

raster_crs <- crs(temperature_maps)
if (!is.na(raster_crs) && nzchar(raster_crs))
	population_points <- project(population_points, raster_crs)

temperature_by_population <- extract(
	temperature_maps,
	population_points
)
temperature_by_population <- as.matrix(
	temperature_by_population[, -1, drop = FALSE]
)

### Convert Kelvin to Celsius only when the extracted values are Kelvin-like.
if (median(temperature_by_population, na.rm = TRUE) > 100)
	temperature_by_population <- temperature_by_population - 273.15

annual_temperature_c <- matrix(
	NA_real_,
	nrow = length(requested_years),
	ncol = nrow(population_locations),
	dimnames = list(
		as.character(requested_years),
		paste0("p", population_locations$pop)
	)
)

for (year_position in seq_along(requested_years))
{
	this_year <- requested_years[year_position]
	layers_this_year <- years_by_layer == this_year

	annual_temperature_c[year_position, ] <- rowMeans(
		temperature_by_population[
			,
			layers_this_year,
			drop = FALSE
		],
		na.rm = TRUE
	)
}

if (any(!is.finite(annual_temperature_c)))
	stop("Annual climate matrix contains non-finite temperatures.")

baseline_rows <- requested_years >= baseline_start_year &
	requested_years <= baseline_end_year

baseline_temperature_c <- colMeans(
	annual_temperature_c[baseline_rows, , drop = FALSE]
)

dir.create(dirname(climate_matrix_file), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(metadata_file), recursive = TRUE, showWarnings = FALSE)

write.table(
	round(annual_temperature_c, 4),
	file = climate_matrix_file,
	sep = ",",
	row.names = FALSE,
	col.names = FALSE
)

write.table(
	requested_years,
	file = climate_years_file,
	sep = ",",
	row.names = FALSE,
	col.names = FALSE
)

climate_metadata <- data.frame(
	year = requested_years,
	round(annual_temperature_c, 4),
	check.names = FALSE
)

baseline_metadata <- data.frame(
	pop = population_locations$pop,
	location = population_locations$location,
	lon = population_locations$lon,
	lat = population_locations$lat,
	baseline_start_year = baseline_start_year,
	baseline_end_year = baseline_end_year,
	baseline_temp_c = round(baseline_temperature_c, 4)
)

write.csv(climate_metadata, metadata_file, row.names = FALSE)
write.csv(baseline_metadata, baseline_file, row.names = FALSE)

written_climate <- as.matrix(read.csv(
	climate_matrix_file,
	header = FALSE
))
written_years <- scan(
	climate_years_file,
	what = integer(),
	sep = ",",
	quiet = TRUE
)

if (!identical(dim(written_climate), c(length(requested_years), 4L)))
	stop("Written climate matrix does not have dimensions 86 x 4.")

if (!identical(written_years, requested_years))
	stop("Written climate years are not exactly 1940:2025.")

message("Wrote climate matrix: ", climate_matrix_file)
message("Wrote climate years: ", climate_years_file)
message("Wrote annual metadata: ", metadata_file)
message("Wrote baseline metadata: ", baseline_file)
print(baseline_metadata)
