# Load packages
library(tidyverse)
library(GGally)


# 1. Import data
dat <- read.csv("C:/Users/WilliamWallisch/OneDrive - Loft Dynamics AG/Desktop/population_log.csv")

# Structure and overview
str(dat)
summary(dat)

# Missing values
colSums(is.na(dat))

# 2. Basic EDA
# Histograms of key variables

numeric_vars <- c(
  "N",
  "phenotype_mean",
  "phenotype_sd",
  "allelic_richness",
  "phenotype_lag",
  "adaptive_fitness"
)

for(v in numeric_vars){
  print(
    ggplot(dat, aes_string(x = v)) +
      geom_histogram(bins = 30, fill = "steelblue", color = "black") +
      theme_minimal() +
      ggtitle(paste("Distribution of", v))
  )
}

# Boxplots
dat %>%
  pivot_longer(cols = all_of(numeric_vars),
               names_to = "variable",
               values_to = "value") %>%
  ggplot(aes(x = variable, y = value)) +
  geom_boxplot(fill = "lightblue") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# 3. Time-series trends
# Average population size through time
dat %>%
  group_by(tick) %>%
  summarise(mean_N = mean(N)) %>%
  ggplot(aes(tick, mean_N)) +
  geom_line() +
  theme_minimal() +
  labs(title = "Mean Population Size Through Time")

# Average adaptive fitness through time
dat %>%
  group_by(tick) %>%
  summarise(mean_fitness = mean(adaptive_fitness)) %>%
  ggplot(aes(tick, mean_fitness)) +
  geom_line() +
  theme_minimal() +
  labs(title = "Mean Adaptive Fitness Through Time")

# Phenotype tracking optimum
sample_dat <- dat %>%
  filter(pop_id == 1)

ggplot(sample_dat, aes(x = tick)) +
  geom_line(aes(y = optimum, colour = "Optimum")) +
  geom_line(aes(y = phenotype_mean, colour = "Phenotype")) +
  theme_minimal() +
  labs(title = "Population 1: Phenotype vs Optimum",
       colour = "")


# 4. Correlation analysis
corr_data <- dat %>%
  select(
    N,
    phenotype_mean,
    phenotype_sd,
    allelic_richness,
    phenotype_lag,
    adaptive_fitness
  )

cor_matrix <- cor(corr_data,
                  use = "complete.obs")

round(cor_matrix, 3)

# Pairwise plots
ggpairs(corr_data)

# 5. Population comparisons
# Mean fitness by population
ggplot(dat,
       aes(factor(pop_id), adaptive_fitness)) +
  geom_boxplot(fill = "lightgreen") +
  theme_minimal() +
  labs(x = "Population ID",
       y = "Adaptive Fitness")

# One-way ANOVA
fitness_aov <- aov(adaptive_fitness ~ factor(pop_id),
                   data = dat)
summary(fitness_aov)

# 6. Linear regression models
# Model 1:
# Does adaptive fitness depend on lag and diversity?
model1 <- lm(
  adaptive_fitness ~ phenotype_lag +
    allelic_richness +
    phenotype_sd,
  data = dat
)
summary(model1)


# Model 2:
# Does population size depend on adaptation?
model2 <- lm(
  N ~ adaptive_fitness +
    allelic_richness +
    phenotype_lag,
  data = dat
)

summary(model2)

# Diagnostic plots
par(mfrow = c(2,2))
plot(model2)

# 7. Extinction analysis
table(dat$extinct)

# Extinction frequency by population
dat %>%
  group_by(pop_id) %>%
  summarise(
    extinction_rate = mean(extinct)
  ) %>%
  print()

# 8. Final summary statistics table
dat %>%
  select(
    N,
    phenotype_mean,
    phenotype_sd,
    allelic_richness,
    phenotype_lag,
    adaptive_fitness
  ) %>%
  summarise_all(
    list(
      mean = mean,
      sd = sd,
      min = min,
      max = max
    ),
    na.rm = TRUE
  )

