#make one climate file for each run in run_matrix_1000.csv (made by 33_batch_matrix_creation.R)
#each run gets only the columns for its own cities, in the same order as pop_ids
#so column 1 of the climate file and row 1 of the migration file are the same city

## load the run matrix
run_matrix = read.csv("run_matrix_1000.csv")
head(run_matrix)

## load the 8-city climate file made by 35_grib_climate_matrix_8pop_degrees_c_1940_2025.R
## one row per year (1940-2025), one column per city, columns in city number order 0-7
workspace = Sys.getenv("MSC_WORKSPACE", unset = "C:/Users/WilliamWallisch/msc_workspace")
climate_8pop_file = file.path(workspace, "SLiM/input/grib_pop_index_local_adaptation/climate_matrix/grib_climate_matrix_8pop_degrees_c_1940_2025.csv")

climate_8pop = read.csv(climate_8pop_file, header = FALSE)

# name the columns with the city numbers 0-7
# 0 geneva, 1 lausanne, 2 neuchatel, 3 bern, 4 solothurn, 5 lucerne, 6 winterthur, 7 stgallen
colnames(climate_8pop) = 0:7
head(climate_8pop)

## city names, for the readable lookup table below
city_names = c("geneva", "lausanne", "neuchatel", "bern", "solothurn", "lucerne", "winterthur", "stgallen")

## make a folder for the climate files
dir.create("climate_matrices")

## make the climate file for every run
population_order = data.frame() # readable lookup: which city is in which column/row of each run's files

for (i in 1:nrow(run_matrix)) {

  # the cities in this run, e.g. "0;3;5;7" becomes "0" "3" "5" "7"
  ids = strsplit(run_matrix$pop_ids[i], ";")[[1]]

  # keep only the columns for the cities in this run, in pop_ids order
  clim = climate_8pop[, ids]

  # save it with no column names and no row names (the format SLiM expects)
  write.table(clim, paste0("climate_matrices/run_", i, ".csv"), sep = ",", row.names = FALSE, col.names = FALSE)

  # add this run to the lookup table
  population_order = rbind(population_order, data.frame(
    run = i,
    position = 1:length(ids),                   # column in the climate file = row/column in the migration file
    city_id = as.numeric(ids),                  # SLiM subpopulation p<city_id>
    city = city_names[as.numeric(ids) + 1]      # +1 because R counts from 1, the city numbers start at 0
  ))
}

## save the lookup table
head(population_order, 12)
write.csv(population_order, "run_population_order_1000.csv", row.names = FALSE)

## check run 1 by hand: column 1 of run_1.csv should be the full 8-city column for the first city in run 1
ids = strsplit(run_matrix$pop_ids[1], ";")[[1]]
ids
run1 = read.csv("climate_matrices/run_1.csv", header = FALSE)
head(run1)

head(climate_8pop[, ids[1]])
head(run1[, 1])
all(run1[, 1] == climate_8pop[, ids[1]]) # should be TRUE
