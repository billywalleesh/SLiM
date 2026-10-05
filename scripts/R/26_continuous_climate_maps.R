### Climate maps for the continuous-space model (stage S0)
### ERA5 2 m temperature GRIB -> SLiM-ready temperature maps in Swiss LV95 km
###
### Writes, under SLiM/input/continuous_swiss/:
###   maps_cells/   nearest-neighbour maps: every point takes the value of the
###                 ERA5 cell it lies in, so the four cities get EXACTLY the
###                 same temperatures as the v1.2 climate matrix (default)
###   maps_smooth/  bilinear maps: temperature changes smoothly between ERA5
###                 cell centres (city values differ from v1.2 by up to ~0.5 C)
###   each folder:  hist_1940_1970.csv  (mean of the annual means, 1940-1970,
###                 the same baseline years as v1.2)
###                 annual_1970.csv ... annual_2025.csv
###   map_metadata.csv                   grid size, resolution, origin
###   population_locations_lv95.csv      city coordinates in model km
###   check_maps.png                     visual check
###
### MAP ORIENTATION (important for SLiM)
###   Each CSV is a matrix with row 1 = NORTH edge and column 1 = WEST edge,
###   exactly as the map looks on screen. Values sit on grid points spaced
###   RES_KM apart; the first/last row and column are the edges of the
###   SLiM spatial bounds (0 .. width_km, 0 .. height_km).
###   SLiM 5.2 reads a matrix in exactly this orientation (verified: the
###   top-left value sits at x = 0, y = height). The SLiM model re-checks
###   this at startup against population_locations_lv95.csv (stage S1).
###
### Model coordinates: x_km = LV95 east / 1000 - origin_x_km
###                    y_km = LV95 north / 1000 - origin_y_km

library(terra)

### 1. File paths

workspace <- Sys.getenv("MSC_WORKSPACE", unset = "C:/Users/WilliamWallisch/msc_workspace")

grib_file <- file.path(workspace, "SLiM/data/raw/2m_temp_1940-2026.grib")
population_file <- file.path(workspace,
  "SLiM/input/grib_pop_index_local_adaptation/population_locations/grib_population_locations_4pop_swiss_plateau.csv")
output_directory <- file.path(workspace, "SLiM/input/continuous_swiss")

### 2. Settings

RES_KM <- 2                 # spacing of SLiM map grid points (km)
climate_years <- 1940:2025
baseline_years <- 1940:1970 # same baseline as v1.2
observed_years <- 1970:2025 # climate-change phase, as in v1.2

### 3. Annual mean temperature per ERA5 cell (degrees C)

temperature_maps <- rast(grib_file)
layer_years <- as.integer(format(as.Date(time(temperature_maps)), "%Y"))

keep <- layer_years %in% climate_years
annual <- tapp(temperature_maps[[which(keep)]], layer_years[keep], mean)
annual <- annual - 273.15   # GRIB values are Kelvin (the "C" label is wrong)
names(annual) <- as.character(sort(unique(layer_years[keep])))
crs(annual) <- "EPSG:4326"
annual

historical_mean <- mean(annual[[as.character(baseline_years)]])

### 4. Target grid in LV95 km

# grid points must stay inside the ERA5 cell-centre footprint so that the
# bilinear maps never extrapolate
centre_extent <- ext(annual) - 0.125     # shrink by half a cell: cell centres
corners <- vect(rbind(
  c(xmin(centre_extent), ymin(centre_extent)), c(xmax(centre_extent), ymin(centre_extent)),
  c(xmin(centre_extent), ymax(centre_extent)), c(xmax(centre_extent), ymax(centre_extent)),
  c(mean(c(xmin(centre_extent), xmax(centre_extent))), ymin(centre_extent)),
  c(mean(c(xmin(centre_extent), xmax(centre_extent))), ymax(centre_extent))),
  crs = "EPSG:4326")
corners_lv95 <- crds(project(corners, "EPSG:2056")) / 1000
corners_lv95

# inscribed box (rounded inward to whole km)
box_xmin <- ceiling(max(corners_lv95[c(1, 3), 1]))
box_xmax <- floor(min(corners_lv95[c(2, 4), 1]))
box_ymin <- ceiling(max(corners_lv95[c(1, 2, 5), 2]))
box_ymax <- floor(min(corners_lv95[c(3, 4, 6), 2]))

number_columns <- floor((box_xmax - box_xmin) / RES_KM) + 1
number_rows <- floor((box_ymax - box_ymin) / RES_KM) + 1
width_km <- (number_columns - 1) * RES_KM
height_km <- (number_rows - 1) * RES_KM

# a raster whose CELL CENTRES are the SLiM grid points
template <- rast(
  ncols = number_columns, nrows = number_rows,
  xmin = (box_xmin - RES_KM / 2) * 1000, xmax = (box_xmin + width_km + RES_KM / 2) * 1000,
  ymin = (box_ymin - RES_KM / 2) * 1000, ymax = (box_ymin + height_km + RES_KM / 2) * 1000,
  crs = "EPSG:2056")
template

### 5. Reproject

to_grid <- function(layer, method) {
  projected <- project(layer, template, method = method)
  if (any(is.na(values(projected))))
    stop("NA values in the projected map - the box is outside the ERA5 footprint")
  projected
}

map_sets <- list(cells = "near", smooth = "bilinear")

write_map <- function(layer, path) {
  # row 1 = north, column 1 = west
  values_matrix <- as.matrix(layer, wide = TRUE)
  write.table(round(values_matrix, 4), path, sep = ",",
    row.names = FALSE, col.names = FALSE)
}

dir.create(output_directory, recursive = TRUE, showWarnings = FALSE)

projected_historical <- list()

for (set_name in names(map_sets)) {
  set_directory <- file.path(output_directory, paste0("maps_", set_name))
  dir.create(set_directory, showWarnings = FALSE)

  projected_historical[[set_name]] <- to_grid(historical_mean, map_sets[[set_name]])
  write_map(projected_historical[[set_name]],
    file.path(set_directory, "hist_1940_1970.csv"))

  for (year in observed_years) {
    write_map(to_grid(annual[[as.character(year)]], map_sets[[set_name]]),
      file.path(set_directory, paste0("annual_", year, ".csv")))
  }
  cat("wrote", set_name, "maps\n")
}

### 6. City coordinates in model km, and the map value at each city

populations <- read.csv(population_file)
populations <- populations[order(populations$pop), ]
city_points <- vect(populations, geom = c("lon", "lat"), crs = "EPSG:4326")
city_lv95 <- crds(project(city_points, "EPSG:2056")) / 1000

populations$x_km <- round(city_lv95[, 1] - box_xmin, 3)
populations$y_km <- round(city_lv95[, 2] - box_ymin, 3)

# v1.2's value (nearest ERA5 cell, lon/lat) and the value in each map set
populations$hist_temp_v1.2 <- round(extract(historical_mean, city_points)[, 2], 4)
city_points_lv95 <- project(city_points, "EPSG:2056")
populations$hist_temp_cells <- round(extract(projected_historical$cells, city_points_lv95)[, 2], 4)
populations$hist_temp_smooth <- round(extract(projected_historical$smooth, city_points_lv95,
  method = "bilinear")[, 2], 4)
populations

write.csv(populations, file.path(output_directory, "population_locations_lv95.csv"),
  row.names = FALSE)

metadata <- data.frame(
  crs = "EPSG:2056 (LV95), km",
  res_km = RES_KM,
  ncol = number_columns,
  nrow = number_rows,
  width_km = width_km,
  height_km = height_km,
  origin_x_km = box_xmin,
  origin_y_km = box_ymin,
  orientation = "row 1 = north edge (y = height_km), column 1 = west edge (x = 0)",
  baseline_years = "1940-1970",
  observed_years = "1970-2025",
  source = "ERA5 daily 2 m temperature, 0.25 deg, annual means")
write.csv(metadata, file.path(output_directory, "map_metadata.csv"), row.names = FALSE)

### 7. Visual check

png(file.path(output_directory, "check_maps.png"), width = 1600, height = 1000, res = 130)
par(mfrow = c(2, 2))
for (set_name in names(map_sets)) {
  plot(projected_historical[[set_name]] , main = paste("1940-1970 mean,", set_name))
  points(city_lv95 * 1000, pch = 19)
  text(city_lv95 * 1000, labels = populations$location, pos = 3)
}
plot(to_grid(annual[["2025"]], "near"), main = "2025, cells")
points(city_lv95 * 1000, pch = 19)
plot(to_grid(annual[["2025"]] - historical_mean, "bilinear"), main = "2025 minus 1940-1970, smooth")
points(city_lv95 * 1000, pch = 19)
dev.off()

cat("Grid:", number_columns, "x", number_rows, "points,", width_km, "x", height_km, "km\n")
