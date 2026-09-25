# ---------------------------------------------------------------------------
# 16_map_migration_circuit.R
#
# Migration between the four demes, distance-decay treatment, drawn as
# blueprint traces: no straight chords, trace width proportional to the
# per-generation migration rate, open arrowheads at both ends.
#
# STYLE <- "arc"      smooth nested bows; nothing orthogonal  (default)
# STYLE <- "circuit"  lane routing with filleted corners      (squarer)
#
# BLUEPRINT <- TRUE   white traces on blueprint navy
# BLUEPRINT <- FALSE  navy traces on white
#
# Writes:
#   results/figures/map_migration_<STYLE>_<TREATMENT>[_blueprint].{png,pdf}
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(ggplot2); library(sf); library(rnaturalearth)
})

root <- Sys.getenv("MSC_WORKSPACE", "C:/Users/WilliamWallisch/msc_workspace")
slim <- file.path(root, "SLiM")

TREATMENT <- "decay"
STYLE     <- "arc"
BLUEPRINT <- FALSE

BOW       <- 0.20   # arc only: bow depth as a fraction of the chord length
CORNER_R  <- 0.16   # circuit only: fillet radius in degrees; 0 gives square

pal <- if (BLUEPRINT) {
  list(bg = "#123a5e", land = "#17476f", edge = "#7fb3d9",
       trace = "#eaf4fb", ink = "#ffffff", grid = "#2b5c86", labfill = "#123a5e")
} else {
  list(bg = "#ffffff", land = "#f2f6fa", edge = "#9bb3c7",
       trace = "#1f4e79", ink = "#0b0b0b", grid = "#dce6ee", labfill = "#ffffff")
}

## ---- data ------------------------------------------------------------------

loc <- read.csv(file.path(
  slim, "input/grib_pop_index_local_adaptation/population_locations",
  "grib_population_locations_4pop_swiss_plateau.csv"))
loc$label <- c("Geneva", "Bern", "Zurich", "St. Gallen")
loc$lx <- c(0.00, 0.00, 0.00, 0.24)
loc$ly <- c(0.19, 0.19, 0.19, 0.00)
loc$hj <- c(0.5,  0.5,  0.5,  0   )

mig <- as.matrix(read.csv(file.path(
  slim, "input/grib_pop_index_local_adaptation/migration_matrix",
  sprintf("grib_migration_matrix_4pop_%s.csv", TREATMENT)), header = FALSE))

ch <- ne_countries(country = "Switzerland", scale = "medium", returnclass = "sf")

links <- data.frame(i = c(1, 2, 3, 1, 2, 1),
                    j = c(2, 3, 4, 3, 4, 4))
links$rate <- mig[cbind(links$i, links$j)]

## ---- geometry helpers ------------------------------------------------------

# A quadratic Bezier bowing away from the chord. Bow depth scales with chord
# length, so long links sit outside short ones and the six traces nest instead
# of crossing.
arc_pts <- function(x1, y1, x2, y2, bow, n = 160) {
  mx <- (x1 + x2) / 2; my <- (y1 + y2) / 2
  dx <- x2 - x1; dy <- y2 - y1
  L  <- sqrt(dx^2 + dy^2)
  cx <- mx + (dy / L) * bow * L * 2      # perpendicular, south side
  cy <- my - (dx / L) * bow * L * 2
  t  <- seq(0, 1, length.out = n)
  data.frame(x = (1 - t)^2 * x1 + 2 * (1 - t) * t * cx + t^2 * x2,
             y = (1 - t)^2 * y1 + 2 * (1 - t) * t * cy + t^2 * y2)
}

# Replaces each interior corner with a quadratic Bezier, so a lane route keeps
# its orthogonal logic but bends instead of snapping.
round_corners <- function(x, y, r = 0.1, n = 20) {
  m <- length(x)
  if (m < 3 || r <= 0) return(data.frame(x = x, y = y))
  ox <- x[1]; oy <- y[1]
  for (i in 2:(m - 1)) {
    p0 <- c(x[i - 1], y[i - 1]); p1 <- c(x[i], y[i]); p2 <- c(x[i + 1], y[i + 1])
    v1 <- p0 - p1; v2 <- p2 - p1
    l1 <- sqrt(sum(v1^2)); l2 <- sqrt(sum(v2^2))
    if (l1 == 0 || l2 == 0) next
    d <- min(r, l1 / 2, l2 / 2)
    a <- p1 + v1 / l1 * d
    b <- p1 + v2 / l2 * d
    t <- seq(0, 1, length.out = n)
    ox <- c(ox, (1 - t)^2 * a[1] + 2 * (1 - t) * t * p1[1] + t^2 * b[1])
    oy <- c(oy, (1 - t)^2 * a[2] + 2 * (1 - t) * t * p1[2] + t^2 * b[2])
  }
  data.frame(x = c(ox, x[m]), y = c(oy, y[m]))
}

## ---- routing ---------------------------------------------------------------

if (STYLE == "arc") {
  path <- do.call(rbind, lapply(seq_len(nrow(links)), function(k) {
    a <- links$i[k]; b <- links$j[k]
    data.frame(link = k, rate = links$rate[k],
               arc_pts(loc$lon[a], loc$lat[a], loc$lon[b], loc$lat[b], BOW))
  }))
} else {
  lanes <- c(47.15, 46.90, 46.70, 46.55, 46.40, 46.25)
  ord   <- order(-links$rate)                 # strongest link hugs the chain
  lane  <- numeric(nrow(links)); lane[ord] <- lanes
  path <- do.call(rbind, lapply(seq_len(nrow(links)), function(k) {
    a <- links$i[k]; b <- links$j[k]; ly <- lane[k]
    data.frame(link = k, rate = links$rate[k],
               round_corners(x = c(loc$lon[a], loc$lon[a], loc$lon[b], loc$lon[b]),
                             y = c(loc$lat[a], ly,         ly,         loc$lat[b]),
                             r = CORNER_R))
  }))
}

# Open arrowheads riding the trace, one near each end, tangent to the curve.
heads <- do.call(rbind, lapply(split(path, path$link), function(d) {
  n <- nrow(d)
  f <- c(0.13, 0.87); g <- c(0.19, 0.81)     # tail and tip fractions
  idx <- function(p) pmax(1, pmin(n, round(p * n)))
  data.frame(link = d$link[1], rate = d$rate[1],
             x    = d$x[idx(f)], y    = d$y[idx(f)],
             xend = d$x[idx(g)], yend = d$y[idx(g)])
}))

cat("rates drawn:\n")
print(data.frame(from = loc$label[links$i], to = loc$label[links$j],
                 rate = links$rate))

## ---- plot ------------------------------------------------------------------

p <- ggplot() +
  geom_sf(data = ch, fill = pal$land, colour = pal$edge, linewidth = 0.6) +
  geom_path(data = path, aes(x, y, group = link, linewidth = rate),
            colour = pal$trace, lineend = "round", alpha = 0.95) +
  geom_segment(data = heads,
               aes(x = x, y = y, xend = xend, yend = yend, linewidth = rate),
               colour = pal$trace, lineend = "butt",
               arrow = arrow(length = unit(0.17, "cm"), type = "open",
                             angle = 22)) +
  scale_linewidth(range = c(0.9, 2.7),
                  breaks = sort(unique(links$rate)),
                  labels = function(v) sprintf("%.1f%%", v * 100),
                  name = "Migration rate\nper generation") +
  geom_point(data = loc, aes(lon, lat), shape = 21, fill = pal$bg,
             colour = pal$trace, size = 6.4, stroke = 1.9) +
  geom_point(data = loc, aes(lon, lat), colour = pal$trace, size = 1.7) +
  geom_label(data = loc, aes(lon + lx, lat + ly, label = label, hjust = hj),
             size = 3.2, colour = pal$ink, fontface = "bold",
             fill = pal$labfill, alpha = 0.85, label.size = 0,
             label.padding = unit(0.10, "lines")) +
  coord_sf(xlim = c(5.7, 10.7), ylim = c(45.78, 47.92), expand = FALSE) +
  labs(x = NULL, y = NULL,
       title = "Migration between demes, distance-decay") +
  theme_bw(base_size = 10) +
  theme(panel.background  = element_rect(fill = pal$bg, colour = NA),
        plot.background   = element_rect(fill = pal$bg, colour = NA),
        legend.background = element_rect(fill = pal$bg, colour = NA),
        legend.key        = element_rect(fill = pal$bg, colour = NA),
        panel.grid   = element_line(colour = pal$grid, linewidth = 0.3,
                                    linetype = "dashed"),
        panel.border = element_rect(colour = pal$edge, linewidth = 0.6),
        axis.text    = element_text(colour = pal$ink, size = 8),
        legend.key.height = unit(0.55, "cm"),
        legend.title = element_text(size = 8.5, colour = pal$ink),
        legend.text  = element_text(size = 8,   colour = pal$ink),
        plot.title   = element_text(hjust = 0.5, face = "bold", size = 10,
                                    colour = pal$ink))

## ---- save ------------------------------------------------------------------

out <- file.path(slim, "results", "figures")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
stem <- file.path(out, sprintf("map_migration_%s_%s%s", STYLE, TREATMENT,
                               if (BLUEPRINT) "_blueprint" else ""))

ggsave(paste0(stem, ".png"), p, width = 7.2, height = 4.4, dpi = 300,
       bg = pal$bg)
ggsave(paste0(stem, ".pdf"), p, width = 7.2, height = 4.4, bg = pal$bg,
       device = grDevices::cairo_pdf)
cat("wrote", paste0(stem, ".png/.pdf"), "\n")
