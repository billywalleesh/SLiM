# ---------------------------------------------------------------------------
# 14_map_mean_annual_temp.R
#
# Two maps:
#   1. Mean annual 2 m temperature, 1940-1970
#   2. Mean annual 2 m temperature, 1971-2025
#
# Both maps use the same diverging colour scale for direct comparison.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(terra)
  library(ggplot2)
  library(sf)
  library(rnaturalearth)
})

root <- Sys.getenv("MSC_WORKSPACE", "C:/Users/WilliamWallisch/msc_workspace")
slim <- file.path(root, "SLiM")

# ---------------------------------------------------------------------------
# Colour settings
# ---------------------------------------------------------------------------

# ColorBrewer RdBu endpoints. Red/blue stays distinguishable for the common
# forms of colour blindness, unlike red/green.
COL_COLD <- "#2166AC"
COL_MID  <- "#F7F7F7"
COL_WARM <- "#B2182B"

# A diverging scale claims its midpoint means something, so choose it on
# purpose and state it in the caption. Options:
#   mean(temp_limits)   midpoint of the mapped range  (default below)
#   0                   freezing - physically meaningful, but every cell here
#                       is above 0, so the whole map would be red
#   mean(values(tmean_1940_1970))   the baseline average: blue = colder than
#                       Switzerland was, red = warmer
MIDPOINT_MODE <- "range"      # "range" | "zero" | "baseline"

# ---------------------------------------------------------------------------
# Read GRIB and build the two periods
# ---------------------------------------------------------------------------

grib <- rast(file.path(slim, "data/raw/2m_temp_1940-2026.grib"))
yr   <- as.integer(format(as.Date(time(grib)), "%Y"))

keep_1 <- which(yr %in% 1940:1970)
keep_2 <- which(yr %in% 1971:2025)
cat(sprintf("1940-1970: %d daily layers\n1971-2025: %d daily layers\n",
            length(keep_1), length(keep_2)))

tmean_1940_1970 <- mean(grib[[keep_1]]) - 273.15
tmean_1971_2025 <- mean(grib[[keep_2]]) - 273.15
names(tmean_1940_1970) <- "temp_C"
names(tmean_1971_2025) <- "temp_C"

temp_limits <- range(c(values(tmean_1940_1970), values(tmean_1971_2025)),
                     na.rm = TRUE)

midpoint <- switch(MIDPOINT_MODE,
                   range    = mean(temp_limits),
                   zero     = 0,
                   baseline = mean(values(tmean_1940_1970), na.rm = TRUE))

cat(sprintf("colour scale: %.2f to %.2f degC, white at %.2f degC\n",
            temp_limits[1], temp_limits[2], midpoint))

# ---------------------------------------------------------------------------
# Border and study sites
# ---------------------------------------------------------------------------

ch <- ne_countries(country = "Switzerland", scale = "medium", returnclass = "sf")

loc <- read.csv(file.path(
  slim, "input/grib_pop_index_local_adaptation/population_locations",
  "grib_population_locations_4pop_swiss_plateau.csv"))
loc$label <- c("Geneva", "Bern", "Zurich", "St. Gallen")
loc$nx <- c( 0.12,  0.00,  0.00,  0.12)
loc$ny <- c(-0.12, -0.14,  0.14,  0.14)
loc$hj <- c( 0,     0.5,   0.5,   0   )

# ---------------------------------------------------------------------------
# Map function
# ---------------------------------------------------------------------------

make_temp_map <- function(tmean, title_text,
                          limits = temp_limits, mid = midpoint,
                          legend_title = "Temperature (\u00B0C)") {

  df <- as.data.frame(tmean, xy = TRUE, na.rm = TRUE)

  ggplot() +
    geom_raster(data = df, aes(x, y, fill = temp_C)) +
    geom_sf(data = ch, fill = NA, colour = "black", linewidth = 0.5) +
    geom_point(data = loc, aes(lon, lat), shape = 21,
               fill = "black", colour = "white", size = 2.6, stroke = 0.8) +
    # A label rather than plain text: the background now runs from deep blue
    # to deep red, so no single text colour stays readable on all of it.
    geom_label(data = loc,
               aes(lon + nx, lat + ny, label = label, hjust = hj),
               size = 3.0, colour = "black", fontface = "bold",
               fill = "white", alpha = 0.75, label.size = 0,
               label.padding = unit(0.09, "lines")) +
    scale_fill_gradient2(low = COL_COLD, mid = COL_MID, high = COL_WARM,
                         midpoint = mid, limits = limits,
                         name = legend_title) +
    coord_sf(xlim = range(df$x), ylim = range(df$y), expand = FALSE) +
    labs(x = NULL, y = NULL, title = title_text) +
    theme_bw(base_size = 10) +
    theme(panel.grid   = element_blank(),
          panel.border = element_rect(colour = "black", linewidth = 0.6),
          legend.key.height = unit(1.1, "cm"),
          legend.key.width  = unit(0.35, "cm"),
          legend.title = element_text(size = 8.5),
          legend.text  = element_text(size = 8),
          plot.title   = element_text(hjust = 0.5, face = "bold"))
}

p_1940_1970 <- make_temp_map(tmean_1940_1970,
                             "Mean annual temperature 1940\u20131970")
p_1971_2025 <- make_temp_map(tmean_1971_2025,
                             "Mean annual temperature 1971\u20132025")

# Optional third panel. Here the midpoint is not a choice - zero means
# "no change" - which is what a diverging scale is actually for.
dd <- tmean_1971_2025 - tmean_1940_1970
names(dd) <- "temp_C"
dmax <- max(abs(values(dd)), na.rm = TRUE)
p_diff <- make_temp_map(dd, "Difference: 1971\u20132025 minus 1940\u20131970",
                        limits = c(-dmax, dmax), mid = 0,
                        legend_title = "Warming (\u00B0C)")

# ---------------------------------------------------------------------------
# Save
# ---------------------------------------------------------------------------

out <- file.path(slim, "results", "figures")
dir.create(out, recursive = TRUE, showWarnings = FALSE)

save_pair <- function(p, stem) {
  f <- file.path(out, stem)
  ggsave(paste0(f, ".png"), p, width = 7.2, height = 4.4, dpi = 300, bg = "white")
  # cairo_pdf keeps the degree sign and en dash intact in the vector output
  ggsave(paste0(f, ".pdf"), p, width = 7.2, height = 4.4, bg = "white",
         device = grDevices::cairo_pdf)
  cat("wrote", paste0(f, ".png/.pdf"), "\n")
}

save_pair(p_1940_1970, "map_mean_annual_temp_1940_1970")
save_pair(p_1971_2025, "map_mean_annual_temp_1971_2025")
save_pair(p_diff,      "map_mean_annual_temp_difference")

# ---------------------------------------------------------------------------
# Temperature at each study location
# ---------------------------------------------------------------------------

t1 <- terra::extract(tmean_1940_1970, loc[, c("lon", "lat")])[, 2]
t2 <- terra::extract(tmean_1971_2025, loc[, c("lon", "lat")])[, 2]

print(data.frame(site           = loc$label,
                 temp_1940_1970 = round(t1, 2),
                 temp_1971_2025 = round(t2, 2),
                 change_C       = round(t2 - t1, 2)))
p_1940_1970
p_1971_2025
