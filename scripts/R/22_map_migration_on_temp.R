# ---------------------------------------------------------------------------
# 18_map_migration_on_temp.R
#
# One map carrying both halves of the model setup: the climate gradient the
# demes sit in, and the migration that connects them.
#
#   fill       mean annual 2 m temperature over PERIOD (ERA5, diverging RdBu)
#   traces     per-generation migration between demes, width by rate
#
# The traces stay black on a white halo so they read over any part of the
# colour ramp - the raster owns colour here, the network owns weight.
#
# Same frame, projection, marker and label style as 14_map_mean_annual_temp.R,
# and the panel is forced to the identical rectangle: the plot is built twice,
# once without the migration layer, and the gtable column/row sizes of that
# reference are copied over. Both figures therefore put the map in exactly the
# same place on a 7.2 x 4.4 in canvas, so a slide transition crossfades cleanly
# instead of sliding.
#
# Writes: results/figures/map_migration_on_temp_<TREATMENT>.{png,pdf}
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(terra); library(ggplot2); library(sf); library(rnaturalearth)
})

root <- Sys.getenv("MSC_WORKSPACE", "C:/Users/WilliamWallisch/msc_workspace")
slim <- file.path(root, "SLiM")

TREATMENT <- "decay"
PERIOD    <- 1940:2025    # years averaged for the temperature field

BOW       <- 0.16         # bow depth as a fraction of chord length
W_RANGE   <- c(0.7, 2.1)  # trace width in mm, thinnest to thickest link
HALO      <- 0.8          # extra mm of white under each trace
LEGEND_W  <- 3.0          # cm; fixed legend column, so the panel cannot move

COL_COLD <- "#2166AC"; COL_MID <- "#F7F7F7"; COL_WARM <- "#B2182B"
MIDPOINT_MODE <- "range"  # "range" | "zero"

## ---- temperature field -----------------------------------------------------

grib <- rast(file.path(slim, "data/raw/2m_temp_1940-2026.grib"))
yr   <- as.integer(format(as.Date(time(grib)), "%Y"))
keep <- which(yr %in% PERIOD)
cat(sprintf("%d-%d: %d daily layers\n", min(PERIOD), max(PERIOD), length(keep)))

tmean <- mean(grib[[keep]]) - 273.15
names(tmean) <- "temp_C"

df <- as.data.frame(tmean, xy = TRUE, na.rm = TRUE)
temp_limits <- range(df$temp_C)
midpoint <- if (MIDPOINT_MODE == "zero") 0 else mean(temp_limits)
cat(sprintf("colour scale: %.2f to %.2f degC, white at %.2f degC\n",
            temp_limits[1], temp_limits[2], midpoint))

## ---- sites, border, migration ----------------------------------------------

ch <- ne_countries(country = "Switzerland", scale = "medium", returnclass = "sf")

loc <- read.csv(file.path(
  slim, "input/grib_pop_index_local_adaptation/population_locations",
  "grib_population_locations_4pop_swiss_plateau.csv"))
loc$label <- c("Geneva", "Bern", "Zurich", "St. Gallen")

# As in the temperature map, except Geneva and Bern, whose labels would sit on
# top of a trace if they stayed below their points.
loc$nx <- c( 0.12,  0.00,  0.00,  0.12)
loc$ny <- c( 0.14,  0.15,  0.14,  0.14)
loc$hj <- c( 0,     0.5,   0.5,   0   )

mig <- as.matrix(read.csv(file.path(
  slim, "input/grib_pop_index_local_adaptation/migration_matrix",
  sprintf("grib_migration_matrix_4pop_%s.csv", TREATMENT)), header = FALSE))

links <- data.frame(i = c(1, 2, 3, 1, 2, 1),
                    j = c(2, 3, 4, 3, 4, 4))
links$rate <- mig[cbind(links$i, links$j)]

# Width in mm on an identity scale, so the white halo layer can carry its own
# width without ggplot demanding a second linewidth scale.
rr <- range(links$rate)
links$w <- if (diff(rr) == 0) mean(W_RANGE) else
  W_RANGE[1] + (links$rate - rr[1]) / diff(rr) * diff(W_RANGE)

## ---- geometry --------------------------------------------------------------

arc_pts <- function(x1, y1, x2, y2, bow, n = 200) {
  mx <- (x1 + x2) / 2; my <- (y1 + y2) / 2
  dx <- x2 - x1; dy <- y2 - y1
  L  <- sqrt(dx^2 + dy^2)
  cx <- mx + (dy / L) * bow * L * 2      # perpendicular, south side
  cy <- my - (dx / L) * bow * L * 2
  t  <- seq(0, 1, length.out = n)
  data.frame(x = (1 - t)^2 * x1 + 2 * (1 - t) * t * cx + t^2 * x2,
             y = (1 - t)^2 * y1 + 2 * (1 - t) * t * cy + t^2 * y2)
}

path <- do.call(rbind, lapply(seq_len(nrow(links)), function(k) {
  a <- links$i[k]; b <- links$j[k]
  data.frame(link = k, w = links$w[k],
             arc_pts(loc$lon[a], loc$lat[a], loc$lon[b], loc$lat[b], BOW))
}))

heads <- do.call(rbind, lapply(split(path, path$link), function(d) {
  n <- nrow(d); idx <- function(p) pmax(1, pmin(n, round(p * n)))
  f <- c(0.13, 0.87); g <- c(0.185, 0.815)
  data.frame(link = d$link[1], w = d$w[1],
             x    = d$x[idx(f)], y    = d$y[idx(f)],
             xend = d$x[idx(g)], yend = d$y[idx(g)])
}))

cat("rates drawn:\n")
print(data.frame(from = loc$label[links$i], to = loc$label[links$j],
                 rate = links$rate))

## ---- plot ------------------------------------------------------------------

# One halo + one trace per link, thinnest first, so the heaviest flow passes
# over the lighter ones at every crossing.
trace_layers <- unlist(lapply(order(links$w), function(k) {
  d <- path[path$link == k, ]; h <- heads[heads$link == k, ]
  list(
    geom_path(data = d, aes(x, y), colour = "white",
              linewidth = links$w[k] + HALO, lineend = "round"),
    geom_path(data = d, aes(x, y, linewidth = w), colour = "black",
              lineend = "round"),
    geom_segment(data = h, aes(x = x, y = y, xend = xend, yend = yend,
                               linewidth = w),
                 colour = "black", lineend = "butt",
                 arrow = arrow(length = unit(0.17, "cm"), type = "open",
                               angle = 22))
  )
}), recursive = FALSE)

# Built twice: once with the migration layers, once without. The second is the
# geometry reference - it is exactly the plot 14_map_mean_annual_temp.R makes,
# so copying its gtable sizes pins this panel to the same rectangle.
build <- function(traces = NULL, title_text) ggplot() +
  geom_raster(data = df, aes(x, y, fill = temp_C)) +
  geom_sf(data = ch, fill = NA, colour = "black", linewidth = 0.5) +
  traces +
  scale_fill_gradient2(low = COL_COLD, mid = COL_MID, high = COL_WARM,
                       midpoint = midpoint, limits = temp_limits,
                       name = "Temperature (\u00B0C)") +
  scale_linewidth_identity(
    guide  = "legend",
    breaks = sort(unique(links$w)),
    labels = sprintf("%.1f%%", sort(unique(links$rate)) * 100),
    name   = "Migration rate\nper generation") +
  geom_point(data = loc, aes(lon, lat), shape = 21,
             fill = "black", colour = "white", size = 2.6, stroke = 0.8) +
  geom_label(data = loc, aes(lon + nx, lat + ny, label = label, hjust = hj),
             size = 3.0, colour = "black", fontface = "bold",
             fill = "white", alpha = 0.90, label.size = 0,
             label.padding = unit(0.09, "lines")) +
  coord_sf(xlim = range(df$x), ylim = range(df$y), expand = FALSE) +
  labs(x = NULL, y = NULL, title = title_text) +
  guides(fill = guide_colourbar(order = 1),
         linewidth = guide_legend(order = 2,
                                  keyheight = unit(0.40, "cm"),
                                  keywidth  = unit(0.80, "cm"))) +
  theme_bw(base_size = 10) +
  theme(panel.grid   = element_blank(),
        panel.border = element_rect(colour = "black", linewidth = 0.6),
        legend.justification = "top",   # colourbar lands at the same
        legend.key.height = unit(1.1,  "cm"),   # height in both frames
        legend.key.width  = unit(0.35, "cm"),
        legend.title = element_text(size = 8.5),
        legend.text  = element_text(size = 8),
        legend.spacing.y  = unit(0.45, "cm"),
        plot.title   = element_text(hjust = 0.5, face = "bold"))

## ---- build both frames -----------------------------------------------------
# The pair is rendered from the same builder with the legend column pinned to a
# fixed width, so the panel lands on exactly the same rectangle in both. A slide
# transition then crossfades between them instead of sliding the map.

p <- build(trace_layers,
           sprintf("Temperature gradient and migration, %d\u2013%d",
                   min(PERIOD), max(PERIOD)))

p_temp <- build(NULL,
                sprintf("Mean annual temperature %d\u2013%d",
                        min(PERIOD), max(PERIOD)))

# ggplot sizes the legend column to fit its contents, so adding a second legend
# would steal width from the panel and shift the map between the two slides.
# Pinning that column to a fixed width is what keeps the panel identical.
# Done on the gtable rather than through a theme element, because the theme
# element for it does not exist before ggplot2 3.5.
pin_legend <- function(plot, w_cm = LEGEND_W) {
  g <- ggplotGrob(plot)
  i <- grep("^guide-box", g$layout$name)
  i <- i[g$layout$l[i] > g$layout$l[grep("^panel", g$layout$name)[1]]]
  if (!length(i)) stop("no guide box to the right of the panel")
  g$widths[g$layout$l[i[1]]] <- unit(w_cm, "cm")
  g
}

g      <- pin_legend(p)
g_temp <- pin_legend(p_temp)

## ---- save ------------------------------------------------------------------

out <- file.path(slim, "results", "figures")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
save_pair <- function(plot, stem) {
  f <- file.path(out, stem)
  ggsave(paste0(f, ".png"), plot, width = 7.2, height = 4.4, dpi = 300,
         bg = "white")
  ggsave(paste0(f, ".pdf"), plot, width = 7.2, height = 4.4, bg = "white",
         device = grDevices::cairo_pdf)
  cat("wrote", paste0(f, ".png/.pdf"), "\n")
}

# Both halves of the transition. Use the temperature frame from here rather than
# the one 14_ writes: that one sizes its legend column to its own content, so
# its panel is a few pixels wider and the map would jump between slides.
save_pair(g_temp, sprintf("map_temp_only_%d_%d", min(PERIOD), max(PERIOD)))
save_pair(g,      sprintf("map_migration_on_temp_%s", TREATMENT))
p
