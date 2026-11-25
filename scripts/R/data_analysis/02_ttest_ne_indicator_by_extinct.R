library(tidyverse)
library(pROC)
library(visreg)

#is the ne 500 indicator at the disturbance (1970) different between runs that went extinct and runs that did not?
#extinct = TRUE if every population of the run had no individuals left by the end (2025) = the whole metapopulation is gone
#ne_indicator_dist = proportion of the run's populations with Ne (here N) above 500, right after the disturbance (tick 54000)
#data from run_summary_burnin50k_20112026.csv (batch 2, made by data_pipeline/06_build_run_summary.R), one row per run

#import dataset
d <- read.csv("C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k_20112026/run_summary_burnin50k_20112026.csv")
nrow(d) # should be 1000

#folder for the picture
output_dir <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/scripts/R/figure_creation/output/data_analysis_01_ttest_20112026"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

#how many runs in each group
table(d$extinct)

#the mean indicator in each group
aggregate(ne_indicator_dist ~ extinct, data = d, FUN = mean)

####t test

#welch two sample t test (the default in R, does not assume the two groups have the same variance)
t.test(ne_indicator_dist ~ extinct, data = d)

#the indicator is a proportion (0 to 1) and only takes a few values, so it is not normal
#with 1000 runs the t test is still fine for comparing means, but a wilcoxon test is a good check
wilcox.test(ne_indicator_dist ~ extinct, data = d)

####plot

#extinct as a label for the x axis
d$extinct_label <- ifelse(d$extinct, "extinct", "not extinct")

#boxplot with every run on top, jittered sideways (the indicator only takes a few values)
#the red dot is the group mean, the value the t test compares
ttest_plot <- ggplot(d, aes(x = extinct_label, y = ne_indicator_dist)) +
  geom_boxplot(outlier.shape = NA) +
  geom_jitter(width = 0.2, height = 0.01, alpha = 0.3, size = 1.5) +
  stat_summary(fun = mean, geom = "point", color = "red", size = 4) +
  xlab("metapopulation extinct by 2025") + ylab("Ne > 500 indicator: 1970") +
  theme_classic()
ttest_plot

ggsave(file.path(output_dir, "ne_indicator_1970_by_extinct.png"), ttest_plot,
       width = 6, height = 6.8, dpi = 250)

#% of runs extinct and mean 1970 indicator for each number of populations
n_pop_table <- rbind(pct_extinct = round(100 * tapply(d$extinct, d$n_populations, mean)),
                     mean_indicator_1970 = round(tapply(d$ne_indicator_dist, d$n_populations, mean), 2))
n_pop_table

#how many runs in each cell (extinct or not, per number of populations)
table(d$n_populations, d$extinct)

#boxplot of the 1970 indicator for each number of populations, split by extinct
#each run on top, dodged next to its own box, only jittered sideways
#the red dot is the group mean
n_pop_plot <- ggplot(d, aes(x = factor(n_populations), y = ne_indicator_dist, fill = extinct_label)) +
  geom_boxplot(outlier.shape = NA) +
  geom_point(position = position_jitterdodge(jitter.width = 0.2, jitter.height = 0),
             alpha = 0.3, size = 1.2) +
  stat_summary(fun = mean, geom = "point", color = "red", size = 3,
               position = position_dodge(width = 0.75)) +
  scale_fill_manual(values = c("not extinct" = "white", "extinct" = "grey")) +
  xlab("number of populations") + ylab("Ne > 500 indicator: 1970") +
  labs(fill = "") +
  theme_classic()
n_pop_plot

ggsave(file.path(output_dir, "ne_indicator_1970_by_n_pop_and_extinct.png"), n_pop_plot,
       width = 8, height = 6.8, dpi = 250)

#### logistic regression ####

#proportion of the run's populations hit by the disturbance
d$prop_pop_disturbed <- d$D_pop / d$n_populations
d$disturbance_type <- factor(d$disturbance_type)

#D_inds and D_habitat are the proportion of individuals / habitat kept in the disturbed populations
#1 = that disturbance is off, so they go in as plain numbers
#disturbance_type * prop_pop_disturbed: the effect of hitting more populations can differ by disturbance type
m_ext <- glm(extinct ~ n_populations + selection_strength + 
               slope_decay + disturbance_type * prop_pop_disturbed + 
               D_inds + D_habitat + prop_pop_disturbed:D_inds + 
               prop_pop_disturbed:D_habitat + K + ne_indicator_dist + K:ne_indicator_dist + n_populations:ne_indicator_dist, family = binomial, data = d)

summary(m_ext)
visreg(m_ext, xvar = "n_populations", scale = "response")
visreg(m_ext, xvar = "selection_strength", scale = "response")
visreg(m_ext, xvar = "slope_decay", scale = "response")
visreg(m_ext, xvar = "ne_indicator_dist", scale = "response")
visreg(m_ext, xvar = "K", scale = "response")
plot(m_ext)
plot(d$slope_decay,d$extinct)


#the indicator on its own (what a manager would actually have)
m_ind <- glm(extinct ~ ne_indicator_dist, family = binomial, data = d)
summary(m_ind)
plot(m_ind)

#how well each model separates extinct from not extinct runs (0.5 = coin flip, 1 = perfect)
auc(roc(d$extinct, fitted(m_ind)))
auc(roc(d$extinct, fitted(m_ext)))

d %>% group_by(n_populations, ne_indicator_dist) %>%
  summarise(n = n(), pct_extinct = round(100 * mean(extinct)), .groups = "drop")

m0 <- glm(extinct ~ 1, family = binomial, data = d)
m_ind <- glm(extinct ~ ne_indicator_dist + factor(n_populations), family = binomial, data = d)
summary(m_ind)
anova(m0, m_ind, test = "Chisq")
exp(0.1 * coef(m_ind)["ne_indicator_dist"])   # odds ratio per +0.1 in the indicator

#disturbance_type * prop_pop_disturbed: the effect of hitting more populations can differ by disturbance type
m2 <- glm(extinct ~ n_populations + selection_strength + 
               slope_decay + prop_pop_disturbed + 
               prop_pop_disturbed:D_inds + 
               prop_pop_disturbed:D_habitat + K + ne_indicator_dist + K:ne_indicator_dist + n_populations:ne_indicator_dist + selection_strength:ne_indicator_dist, family = binomial, data = d)
summary(m2)



