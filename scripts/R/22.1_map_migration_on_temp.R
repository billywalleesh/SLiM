#this script makes the map of the mean temperature (1940-2025) with the migration between the populations on top
#it uses one run from the cluster run matrix, so only the cities that are in that run are drawn
#the migration matrix is symmetric so every line means migration in both directions, thicker line = higher migration rate
#it saves 2 pictures: one with only the temperature and one with temperature + migration, the map is in the same spot in both
#so they can be used on 2 slides after each other

library(terra)
library(ggplot2)
library(sf)
library(rnaturalearth)

#which run to draw
run = 22

#folders
slim_folder = "C:/Users/WilliamWallisch/msc_workspace/SLiM"
run_folder = file.path(slim_folder, "input/grib_pop_index_local_adaptation/run_repo/14102026")

#the years for the mean temperature
years = 1940:2025

#settings for the lines
bow = 0.10 #how much the lines bend
line_min = 0.1 #thinnest line in mm
line_max = 1.3 #thickest line in mm
halo = 0.35 #white edge around the lines so they show up on the colours


##temperature
#load the temperature data and only keep the years we want
temp = rast(file.path(slim_folder, "data/raw/2m_temp_1940-2026.grib"))
temp_years = as.integer(format(as.Date(time(temp)), "%Y"))
temp = temp[[which(temp_years %in% years)]]

#mean over all days, kelvin to celsius
temp_mean = mean(temp) - 273.15

#turn into a data frame for ggplot
temp_df = as.data.frame(temp_mean, xy = TRUE, na.rm = TRUE)
colnames(temp_df) = c("x", "y", "temp_C")
head(temp_df)

#white in the middle of the colour scale
temp_range = range(temp_df$temp_C)
temp_mid = mean(temp_range)
temp_range


##switzerland border
swiss = ne_countries(country = "Switzerland", scale = "medium", returnclass = "sf")


##cities in this run
run_matrix = read.csv(file.path(run_folder, "run_matrix_1000.csv"))

#the city numbers in this run, e.g. "0;1;4;5" becomes 0 1 4 5
ids = as.numeric(strsplit(run_matrix$pop_ids[run_matrix$run == run], ";")[[1]])
ids

#all 8 cities with their coordinates
cities = read.csv(file.path(slim_folder, "input/grib_pop_index_local_adaptation/population_locations/grib_population_locations_8pop_swiss_plateau.csv"))
cities

#names on the map and where the label goes next to the point (in degrees), in the same order as the city numbers 0-7
cities$label = c("Geneva", "Lausanne", "Neuch\u00E2tel", "Bern", "Solothurn", "Lucerne", "Winterthur", "St. Gallen")
cities$label_x = c(0.10, 0.10, -0.10, 0.10, 0, 0, 0, 0)
cities$label_y = c(0, 0, 0, -0.12, 0.14, -0.14, 0.14, 0.14)
cities$label_just = c(0, 0, 1, 0, 0.5, 0.5, 0.5, 0.5) #0 = label starts at the point, 1 = label ends at the point, 0.5 = centered

#keep only the cities in this run, in the same order as pop_ids (+1 because R counts from 1 and the city numbers start at 0)
loc = cities[ids + 1, ]
loc


##migration
#row/column 1 of the migration matrix is the first city in pop_ids, row/column 2 the second, ...
mig = as.matrix(read.csv(file.path(run_folder, "migration_matrices", paste0("run_", run, ".csv")), header = FALSE))
mig

#every pair of cities once, without migration rates of 0
links = data.frame()

for (i in 1:nrow(mig)) {
  for (j in 1:nrow(mig)) {
    if (i < j & mig[i, j] > 0) {
      links = rbind(links, data.frame(i = i, j = j, rate = mig[i, j]))
    }
  }
}

#line width for each link: the lowest rate gets line_min and the highest rate gets line_max
rate_min = min(links$rate)
rate_max = max(links$rate)
links$width = line_min + (links$rate - rate_min) / (rate_max - rate_min) * (line_max - line_min)

#print the links with the city names
data.frame(from = loc$label[links$i], to = loc$label[links$j], rate = links$rate)


##bent lines between the cities
#each line is a curve from city a to city b that bends a bit to the south
#the curve is made from 200 points
t = seq(0, 1, length.out = 200)
lines_df = data.frame()

for (k in 1:nrow(links)) {

  x1 = loc$lon[links$i[k]]
  y1 = loc$lat[links$i[k]]
  x2 = loc$lon[links$j[k]]
  y2 = loc$lat[links$j[k]]

  #middle point of the curve, moved to the side so the line bends
  mid_x = (x1 + x2) / 2 + (y2 - y1) * bow * 2
  mid_y = (y1 + y2) / 2 - (x2 - x1) * bow * 2

  #points on the curve
  x = (1 - t)^2 * x1 + 2 * (1 - t) * t * mid_x + t^2 * x2
  y = (1 - t)^2 * y1 + 2 * (1 - t) * t * mid_y + t^2 * y2

  lines_df = rbind(lines_df, data.frame(link = k, x = x, y = y, width = links$width[k]))
}


##legend for the lines
#a few round rates between the lowest and highest rate
legend_rates = pretty(c(rate_min, rate_max), n = 4)
legend_rates = legend_rates[legend_rates >= rate_min & legend_rates <= rate_max]
legend_widths = line_min + (legend_rates - rate_min) / (rate_max - rate_min) * (line_max - line_min)
legend_rates


##map with only temperature
map_temp = ggplot() +
  geom_raster(data = temp_df, aes(x, y, fill = temp_C)) +
  geom_sf(data = swiss, fill = NA, colour = "black", linewidth = 0.5)

##map with temperature and migration
map_mig = map_temp

#draw the thinnest lines first so the thick lines are on top
for (k in order(links$width)) {
  one_line = lines_df[lines_df$link == k, ]
  map_mig = map_mig +
    geom_path(data = one_line, aes(x, y), colour = "white", linewidth = links$width[k] + halo, lineend = "round") +
    geom_path(data = one_line, aes(x, y, linewidth = width), colour = "black", lineend = "round")
}

#the rest is the same for both maps: colours, legend, cities, labels and the look
finish_map = function(map, title) {
  map +
    scale_fill_gradient2(low = "#2166AC", mid = "#F7F7F7", high = "#B2182B", midpoint = temp_mid,
                         limits = temp_range, name = "Temperature (\u00B0C)") +
    scale_linewidth_identity(guide = "legend", breaks = legend_widths,
                             labels = paste0(format(legend_rates * 100, nsmall = 2), "%"),
                             name = "Migration rate\nper generation") +
    geom_point(data = loc, aes(lon, lat), shape = 21, fill = "black", colour = "white", size = 2.6, stroke = 0.8) +
    geom_label(data = loc, aes(lon + label_x, lat + label_y, label = label, hjust = label_just),
               size = 3, fontface = "bold", fill = "white", alpha = 0.9, label.size = 0,
               label.padding = unit(0.09, "lines")) +
    coord_sf(xlim = range(temp_df$x), ylim = range(temp_df$y), expand = FALSE) +
    labs(x = NULL, y = NULL, title = title) +
    guides(fill = guide_colourbar(order = 1),
           linewidth = guide_legend(order = 2, keyheight = unit(0.3, "cm"), keywidth = unit(0.8, "cm"))) +
    theme_bw(base_size = 10) +
    theme(panel.grid = element_blank(),
          panel.border = element_rect(colour = "black", linewidth = 0.6),
          legend.justification = "top",
          legend.key.height = unit(0.9, "cm"),
          legend.key.width = unit(0.35, "cm"),
          legend.title = element_text(size = 8.5),
          legend.text = element_text(size = 8),
          legend.spacing.y = unit(0.25, "cm"),
          plot.title = element_text(hjust = 0.5, face = "bold"))
}

map_temp = finish_map(map_temp, "Mean annual temperature 1940\u20132025")
map_mig = finish_map(map_mig, paste("Temperature gradient and migration, run", run))
map_mig


##keep the map in the same spot in both pictures
#the migration map has an extra legend, which makes the legend column wider and the map smaller
#so the legend column is set to 3 cm in both pictures
fix_legend = function(map) {
  g = ggplotGrob(map)
  legend_col = max(g$layout$l[grep("guide-box", g$layout$name)]) #the legend on the right is the last column
  g$widths[legend_col] = unit(3, "cm")
  g
}

map_temp_fixed = fix_legend(map_temp)
map_mig_fixed = fix_legend(map_mig)


##save
out_folder = file.path(slim_folder, "results/figures")
dir.create(out_folder, showWarnings = FALSE)

ggsave(file.path(out_folder, "map_temp_only_1940_2025.png"), map_temp_fixed, width = 7.2, height = 4.4, dpi = 300, bg = "white")
ggsave(file.path(out_folder, "map_temp_only_1940_2025.pdf"), map_temp_fixed, width = 7.2, height = 4.4, bg = "white", device = cairo_pdf)

ggsave(file.path(out_folder, paste0("map_migration_on_temp_run_", run, ".png")), map_mig_fixed, width = 7.2, height = 4.4, dpi = 300, bg = "white")
ggsave(file.path(out_folder, paste0("map_migration_on_temp_run_", run, ".pdf")), map_mig_fixed, width = 7.2, height = 4.4, bg = "white", device = cairo_pdf)
