# ---------------------------------------------------------------------------
# 17_map_migration_bw.R
#
# Migration between the four demes, distance-decay treatment, in black and
# white, on the same frame as 14_map_mean_annual_temp.R so the two figures
# sit together in the deck: identical extent, projection, panel geometry,
# site markers, label style and output size.
#
# Traces are quadratic Beziers bowing south, bow depth proportional to chord
# length, so the six links nest instead of piling up. Each trace is drawn over
# a white halo, thinnest first, so crossings read as over/under rather than as
# a blot - in colour that job was done by hue.
#
# Writes: results/figures/map_migration_bw_<TREATMENT>.{png,pdf}
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(ggplot2); library(sf); library(rnaturalearth)
})

root <- Sys.getenv("MSC_WORKSPACE", "C:/Users/WilliamWallisch/msc_workspace")
slim <- file.path(root, "SLiM")

TREATMENT <- "decay"
BOW       <- 0.16    # bow depth as a fraction of chord length
W_RANGE   <- c(0.7, 2.1)   # trace width in mm, thinnest to thickest link
HALO      <- 1.3     # extra mm of white under each trace

# Frame copied from 14_map_mean_annual_temp.R: the ERA5 cell centres, i.e.
# range(df$x) and range(df$y) of the raster that map is drawn from.
XLIM <- c(6.00, 10.50)
YLIM <- c(46.00, 47.75)

## ---- data ------------------------------------------------------------------

loc <- read.csv(file.path(
  slim, "input/grib_pop_index_local_adaptation/population_locations",
  "grib_population_locations_4pop_swiss_plateau.csv"))
loc$label <- c("Geneva", "Bern", "Zurich", "St. Gallen")

# Same nudges as the temperature map, except Geneva, whose label would sit on
# top of the Geneva-St. Gallen trace if it stayed below the point.
loc$nx <- c( 0.12,  0.00,  0.00,  0.12)
loc$ny <- c( 0.14,  0.15,  0.14,  0.14)
loc$hj <- c( 0,     0.5,   0.5,   0   )

mig <- as.matrix(read.csv(file.path(
  slim, "input/grib_pop_index_local_adaptation/migration_matrix",
  sprintf("grib_migration_matrix_4pop_%s.csv", TREATMENT)), header = FALSE))

ch <- ne_countries(country = "Switzerland", scale = "medium", returnclass = "sf")

links <- data.frame(i = c(1, 2, 3, 1, 2, 1),
                    j = c(2, 3, 4, 3, 4, 4))
links$rate <- mig[cbind(links$i, links$j)]

# Width in mm, assigned by rate. Identity scale, so the halo layer can carry a
# second width without ggplot complaining about two linewidth scales.
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

# Open arrowheads riding the trace, one near each end, tangent to the curve.
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
cat(sprintf("southernmost point of any trace: %.3f N (frame starts %.2f)\n",
            min(path$y), YLIM[1]))

## ---- plot ------------------------------------------------------------------

# One halo + one trace per link, thinnest link first, so the heaviest flow
# passes over the lighter ones at every crossing.
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

p <- ggplot() +
  geom_sf(data = ch, fill = "grey96", colour = "black", linewidth = 0.5) +
  trace_layers +
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
  coord_sf(xlim = XLIM, ylim = YLIM, expand = FALSE) +
  labs(x = NULL, y = NULL,
       title = "Swiss Plateu Population Migration") +
  theme_bw(base_size = 10) +
  theme(panel.grid   = element_blank(),
        panel.border = element_rect(colour = "black", linewidth = 0.6),
        legend.key.height = unit(0.55, "cm"),
        legend.key.width  = unit(0.9,  "cm"),
        legend.title = element_text(size = 8.5),
        legend.text  = element_text(size = 8),
        plot.title   = element_text(hjust = 0.5, face = "bold"))

## ---- save ------------------------------------------------------------------

out <- file.path(slim, "results", "figures")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
f <- file.path(out, sprintf("map_migration_bw_%s", TREATMENT))

ggsave(paste0(f, ".png"), p, width = 7.2, height = 4.4, dpi = 300, bg = "white")
ggsave(paste0(f, ".pdf"), p, width = 7.2, height = 4.4, bg = "white",
       device = grDevices::cairo_pdf)
cat("wrote", paste0(f, ".png/.pdf"), "\n")
p
