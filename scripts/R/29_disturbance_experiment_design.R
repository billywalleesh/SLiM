# Design of the disturbance experiment for grib_ramp_v1.2_disturbance.slim
#
# Writes two files:
#   1. disturbance_scenarios.csv - one row per disturbance scenario. Each
#      scenario gives every population two numbers:
#        survive = fraction of individuals left alive at the disturbance
#        habitat = fraction of K left afterwards (0 = habitat gone for good)
#      The SLiM script reads one row with  -d SCENARIO_ID=<id>.
#   2. run_grid.csv - one row per simulation run:
#      scenario x K x migration x selection x replicate, with its seed.
#
# Severities (applied to every population that is hit):
#   halve           survive 0.5, habitat 0.5   habitat loss, 50 %
#   severe          survive 0.1, habitat 0.1   habitat loss, 90 %
#   bottleneck      survive 0.1, habitat 1     individuals lost, habitat intact
#   destroy_recol   survive 0,   habitat 1     wiped out, can be recolonised
#   destroy_norecol survive 0,   habitat 0     wiped out, habitat gone (sink)
#
# Scenarios:
#   0        control (nothing happens)
#   subsets  every set of populations (15 sets: 4 single, 6 pairs, 4 triples,
#            all 4) x the 5 severities, minus "destroy all 4" (2 rows: the
#            whole metapopulation would simply be gone) = 73
#   gradient habitat loss that increases along the plateau, west to east or
#            east to west (2)
#   total    76 scenarios

project_root <- "C:/Users/WilliamWallisch/msc_workspace"
out_dir <- file.path(project_root,
                     "SLiM/input/grib_pop_index_local_adaptation/disturbance_experiment")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

pop_names <- c("Geneva", "Bern", "Zurich", "St_Gallen")   # p0 ... p3, west to east
n_pops <- length(pop_names)


# ---------------- 1. Scenarios ----------------

severities <- data.frame(
  severity = c("halve", "severe", "bottleneck", "destroy_recol", "destroy_norecol"),
  survive  = c(0.5, 0.1, 0.1, 0, 0),
  habitat  = c(0.5, 0.1, 1, 1, 0)
)

# one scenario row from a survive and a habitat vector (one value per population)
make_row <- function(family, severity, hit, survive, habitat) {
  row <- data.frame(
    family   = family,
    severity = severity,
    pops_hit = if (length(hit) == 0) "none" else paste0("p", hit, collapse = "+"),
    n_hit    = length(hit)
  )
  for (p in 1:n_pops) row[[paste0("survive_p", p - 1)]] <- survive[p]
  for (p in 1:n_pops) row[[paste0("habitat_p", p - 1)]] <- habitat[p]

  # summaries for the analysis
  row$n_destroyed  <- sum(survive == 0)
  row$habitat_lost <- 1 - mean(habitat)    # share of the total K that is gone
  row$indiv_lost   <- 1 - mean(survive)    # share of individuals killed (if all at K)
  row$recolonize   <- any(survive == 0 & habitat > 0)
  row
}

rows <- list()

# control
rows[[1]] <- make_row("control", "none", integer(0), rep(1, n_pops), rep(1, n_pops))

# every set of populations x every severity
for (size in 1:n_pops) {
  sets <- combn(0:(n_pops - 1), size, simplify = FALSE)
  for (hit in sets) {
    for (s in 1:nrow(severities)) {
      if (size == n_pops && severities$survive[s] == 0) next   # no "destroy all"
      survive <- rep(1, n_pops)
      habitat <- rep(1, n_pops)
      survive[hit + 1] <- severities$survive[s]
      habitat[hit + 1] <- severities$habitat[s]
      rows[[length(rows) + 1]] <- make_row("subset", severities$severity[s],
                                           hit, survive, habitat)
    }
  }
}

# gradients: the fraction kept rises 0.25 -> 0.5 -> 0.75 -> 1 along the plateau
gradient <- c(0.25, 0.5, 0.75, 1)
rows[[length(rows) + 1]] <- make_row("gradient", "west_hardest", 0:2, gradient, gradient)
rows[[length(rows) + 1]] <- make_row("gradient", "east_hardest", 1:3,
                                     rev(gradient), rev(gradient))

scenarios <- do.call(rbind, rows)
scenarios <- cbind(scenario_id = 0:(nrow(scenarios) - 1), scenarios)

cat("Scenarios:", nrow(scenarios), "\n")
print(table(scenarios$family, scenarios$severity))


# ---------------- 2. Run grid ----------------

k_levels        <- c(500, 1000, 5000)
migration_files <- c(weak   = "grib_migration_matrix_4pop_weak.csv",
                     strong = "grib_migration_matrix_4pop_strong.csv")
selection       <- c(0.025, 0.05)   # v1.2 uses 0.05
n_reps          <- 10

backgrounds <- expand.grid(K = k_levels, migration = names(migration_files),
                           selection = selection, rep = 1:n_reps,
                           stringsAsFactors = FALSE)

# One seed per background and replicate, shared by all its scenarios: the
# runs are then identical up to the disturbance, so every scenario has a
# matched control.
set.seed(20261005)
backgrounds$seed <- sample(1e8:2e9, nrow(backgrounds))

grid <- merge(backgrounds, data.frame(scenario_id = scenarios$scenario_id))
grid <- grid[order(grid$K, grid$migration, grid$selection, grid$rep, grid$scenario_id), ]
grid$migration_file <- migration_files[grid$migration]
grid <- cbind(job_id = 1:nrow(grid),
              grid[, c("scenario_id", "K", "migration", "migration_file",
                       "selection", "rep", "seed")])

cat("Runs:", nrow(grid), "\n")


# ---------------- Save ----------------
# written with Unix line endings so SLiM can read them on Linux too

write_lf <- function(x, path) {
  con <- file(path, "wb")
  write.csv(x, con, row.names = FALSE, quote = FALSE)
  close(con)
}

write_lf(scenarios, file.path(out_dir, "disturbance_scenarios.csv"))
write_lf(grid, file.path(out_dir, "run_grid.csv"))

cat("Saved in", out_dir, "\n")
