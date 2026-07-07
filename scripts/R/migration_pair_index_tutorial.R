M <- matrix(
  c(
    0.000, 0.005, 0.001,
    0.005, 0.000, 0.005,
    0.001, 0.005, 0.000
  ),
  nrow = 3,
  byrow = TRUE
)

print(M)

# Rows are climate stages. Columns are populations.
climateMatrix <- matrix(
  c(
    2.0, 6.0, 8.0,
    6.0, 8.0, 8.0
  ),
  nrow = 2,
  byrow = TRUE
)

rownames(climateMatrix) <- c("climate0", "climate1")
colnames(climateMatrix) <- paste0("p", 0:2)

print(climateMatrix)

# Each position in these three vectors describes one migration pair.
# Example:
# migrationPairSourcePop[1]      = 0
# migrationPairDestinationPop[1] = 1
# migrationPairRate[1]           = 0.005
# means: p0 sends migrants to p1 at rate 0.005.
migrationPairSourcePop <- c()
migrationPairDestinationPop <- c()
migrationPairRate <- c()

print(migrationPairSourcePop)
print(migrationPairDestinationPop)
print(migrationPairRate)

numPops <- nrow(M)

for (sourcePop in 0:(numPops - 1))
{
  for (destPop in 0:(numPops - 1))
  {
    if (sourcePop == destPop)
    {
      next
    }
    
    # R matrix positions need +1 because R starts counting at 1.
    # SLiM would use M[sourcePop, destPop].
    # R uses M[sourcePop + 1, destPop + 1].
    migrationRate <- M[sourcePop + 1, destPop + 1]
    
    if (migrationRate == 0.0)
    {
      next
    }
    
    migrationPairSourcePop <- c(migrationPairSourcePop, sourcePop)
    migrationPairDestinationPop <- c(migrationPairDestinationPop, destPop)
    migrationPairRate <- c(migrationPairRate, migrationRate)
    
  }
}

print(migrationPairSourcePop)
print(migrationPairDestinationPop)
print(migrationPairRate)

sourcePop <- 0

# In R, which() returns 1-based positions.
# In SLiM, the idea is the same: find the positions where sourcePop is the source.
popMigrationPairs <- which(migrationPairSourcePop == sourcePop)
popMigrationPairs

possibleDestinations <- migrationPairDestinationPop[popMigrationPairs]
possibleDestinations

migrationRates <- migrationPairRate[popMigrationPairs]
migrationRates

totalMigrationRate <- sum(migrationRates)
totalMigrationRate

destinationProbability <- migrationRates / totalMigrationRate
destinationProbability

destinationTable <- data.frame(
  destination = paste0("p", possibleDestinations),
  rate = migrationRates,
  probability_among_migrants = destinationProbability
)

destinationTable

set.seed(10)
sourcePopSize <- 5000

numMigrants <- rbinom(1, sourcePopSize, totalMigrationRate)
numMigrants

popMigrants <- paste0("p0_ind_", sample(1:sourcePopSize, numMigrants))
popMigrants

popDestinations <- sample(
  possibleDestinations,
  numMigrants,
  replace = TRUE,
  prob = migrationRates
)

popDestinations

exampleOutput <- data.frame(
  migrant = head(popMigrants, 10),
  destination = paste0("p", head(popDestinations, 10))
)
exampleOutput

for (sourcePop in 0:(numPops - 1))
{
  popMigrationPairs <- which(migrationPairSourcePop == sourcePop)
  possibleDestinations <- migrationPairDestinationPop[popMigrationPairs]
  migrationRates <- migrationPairRate[popMigrationPairs]
  totalMigrationRate <- sum(migrationRates)
  
  summaryTable <- data.frame(
    destination = paste0("p", possibleDestinations),
    rate = migrationRates,
    probability_among_migrants = migrationRates / totalMigrationRate
  )
  
  print(summaryTable, row.names = FALSE)
}

