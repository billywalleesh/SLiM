# 15_polygenic_effect_size_tutorial.R
#
# A step by step walk through of how a phenotype built from SUMMED mutation
# effect sizes tracks a moving climate optimum, and how that differs from a
# phenotype built from a COUNT of mutations.
#
# SLiM equivalents:
#   countOfMutationsOfType(m2)  ->  the oligogenic phenotype
#   sumOfMutationsOfType(m2)    ->  the polygenic phenotype
#
# One population. Base R only. Everything is printed as it is created.

rm(list = ls())
set.seed(42)


# ---------------------------------------------------------------------
# PART 1 - WHAT AN EFFECT SIZE ACTUALLY IS
# ---------------------------------------------------------------------

# In the oligogenic model m2 was declared like this:
#   initializeMutationType("m2", 0.5, "f", 0.0)
# "f" means a FIXED distribution, and the value is 0.0, so every single m2
# mutation is identical and carries no value of its own. The only thing that
# can vary between individuals is HOW MANY copies they carry.
#
# In the polygenic model m2 is declared like this:
#   initializeMutationType("m2", 0.5, "n", 0.0, 0.1)
# "n" means a NORMAL distribution, with mean 0.0 and standard deviation 0.1.
# Now every m2 mutation that arises draws its own private effect size from
# that distribution. Some push the phenotype up, some push it down, and most
# of them are small.

effectSD <- 0.1

# Draw effect sizes for five positions, exactly as SLiM would when five
# m2 mutations arise.
numDemoLoci <- 5

demoEffects <- rnorm(numDemoLoci, mean = 0, sd = effectSD)
demoEffects

# Notice that some are negative. A mutation is not automatically "good" here.
# It is only good or bad relative to where the optimum currently sits.


# ---------------------------------------------------------------------
# PART 2 - ONE DIPLOID INDIVIDUAL, WORKED BY HAND
# ---------------------------------------------------------------------

# A diploid individual carries two haplotypes. At each position, 1 means the
# m2 mutation is present on that haplotype and 0 means it is absent.

haplotype1 <- c(1, 0, 1, 1, 0)
haplotype1

haplotype2 <- c(1, 0, 0, 1, 1)
haplotype2

# Adding the two haplotypes gives the number of COPIES carried at each
# position: 0 (absent), 1 (heterozygous) or 2 (homozygous).
demoCopies <- haplotype1 + haplotype2
demoCopies

# Each copy contributes its own effect size. A homozygote contributes the
# effect size twice, because it really is carrying two copies of it.
demoContribution <- demoCopies * demoEffects
demoContribution

# This table is the whole idea in one place.
demoTable <- data.frame(
  position = 1:numDemoLoci,
  effectSize = round(demoEffects, 4),
  copies = demoCopies,
  contribution = round(demoContribution, 4)
)
print(demoTable, row.names = FALSE)

# SLiM: countOfMutationsOfType(m2)
# Adds up the "copies" column and throws the "effectSize" column away.
countPhenotype <- sum(demoCopies)
countPhenotype

# SLiM: sumOfMutationsOfType(m2)
# Adds up the "contribution" column, so the effect sizes are what matter.
sumPhenotype <- sum(demoContribution)
sumPhenotype

# The count phenotype can only ever be a whole number.
# The sum phenotype is continuous, and it is the sum of many small pieces.


# ---------------------------------------------------------------------
# PART 3 - WHY THE SUM MATTERS: TWO INDIVIDUALS, SAME COUNT
# ---------------------------------------------------------------------

# Here is a second individual carrying the mutation at different positions.
otherCopies <- c(0, 2, 2, 0, 1)
otherCopies

# Both individuals carry exactly the same NUMBER of m2 copies.
sum(demoCopies)
sum(otherCopies)

# But their summed phenotypes are not the same at all.
sum(demoCopies * demoEffects)
sum(otherCopies * demoEffects)

# In the oligogenic model these two individuals would be interchangeable,
# because the model only ever asked how many copies they had. In the
# polygenic model they are different phenotypes, and selection can tell
# them apart. That is the practical meaning of the switch from
# countOfMutationsOfType to sumOfMutationsOfType.


# ---------------------------------------------------------------------
# PART 4 - TURNING A PHENOTYPE INTO A FITNESS
# ---------------------------------------------------------------------

# This is the fitness function from the SLiM model, unchanged between the
# oligogenic and polygenic versions:
#   fitness = 1.0 - (phenotype - optimum)^2 * selectionStrength
#   fitness[fitness < 0.0] = 0.0

selectionStrength <- 0.05
optimum <- 2.0

deviation <- sumPhenotype - optimum
deviation

demoFitness <- 1.0 - deviation^2 * selectionStrength
demoFitness <- max(demoFitness, 0.0)
demoFitness

# Note how far this individual is from the optimum. Five positions with
# effect sizes of about 0.1 cannot get anywhere near a phenotype of 2.0.
# To reach 2.0 you need roughly this many copies of average positive effect:
optimum / (effectSD * 0.798)

# That number is the reason this is called polygenic. The trait can only
# reach the optimum by accumulating small contributions across MANY
# positions. No single mutation can do the job on its own, which is the
# opposite of the oligogenic model where each copy moved the phenotype by a
# full unit and six copies were enough.


# ---------------------------------------------------------------------
# PART 5 - BUILDING A WHOLE POPULATION
# ---------------------------------------------------------------------

# Now scale up from one individual to a population, with enough positions
# for the trait to actually be polygenic.

numInds <- 500
numLoci <- 300

# Every position gets its own effect size, drawn once, exactly like SLiM
# drawing an effect size for each new m2 mutation.
locusEffects <- rnorm(numLoci, mean = 0, sd = effectSD)
locusEffects
# Centre the effects so they sum to exactly zero. This is a convenience for
# the demonstration only: it means the starting population sits at a
# phenotype of 0 every time you run the script, instead of at a random
# offset, so the burn-in below always starts from the same place. SLiM does
# not do this.
locusEffects <- locusEffects - mean(locusEffects)

# Look at the distribution of effect sizes we are working with.
summary(locusEffects)

# Start the population with standing variation: each haplotype carries the
# mutation at each position with probability 0.5.
haplotypeA <- matrix(
  rbinom(numInds * numLoci, 1, 0.5),
  nrow = numInds,
  ncol = numLoci
)

haplotypeB <- matrix(
  rbinom(numInds * numLoci, 1, 0.5),
  nrow = numInds,
  ncol = numLoci
)

dim(haplotypeA)
dim(haplotypeB)

# Copy counts for every individual at every position, 0 / 1 / 2.
genotypes <- haplotypeA + haplotypeB
genotypes[1:5, 1:8]

# The summed phenotype for every individual at once. This single line is
# the R equivalent of inds.sumOfMutationsOfType(m2) in SLiM.
phenotypes <- as.vector(genotypes %*% locusEffects)
phenotypes
# And the count phenotype, for comparison. This is the R equivalent of
# inds.countOfMutationsOfType(m2).
countPhenotypes <- as.vector(rowSums(genotypes))

head(round(phenotypes, 3))
head(countPhenotypes)

mean(phenotypes)
sd(phenotypes)

# The two phenotype definitions look completely different as distributions.
oldPar <- par(mfrow = c(1, 2))

hist(countPhenotypes,
     breaks = 30,
     col = "grey",
     main = "Count phenotype",
     xlab = "countOfMutationsOfType(m2)")

hist(phenotypes,
     breaks = 30,
     col = "grey",
     main = "Summed phenotype",
     xlab = "sumOfMutationsOfType(m2)")

par(oldPar)

# The count phenotype is dominated by how many mutations you happen to
# carry, and every individual carries roughly numLoci copies, so it is a
# tight distribution centred on a large number that has nothing to do with
# the optimum. The summed phenotype is centred on zero because positive and
# negative effects cancel, and it has real spread, somewhere around 1.2.
# That spread is the additive genetic variance selection will work with,
# and it is the thing that small effective population size erodes.


# ---------------------------------------------------------------------
# PART 6 - ONE GENERATION, STEP BY STEP
# ---------------------------------------------------------------------

# Fitness for every individual, using the same formula as the SLiM model.
currentOptimum <- 2.0

fitness <- 1.0 - (phenotypes - currentOptimum)^2 * selectionStrength
fitness[fitness < 0.0] <- 0.0

head(round(fitness, 3))
mean(fitness)

# Individuals closer to the optimum have higher fitness, so they are more
# likely to be sampled as parents.
parentTable <- data.frame(
  phenotype = round(head(phenotypes, 6), 3),
  deviation = round(head(phenotypes - currentOptimum, 6), 3),
  fitness = round(head(fitness, 6), 3)
)
print(parentTable, row.names = FALSE)

# Choose mothers and fathers in proportion to fitness.
mothers <- sample(1:numInds, numInds, replace = TRUE, prob = fitness)
fathers <- sample(1:numInds, numInds, replace = TRUE, prob = fitness)

head(mothers)
head(fathers)

# Each parent passes on one gamete. At every position the gamete takes the
# allele from one of the parent's two haplotypes at random. This is free
# recombination, which is a simplification of the SLiM model, but it keeps
# the demonstration readable.
pickA <- matrix(
  runif(numInds * numLoci) < 0.5,
  nrow = numInds,
  ncol = numLoci
)

maternalGamete <- ifelse(pickA,
                         haplotypeA[mothers, ],
                         haplotypeB[mothers, ])

pickB <- matrix(
  runif(numInds * numLoci) < 0.5,
  nrow = numInds,
  ncol = numLoci
)

paternalGamete <- ifelse(pickB,
                         haplotypeA[fathers, ],
                         haplotypeB[fathers, ])

# The offspring generation.
offspringGenotypes <- maternalGamete + paternalGamete
offspringPhenotypes <- as.vector(offspringGenotypes %*% locusEffects)

# Selection moved the mean phenotype toward the optimum in a single
# generation. Compare these two numbers.
mean(phenotypes)
mean(offspringPhenotypes)
currentOptimum


# ---------------------------------------------------------------------
# PART 7 - MANY GENERATIONS WITH A MOVING OPTIMUM
# ---------------------------------------------------------------------

# Now repeat that generation loop while the optimum moves, mirroring the
# structure of the SLiM model: a period at the historical optimum, then a
# climate change ramp, then a hold at the new optimum.

numGenerations <- 150
burnInEnd <- 30
rampEnd <- 90

historicalOptimum <- 2.0
finalOptimum <- 6.0

mutationRate <- 0.0005

# Reset the population so this section can be run on its own.
haplotypeA <- matrix(
  rbinom(numInds * numLoci, 1, 0.5),
  nrow = numInds,
  ncol = numLoci
)

haplotypeB <- matrix(
  rbinom(numInds * numLoci, 1, 0.5),
  nrow = numInds,
  ncol = numLoci
)

# Somewhere to record what happens each generation.
recordGeneration <- rep(NA, numGenerations)
recordOptimum <- rep(NA, numGenerations)
recordMeanPhenotype <- rep(NA, numGenerations)
recordPhenotypeSD <- rep(NA, numGenerations)
recordMeanFitness <- rep(NA, numGenerations)

for (generation in 1:numGenerations)
{
  # Where the optimum sits this generation.
  if (generation <= burnInEnd)
  {
    currentOptimum <- historicalOptimum
  }
  else if (generation <= rampEnd)
  {
    rampProgress <- (generation - burnInEnd) / (rampEnd - burnInEnd)
    currentOptimum <- historicalOptimum +
      rampProgress * (finalOptimum - historicalOptimum)
  }
  else
  {
    currentOptimum <- finalOptimum
  }

  # Phenotype as the sum of the effect sizes of every copy carried.
  genotypes <- haplotypeA + haplotypeB
  phenotypes <- as.vector(genotypes %*% locusEffects)

  # Fitness, same formula as the SLiM model.
  fitness <- 1.0 - (phenotypes - currentOptimum)^2 * selectionStrength
  fitness[fitness < 0.0] <- 0.0

  # Record before reproducing.
  recordGeneration[generation] <- generation
  recordOptimum[generation] <- currentOptimum
  recordMeanPhenotype[generation] <- mean(phenotypes)
  recordPhenotypeSD[generation] <- sd(phenotypes)
  recordMeanFitness[generation] <- mean(fitness)

  # If nobody can reproduce the population is finished.
  if (sum(fitness) == 0)
  {
    cat("Population extinct at generation", generation, "\n")
    break
  }

  # Reproduction, weighted by fitness.
  mothers <- sample(1:numInds, numInds, replace = TRUE, prob = fitness)
  fathers <- sample(1:numInds, numInds, replace = TRUE, prob = fitness)

  pickA <- matrix(runif(numInds * numLoci) < 0.5,
                  nrow = numInds, ncol = numLoci)
  pickB <- matrix(runif(numInds * numLoci) < 0.5,
                  nrow = numInds, ncol = numLoci)

  newHaplotypeA <- ifelse(pickA,
                          haplotypeA[mothers, ],
                          haplotypeB[mothers, ])

  newHaplotypeB <- ifelse(pickB,
                          haplotypeA[fathers, ],
                          haplotypeB[fathers, ])

  # New mutations arise on the gametes.
  newMutationsA <- matrix(runif(numInds * numLoci) < mutationRate,
                          nrow = numInds, ncol = numLoci)
  newMutationsB <- matrix(runif(numInds * numLoci) < mutationRate,
                          nrow = numInds, ncol = numLoci)

  newHaplotypeA[newMutationsA] <- 1
  newHaplotypeB[newMutationsB] <- 1

  haplotypeA <- newHaplotypeA
  haplotypeB <- newHaplotypeB
}

# What happened.
resultTable <- data.frame(
  generation = recordGeneration,
  optimum = round(recordOptimum, 3),
  meanPhenotype = round(recordMeanPhenotype, 3),
  phenotypeSD = round(recordPhenotypeSD, 3),
  meanFitness = round(recordMeanFitness, 3)
)

head(resultTable, 10)
resultTable[seq(1, numGenerations, by = 10), ]
tail(resultTable, 5)


# ---------------------------------------------------------------------
# PART 8 - THE PICTURE
# ---------------------------------------------------------------------

plot(
  recordGeneration,
  recordOptimum,
  type = "l",
  lwd = 3,
  col = "red",
  ylim = range(c(recordOptimum, recordMeanPhenotype), na.rm = TRUE),
  xlab = "Generation",
  ylab = "Phenotype (sum of m2 effect sizes)",
  main = "Polygenic phenotype tracking a moving optimum"
)

lines(recordGeneration, recordMeanPhenotype, lwd = 3, col = "black")

abline(v = burnInEnd, lty = 3)
abline(v = rampEnd, lty = 3)

legend(
  "topleft",
  legend = c("Climate optimum", "Mean phenotype"),
  col = c("red", "black"),
  lwd = 3,
  bty = "n"
)

# The black line lags behind the red line during the ramp. That lag is the
# whole story of adaptation to climate change: the population is always
# chasing an optimum that has already moved. How big the lag gets depends
# on how much additive genetic variance the population has, which is
# exactly what small effective population size erodes.

# The standing variation being used up as the population adapts.
plot(
  recordGeneration,
  recordPhenotypeSD,
  type = "l",
  lwd = 3,
  col = "black",
  xlab = "Generation",
  ylab = "SD of phenotype",
  main = "Phenotypic variation over time"
)

abline(v = burnInEnd, lty = 3)
abline(v = rampEnd, lty = 3)


# ---------------------------------------------------------------------
# PART 9 - WHERE THE RESPONSE ACTUALLY CAME FROM
# ---------------------------------------------------------------------

# In an oligogenic model you would see a few loci sweep from rare to fixed.
# In a polygenic model you see many loci shift a little. Compare the
# starting and ending allele frequencies to see this directly.

finalGenotypes <- haplotypeA + haplotypeB
finalFrequencies <- colSums(finalGenotypes) / (2 * numInds)

# Frequencies started at about 0.5 everywhere by construction.
summary(finalFrequencies)

frequencyChange <- finalFrequencies - 0.5

# Positive effect loci should have gone up, negative effect loci down.
plot(
  locusEffects,
  frequencyChange,
  pch = 16,
  col = "grey30",
  xlab = "Effect size of the locus",
  ylab = "Change in allele frequency",
  main = "Small coordinated shifts across many loci"
)

abline(h = 0, lty = 3)
abline(v = 0, lty = 3)

# The upward slope is the polygenic signature: loci that push the phenotype
# up became more common, loci that push it down became rarer, but almost
# none of them fixed or were lost. No single locus explains the adaptation.

# How many loci actually fixed or were lost?
sum(finalFrequencies == 1.0)
sum(finalFrequencies == 0.0)


# ---------------------------------------------------------------------
# PART 10 - SIMPLIFICATIONS TO BE AWARE OF
# ---------------------------------------------------------------------

# This script is a teaching aid, not a replica of the SLiM model. The
# differences worth remembering:
#
# 1. Here each position has ONE effect size fixed for the whole run. In
#    SLiM each new mutation draws its own effect size, so two mutations at
#    the same position in different individuals can differ, and mutations
#    can stack.
#
# 2. Here all positions are unlinked. The SLiM model has all mutations in a
#    single 100 kb element with a recombination rate of 1e-8, so nearby
#    loci travel together.
#
# 3. Here population size is fixed at numInds. The SLiM model is nonWF,
#    with Poisson litters, density regulation and real extinction.
#
# 4. Here there is one population and no migration.
#
# The one thing this script does reproduce exactly is the phenotype
# calculation and the fitness function, which is what the whole exercise
# was about:
#
#   phenotype = sum over all carried copies of that copy's effect size
#   fitness   = 1.0 - (phenotype - optimum)^2 * selectionStrength

