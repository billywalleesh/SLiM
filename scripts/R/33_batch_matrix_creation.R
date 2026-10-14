#supply all the upper and lower limits
K_max <- 5000 
K_min <- 3000

selection_strength_max <- 0.1
selection_strength_min <- 0.01

slope_max = -0.001/200
slope_min   = -0.001/50
  
n_populations_max <- 8
n_populations_min <- 4

D_pop_max <- 1
D_pop_min <- 0

D_inds_max <- 1
D_inds_min <- 0

D_habitat_max <- 1
D_habitat_min <- 0

#run all the sampling and uniform distribiutions
K = round(runif(1000, min = K_min , max = K_max))
K

selection_strength = runif(1000, min = selection_strength_min, max = selection_strength_max) 
selection_strength

slope_decay = runif(1000, min = slope_min , max = slope_max)
slope_decay

n_populations = sample(n_populations_min:n_populations_max, 1000, replace = TRUE)
n_populations

pop_ids_list <- lapply(n_populations, function(n) sort(sample(0:7, n)))
pop_ids_list
pop_ids <- sapply(pop_ids_list, paste, collapse = ";")
pop_ids

K_per_pop = round(K / n_populations)
K_per_pop

D_pop = runif(1000, min = D_pop_min , max = D_pop_max) 
D_pop

D_inds = runif(1000, min = D_inds_min , max = D_inds_max) 
D_inds

D_habitat = runif(1000, min = D_habitat_min , max = D_habitat_max) 
D_habitat

#create the matrix
run_matrix = data.frame(run = 1:1000, K, n_populations, pop_ids, K_per_pop, selection_strength, slope_decay, D_pop, D_inds, D_habitat)
run_matrix

write.csv(run_matrix, "run_matrix_1000.csv", row.names = FALSE)


