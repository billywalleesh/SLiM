library(tidyverse)
library(lme4)
library(visreg)
library(dplyr)

#EDA of the new response: % of the post-disturbance population (1970) still there in 2025
#data from run_summary_burnin50k.csv (made by 42_build_run_summary.R), one row per run
#pct_n_kept_post_dist_2025 = 100 * n_2025 / n_1970, the climate change period only

#import dataset
d <- read.csv("C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k/run_summary_burnin50k.csv")

par(mfrow = c(1, 1))
nrow(d)
summary(d$pct_n_kept_post_dist_2025)
hist(d$pct_n_kept_post_dist_2025)

scatter.smooth(d$ne_indicator_dist, d$ne_indicator_post_dist)
scatter.smooth(d$ne_indicator_dist, d$pct_n_kept_post_dist_2025)

# colour by selection strength
plot(d$ne_indicator_dist, d$pct_n_kept_post_dist_2025, col = as.factor(d$selection_strength))

# colour by number of populations
plot(d$ne_indicator_dist, d$pct_n_kept_post_dist_2025, col = as.factor(d$n_populations))

#make the groups, same as in 43
d$disturbance_type <- factor(d$disturbance_type, levels = c(0, 1),
                             labels = c("individuals removed", "habitat lost"))

d$K_group <- cut(d$K_per_pop, breaks = c(0, 500, 700, 900, 1300),
                 labels = c("K <= 500", "K 500-700", "K 700-900", "K > 900"))

d$sel_group <- cut(d$selection_strength, breaks = c(0, 0.04, 0.07, 0.1),
                   labels = c("weak", "medium", "strong"))

d$mig_group <- cut(d$slope_decay,
                   breaks = c(-0.00002, -0.000015, -0.00001, -0.000005),
                   labels = c("low migration", "medium migration", "high migration"),
                   include.lowest = TRUE)

d$npop_group <- factor(d$n_populations)

#### 1. the response ####

par(mfrow = c(1, 2))
hist(d$pct_n_kept_post_dist_2025, breaks = 30, main = "% n kept 1970-2025", xlab = "%")
hist(d$pct_n_kept_pre_dist_2025, breaks = 30, main = "% n kept pre dist-2025", xlab = "%")
par(mfrow = c(1, 1))

#how many runs grew back past their 1970 size, and how many nearly died out
sum(d$pct_n_kept_post_dist_2025 > 100)
sum(d$pct_n_kept_post_dist_2025 < 5)

#census size of the whole run in 1970 (after the disturbance) and in 2025
#dashed line = 500
boxplot(d$n_1970, d$n_2025, names = c("1970", "2025"),
        main = "census size per run", ylab = "N (total N)")
abline(h = 500, lty = 2)

summary(d$n_1970)
summary(d$n_2025)


#### 2. boxplots by group ####

par(mfrow = c(2, 3))
boxplot(pct_n_kept_post_dist_2025 ~ disturbance_type, data = d, main = "disturbance type", xlab = "", ylab = "% n kept")
boxplot(pct_n_kept_post_dist_2025 ~ K_group, data = d, main = "K per pop", xlab = "", ylab = "% n kept")
boxplot(pct_n_kept_post_dist_2025 ~ sel_group, data = d, main = "selection", xlab = "", ylab = "% n kept")
boxplot(pct_n_kept_post_dist_2025 ~ mig_group, data = d, main = "migration", xlab = "", ylab = "% n kept")
boxplot(pct_n_kept_post_dist_2025 ~ npop_group, data = d, main = "number of populations", xlab = "", ylab = "% n kept")
par(mfrow = c(1, 1))

boxplot(ne_indicator_dist ~ K_group, data = d, main = "indicator by K per pop", xlab = "", ylab = "ne indicator at disturbance")

#the group means behind the boxplots
aggregate(pct_n_kept_post_dist_2025 ~ sel_group, data = d, FUN = mean)
aggregate(pct_n_kept_post_dist_2025 ~ K_group, data = d, FUN = mean)
aggregate(pct_n_kept_post_dist_2025 ~ npop_group, data = d, FUN = mean)

#### 3. against the indicator at the disturbance, coloured by group ####

#the indicator only takes a few values, so jitter it sideways a little (not up and down)
ind_plot <- ggplot(d, aes(x = ne_indicator_dist, y = pct_n_kept_post_dist_2025)) +
  geom_jitter(width = 0.02, height = 0, alpha = 0.4, size = 2) +
  geom_smooth(method = "lm") +
  xlab("ne indicator at disturbance") + ylab("% n kept 1970-2025") +
  theme_classic()
ind_plot

post_dist_ind_plot <- ggplot(d, aes(x = ne_indicator_post_dist, y = pct_n_kept_post_dist_2025)) +
  geom_jitter(width = 0.02, height = 0, alpha = 0.4, size = 2) +
  geom_smooth(method = "lm") +
  xlab("ne indicator post disturbance") + ylab("% n kept 1970-2025") +
  theme_classic()
post_dist_ind_plot

sel_color_plot <- ggplot(d, aes(x = ne_indicator_dist, y = pct_n_kept_post_dist_2025, color = sel_group)) +
  geom_jitter(width = 0.02, height = 0, alpha = 0.4, size = 2) +
  geom_smooth(method = "lm", se = FALSE) +
  xlab("ne indicator at disturbance") + ylab("% n kept 1970-2025") +
  theme_classic()
sel_color_plot

k_color_plot <- ggplot(d, aes(x = ne_indicator_dist, y = pct_n_kept_post_dist_2025, color = K_group)) +
  geom_jitter(width = 0.02, height = 0, alpha = 0.4, size = 2) +
  geom_smooth(method = "lm", se = FALSE) +
  xlab("ne indicator at disturbance") + ylab("% n kept 1970-2025") +
  theme_classic()
k_color_plot


#### 4. against the parameters directly ####

#selection is a continuous number, so plot it on the x axis instead of grouping it
sel_plot <- ggplot(d, aes(x = selection_strength, y = pct_n_kept_post_dist_2025, color = K_group)) +
  geom_point(alpha = 0.4, size = 2) +
  geom_smooth(method = "lm", se = FALSE) +
  ylab("% n kept 1970-2025") +
  theme_classic()
sel_plot

#split plot: selection within each number of populations
split_plot <- ggplot(d, aes(x = selection_strength, y = pct_n_kept_post_dist_2025)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm") +
  facet_wrap(~ npop_group, nrow = 1) +
  ylab("% n kept 1970-2025") +
  theme_classic()
split_plot


#is the indicator just K per pop?
cor(d$K_per_pop, d$ne_indicator_dist)
cor(d$K_per_pop, d$ne_indicator_post_dist)

k_ind_plot <- ggplot(d, aes(x = K_per_pop, y = ne_indicator_dist, color = npop_group)) +
  geom_jitter(width = 0, height = 0.02, alpha = 0.5) +
  geom_vline(xintercept = 500, linetype = "dashed") +
  geom_smooth(aes(group = 1), method = "lm", color = "black") +
  theme_classic()
k_ind_plot


#### 5. linear models ####

#the indicator on its own (what a manager would see)
m_ind <- lm(pct_n_kept_post_dist_2025 ~ ne_indicator_dist, data = d)
summary(m_ind)

#the parameters first, the indicator last
#K and n_populations instead of K_per_pop, because those two were drawn independently
m_full <- lm(pct_n_kept_post_dist_2025 ~ selection_strength + K + n_populations + slope_decay + disturbance_type + ne_indicator_dist, data = d)
summary(m_full)
anova(m_full) # sequential: the indicator line = what it adds beyond the parameters

#the residuals are what need to be normal
par(mfrow = c(2, 2))
plot(m_full)
par(mfrow = c(1, 1))

#main effects first, then all two-way interactions, written out
m_int <- lm(pct_n_kept_post_dist_2025 ~ selection_strength + K + n_populations + slope_decay +
              disturbance_type + ne_indicator_dist +
              selection_strength:K +
              selection_strength:n_populations +
              selection_strength:slope_decay +
              selection_strength:disturbance_type +
              selection_strength:ne_indicator_dist +
              K:n_populations +
              K:slope_decay +
              K:disturbance_type +
              K:ne_indicator_dist +
              n_populations:slope_decay +
              n_populations:disturbance_type +
              n_populations:ne_indicator_dist +
              slope_decay:disturbance_type +
              slope_decay:ne_indicator_dist +
              disturbance_type:ne_indicator_dist, data = d)
summary(m_int)
plot(m_int)
anova(m_int)

#do the interactions add anything beyond the main-effects model?
anova(m_full, m_int)
