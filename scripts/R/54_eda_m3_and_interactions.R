library(tidyverse)

#eda of two models for % of the 1970 census size still there in 2025
#  m3    = selection and number of populations first, the indicator last
#  m_int = all main effects, then all two-way interactions (same as in 44)
#data from run_summary_burnin50k.csv (made by 42_build_run_summary.R), one row per run

#import dataset
d <- read.csv("C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k/run_summary_burnin50k.csv")
nrow(d)

#folder for the pictures
output_dir <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/scripts/R/output/54_eda_m3_and_interactions"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

#make the groups, same as in 43 and 44
d$disturbance_type <- factor(d$disturbance_type, levels = c(0, 1),
                             labels = c("individuals removed", "habitat lost"))

#number of populations as a factor, so every number (4 to 8) gets its own mean
d$npop_f <- factor(d$n_populations)
table(d$npop_f)


#### 1. m3: selection and number of populations first, the indicator last ####

m3 <- lm(pct_n_kept_post_dist_2025 ~ selection_strength + npop_f + ne_indicator_dist, data = d)
summary(m3)
anova(m3)

#the residuals are what need to be normal
par(mfrow = c(2, 2))
plot(m3)
par(mfrow = c(1, 1))

#the same model without the indicator, does the indicator add anything?
m3_no_ind <- lm(pct_n_kept_post_dist_2025 ~ selection_strength + npop_f, data = d)
anova(m3_no_ind, m3)

#what m3 predicts: one line per number of populations, at the mean selection strength
new <- expand.grid(ne_indicator_dist = seq(0, 1, by = 0.1),
                   npop_f = levels(d$npop_f),
                   selection_strength = mean(d$selection_strength))
new$pred <- predict(m3, newdata = new)
head(new)

m3_plot <- ggplot(d, aes(x = ne_indicator_dist, y = pct_n_kept_post_dist_2025, color = npop_f)) +
  geom_jitter(width = 0.02, height = 0, alpha = 0.3, size = 2) +
  geom_line(data = new, aes(y = pred), linewidth = 1.2) +
  geom_hline(yintercept = 100, linetype = "dotted") +
  scale_color_viridis_d() +
  xlab("Ne > 500 indicator: 1970") + ylab("% census size kept 1970-2025") +
  labs(color = "number of populations") +
  theme_classic()
m3_plot

ggsave(file.path(output_dir, "1_m3_predicted_lines.png"), m3_plot, width = 8, height = 6.8, dpi = 250)


#### 2. m_int: main effects first, then all two-way interactions, written out ####

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
anova(m_int)

par(mfrow = c(2, 2))
plot(m_int)
par(mfrow = c(1, 1))

#the main effects model from 44, do the interactions add anything?
m_full <- lm(pct_n_kept_post_dist_2025 ~ selection_strength + K + n_populations + slope_decay +
               disturbance_type + ne_indicator_dist, data = d)
anova(m_full, m_int)

d$pct_K_1970 <- 100 * d$n_1970 / d$K


##pre and post indicator model 
m_ind25 <- lm(ne_indicator_post_dist ~ selection_strength + K + n_populations + slope_decay +
                disturbance_type + pct_K_1970 + ne_indicator_dist, data = d)
summary(m_ind25)
anova(m_ind25)
plot(m_ind25)
hist(d$ne_indicator_post_dist)

x <- jitter(d$ne_indicator_dist, amount = 0.02)
y <- jitter(d$ne_indicator_post_dist, amount = 0.02)

plot(x, y,
     xlab = "Ne > 500 indicator: 1970",
     ylab = "Ne > 500 indicator: 2025")

#dashed line = the indicator did not change
abline(0, 1, lty = 2)


#### 3. how much every term of m_int explains ####

#share of the total sum of squares for every line of the anova table
a <- anova(m_int)
v <- data.frame(term = rownames(a), pct = 100 * a$"Sum Sq" / sum(a$"Sum Sq"), p = a$"Pr(>F)")
v

#mark the terms that have the indicator in them
v$indicator <- grepl("ne_indicator", v$term)

#biggest at the top
v$term <- factor(v$term, levels = v$term[order(v$pct)])

var_plot <- ggplot(v, aes(x = term, y = pct, fill = indicator)) +
  geom_col() +
  geom_text(aes(label = round(pct, 1)), hjust = -0.2) +
  coord_flip() +
  ylim(0, 55) +
  scale_fill_manual(values = c("grey60", "red"), labels = c("other terms", "terms with the indicator")) +
  xlab("") + ylab("% of variation in % census size kept explained") +
  labs(fill = "") +
  theme_classic()
var_plot

ggsave(file.path(output_dir, "2_m_int_variance_explained.png"), var_plot, width = 9, height = 7.5, dpi = 250)


#### 4. the biggest interactions as pictures ####

#4a. disturbance type x indicator
dist_ind_plot <- ggplot(d, aes(x = ne_indicator_dist, y = pct_n_kept_post_dist_2025, color = disturbance_type)) +
  geom_jitter(width = 0.02, height = 0, alpha = 0.4, size = 2) +
  geom_smooth(method = "lm", se = FALSE) +
  geom_hline(yintercept = 100, linetype = "dotted") +
  scale_color_manual(values = c("blue", "red")) +
  xlab("Ne > 500 indicator: 1970") + ylab("% census size kept 1970-2025") +
  labs(color = "disturbance type") +
  theme_classic()
dist_ind_plot

ggsave(file.path(output_dir, "3_disturbance_x_indicator.png"), dist_ind_plot, width = 8, height = 6.8, dpi = 250)

#the slope of the indicator in each disturbance type
coef(lm(pct_n_kept_post_dist_2025 ~ ne_indicator_dist, data = d[d$disturbance_type == "individuals removed", ]))
coef(lm(pct_n_kept_post_dist_2025 ~ ne_indicator_dist, data = d[d$disturbance_type == "habitat lost", ]))

#4b. disturbance type x selection
dist_sel_plot <- ggplot(d, aes(x = selection_strength, y = pct_n_kept_post_dist_2025, color = disturbance_type)) +
  geom_point(alpha = 0.4, size = 2) +
  geom_smooth(method = "lm", se = FALSE) +
  geom_hline(yintercept = 100, linetype = "dotted") +
  scale_color_manual(values = c("blue", "red")) +
  xlab("selection strength") + ylab("% census size kept 1970-2025") +
  labs(color = "disturbance type") +
  theme_classic()
dist_sel_plot

ggsave(file.path(output_dir, "4_disturbance_x_selection.png"), dist_sel_plot, width = 8, height = 6.8, dpi = 250)

#4c. disturbance type x number of populations
dist_npop_plot <- ggplot(d, aes(x = n_populations, y = pct_n_kept_post_dist_2025, color = disturbance_type)) +
  geom_jitter(width = 0.15, height = 0, alpha = 0.4, size = 2) +
  geom_smooth(method = "lm", se = FALSE) +
  geom_hline(yintercept = 100, linetype = "dotted") +
  scale_color_manual(values = c("blue", "red")) +
  xlab("number of populations") + ylab("% census size kept 1970-2025") +
  labs(color = "disturbance type") +
  theme_classic()
dist_npop_plot

ggsave(file.path(output_dir, "5_disturbance_x_npop.png"), dist_npop_plot, width = 8, height = 6.8, dpi = 250)

#4d. selection x number of populations
sel_npop_plot <- ggplot(d, aes(x = selection_strength, y = pct_n_kept_post_dist_2025, color = npop_f)) +
  geom_point(alpha = 0.3, size = 2) +
  geom_smooth(method = "lm", se = FALSE) +
  geom_hline(yintercept = 100, linetype = "dotted") +
  scale_color_viridis_d() +
  xlab("selection strength") + ylab("% census size kept 1970-2025") +
  labs(color = "number of populations") +
  theme_classic()
sel_npop_plot

ggsave(file.path(output_dir, "6_selection_x_npop.png"), sel_npop_plot, width = 8, height = 6.8, dpi = 250)

#mean % kept per disturbance type
aggregate(pct_n_kept_post_dist_2025 ~ disturbance_type, data = d, FUN = mean)
