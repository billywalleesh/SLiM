### Annual mean temperature for four Swiss Plateau populations
### p0 = Geneva, p1 = Bern, p2 = Zurich, p3 = St_Gallen

library(terra)

### 1. File paths

workspace <- Sys.getenv("MSC_WORKSPACE",unset = "C:/Users/WilliamWallisch/msc_workspace")
workspace

input_directory <- file.path(workspace,"SLiM/input/grib_pop_index_local_adaptation")
input_directory

grib_file <- file.path(workspace, "SLiM/data/raw/2m_temp_1940-2026.grib")
population_file <- file.path(input_directory, "population_locations/grib_population_locations_4pop_swiss_plateau.csv")
climate_matrix_file <- file.path(input_directory, "climate_matrix/grib_climate_matrix_4pop_degrees_c_1940_2025.csv")
climate_years_file <- file.path(input_directory, "climate_matrix/grib_climate_years_4pop_1940_2025.csv")
metadata_file <- file.path(input_directory, "metadata/grib_climate_matrix_4pop_degrees_c_1940_2025_metadata.csv")
baseline_file <- file.path(input_directory, "metadata/grib_climate_matrix_4pop_degrees_c_1940_2025_baseline_metadata.csv")

### 2. Years used in the analysis

climate_years <- 1940:2025
climate_years

baseline_start_year <- 1940
baseline_end_year <- 1970

### 3. Read the population locations

population_locations <- read.csv(population_file)
population_locations

population_locations <- population_locations[
  order(population_locations$pop),
  c("pop", "location", "lon", "lat")
]
population_locations

### 4. Read the temperature maps

temperature_maps <- rast(grib_file)
temperature_maps

climate_dates <- as.Date(time(temperature_maps))
climate_dates

years_by_layer <- as.integer(format(climate_dates, "%Y"))
years_by_layer

### Show whether any required years are missing

available_years <- sort(unique(years_by_layer))
available_years

missing_years <- setdiff(climate_years, available_years)
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
temperature_by_population

### Remove the ID column and turn the result into a matrix

temperature_by_population <- as.matrix(temperature_by_population[, -1])
temperature_by_population

### Convert temperature from Kelvin to degrees Celsius

temperature_by_population <- temperature_by_population - 273.15
temperature_by_population

### 7. Create an empty annual temperature matrix

annual_temperature_c <- matrix(
  NA,
  nrow = length(climate_years),
  ncol = nrow(population_locations)
)
annual_temperature_c

rownames(annual_temperature_c) <- climate_years
colnames(annual_temperature_c) <- paste0("p", population_locations$pop)
annual_temperature_c

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

### 9. Calculate the 1940-1970 baseline temperature

baseline_rows <- climate_years >= baseline_start_year &
  climate_years <= baseline_end_year
baseline_rows

baseline_temperature_c <- colMeans(
  annual_temperature_c[baseline_rows, , drop = FALSE],
  na.rm = TRUE
)
baseline_temperature_c

### 10. Create the output folders

dir.create(dirname(climate_matrix_file), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(metadata_file), recursive = TRUE, showWarnings = FALSE)

### 11. Save the files used by SLiM

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

### 12. Create and save readable metadata files

climate_metadata <- data.frame(
  year = climate_years,
  round(annual_temperature_c, 4),
  check.names = FALSE
)
climate_metadata

baseline_metadata <- data.frame(
  pop = population_locations$pop,
  location = population_locations$location,
  lon = population_locations$lon,
  lat = population_locations$lat,
  baseline_start_year = baseline_start_year,
  baseline_end_year = baseline_end_year,
  baseline_temp_c = round(baseline_temperature_c, 4)
)
baseline_metadata

write.csv(climate_metadata, metadata_file, row.names = FALSE)
write.csv(baseline_metadata, baseline_file, row.names = FALSE)

### 13. Read the two SLiM files back in to check them

written_climate <- as.matrix(read.csv(climate_matrix_file, header = FALSE))
written_climate

written_years <- scan(
  climate_years_file,
  what = integer(),
  sep = ",",
  quiet = TRUE
)
written_years
