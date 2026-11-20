library(tidyverse)
library(lme4)
library(visreg)
library(dplyr)

#first lmm of the SLiM simulation 
#taken from results of ramp_v1.3.1_burnin50k 

#import dataset 
d <- read.csv("C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k/run_results_burnin50k.csv")

#first EDA
head(d, 10)
str(d)
summary(d)

#visualising the data (basic EDA)
par(mfrow = c(1, 3))
hist(d$ne_indicator_pre_dist)
hist(d$ne_indicator_dist)
hist(d$ne_indicator_post_dist)

boxplot(d$ne_indicator_pre_dist)
boxplot(d$ne_indicator_dist)
boxplot(d$ne_indicator_post_dist)
par(mfrow = c(1, 1))

#just checking on how the correlation looks 
plot(d$ne_indicator_pre_dist, d$ne_indicator_post_dist)
plot(d$ne_indicator_pre_dist, d$K_per_pop)
plot(d$ne_indicator_post_dist, d$K_per_pop)

#data does not look normal - what type of transformation would work for this? 
#I will continue without transforming...

m <- lm(ne_indicator_post_dist ~ ne_indicator_pre_dist, data= d)
summary(m)

prelim_plot <- ggplot(d, aes(x = ne_indicator_pre_dist, y = ne_indicator_post_dist)) +
  geom_jitter(width = 0.03, height = 0.03, alpha = 0.5, size = 2) +
  theme_classic()+
  geom_smooth(method = "lm")
prelim_plot

plot(m, which = 1)
plot(m, which = 2)
par(mfrow = c(2, 2))
plot(m)
par(mfrow = c(1, 1))

#make disturbance type a factor with readable names
d$disturbance_type <- factor(d$disturbance_type, levels = c(0, 1),
                             labels = c("individuals removed", "habitat lost"))

#group K_per_pop, selection strength and migration into a few bins, for facets
d$K_group <- cut(d$K_per_pop, breaks = c(0, 500, 700, 900, 1300),
                 labels = c("ne < 500", "ne > 500-700", "ne > 700-900", "ne > 900"))

d$sel_group <- cut(d$selection_strength, breaks = c(0, 0.04, 0.07, 0.1),
                   labels = c("weak", "medium", "strong"))

d$mig_group <- cut(d$slope_decay,
                   breaks = c(-0.00002, -0.000015, -0.00001, -0.000005),
                   labels = c("low migration", "medium migration", "high migration"),
                   include.lowest = TRUE)

d$npop_group <- factor(d$n_populations)

table(d$K_group)
table(d$sel_group)
table(d$mig_group)
table(d$npop_group) 
table(d$extinct)
#extinct = TRUE if at least one population had died out by the end of the run

#boxplots of explanatory variables that may effect Ne in 2025
boxplot(ne_indicator_post_dist ~ disturbance_type, data = d) 
boxplot(ne_indicator_post_dist ~ run , data = d) 
boxplot(ne_indicator_post_dist ~ K_group, data = d) 
boxplot(ne_indicator_post_dist ~ sel_group, data = d) 
boxplot(ne_indicator_post_dist ~ mig_group, data = d) 

dist_color_plot <- ggplot(d, aes(x = ne_indicator_pre_dist, y = ne_indicator_post_dist, color = disturbance_type)) +
  geom_jitter(width = 0.03, height = 0.03, alpha = 0.5, size = 2) +
  theme_classic()+
  geom_smooth(method = "lm")
dist_color_plot 

k_color_plot <- ggplot(d, aes(x = ne_indicator_pre_dist, y = ne_indicator_post_dist, color = K_group)) +
  geom_jitter(width = 0.03, height = 0.03, alpha = 0.5, size = 2) +
  theme_classic()+
  geom_smooth(method = "lm")
k_color_plot 

sel_color_plot <- ggplot(d, aes(x = ne_indicator_pre_dist, y = ne_indicator_post_dist, color = sel_group)) +
  geom_jitter(width = 0.03, height = 0.03, alpha = 0.5, size = 2) +
  theme_classic()+
  geom_smooth(method = "lm")
sel_color_plot 

mig_color_plot <- ggplot(d, aes(x = ne_indicator_pre_dist, y = ne_indicator_post_dist, color = mig_group)) +
  geom_jitter(width = 0.03, height = 0.03, alpha = 0.5, size = 2) +
  theme_classic()+
  geom_smooth(method = "lm")
mig_color_plot 

npop_color_plot <- ggplot(d, aes(x = ne_indicator_pre_dist, y = ne_indicator_post_dist, color = npop_group)) +
  geom_jitter(width = 0.03, height = 0.03, alpha = 0.5, size = 2) +
  theme_classic()+
  geom_smooth(method = "lm")
npop_color_plot

##interesting thing about npops and deme size, seems we never see runs with low deme number and low pop size also never high number of demes and high pop 
#maybe I could use K total and n_populations as predictors also 
##could also investigate if certain cities are not independent also 

m1 <- lm(ne_indicator_post_dist ~ ne_indicator_pre_dist + selection_strength + slope_decay + K_per_pop + n_populations, data= d)
summary(m1)
visreg(m1, xvar = "ne_indicator_pre_dist", by = "selection_strength")

plot(m1, which = 1)
plot(m1, which = 2)
par(mfrow = c(2, 2))
plot(m1)
par(mfrow = c(1, 1))

##not working
##lmm <- lmer(ne_indicator_post_dist ~ ne_indicator_pre_dist + selection_strength + slope_decay + K_per_pop + n_populations + (1|run), data= d)
##summary(lmm)

m2 <- glm(extinct ~ ne_indicator_pre_dist + selection_strength + slope_decay + K_per_pop + n_populations, data= d, family = binomial)
summary(m2)

plot(m2, which = 1)
plot(m2, which = 2)
par(mfrow = c(2, 2))
plot(m2)
par(mfrow = c(1, 1))

#selection strength plots
extinct_box_plot <- ggplot(d, aes(x = extinct, y = ne_indicator_pre_dist)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.6) +
  geom_jitter(width = 0.15, height = 0.02, alpha = 0.3, size = 1.5) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3, fill = "white") +  # white diamond = mean
  theme_classic()
extinct_box_plot

extinct_box_plot_2025 <- ggplot(d, aes(x = extinct, y = ne_indicator_post_dist)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.6) +
  geom_jitter(width = 0.15, height = 0.02, alpha = 0.3, size = 1.5) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3, fill = "white") +  # white diamond = mean
  theme_classic()
extinct_box_plot_2025

extinct_box_plot_sel <- ggplot(d, aes(x = extinct, y = ne_indicator_pre_dist, fill = sel_group)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.6) +   # outliers off, the points below show them anyway
  geom_point(position = position_jitterdodge(jitter.width = 0.15, jitter.height = 0.02, dodge.width = 0.75),
             alpha = 0.3, size = 1.5) +
  stat_summary(aes(group = sel_group), fun = mean, geom = "point", shape = 23, size = 3,
               fill = "white", position = position_dodge(width = 0.75)) +
  theme_classic()
extinct_box_plot_sel

extinct_box_plot_sel_2025 <- ggplot(d, aes(x = extinct, y = ne_indicator_post_dist, fill = sel_group)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.6) +   # outliers off, the points below show them anyway
  geom_point(position = position_jitterdodge(jitter.width = 0.15, jitter.height = 0.02, dodge.width = 0.75),
             alpha = 0.3, size = 1.5) +
  stat_summary(aes(group = sel_group), fun = mean, geom = "point", shape = 23, size = 3,
               fill = "white", position = position_dodge(width = 0.75)) +
  theme_classic()
extinct_box_plot_sel_2025

#carrying capacity plots
K_box_plot <- ggplot(d, aes(x = extinct, y = ne_indicator_pre_dist, fill = K_group)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.6) +   # outliers off, the points below show them anyway
  geom_point(position = position_jitterdodge(jitter.width = 0.15, jitter.height = 0.02, dodge.width = 0.75),
             alpha = 0.3, size = 1.5) +
  stat_summary(aes(group = K_group), fun = mean, geom = "point", shape = 23, size = 3,
               fill = "white", position = position_dodge(width = 0.75)) +
  theme_classic()
K_box_plot

K_box_plot_2025 <- ggplot(d, aes(x = extinct, y = ne_indicator_post_dist, fill = K_group)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.6) +   # outliers off, the points below show them anyway
  geom_point(position = position_jitterdodge(jitter.width = 0.15, jitter.height = 0.02, dodge.width = 0.75),
             alpha = 0.3, size = 1.5) +
  stat_summary(aes(group = K_group), fun = mean, geom = "point", shape = 23, size = 3,
               fill = "white", position = position_dodge(width = 0.75)) +
  theme_classic()
K_box_plot_2025

anova(m)
anova(m1)
anova(m2)


#having issues with a mixed model with run as a random effect, seems that each run being one row means that our gorup does not find a difference between runs 
#we would need run to be a heirarchy and have the same number of populations per run, the long data does not show the full story 

#the deme number and pop size variable seems to be tangled, low demes means high pop N high demes means low pop N 

m3 <- lm(prop_extinct ~ ne_indicator_dist + slope_decay + selection_strength + ne_indicator_pre_dist, data = d)
plot(m3)

hist(d$prop_extinct)
#I may need to log + 1 transform my proportion extict to make all the values positiva and to reduce the number of 0s 

d_log <- d %>%
  mutate(log_prop_extinct = log(prop_extinct + 1))

hist(d_log$log_prop_extinct)

