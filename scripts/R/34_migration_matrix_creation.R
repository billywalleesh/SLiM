#make one migration matrix for each run in run_matrix_1000.csv (made by 33_batch_matrix_creation.R)
#migration rate = a + slope * distance, with a fixed at 0.005 and the slope from each run

library(sf)

## the linear decay function (same as in 32_dispersal_decay_function.R)
linear_decay = function(d, a, b) { # d is the distance value, a the intercept, b is the slope
  mr = a + d*b # migration rate simple linear regression of d
  mr[mr<0] = 0 # negative migration values not allowed
  mr[d == 0] = NA # if distance is 0, return NAs
  return(mr)
}

## load the run matrix
run_matrix = read.csv("run_matrix_1000.csv")
head(run_matrix)

## coordinates of the 8 cities (same as in 32_dispersal_decay_function.R)
coordinates = data.frame()
coordinates['geneva',1:2]     = c(46.211464648492914, 6.14748447123683)
coordinates['lausanne',1:2]   = c(46.5197, 6.6323)
coordinates['neuchatel',1:2]  = c(46.9896, 6.9293)
coordinates['bern',1:2]       = c(46.94798849012668, 7.446219548848173)
coordinates['solothurn',1:2]  = c(47.2088, 7.5372)
coordinates['lucerne',1:2]    = c(47.0502, 8.3093)
coordinates['winterthur',1:2] = c(47.4988, 8.7237)
coordinates['stgallen',1:2]   = c(47.42899841401629, 9.376234097036747)
colnames(coordinates) = c('lat','lon')
coordinates

## calculate distances in km between all 8 cities
coord_sp <- st_as_sf(coordinates, coords = c("lon", "lat"), crs = 4326)
geoD = as.matrix(st_distance(coord_sp)/1000)
geoD = units::drop_units(geoD)

# name the rows and columns with the city numbers 0-7
# 0 geneva, 1 lausanne, 2 neuchatel, 3 bern, 4 solothurn, 5 lucerne, 6 winterthur, 7 stgallen
colnames(geoD) = rownames(geoD) = 0:7
geoD

## make a folder for the migration matrices
dir.create("migration_matrices")

## make the migration matrix for every run
mean_emigration = c() # total migration out of each population, averaged (goes up with more populations)

for (i in 1:nrow(run_matrix)) {

  # the cities in this run, e.g. "0;3;5;7" becomes "0" "3" "5" "7"
  ids = strsplit(run_matrix$pop_ids[i], ";")[[1]]

  # the slope for this run
  slope = run_matrix$slope_decay[i]

  # distances between only the cities in this run
  d = geoD[ids, ids]

  # convert distance to migration rate
  mig = linear_decay(d, a = 0.005, b = slope)

  # no migration from a population to itself
  diag(mig) = 0

  # save it
  write.table(mig, paste0("migration_matrices/run_", i, ".csv"), sep = ",", row.names = FALSE, col.names = FALSE)

  mean_emigration[i] = mean(rowSums(mig))
}

## check run 1 by hand
ids = strsplit(run_matrix$pop_ids[1], ";")[[1]]
ids
run1 = read.csv("migration_matrices/run_1.csv", header = FALSE)
run1

# first two cities of run 1: rate should be 0.005 + slope * distance
0.005 + run_matrix$slope_decay[1] * geoD[ids[1], ids[2]]
run1[1, 2]

## save mean emigration per run
mig_summary = data.frame(run = run_matrix$run, n_populations = run_matrix$n_populations, mean_emigration)
head(mig_summary)

write.csv(mig_summary, "migration_summary_1000.csv", row.names = FALSE)
