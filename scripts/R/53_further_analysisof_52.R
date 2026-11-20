library(tidyverse)

#further analysis of 52, figures for the supervisor meeting: what drives the decline, and what the ne 500 indicator adds
#data from run_summary_burnin50k.csv (made by 42_build_run_summary.R), one row per run

#import dataset
d <- read.csv("C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k/run_summary_burnin50k.csv")
nrow(d)

#folder for the pictures
output_dir <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/scripts/R/output/53_supervisor_figures"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

#mean population size per run (K is shared out over the populations)
d$mean_n_1970 <- d$n_1970 / d$n_populations
d$mean_n_2025 <- d$n_2025 / d$n_populations

#log scale for the model (+1 so runs that died out are not -Inf)
d$log_n_1970 <- log(d$mean_n_1970)
d$log_n_2025 <- log(d$mean_n_2025 + 1)

#selection groups, same as in 43, 44 and 52
d$sel_group <- cut(d$selection_strength, breaks = c(0, 0.04, 0.07, 0.1),
                   labels = c("weak", "medium", "strong"))
table(d$sel_group)

#number of populations in three groups
d$npop_group <- cut(d$n_populations, breaks = c(3, 5, 6, 8),
                    labels = c("4-5 populations", "6 populations", "7-8 populations"))
table(d$npop_group)

#colour-blind safe colours
sel_cols <- c("#0072B2", "#E69F00", "#D55E00")
npop_cols <- c("blue", "#999999", "red")


#### 1. size in 1970 vs size in 2025 ####

#dashed line = the run kept exactly its 1970 size
#runs that died out sit at the bottom (0 + 1 = 1 on the log axis)
size_plot <- ggplot(d, aes(x = mean_n_1970, y = mean_n_2025 + 1, color = sel_group)) +
  geom_point(alpha = 0.5, size = 2) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed") +
  scale_x_log10() + scale_y_log10() +
  scale_color_manual(values = sel_cols) +
  xlab("mean population size 1970") + ylab("mean population size 2025") +
  labs(color = "selection strength") +
  theme_classic()
size_plot

ggsave(file.path(output_dir, "1_start_vs_end_size.png"), size_plot, width = 8, height = 6.8, dpi = 250)

#share of runs that lost more than half their 1970 size, per selection group
d$lost_half <- d$pct_n_kept_post_dist_2025 < 50
prop.table(table(d$sel_group, d$lost_half), 1)


#### 2. % kept vs the indicator, by number of populations ####

#the indicator only takes a few values, so jitter it sideways a little (not up and down)
npop_plot <- ggplot(d, aes(x = ne_indicator_dist, y = pct_n_kept_post_dist_2025, color = npop_group)) +
  geom_jitter(width = 0.02, height = 0, alpha = 0.4, size = 2) +
  geom_smooth(method = "lm", se = FALSE) +
  geom_hline(yintercept = 100, linetype = "dotted") +
  scale_color_manual(values = npop_cols) +
  xlab("Ne > 500 indicator: 1970") + ylab("% census size kept 1970-2025") +
  labs(color = "number of populations") +
  theme_classic()
npop_plot

ggsave(file.path(output_dir, "2_pct_kept_vs_indicator_by_npop.png"), npop_plot, width = 8, height = 6.8, dpi = 250)

#mean % kept and mean indicator per group
aggregate(cbind(pct_n_kept_post_dist_2025, ne_indicator_dist) ~ npop_group, data = d, FUN = mean)


#### 3. variance explained (model m2) ####

m2 <- lm(log_n_2025 ~ selection_strength + n_populations + log_n_1970
         + selection_strength:n_populations
         + ne_indicator_dist
         + selection_strength:ne_indicator_dist, data = d)
a <- anova(m2)
a

#share of the total sum of squares for every line of the anova table
v <- data.frame(term = rownames(a), pct = 100 * a$"Sum Sq" / sum(a$"Sum Sq"))
v

#keep the order of the anova table (first term at the top)
v$term <- factor(v$term, levels = rev(v$term))

var_plot <- ggplot(v, aes(x = term, y = pct)) +
  geom_col(fill = "grey60") +
  geom_text(aes(label = round(pct, 2)), hjust = -0.2) +
  coord_flip() +
  ylim(0, 65) +
  xlab("") + ylab("% of variation in 2025 population size explained") +
  theme_classic()
var_plot

ggsave(file.path(output_dir, "3_variance_explained.png"), var_plot, width = 8, height = 6.8, dpi = 250)


#### 4. indicator 1970 vs 2025 ####

#dashed line = the indicator did not change
ind_plot <- ggplot(d, aes(x = ne_indicator_dist, y = ne_indicator_post_dist, color = sel_group)) +
  geom_jitter(width = 0.02, height = 0.02, alpha = 0.5, size = 2) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed") +
  scale_color_manual(values = sel_cols) +
  xlab("Ne > 500 indicator: 1970") + ylab("Ne > 500 indicator: 2025") +
  labs(color = "selection strength") +
  theme_classic()
ind_plot

ggsave(file.path(output_dir, "4_indicator_1970_vs_2025.png"), ind_plot, width = 8, height = 6.8, dpi = 250)

#the 2 x 2 table: at least half the populations above 500 or not
table(in_1970 = d$ne_indicator_dist >= 0.5, in_2025 = d$ne_indicator_post_dist >= 0.5)
cor(d$ne_indicator_dist, d$ne_indicator_post_dist)


#### 5. extinction by selection and indicator ####

d$ind_class <- ifelse(d$ne_indicator_dist >= 0.5, "indicator 1970 >= 0.5", "indicator 1970 < 0.5")

#% of runs with at least one extinct population, and how many runs in each group
ext <- aggregate(extinct ~ sel_group + ind_class, data = d, FUN = mean)
ext$pct <- 100 * ext$extinct
ext$n <- aggregate(extinct ~ sel_group + ind_class, data = d, FUN = length)$extinct
ext

ext_plot <- ggplot(ext, aes(x = sel_group, y = pct, fill = ind_class)) +
  geom_col(position = "dodge") +
  geom_text(aes(label = paste0("n = ", n)), position = position_dodge(width = 0.9), vjust = -0.5) +
  scale_fill_manual(values = c("grey75", "grey35")) +
  xlab("selection strength") + ylab("% of runs with at least one extinct population") +
  labs(fill = "") +
  theme_classic()
ext_plot

ggsave(file.path(output_dir, "5_extinction_by_selection_and_indicator.png"), ext_plot, width = 8, height = 6.8, dpi = 250)

#test of the whole table (use fisher.test if chisq.test warns)
chisq.test(table(d$ind_class, d$extinct))
