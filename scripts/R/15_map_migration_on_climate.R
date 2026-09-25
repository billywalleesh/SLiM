# ---------------------------------------------------------------------------
# 15_map_migration_on_climate.R
#
# The same map as 14_map_mean_annual_temp.R - same extent, frame, border,
# sites and styling - with migration between the four demes drawn on top.
#
# SHOW_CLIMATE <- TRUE   climate raster behind the links
# SHOW_CLIMATE <- FALSE  plain white background, links only
#
# Writes: results/figures/map_migration_<treatment>[_climate].{png,pdf}
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(terra); library(ggplot2); library(sf); library(rnaturalearth)
})

root <- Sys.getenv("MSC_WORKSPACE", "C:/Users/WilliamWallisch/msc_workspace")
slim <- file.path(root, "SLiM")

SHOW_CLIMATE <- TRUE
TREATMENT    <- "strong"        # "weak" | "strong" | "decay"
YEARS        <- 1940:2025

COL_COLD <- "#2166AC"; COL_MID <- "#F7F7F7"; COL_WARM <- "#B2182B"
LINK_COL <- "grey25"

## ---- climate ---------------------------------------------------------------

grib  <- rast(file.path(slim, "data/raw/2m_temp_1940-2026.grib"))
yr    <- as.integer(format(as.Date(time(grib)), "%Y"))
tmean <- mean(grib[[which(yr %in% YEARS)]]) - 273.15
names(tmean) <- "temp_C"
df <- as.data.frame(tmean, xy = TRUE, na.rm = TRUE)
lims <- range(df$temp_C)
cat(sprintf("climate %.2f to %.2f degC, white at %.2f\n",
            lims[1], lims[2], mean(lims)))

## ---- border, sites, migration ----------------------------------------------

ch <- ne_countries(country = "Switzerland", scale = "medium", returnclass = "sf")

loc <- read.csv(file.path(
  slim, "input/grib_pop_index_local_adaptation/population_locations",
  "grib_population_locations_4pop_swiss_plateau.csv"))
loc$label <- c("Geneva", "Bern", "Zurich", "St. Gallen")
loc$nx <- c( 0.12,  0.00,  0.00,  0.12)
loc$ny <- c(-0.12, -0.14,  0.14,  0.14)
loc$hj <- c( 0,     0.5,   0.5,   0   )

mig <- as.matrix(read.csv(file.path(
  slim, "input/grib_pop_index_local_adaptation/migration_matrix",
  sprintf("grib_migration_matrix_4pop_%s.csv", TREATMENT)), header = FALSE))

edges <- expand.grid(i = 1:4, j = 1:4)
edges <- edges[edges$i < edges$j, ]
edges$rate <- mig[cbind(edges$i, edges$j)]
edges$x    <- loc$lon[edges$i]; edges$y    <- loc$lat[edges$i]
edges$xend <- loc$lon[edges$j]; edges$yend <- loc$lat[edges$j]

cat(sprintf("%s migration: %s per generation\n", TREATMENT,
            paste(unique(format(edges$rate, digits = 3)), collapse = ", ")))

## ---- map -------------------------------------------------------------------

p <- ggplot()

if (SHOW_CLIMATE) {
  p <- p +
    geom_raster(data = df, aes(x, y, fill = temp_C)) +
    scale_fill_gradient2(low = COL_COLD, mid = COL_MID, high = COL_WARM,
                         midpoint = mean(lims), limits = lims,
                         name = "Mean annual\ntemperature\n1940\u20132025 (\u00B0C)")
}

p <- p +
  geom_sf(data = ch, fill = if (SHOW_CLIMATE) NA else "white",
          colour = "black", linewidth = 0.5) +
  # Straight links: with four demes there are six of them, and curves tangle.
  geom_segment(data = edges,
               aes(x = x, y = y, xend = xend, yend = yend, linewidth = rate),
               colour = LINK_COL, alpha = 0.85, lineend = "round") +
  scale_linewidth(range = c(0.45, 1.6), guide = "none") +
  geom_point(data = loc, aes(lon, lat), shape = 21,
             fill = "black", colour = "white", size = 2.8, stroke = 0.9) +
  geom_label(data = loc, aes(lon + nx, lat + ny, label = label, hjust = hj),
             size = 3.0, colour = "black", fontface = "bold",
             fill = "white", alpha = 0.78, label.size = 0,
             label.padding = unit(0.09, "lines")) +
  coord_sf(xlim = range(df$x), ylim = range(df$y), expand = FALSE) +
  labs(x = NULL, y = NULL,
       title = sprintf("Migration between demes (%s: %.3g per generation)",
                       TREATMENT, edges$rate[1])) +
  theme_bw(base_size = 10) +
  theme(panel.grid   = element_blank(),
        panel.border = element_rect(colour = "black", linewidth = 0.6),
        legend.key.height = unit(1.1, "cm"),
        legend.key.width  = unit(0.35, "cm"),
        legend.title = element_text(size = 8.5),
        legend.text  = element_text(size = 8),
        plot.title   = element_text(hjust = 0.5, face = "bold", size = 10))

## ---- save ------------------------------------------------------------------

out <- file.path(slim, "results", "figures")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
stem <- file.path(out, sprintf("map_migration_%s%s", TREATMENT,
                               if (SHOW_CLIMATE) "_climate" else ""))
ggsave(paste0(stem, ".png"), p, width = 7.2, height = 4.4, dpi = 300, bg = "white")
ggsave(paste0(stem, ".pdf"), p, width = 7.2, height = 4.4, bg = "white",
       device = grDevices::cairo_pdf)
cat("wrote", paste0(stem, ".png/.pdf"), "\n")
