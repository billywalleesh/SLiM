library(tidyverse)

#main result: % of the 1970 census size still there in 2025 against the ne 500 indicator in 1970
#data from run_summary_burnin50k.csv (made by 42_build_run_summary.R), one row per run

#import dataset
d <- read.csv("C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k/run_summary_burnin50k.csv")
nrow(d)

#folder for the pictures
output_dir <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/scripts/R/output/52_main_result"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

#selection groups, same as in 43 and 44
d$sel_group <- cut(d$selection_strength, breaks = c(0, 0.04, 0.07, 0.1),
                   labels = c("weak", "medium", "strong"))
table(d$sel_group)

#### the model behind the line ####

m_ind <- lm(pct_n_kept_post_dist_2025 ~ ne_indicator_dist, data = d)
summary(m_ind)

#### 1. all runs, one line ####

#the indicator only takes a few values, so jitter it sideways a little (not up and down)
main_plot <- ggplot(d, aes(x = ne_indicator_dist, y = pct_n_kept_post_dist_2025)) +
  geom_jitter(width = 0.02, height = 0, alpha = 0.4, size = 2) +
  geom_smooth(method = "lm", color = "red") +
  geom_hline(yintercept = 100, linetype = "dotted") +
  xlab("Ne > 500 indicator: 1970") + ylab("% census size kept 1970-2025") +
  theme_classic()
main_plot

ggsave(file.path(output_dir, "main_result_pct_n_kept_vs_indicator.png"), main_plot,
       width = 8, height = 6.8, dpi = 250)

#### 2. coloured by selection strength ####

sel_plot <- ggplot(d, aes(x = ne_indicator_dist, y = pct_n_kept_post_dist_2025, color = sel_group)) +
  geom_jitter(width = 0.02, height = 0, alpha = 0.4, size = 2) +
  geom_smooth(method = "lm", se = FALSE) +
  geom_hline(yintercept = 100, linetype = "dotted") +
  scale_color_manual(values = c("blue", "grey", "red")) +
  xlab("Ne > 500 indicator: 1970") + ylab("% census size kept 1970-2025") +
  labs(color = "selection strength") +
  theme_classic()
sel_plot

ggsave(file.path(output_dir, "main_result_pct_n_kept_vs_indicator_by_selection.png"), sel_plot,
       width = 8, height = 6.8, dpi = 250)

#the mean % kept per selection group
aggregate(pct_n_kept_post_dist_2025 ~ sel_group, data = d, FUN = mean)

#### 3. number of populations against the indicator ####

#both only take a few values, so jitter both a little
npop_plot <- ggplot(d, aes(x = ne_indicator_dist, y = n_populations)) +
  geom_jitter(width = 0.02, height = 0.15, alpha = 0.4, size = 2) +
  geom_smooth(method = "lm", color = "red") +
  xlab("Ne > 500 indicator: 1970") + ylab("number of populations") +
  theme_classic()
npop_plot

ggsave(file.path(output_dir, "n_populations_vs_indicator.png"), npop_plot,
       width = 8, height = 6.8, dpi = 250)

#how strongly the two go together
cor(d$ne_indicator_dist, d$n_populations)
