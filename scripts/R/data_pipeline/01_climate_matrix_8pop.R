### Annual mean temperature for the eight Swiss Plateau cities
### Same steps as 9_grib_climate_matrix_4pop_degrees_c_1940_2025.R, but for all 8 cities.
### Column order = city number 0-7 (west to east), the same numbers used in pop_ids:
### 0 geneva, 1 lausanne, 2 neuchatel, 3 bern, 4 solothurn, 5 lucerne, 6 winterthur, 7 stgallen

library(terra)

### 1. File paths

workspace <- Sys.getenv("MSC_WORKSPACE",unset = "C:/Users/WilliamWallisch/msc_workspace")
workspace

input_directory <- file.path(workspace,"SLiM/input/grib_pop_index_local_adaptation")
input_directory

grib_file <- file.path(workspace, "SLiM/data/raw/2m_temp_1940-2026.grib")
population_file <- file.path(input_directory, "population_locations/grib_population_locations_8pop_swiss_plateau.csv")
climate_matrix_file <- file.path(input_directory, "climate_matrix/grib_climate_matrix_8pop_degrees_c_1940_2025.csv")
climate_years_file <- file.path(input_directory, "climate_matrix/grib_climate_years_8pop_1940_2025.csv")
metadata_file <- file.path(input_directory, "metadata/grib_climate_matrix_8pop_degrees_c_1940_2025_metadata.csv")

### 2. Years used in the analysis

climate_years <- 1940:2025
climate_years

### 3. The eight population locations (same coordinates as 32_dispersal_decay_function.R)

population_locations <- data.frame(
  pop = 0:7,
  location = c("geneva", "lausanne", "neuchatel", "bern", "solothurn", "lucerne", "winterthur", "stgallen"),
  lon = c(6.14748447123683, 6.6323, 6.9293, 7.446219548848173, 7.5372, 8.3093, 8.7237, 9.376234097036747),
  lat = c(46.211464648492914, 46.5197, 46.9896, 46.94798849012668, 47.2088, 47.0502, 47.4988, 47.42899841401629)
)
population_locations

dir.create(dirname(population_file), recursive = TRUE, showWarnings = FALSE)
write.csv(population_locations, population_file, row.names = FALSE)

### 4. Read the temperature maps

temperature_maps <- rast(grib_file)
temperature_maps

climate_dates <- as.Date(time(temperature_maps))
years_by_layer <- as.integer(format(climate_dates, "%Y"))

### Show whether any required years are missing

missing_years <- setdiff(climate_years, sort(unique(years_by_layer)))
missing_years

### 5. Turn the population coordinates into spatial points

population_points <- vect(
  population_locations,
  geom = c("lon", "lat"),
  crs = "EPSG:4326"
)
population_points

### 6. Extract the temperature at each population

temperature_by_population <- extract(temperature_maps, population_points)

### Remove the ID column, turn the result into a matrix, convert Kelvin to degrees Celsius

temperature_by_population <- as.matrix(temperature_by_population[, -1])
temperature_by_population <- temperature_by_population - 273.15

### 7. Create an empty annual temperature matrix (one row per year, one column per city)

annual_temperature_c <- matrix(
  NA,
  nrow = length(climate_years),
  ncol = nrow(population_locations)
)
rownames(annual_temperature_c) <- climate_years
colnames(annual_temperature_c) <- population_locations$pop

### 8. Calculate the annual mean temperature for each population

for (i in 1:length(climate_years)) {
  year <- climate_years[i]

  temperatures_this_year <- temperature_by_population[
    , years_by_layer == year,
    drop = FALSE
  ]

  annual_temperature_c[i, ] <- rowMeans(
    temperatures_this_year,
    na.rm = TRUE
  )
}

annual_temperature_c

### 9. Save the 8-city file (no column names, like the 4pop file)

dir.create(dirname(climate_matrix_file), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(metadata_file), recursive = TRUE, showWarnings = FALSE)

write.table(
  round(annual_temperature_c, 4),
  climate_matrix_file,
  sep = ",",
  row.names = FALSE,
  col.names = FALSE
)

write.table(
  climate_years,
  climate_years_file,
  sep = ",",
  row.names = FALSE,
  col.names = FALSE
)

### 10. Save a readable copy with the year and city names, for checking by eye

climate_metadata <- data.frame(
  year = climate_years,
  round(annual_temperature_c, 4),
  check.names = FALSE
)
colnames(climate_metadata) <- c("year", paste0(population_locations$pop, "_", population_locations$location))
climate_metadata

write.csv(climate_metadata, metadata_file, row.names = FALSE)
