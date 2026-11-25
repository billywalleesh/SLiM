#first lm of the SLiM simulation 
#taken from results of ramp_v1.3.1_burnin50k 

#import dataset 
d <- read.csv("C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k_20112026/run_summary_burnin50k_20112026.csv")

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
hist(d$prop_extinct)

par(mfrow = c(1, 3))
boxplot(d$ne_indicator_pre_dist)
boxplot(d$ne_indicator_dist)
boxplot(d$ne_indicator_post_dist)
par(mfrow = c(1, 1))

plot(d$ne_indicator_dist, d$prop_extinct)
plot(d$ne_indicator_dist, d$extinct)
plot(d$n_1970, d$prop_extinct)
plot(d$n_1970, d$n_2025)

qqnorm(d$ne_indicator_pre_dist)
qqnorm(d$ne_indicator_dist)
qqnorm(d$ne_indicator_post_dist)

#first lm
m <- lm(extinct ~ ne_indicator_pre_dist, data= d)
summary(m)

qqnorm(resid(m))
qqline(resid(m))

par(mfrow = c(2, 2))
plot(m)
par(mfrow = c(1, 1))

#data is looking a bit weird I will log transform the ne indicator values 
extinct <- sum(d$extinct == 0, na.rm = TRUE)
extinct
not_extinct <- sum(d$extinct == 1, na.rm = TRUE)
not_extinct

#log transform the ne indicators
d$log_prop_extinct <- log(d$prop_extinct + 1.001)
hist(d$log_prop_extinct)

m1 <- lm(extinct ~ ne_indicator_dist + K_per_pop + selection_strength + slope_decay + D_pop + D_inds + D_habitat + disturbance_type, data= d)
summary(m1)

qqnorm(resid(m1))
qqline(resid(m1))

par(mfrow = c(2, 2))
plot(m1)
par(mfrow = c(1, 1))

