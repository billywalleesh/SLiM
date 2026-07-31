#first try at analyzing SLiM output 

library(dplyr)
library(ggplot2)

d <- read.csv("C:/Users/WilliamWallisch/msc_workspace/SLiM/results/reps/grib_4pop_ne_ramp_weak_sel050_K500_rep_1_seed_8000001.csv")

#small eda
head(d)
dim(d)
names(d)
str(d)
summary(d)

table(d$migration_treatment)
table(d$selection_strength)
table(d$K)
table(d$replicate)

table(d$phase)
table(d$pop_id)
table(d$location)
table(d$extinct)

table(table(d$tick))

d$pop_id <- factor(d$pop_id)
d$location <- factor(d$location)
d$phase <- factor(d$phase)

str(d)

hist(
  d$N,
  main = "Distribution of population size",
  xlab = "Population size"
)

boxplot(
  N ~ location,
  data = d,
  main = "Population size by location",
  xlab = "Location",
  ylab = "Population size"
)

aggregate(
  N ~ location,
  data = d,
  FUN = mean
)

aggregate(
  N ~ location + phase,
  data = d,
  FUN = mean
)

plot(
  N ~ tick,
  data = d,
  col = pop_id,
  pch = 16,
  cex = 0.5,
  xlab = "Simulation tick",
  ylab = "Population size",
  main = "Population size through time"
)

legend(
  "topright",
  legend = levels(d$pop_id),
  col = 1:length(levels(d$pop_id)),
  pch = 16,
  title = "Population"
)

summary(d$Ne_fecundity_preMigration)

hist(
  d$Ne_fecundity_preMigration,
  main = "Distribution of effective population size",
  xlab = "Fecundity Ne"
)

ggplot(
  d,
  aes(
    x = tick,
    y = Ne_fecundity_preMigration,
    colour = location
  )
) +
  geom_line() +
  labs(
    title = "Effective population size through time",
    x = "Simulation tick",
    y = "Fecundity Ne",
    colour = "Population"
  ) +
  theme_bw()

aggregate(
  Ne_fecundity_preMigration ~ location + phase,
  data = d,
  FUN = mean
)

d$Ne_N_ratio <- d$Ne_fecundity_preMigration / d$N
d$Ne_N_ratio

summary(d$Ne_N_ratio)

hist(
  d$Ne_N_ratio,
  main = "Distribution of Ne/N",
  xlab = "Ne divided by N"
)

aggregate(
  Ne_N_ratio ~ location + phase,
  data = d,
  FUN = mean
)

ggplot(
  d,
  aes(
    x = tick,
    y = Ne_N_ratio,
    colour = location
  )
) +
  geom_line() +
  geom_hline(
    yintercept = 1,
    linetype = "dashed"
  ) +
  labs(
    title = "Effective size relative to population size",
    x = "Simulation tick",
    y = "Ne / N",
    colour = "Population"
  ) +
  theme_bw()

summary(d$phenotype_lag)

hist(
  d$phenotype_lag,
  main = "Distribution of phenotype lag",
  xlab = "Phenotype lag"
)

ggplot(
  d,
  aes(
    x = tick,
    y = phenotype_lag,
    colour = location
  )
) +
  geom_line() +
  geom_hline(
    yintercept = 0,
    linetype = "dashed"
  ) +
  labs(
    title = "Phenotype lag through time",
    x = "Simulation tick",
    y = "Phenotype lag",
    colour = "Population"
  ) +
  theme_bw()

d$N
d$Ne_fecundity_preMigration
d$phenotype_lag
