library(tidyverse)
library(lme4)
library(visreg)
library(dplyr)

#import dataset
d <- read.csv("C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k/run_summary_burnin50k.csv")

scatter.smooth(d$ne_indicator_dist, d$n_2025/d$n_populations)

par(mfrow = c(1, 2))
scatter.smooth(d$ne_indicator_dist, log(d$n_2025 / d$n_populations + 1),
               xlab = "ne indicator 1970", ylab = "log mean deme N 2025")
scatter.smooth(log(d$n_1970 / d$n_populations), log(d$n_2025 / d$n_populations + 1),
               xlab = "log mean deme N 1970", ylab = "log mean deme N 2025")

d$log_n_1970 <- log(d$n_1970 / d$n_populations)
d$log_n_2025 <- log(d$n_2025 / d$n_populations + 1)

m1 <- lm(log_n_2025 ~ selection_strength + n_populations + log_n_1970
         + ne_indicator_dist
         + selection_strength:ne_indicator_dist, data = d)
anova(m1)
visreg(m1, "ne_indicator_dist")

visreg(m1, "ne_indicator_dist", by = "selection_strength", breaks = 3, overlay = TRUE)
plot(m1)

m2 <- lm(log_n_2025 ~ selection_strength + n_populations + log_n_1970
         + selection_strength:n_populations
         + ne_indicator_dist
         + selection_strength:ne_indicator_dist, data = d)
anova(m2)

plot(m2)

visreg(m2, "n_populations", by = "selection_strength", breaks = 3, overlay = TRUE)
