# ---------------------------------------------------------------------------
# 14_map_mean_annual_temp.R
#
# Two maps:
#   1. Mean annual 2 m temperature, 1940-1970
#   2. Mean annual 2 m temperature, 1971-2025
#
# Both maps use the same temperature colour scale for direct comparison.
#
# Reads:
#   data/raw/2m_temp_1940-2026.grib
#   input/.../grib_population_locations_4pop_swiss_plateau.csv
#
# Writes:
#   results/figures/map_mean_annual_temp_1940_1970.{png,pdf}
#   results/figures/map_mean_annual_temp_1971_2025.{png,pdf}
#
# Packages:
#   terra, ggplot2, sf, rnaturalearth
# ---------------------------------------------------------------------------


suppressPackageStartupMessages({
  library(terra)
  library(ggplot2)
  library(sf)
  library(rnaturalearth)
})


# ---------------------------------------------------------------------------
# 1. Paths
# ---------------------------------------------------------------------------

root <- Sys.getenv(
  "MSC_WORKSPACE",
  "C:/Users/WilliamWallisch/msc_workspace"
)

slim <- file.path(root, "SLiM")


# ---------------------------------------------------------------------------
# 2. Read GRIB
# ---------------------------------------------------------------------------

grib <- rast(
  file.path(slim, "data/raw/2m_temp_1940-2026.grib")
)


# ---------------------------------------------------------------------------
# 3. Identify years
# ---------------------------------------------------------------------------

yr <- as.integer(
  format(as.Date(time(grib)), "%Y")
)


# ---------------------------------------------------------------------------
# 4. Define the two periods
# ---------------------------------------------------------------------------

years_1 <- 1940:1970
years_2 <- 1971:2025


keep_1 <- which(yr %in% years_1)
keep_2 <- which(yr %in% years_2)

cat(
  sprintf(
    "1940-1970: using %d daily layers\n",
    length(keep_1)
  )
)

cat(
  sprintf(
    "1971-2025: using %d daily layers\n",
    length(keep_2)
  )
)


# ---------------------------------------------------------------------------
# 5. Calculate mean annual temperature for each period
# ---------------------------------------------------------------------------

# Kelvin -> Celsius
tmean_1940_1970 <- mean(
  grib[[keep_1]]
) - 273.15

tmean_1971_2025 <- mean(
  grib[[keep_2]]
) - 273.15

names(tmean_1940_1970) <- "temp_C"
names(tmean_1971_2025) <- "temp_C"


# Print temperature ranges
cat(
  sprintf(
    "1940-1970 temperature range: %.2f to %.2f °C\n",
    min(values(tmean_1940_1970), na.rm = TRUE),
    max(values(tmean_1940_1970), na.rm = TRUE)
  )
)

cat(
  sprintf(
    "1971-2025 temperature range: %.2f to %.2f °C\n",
    min(values(tmean_1971_2025), na.rm = TRUE),
    max(values(tmean_1971_2025), na.rm = TRUE)
  )
)


# ---------------------------------------------------------------------------
# 6. Switzerland border
# ---------------------------------------------------------------------------

ch <- ne_countries(
  country = "Switzerland",
  scale = "medium",
  returnclass = "sf"
)


# ---------------------------------------------------------------------------
# 7. Study locations
# ---------------------------------------------------------------------------

loc <- read.csv(
  file.path(
    slim,
    "input/grib_pop_index_local_adaptation/population_locations",
    "grib_population_locations_4pop_swiss_plateau.csv"
  )
)

loc$label <- c(
  "Geneva",
  "Bern",
  "Zurich",
  "St. Gallen"
)

# Label nudges, in degrees
loc$nx <- c(
  0.10,
  0.00,
  0.00,
  0.10
)

loc$ny <- c(
  -0.10,
  -0.12,
  0.12,
  0.12
)

loc$hj <- c(
  0,
  0.5,
  0.5,
  0
)


# ---------------------------------------------------------------------------
# 8. Common colour scale
# ---------------------------------------------------------------------------

# Use the same limits for both maps so that colours mean the same
# temperature on both maps.

all_temp <- c(
  values(tmean_1940_1970),
  values(tmean_1971_2025)
)

temp_limits <- range(
  all_temp,
  na.rm = TRUE
)

cat(
  sprintf(
    "Common colour scale: %.2f to %.2f °C\n",
    temp_limits[1],
    temp_limits[2]
  )
)


# ---------------------------------------------------------------------------
# 9. Function to create a temperature map
# ---------------------------------------------------------------------------

make_temp_map <- function(tmean, title_text) {
  
  df <- as.data.frame(
    tmean,
    xy = TRUE,
    na.rm = TRUE
  )
  
  ggplot() +
    
    # Temperature raster
    geom_raster(
      data = df,
      aes(
        x = x,
        y = y,
        fill = temp_C
      )
    ) +
    
    # Switzerland border
    geom_sf(
      data = ch,
      fill = NA,
      colour = "black",
      linewidth = 0.5
    ) +
    
    # Study locations
    geom_point(
      data = loc,
      aes(
        lon,
        lat
      ),
      shape = 21,
      fill = "white",
      colour = "black",
      size = 2.6,
      stroke = 0.7
    ) +
    
    # Location labels
    geom_text(
      data = loc,
      aes(
        lon + nx,
        lat + ny,
        label = label,
        hjust = hj
      ),
      size = 3.1,
      colour = "white",
      fontface = "bold"
    ) +
    
    # Same scale for both maps
    scale_fill_gradient(
      low = "white",
      high = "grey12",
      limits = temp_limits,
      name = "Temperature (°C)"
    ) +
    
    # Map extent
    coord_sf(
      xlim = range(df$x),
      ylim = range(df$y),
      expand = FALSE
    ) +
    
    # Title and labels
    labs(
      x = NULL,
      y = NULL,
      title = title_text
    ) +
    
    # Theme
    theme_bw(
      base_size = 10
    ) +
    
    theme(
      panel.grid = element_blank(),
      
      panel.border = element_rect(
        colour = "black",
        linewidth = 0.6
      ),
      
      legend.key.height = unit(
        1.1,
        "cm"
      ),
      
      legend.key.width = unit(
        0.35,
        "cm"
      ),
      
      legend.title = element_text(
        size = 8.5
      ),
      
      legend.text = element_text(
        size = 8
      ),
      
      # Centre title
      plot.title = element_text(
        hjust = 0.5,
        face = "bold"
      )
    )
}


# ---------------------------------------------------------------------------
# 10. Create the two maps
# ---------------------------------------------------------------------------

p_1940_1970 <- make_temp_map(
  tmean_1940_1970,
  "Mean annual temperature 1940–1970 (°C)"
)

p_1971_2025 <- make_temp_map(
  tmean_1971_2025,
  "Mean annual temperature 1971–2025 (°C)"
)


# ---------------------------------------------------------------------------
# 11. Save maps
# ---------------------------------------------------------------------------

out <- file.path(
  slim,
  "results",
  "figures"
)

dir.create(
  out,
  recursive = TRUE,
  showWarnings = FALSE
)


# 1940-1970

f1 <- file.path(
  out,
  "map_mean_annual_temp_1940_1970"
)

ggsave(
  paste0(f1, ".png"),
  p_1940_1970,
  width = 7.2,
  height = 4.4,
  dpi = 300,
  bg = "white"
)

ggsave(
  paste0(f1, ".pdf"),
  p_1940_1970,
  width = 7.2,
  height = 4.4,
  bg = "white"
)


# 1971-2025

f2 <- file.path(
  out,
  "map_mean_annual_temp_1971_2025"
)

ggsave(
  paste0(f2, ".png"),
  p_1971_2025,
  width = 7.2,
  height = 4.4,
  dpi = 300,
  bg = "white"
)

ggsave(
  paste0(f2, ".pdf"),
  p_1971_2025,
  width = 7.2,
  height = 4.4,
  bg = "white"
)


cat("\nWrote:\n")
cat(paste0(f1, ".png\n"))
cat(paste0(f1, ".pdf\n"))
cat(paste0(f2, ".png\n"))
cat(paste0(f2, ".pdf\n"))


# ---------------------------------------------------------------------------
# 12. Temperature at each study location
# ---------------------------------------------------------------------------

temp_1 <- terra::extract(
  tmean_1940_1970,
  loc[, c("lon", "lat")]
)[, 2]

temp_2 <- terra::extract(
  tmean_1971_2025,
  loc[, c("lon", "lat")]
)[, 2]


site_temps <- data.frame(
  site = loc$label,
  temp_1940_1970 = round(temp_1, 2),
  temp_1971_2025 = round(temp_2, 2),
  change_C = round(temp_2 - temp_1, 2)
)

print(site_temps)


# ---------------------------------------------------------------------------
# 13. Display maps
# ---------------------------------------------------------------------------

p_1940_1970
p_1971_2025


