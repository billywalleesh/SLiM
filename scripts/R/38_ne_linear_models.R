#first linear models of the 1000 cluster runs
#response: Ne at the end of the run (Ne_inb_end)
#one row per population per run, from 37_combine_cluster_results.R

library(lme4) # for the mixed model at the end; install.packages("lme4") if you don't have it

## load the table
dat = read.csv("C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_cluster/analysis_table_1000.csv")
dim(dat)
length(unique(dat$run)) # should be 1000


## the response: Ne at the end
#Ne is NA when a population has no individuals left (it cannot be estimated)
#an extinct population has Ne = 0, so set those to 0 instead of dropping them
dat$Ne_end = dat$Ne_inb_end
dat$Ne_end[dat$N_end == 0] = 0

sum(dat$extinct)      # number of extinct populations
sum(is.na(dat$Ne_end)) # populations still NA (alive but too few parents to estimate Ne); lm leaves these out

hist(dat$Ne_end, breaks = 50, main = "Ne at the end of the run", xlab = "Ne_inb_end")


## Model 1: the basic model
#pop_ids and target_pops are text, so they are replaced by targeted (was this population hit?)
#n_target is left out because it is round(D_pop * n_populations), so it repeats those two
#D_pop is left out for the same reason: what it does to a population is captured by targeted
m1 = lm(Ne_end ~ n_populations + K_per_pop + selection_strength + slope_decay +
          D_inds + D_habitat + targeted, data = dat)
summary(m1)


## Model 2: the disturbance only acts on the populations that were hit
#D_inds (survival) and D_habitat (K left) only change a population if it was targeted,
#so they enter as an interaction with targeted (targeted * D_inds)
#
#scale() puts every predictor on the same scale (mean 0, 1 = one standard deviation),
#so the estimates can be compared: "Ne changes by this much for a 1 SD change in x"
#(without it, slope_decay gets a huge number only because its values are tiny, e.g. -0.00001)
m2 = lm(Ne_end ~ scale(n_populations) + scale(K_per_pop) + scale(selection_strength) +
          scale(slope_decay) + targeted * (scale(D_inds) + scale(D_habitat)), data = dat)
summary(m2)

#check the model: residuals should look like random scatter around 0
par(mfrow = c(2, 2))
plot(m2)
par(mfrow = c(1, 1))


## Model 3: populations from the same run are not independent
#they share every run setting and exchange migrants, so run is added as a random effect
m3 = lmer(Ne_end ~ scale(n_populations) + scale(K_per_pop) + scale(selection_strength) +
            scale(slope_decay) + targeted * (scale(D_inds) + scale(D_habitat)) + (1 | run),
          data = dat)
summary(m3)


## Model 4: does Ne before the climate change predict Ne at the end?
m4 = lm(Ne_end ~ scale(Ne_inb_before) + scale(selection_strength) + scale(slope_decay) +
          targeted * (scale(D_inds) + scale(D_habitat)), data = dat)
summary(m4)


## a warning before interpreting Ne: how close is it to N and K?
cor(dat$Ne_inb_before, dat$N_before)  # Ne vs census N before
cor(dat$Ne_inb_before, dat$K_per_pop) # Ne vs K before
plot(dat$N_before, dat$Ne_inb_before, xlab = "N before", ylab = "Ne_inb before")
abline(0, 1, col = "red") # the 1:1 line
