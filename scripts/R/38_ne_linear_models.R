#first lm of the SLiM simulation 
#taken from results of ramp_v1.3.1_burnin50k 

#import dataset 
d <- read.csv("C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k/run_results_burnin50k.csv")

#first EDA
head(d, 10)
str(d)
summary(d)

#visualising the data
par(mfrow = c(1, 3))
hist(d$ne_indicator_pre_dist)
hist(d$ne_indicator_dist)
hist(d$ne_indicator_post_dist)
par(mfrow = c(1, 1))
hist(d$prop_extinct)
hist(d$n_populations)
hist(d$K_per_pop)
hist(d$selection_strength)
hist(d$slope_decay)
hist(d$D_pop)
hist(d$D_habitat)
hist(d$n_target)

boxplot(d$ne_indicator_pre_dist)
boxplot(d$ne_indicator_dist)
boxplot(d$ne_indicator_post_dist)

plot(d$ne_indicator_pre_dist, d$ne_indicator_post_dist)
plot(d$ne_indicator_pre_dist, d$K_per_pop)

qqnorm(d$ne_indicator_pre_dist)
qqnorm(d$ne_indicator_dist)
qqnorm(d$ne_indicator_post_dist)
qqnorm(d$K_per_pop)

#first lm
m <- lm(ne_indicator_post_dist ~ ne_indicator_pre_dist, data= d)
summary(m)

qqnorm(resid(m))
qqline(resid(m))

par(mfrow = c(2, 2))
plot(m)
par(mfrow = c(1, 1))

#data is looking a bit weird I will log transform the ne indicator values 
sum(d$ne_indicator_pre_dist == 0, na.rm = TRUE)
sum(d$ne_indicator_dist == 0, na.rm = TRUE)
sum(d$ne_indicator_post_dist == 0, na.rm = TRUE)

#log transform the ne indicators
d$log_ne_pre  <- log(d$ne_indicator_pre_dist + 1)
d$log_ne_dist <- log(d$ne_indicator_dist + 1)
d$log_ne_post <- log(d$ne_indicator_post_dist + 1)

head(d)

hist(d$log_ne_pre)
hist(d$log_ne_dist)
hist(d$log_ne_post)

m1 <- lm(log_ne_post ~ log_ne_pre, data= d)
summary(m1)

qqnorm(resid(m1))
qqline(resid(m1))

par(mfrow = c(2, 2))
plot(m1)
par(mfrow = c(1, 1))

m2 <- lm(log_ne_post ~ log_ne_pre + K_per_pop + selection_strength + slope_decay + D_pop + D_inds + D_habitat + disturbance_type, data= d)
summary(m2)
anova(m2)

qqnorm(resid(m2))
qqline(resid(m2))

par(mfrow = c(2, 2))
plot(m2)
par(mfrow = c(1, 1))

m3 <- lm(extinct ~ ne_indicator_pre_dist + K_per_pop + selection_strength + slope_decay + D_pop + D_inds + D_habitat + disturbance_type, data= d)
summary(m3)

qqnorm(resid(m3))
qqline(resid(m3))

par(mfrow = c(2, 2))
plot(m3)
par(mfrow = c(1, 1))

m4 <- lm(extinct ~ log_ne_pre + K_per_pop + selection_strength + slope_decay + D_pop + D_inds + D_habitat + disturbance_type, data= d)
summary(m4)

qqnorm(resid(m4))
qqline(resid(m4))

par(mfrow = c(2, 2))
plot(m4)
par(mfrow = c(1, 1))
