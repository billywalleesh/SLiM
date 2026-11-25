#this script is used to create a random 1000 run matrix with the columns: 
#K, n_populations, pop_ids, K_per_pop, selection_strength, slope_decay, D_pop, n_target, target_pops, D_inds, D_habitat)
#these each will be created with upper and lower limits, in order to create a random distribution of runs centered around a central 
#expected value that produces essentially a run with a k per pop around an average of 500 inds. 
#we expect an average run to have 6 pops, selection strength around .10, average destruction of pops around 0.5, average number of targeted populations around 3
#reduction of individuals to average around 0.5 and destruction of habitat to average around 0.5. K for the entire sim should average around 4000
#important to set the seed here for all climate and migration matrices build from this
#we will then supply this run matrix to the climate matrix code and the migration matrix code
#each run will need a separate migration and climate matrix which corresponds to the number of populations sampled, as well as the specific city sampled 
#(0.10–0.25 gave about 20% extinction at 0.17–0.23, and runs above 0.24 died in the burn-in) that is the reasoning for batch 4 selection strength
#batch 5: selection was capped at 0.20 because batch 3 lost 12 runs in the ramp, all but one above 0.20
#batch 6: back to 0.17-0.23 with the 10,000-tick ramp (ramp_v1.3.1_burnin50k_ramp10k.slim), which saved 14 of the 15 runs
#that died in the 4000-tick ramp (run_repo_ramp10k_test)
#set.seed(14102026)
#set.seed(20112026)
#set.seed(25112026)
#set.seed(251120261)
#set.seed(251120262)
set.seed(251120263)
setwd("C:/Users/WilliamWallisch/msc_workspace/SLiM/input/grib_pop_index_local_adaptation/run_repo_251120263")
getwd()

#supply all the upper and lower limits
K_max <- 5000 
K_min <- 3000

#batch 1
#selection_strength_max <- 0.1
#selection_strength_min <- 0.01
#batch 2
#selection_strength_max <- 0.15
#selection_strength_min <- 0.05
#batch 3
#selection_strength_max <- 0.25
#selection_strength_min <- 0.10
#batch 4
#selection_strength_max <- 0.23
#selection_strength_min <- 0.17
#batch 5
#selection_strength_max <- 0.20
#selection_strength_min <- 0.17
#batch 6 (10,000-tick ramp)
selection_strength_max <- 0.23
selection_strength_min <- 0.17

#batch 1
#slope_max = -0.001/200
#slope_min   = -0.001/50
slope_max = -0.001/200
#migration rate drops by 0.001 every 200 km and is 0 beyond 1000 km.
slope_min   = -0.001/25
#migration rate drops by 0.001 every 25 km and is 0 beyond 125 km. 
  
n_populations_max <- 8
n_populations_min <- 4

D_pop_max <- 1
D_pop_min <- 0

D_inds_max <- 1
D_inds_min <- 0

D_habitat_max <- 1
D_habitat_min <- 0

#run all the sampling and uniform distributions
K = round(runif(1000, min = K_min , max = K_max))
K

selection_strength = runif(1000, min = selection_strength_min, max = selection_strength_max) 
selection_strength

slope_decay = runif(1000, min = slope_min , max = slope_max)
slope_decay

#how many populations are in each run
n_populations = sample(n_populations_min:n_populations_max, 1000, replace = TRUE)
n_populations

#used to sample each pop in order to keep the pop number semantics  
pop_ids_list <- lapply(n_populations, function(n) sort(sample(0:7, n)))
pop_ids_list
pop_ids <- sapply(pop_ids_list, paste, collapse = ";")
pop_ids

#used to supply each initial population with a pop size
K_per_pop = round(K / n_populations)
K_per_pop
mean(K_per_pop)

D_pop = runif(1000, min = D_pop_min , max = D_pop_max) 
D_pop

n_target = round(D_pop * n_populations)
n_target

#the number of populations disrupted should depend on D_pop and on how many populations the run has
target_pops_list <- lapply(1:1000, function(i) sort(pop_ids_list[[i]][sample(n_populations[i], n_target[i])]))
target_pops_list

#add target pops to matrix
target_pops <- sapply(target_pops_list, paste, collapse = ";")
target_pops

D_inds = runif(1000, min = D_inds_min , max = D_inds_max) 
D_inds

D_habitat = runif(1000, min = D_habitat_min , max = D_habitat_max) 
D_habitat

disturbance_type <-sample(rep(c(0,1),500))
disturbance_type
length(disturbance_type) 
mean(disturbance_type)

#turn off the other kind of disturbance: 1 means nothing is lost
D_inds[disturbance_type == 1] = 1      #habitat runs: no individuals killed
D_habitat[disturbance_type == 0] = 1   #individual runs: habitat stays intact


#create the matrix
run_matrix = data.frame(run = 1:1000, K, n_populations, pop_ids, K_per_pop, selection_strength, slope_decay, D_pop, n_target, target_pops, D_inds, D_habitat, disturbance_type)
run_matrix

write.csv(run_matrix, "run_matrix_1000.csv", row.names = FALSE)


