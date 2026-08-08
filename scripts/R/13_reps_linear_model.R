#first try at analyzing SLiM output 

library(dplyr)
library(ggplot2)
library(tidyverse)
library(lme4)

d <- read.csv("C:/Users/WilliamWallisch/msc_workspace/SLiM/results/reps/all_runs.csv", na = c("NA", "NAN"))

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

d$migration_treatment <- as.factor(d$migration_treatment)
d$location <- as.factor(d$location)

hist(d$N)

dat <- d %>%
  mutate(
    run_id = interaction(treatment_id, seed, drop = TRUE),
    migration_treatment = factor(migration_treatment),
    selection_strength = factor(selection_strength),
    K = factor(K),
    pop_id = factor(pop_id),
    extinct = extinct == "T"
  )

final_dat <- dat %>%
  filter(year %in% c("2000", "2025")) %>%
  mutate(
    run_id = interaction(treatment_id, seed, drop = TRUE),
    year = as.integer(year)
  ) %>%
  select(
    run_id,
    pop_id,
    migration_treatment,
    selection_strength,
    K,
    year,
    N
  ) %>%
  pivot_wider(
    names_from = year,
    values_from = N,
    names_prefix = "N_"
  ) %>%
  mutate(
    change_N = N_2025 - N_2000
  )

log_dat <- final_dat %>%
  mutate(
    proportional_change = (N_2025 - N_2000) / N_2000,
    log_change = log1p(N_2025) - log1p(N_2000)
  )

ggplot(log_dat, aes(x = change_N)) +
  geom_histogram(bins = 20) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  facet_wrap(~ K, scales = "free_x") +
  theme_classic()

ggplot(log_dat, aes(x = factor(K), y = change_N)) +
  geom_boxplot() +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    x = "Carrying capacity",
    y = "Change in N"
  ) +
  theme_classic()

plot_summary <- log_dat %>%
  group_by(
    K,
    migration_treatment,
    selection_strength,
    pop_id
  ) %>%
  summarise(
    mean_change = mean(change_N),
    se_change = sd(change_N) / sqrt(n()),
    .groups = "drop"
  )

ggplot(
  plot_summary,
  aes(
    x = factor(K),
    y = mean_change,
    group = migration_treatment,
    linetype = migration_treatment
  )
) +
  geom_line() +
  geom_point() +
  geom_errorbar(
    aes(
      ymin = mean_change - se_change,
      ymax = mean_change + se_change
    ),
    width = 0.1
  ) +
  facet_grid(
    selection_strength ~ pop_id
  ) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    x = "Carrying capacity",
    y = "Mean change in N",
    linetype = "Migration"
  ) +
  theme_classic()

ggplot(
  log_dat,
  aes(
    x = N_2000,
    y = change_N,
    shape = migration_treatment
  )
) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(~ pop_id) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    x = "Population size in 2000",
    y = "Change in N, 2000–2025"
  ) +
  theme_classic()

m1 <- lmer(
  change_N ~
    migration_treatment * selection_strength * factor(K) +
    factor(pop_id) +
    (1 | run_id),
  data = final_dat
)

summary(m1)


m2 <- lmer(
  change_N ~
    migration_treatment * selection_strength * factor(K) +
    factor(pop_id) +
    (1 | run_id),
  data = log_dat
)

summary(m2)

m3 <- lm(
  change_N ~
    migration_treatment * selection_strength * factor(K) +
    factor(pop_id),
  data = log_dat
)

anova(m3)
summary(m3)

m4 <- lm(
  change_N ~
    migration_treatment *
    selection_strength *
    factor(K) *
    factor(pop_id),
  data = log_dat
)

anova(m4)
summary(m4)

par(mfrow = c(2, 2))
plot(m4)
