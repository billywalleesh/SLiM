# Tiny R experiment for understanding the SLiM migration loop.
# R uses 1-based indexing, so p0 is stored in subpops[[1]], p1 in subpops[[2]], etc.

set.seed(43)

numPops <- 3

M <- matrix(c(0.0, 0.4, 0.2,
              0.3, 0.0, 0.3,
              0.2, 0.4, 0.0),
            nrow = numPops, byrow = TRUE)

subpops <- list(
  c("p0_ind1", "p0_ind2", "p0_ind3", "p0_ind4", "p0_ind5", "p0_ind6"),
  c("p1_ind1", "p1_ind2", "p1_ind3", "p1_ind4", "p1_ind5", "p1_ind6"),
  c("p2_ind1", "p2_ind2", "p2_ind3", "p2_ind4", "p2_ind5", "p2_ind6")
)

migrant <- character(0)

subpops

# In R, p0 is row/list position 1 and p1 is column/list position 2.
sourcePop <- 1
destPop <- 2

M[1,2]

migrationRate <- M[sourcePop, destPop]
migrationRate

potentialMigrants <- subpops[[sourcePop]][!subpops[[sourcePop]] %in% migrant]
potentialMigrants

rbinom(100, 6, 0.2)

numMigrants <- rbinom(1, length(potentialMigrants), migrationRate)
numMigrants

migrants <- sample(potentialMigrants, numMigrants)
migrants

migrant <- c(migrant, migrants)
migrant

subpops[[sourcePop]] <- subpops[[sourcePop]][!subpops[[sourcePop]] %in% migrants]
subpops[[destPop]] <- c(subpops[[destPop]], migrants)
subpops

