# ---------------------------------------------------------------------------
# 13_map_4pop_migration.R
#
# Map of the four Swiss Plateau demes with migration links drawn from the
# migration matrix actually used by the SLiM models.
#
# Reads:
#   input/grib_pop_index_local_adaptation/population_locations/
#       grib_population_locations_4pop_swiss_plateau.csv
#   input/grib_pop_index_local_adaptation/migration_matrix/
#       grib_migration_matrix_4pop_<TREATMENT>.csv
#
# Writes:
#   results/figures/map_4pop_migration_<TREATMENT>.png
#
# One-time package install:
#   install.packages(c("sf", "ggplot2", "dplyr",
#                      "rnaturalearth", "rnaturalearthdata"))
# Optional, for a finer coastline (1:10m instead of 1:50m):
#   install.packages("rnaturalearthhires",
#                    repos = "https://ropensci.r-universe.dev", type = "source")
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(sf)
  library(ggplot2)
  library(dplyr)
  library(rnaturalearth)
})

## ---- settings -------------------------------------------------------------

TREATMENT <- "decay"        # "weak" | "strong" | "decay"
MAP_SCALE <- "medium"       # "medium" = 1:50m (bundled). "large" = 1:10m,
                            # needs rnaturalearthhires.

root <- Sys.getenv("MSC_WORKSPACE", "C:/Users/WilliamWallisch/msc_workspace")
slim <- file.path(root, "SLiM")

PAL <- c("Geneva"     = "#2a78d6",
         "Bern"       = "#eb6834",
         "Zurich"     = "#1baf7a",
         "St. Gallen" = "#eda100")
INK <- "#0b0b0b"; INK2 <- "#52514e"; MUTED <- "#8a8880"

## ---- data -----------------------------------------------------------------

loc <- read.csv(file.path(
  slim, "input/grib_pop_index_local_adaptation/population_locations",
  "grib_population_locations_4pop_swiss_plateau.csv"))

# The migration matrices have NO header row - every line is data.
mig <- as.matrix(read.csv(file.path(
  slim, "input/grib_pop_index_local_adaptation/migration_matrix",
  sprintf("grib_migration_matrix_4pop_%s.csv", TREATMENT)), header = FALSE))

stopifnot(nrow(loc) == 4, dim(mig) == c(4, 4))

# Population order p0..p3 is fixed everywhere in this project.
loc$label <- c("Geneva", "Bern", "Zurich", "St. Gallen")

# Project to the Swiss national grid so distances and shape are correct.
pts <- st_transform(st_as_sf(loc, coords = c("lon", "lat"), crs = 4326), 2056)
xy  <- st_coordinates(pts)
loc$X <- xy[, 1]; loc$Y <- xy[, 2]

# One row per unordered pair of demes.
edges <- expand.grid(i = 1:4, j = 1:4) |>
  filter(i < j) |>
  mutate(rate = mig[cbind(i, j)],
         x    = loc$X[i],    y    = loc$Y[i],
         xend = loc$X[j],    yend = loc$Y[j],
         mx   = (x + xend) / 2, my = (y + yend) / 2)

## ---- basemap --------------------------------------------------------------

eu <- ne_countries(scale = MAP_SCALE, returnclass = "sf",
                   country = c("Switzerland", "France", "Germany",
                               "Italy", "Austria"))
# rnaturalearth versions differ on which column holds the country name.
nm <- if ("admin" %in% names(eu)) eu$admin else eu$name
eu <- st_transform(eu, 2056)
ch <- eu[nm == "Switzerland", ]
nb <- eu[nm != "Switzerland", ]

## ---- label nudges (metres; adjust to taste) --------------------------------

loc$dx <- c(  -4000,      0,   -2000,  15000)
loc$dy <- c( -21000, -21000,   16000,   6000)
loc$hj <- c(    0.5,    0.5,     0.5,      0)
loc$vj <- c(      1,      1,       0,      0)

## ---- plot -----------------------------------------------------------------

p <- ggplot() +
  geom_sf(data = nb, fill = "#f0efec", colour = "white",   linewidth = 0.6) +
  geom_sf(data = ch, fill = "white",   colour = "#b9b7b0", linewidth = 0.8) +

  # migration links, width proportional to the per-generation rate
  geom_curve(data = edges,
             aes(x = x, y = y, xend = xend, yend = yend, linewidth = rate),
             curvature = 0.16, colour = MUTED, alpha = 0.8,
             arrow = arrow(length = unit(0.18, "cm"),
                           ends = "both", type = "closed")) +
  scale_linewidth(range = c(0.5, 2.6), guide = "none") +

  # rate labels on each link
  geom_label(data = edges,
             aes(x = mx, y = my + 7000,
                 label = sprintf("%.2f%%", rate * 100)),
             size = 4.0, colour = INK2, fill = "white",
             label.size = 0, label.padding = unit(0.10, "lines")) +

  # the four demes
  geom_point(data = loc, aes(X, Y, fill = label),
             shape = 21, size = 7, stroke = 1.4, colour = "white") +
  scale_fill_manual(values = PAL, guide = "none") +
  geom_text(data = loc,
            aes(X + dx, Y + dy, label = label, hjust = hj, vjust = vj),
            size = 6.2, fontface = "bold", colour = INK) +

  # scale bar (LV95 units are metres)
  annotate("segment", x = 2498000, xend = 2548000, y = 1060000, yend = 1060000,
           linewidth = 1.1, colour = INK2) +
  annotate("text", x = 2523000, y = 1067000, label = "50 km",
           size = 4.4, colour = INK2) +

  coord_sf(xlim = c(2480000, 2860000), ylim = c(1048000, 1312000),
           expand = FALSE, datum = NA) +
  labs(caption = sprintf(
    paste0("Per-generation emigration probability between demes, '%s' treatment. ",
           "Arrow width scales with rate. Projection EPSG:2056 (LV95)."),
    TREATMENT)) +
  theme_void(base_family = "sans") +
  theme(plot.caption = element_text(hjust = 0, colour = MUTED, size = 10,
                                    margin = margin(t = 8)),
        plot.margin  = margin(6, 6, 6, 6))

## ---- save -----------------------------------------------------------------

out_dir <- file.path(slim, "results", "figures")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out <- file.path(out_dir, sprintf("map_4pop_migration_%s.png", TREATMENT))

ggsave(out, p, width = 12.6, height = 6.6, dpi = 300, bg = "white")
cat("wrote", out, "\n")

# Rates actually drawn, for the caption / slide notes:
print(edges |>
        mutate(from = loc$label[i], to = loc$label[j]) |>
        select(from, to, rate))
