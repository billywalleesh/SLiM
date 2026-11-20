# What would a field study have measured?
# "virtual sampling" of the ramp_v1.3.1_burnin50k runs: the true Ne from the
# model compared with the census N, the field proxy Ne = 0.1 x N, and genetic
# estimates (temporal, LD and the two combined) at different sampling efforts
#
# the idea (no new cluster run needed):
# the logs already have the true Ne of every population (Ne_inb, from the
# pedigree). a real study does not know this. it takes a sample of S
# individuals, genotypes L SNPs and estimates Ne with the LD method (one
# sample) or the temporal method (two samples, here 1 generation apart).
# Waples (2026, Mol Ecol Resour 26:e70114) gives how noisy these estimates
# are, as a function of the true Ne, S and L:
#   temporal:  var(1/Ne_hat) = 8 * E(F)^2 / (t^2 * n'F)      E(F)  = t/(2Ne) + 1/S     (eq 5b and 11, plan II)
#   LD:        var(1/Ne_hat) = 18 * E(r2)^2 / n'LD            E(r2) = 1/(3Ne) + 1/(S-1) (eq 12 and 16)
# n'F and n'LD = how many loci / pairs of loci are really independent
# (linked SNPs and overlapping pairs carry the same information twice). they
# come from the fitted functions of Waples et al. (2022, Mol Ecol Resour
# 22:503-518; github.com/nwfsc-cb/pseudorep), the same code ComboNe uses
# 1/Ne_hat is close to normal (Waples 2026 fig 1), so one virtual estimate is
#   1/Ne_hat = 1/Ne_true + normal noise with that variance
# a negative 1/Ne_hat means "no drift detected", so Ne_hat = infinite
# temporal and LD are combined with inverse-variance weights, iterated as in
# Waples 2026 section 3.5 (eq 20b, 21 and 25)
#
# what this does NOT include: biases a real estimator would pick up in this
# model from migration between the demes and from selection on the m2 loci
# (Waples assumes closed, neutral populations). so this is the BEST case for
# genetic sampling. testing those biases needs genotypes from a subset of
# runs, not the whole 1000-run batch again.
#
# time points (as in 42_build_run_summary.R, but after the disturbance it is 1971):
#   pre_dist  tick 53999  the generation before the disturbance
#   1971      tick 54001  first generation bred by the disturbed populations
#                         (Ne_inb at tick 54000 still describes the parents from
#                         BEFORE the cull, so it cannot be compared with N at 54000)
#   2025      tick 54055
#
# makes these files in SLiM/scripts/R/output/48_virtual_sampling/:
#   virtual_sampling_ne.csv        one row per population per time point, with every estimate
#   error_by_design.csv            the numbers behind fig 3
#   fig1_example_population.png    like Waples fig 1: spread of Ne_hat and 1/Ne_hat for one population
#   fig2_precision_ratio.png       like Waples fig 2: is temporal or LD more precise in my Ne range?
#   fig3_error_by_design.png       like Waples table 1 / fig 4 bottom: error of each method and sampling effort
#   fig4_ratio_distribution.png    like Waples fig 4 top: estimated Ne / true Ne for each method
#   fig5_indicator_error.png       Ne 500 indicator: error of each method, by disturbance type
#   fig6_decline.png               % of pre-disturbance Ne left in 2025: estimated vs true


## folders (change these if your files move)
log_folder <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/results/ramp_v1.3.1_burnin50k"
summary_file <- file.path(log_folder, "run_summary_burnin50k.csv")
output_dir <- "C:/Users/WilliamWallisch/msc_workspace/SLiM/scripts/R/output/48_virtual_sampling"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

## constants
ticks <- c(53999, 54001, 54055)            # the three time points
time_names <- c("pre_dist", "1971", "2025")
ne_threshold <- 500                        # GBF Ne 500 indicator

sample_sizes <- c(25, 50, 100)             # S = individuals sampled (as in Waples 2026 table 1)
snp_numbers <- c(100, 1000, 5000)          # L = SNPs genotyped (as in Waples 2026 table 1)
main_S <- 50                               # the sampling effort used in fig 1, 4, 5 and 6
main_L <- 1000

n_chromosomes <- 16    # genome of the real species: 16 chromosomes of 50 Mb (Waples 2026 default), used in the n' functions
ld_bias <- 1.05        # LD Ne_hat is about 5% too high (Waples 2026 fig S2), used when drawing LD estimates
n_iterations <- 5      # iterations of the combined weights (Waples 2026 section 3.5: 3-5 is enough)

set.seed(48)           # so the virtual samples are the same every time

## colours: one per method, the same in every figure
col_census <- "grey45"
col_ld <- "#2a78d6"
col_temporal <- "#eb6834"
col_combo <- "#1baf7a"
col_proxy <- "#eda100"
col_individuals <- "#e87ba4"   # disturbance type, fig 6
col_habitat <- "#008300"


# ---------------- Functions ----------------

# effective number of independent loci for the temporal method (n'F)
# Waples et al. 2022, PredictFst.R, only changed so it works on whole columns
nprime_temporal <- function(ne, S, L) {
  ne <- pmin(pmax(ne, 50, S), 3200)   # stay inside the range the function was fitted on
  C <- n_chromosomes
  q1 <- c(0.958633285, 0.013469143, 0.007135748, -0.001863156)
  q2 <- c(2.08304896, -0.24271278, 0.00923448, -0.57920739, 1.21567379, 0.05929167, 0.12727216, 0.09241921)
  q5 <- c(-8.8963881, 2.7271474, 1.8244296, 3.8598313, -0.1480143, -0.4126190, -0.3886260)
  p1 <- q1[1] + q1[2]*log(C) + q1[3]*log(ne) + q1[4]*log(C)*log(ne)
  p2 <- q2[1] + q2[2]*log(C) + q2[3]*log(ne) + q2[4]*log(S) + q2[5]*S/ne + q2[6]*log(C)*log(ne) +
    q2[7]*log(S)*log(ne) + q2[8]*log(S)*log(C)
  p3 <- q5[1] + q5[2]*log(C) + q5[3]*log(ne) + q5[4]*log(S) + q5[5]*log(C)*log(ne) +
    q5[6]*log(S)*log(ne) + q5[7]*log(C)*log(S)
  x <- log10(L)
  A <- x / (1 / p1^p3 + (x / p2)^p3)^(1 / p3)
  pmin(10^A, L)   # never more than the number of loci
}

# effective number of independent pairs of loci for the LD method (n'LD)
# Waples et al. 2022, PredictLD.R
nprime_ld <- function(ne, S, L) {
  ne <- pmin(pmax(ne, 50, S), 3200)
  C <- n_chromosomes
  q1 <- c(1.53450230, 0.12518487, 0.06692614, -0.06710636, -0.24470293, -0.01474650)
  q2 <- c(0.52949689, 0.12559264, 0.61411490, 0.24493530, 0.50730040, -1.38178677, -0.01697811, -0.03484065)
  q5 <- c(1.2317425, 0.5675758, -0.3671743, 1.2211834, 0.3815077, 0.1881963, -0.6756503)
  p1 <- q1[1] + q1[2]*log(C) + q1[3]*log(ne) + q1[4]*log(S) + q1[5]*S/ne + q1[6]*log(C)*log(ne)
  p2 <- q2[1] + q2[2]*log(C) + q2[3]*log(ne) + q2[4]*log(S) + q2[5]*S/ne + q2[6]/C +
    q2[7]*log(C)*log(ne) + q2[8]*log(S)*log(ne)
  p3 <- q5[1] + q5[2]*log(C) + q5[3]*log(ne) + q5[4]*log(S) + q5[5]*log(C)*log(ne) +
    q5[6]*log(S)*log(ne) + q5[7]*log(C)*log(S)
  x <- log10(L)
  A <- x / (1 / p1^p3 + (x / p2)^p3)^(1 / p3)
  pmin(10^A, L * (L - 1) / 2)   # never more than the number of pairs
}

# expected variance of 1/Ne_hat, temporal method, samples 1 generation apart (Waples 2026 eq 11, plan II)
var_inv_ne_temporal <- function(ne, S, L) {
  t <- 1
  EF <- t / (2 * ne) + 1 / S
  8 * EF^2 / (t^2 * nprime_temporal(ne, S, L))
}

# expected variance of 1/Ne_hat, LD method, one sample (Waples 2026 eq 16)
var_inv_ne_ld <- function(ne, S, L) {
  Er2 <- 1 / (3 * ne) + 1 / (S - 1)
  18 * Er2^2 / nprime_ld(ne, S, L)
}

# combined estimate of 1/Ne (Waples 2026 section 3.5):
# start with equal weights, then weight each method by 1 / its variance,
# where the variance is worked out at the current combined estimate
combine_estimates <- function(inv_temp, inv_ld, S, L) {
  inv_combo <- (inv_temp + inv_ld) / 2
  for (i in 1:n_iterations) {
    ne_guess <- 1 / pmax(inv_combo, 1e-6)   # no drift seen = treat as a very large Ne
    w_temp <- 1 / var_inv_ne_temporal(ne_guess, S, L)
    w_ld <- 1 / var_inv_ne_ld(ne_guess, S, L)
    inv_combo <- (w_temp * inv_temp + w_ld * inv_ld) / (w_temp + w_ld)
  }
  inv_combo
}

# 1/Ne back to Ne; zero or negative 1/Ne = no drift detected = infinite Ne
inv_to_ne <- function(inv) {
  ifelse(inv > 0, 1 / inv, Inf)
}

# relative error of the drift signal 1/Ne, root mean square over populations, in %
# Waples uses RMSE of 1/Ne; dividing by the true 1/Ne makes small and large
# populations comparable. (1/Ne_hat - 1/Ne) / (1/Ne) is the same as Ne/Ne_hat - 1
rel_rmse <- function(est, true) {
  100 * sqrt(mean((true / est - 1)^2))
}

# check: the paper's worked example (L = 9100, S = 40, Ne = 100, 16 chromosomes)
# should give n'F = 3118 and n'LD = 7940
round(nprime_temporal(99.96, 40, 9100))
round(nprime_ld(99.96, 40, 9100))


# ---------------- 1. Read the logs ----------------
# one row per population per time point

log_files <- list.files(log_folder, pattern = "^run_[0-9]+_log.csv$", full.names = TRUE)
length(log_files)   # should be 1000

d <- data.frame()

for (i in 1:length(log_files)) {

  one <- read.csv(log_files[i])

  # the populations of this run
  pops <- one[one$cycle == ticks[1], c("run", "pop", "city")]

  for (k in 1:3) {
    rows <- one[one$cycle == ticks[k], c("run", "pop", "city", "N", "Ne_inb", "Ne_proxy")]

    # if every population died out before this tick the run has no rows any more:
    # add them back with N = 0
    gone <- pops[!(pops$pop %in% rows$pop), ]
    if (nrow(gone) > 0) {
      rows <- rbind(rows, data.frame(gone, N = 0, Ne_inb = NA, Ne_proxy = 0))
    }

    rows$time <- time_names[k]
    d <- rbind(d, rows)
  }

  if (i %% 100 == 0) cat("read", i, "of", length(log_files), "logs\n")
}

d$time <- factor(d$time, levels = time_names)
head(d)
table(d$time)

# a population can only be sampled if it has at least 2 individuals.
# populations with fewer (or extinct) get Ne = 0 everywhere
d$alive <- d$N >= 2 & !is.na(d$Ne_inb)
table(d$time, d$alive)

d$ne_true <- ifelse(d$alive, d$Ne_inb, 0)
d$census <- ifelse(d$alive, d$N, 0)        # Ne taken as census N (what 37.1 does)
d$proxy <- ifelse(d$alive, d$Ne_proxy, 0)  # field proxy Ne = 0.1 x N (from the log)

summary(d$ne_true[d$alive])


## add the run settings
s <- read.csv(summary_file)
d <- merge(d, s[, c("run", "disturbance_type", "K_per_pop", "selection_strength", "slope_decay")], by = "run")
d$disturbance_type <- factor(d$disturbance_type, levels = c(0, 1),
                             labels = c("individuals removed", "habitat lost"))
table(d$disturbance_type, d$time)


# ---------------- 2. Virtual sampling ----------------
# for every sampling effort (S individuals x L SNPs) every living population
# gets one temporal, one LD and one combined estimate
# columns are called temporal_S50_L1000, ld_S50_L1000, combo_S50_L1000, ...

a <- d$alive

for (S in sample_sizes) {
  for (L in snp_numbers) {

    name <- paste0("S", S, "_L", L)

    # you cannot sample more individuals than there are
    S_used <- pmin(S, d$N[a])
    ne <- d$ne_true[a]

    # one virtual estimate of 1/Ne per population and method
    inv_temp <- 1 / ne + rnorm(sum(a), 0, sqrt(var_inv_ne_temporal(ne, S_used, L)))
    inv_ld <- 1 / (ld_bias * ne) + rnorm(sum(a), 0, sqrt(var_inv_ne_ld(ne, S_used, L)))
    inv_combo <- combine_estimates(inv_temp, inv_ld, S_used, L)

    # populations that cannot be sampled stay at 0
    d[, paste0("temporal_", name)] <- 0
    d[, paste0("ld_", name)] <- 0
    d[, paste0("combo_", name)] <- 0
    d[a, paste0("temporal_", name)] <- inv_to_ne(inv_temp)
    d[a, paste0("ld_", name)] <- inv_to_ne(inv_ld)
    d[a, paste0("combo_", name)] <- inv_to_ne(inv_combo)

    cat("done", name, "\n")
  }
}

# how often each method saw no drift at all (Ne_hat infinite), main effort
main <- paste0("S", main_S, "_L", main_L)
mean(is.infinite(d[a, paste0("temporal_", main)]))
mean(is.infinite(d[a, paste0("ld_", main)]))
mean(is.infinite(d[a, paste0("combo_", main)]))

write.csv(d, file.path(output_dir, "virtual_sampling_ne.csv"), row.names = FALSE)


# ---------------- Fig 1: one example population ----------------
# like Waples fig 1: 2000 virtual studies of ONE population with true Ne
# close to 500, at the main sampling effort. Ne_hat is very skewed (and
# sometimes infinite), 1/Ne_hat is close to normal

pre <- d[d$time == "pre_dist" & d$alive, ]
ex <- pre[which.min(abs(pre$ne_true - ne_threshold)), ]
ex

n_virtual <- 2000
S_ex <- min(main_S, ex$N)
inv_temp_ex <- 1 / ex$ne_true + rnorm(n_virtual, 0, sqrt(var_inv_ne_temporal(ex$ne_true, S_ex, main_L)))
inv_ld_ex <- 1 / (ld_bias * ex$ne_true) + rnorm(n_virtual, 0, sqrt(var_inv_ne_ld(ex$ne_true, S_ex, main_L)))

ne_ticks <- c(20, 50, 100, 200, 500, 1000, 2000, 5000, 10000)

png(file.path(output_dir, "fig1_example_population.png"), width = 2400, height = 2000, res = 250)
par(mfcol = c(2, 2), mar = c(5, 5, 4, 1), oma = c(3, 0, 2, 0))   # mfcol: fills column by column, one method per column

for (m in 1:2) {
  inv <- if (m == 1) inv_temp_ex else inv_ld_ex
  method_name <- if (m == 1) "Temporal (t = 1)" else "LD"
  col_m <- if (m == 1) col_temporal else col_ld
  ne_hat <- inv_to_ne(inv)

  # top row: Ne_hat on a log axis (infinite estimates cannot be drawn, so they are counted)
  finite <- ne_hat[is.finite(ne_hat) & ne_hat >= min(ne_ticks) & ne_hat <= max(ne_ticks)]
  hist(log10(finite), breaks = seq(log10(min(ne_ticks)), log10(max(ne_ticks)), length.out = 41),
       col = col_m, border = "white", xaxt = "n", xlab = "Estimated Ne (log scale)",
       ylab = "Number of virtual studies", main = method_name)
  axis(1, at = log10(ne_ticks), labels = ne_ticks)
  abline(v = log10(ex$ne_true), lty = 2, lwd = 2)
  abline(v = log10(ex$proxy), col = col_proxy, lwd = 2)
  mtext(paste0(round(100 * mean(is.infinite(ne_hat)), 1), "% infinite (no drift detected)"),
        side = 3, line = 0.2, cex = 0.8)

  # bottom row: 1/Ne_hat on a normal axis
  hist(inv, breaks = 40, col = col_m, border = "white", xlab = "Estimated 1/Ne",
       ylab = "Number of virtual studies", main = "")
  abline(v = 1 / ex$ne_true, lty = 2, lwd = 2)
  abline(v = 0, col = "grey60", lty = 3)
}

mtext(paste0("One population: true Ne = ", round(ex$ne_true), ", N = ", ex$N,
             "   |   ", n_virtual, " virtual studies of S = ", S_ex, " individuals, L = ", main_L, " SNPs"),
      side = 3, outer = TRUE, line = 0.3)

par(fig = c(0, 1, 0, 1), oma = c(0, 0, 0, 0), mar = c(0, 0, 0, 0), new = TRUE)
plot.new()
legend("bottom", horiz = TRUE, bty = "n", lwd = 2, lty = c(2, 1),
       col = c("black", col_proxy), legend = c("true Ne", "proxy Ne = 0.1 x N"))
dev.off()


# ---------------- Fig 2: which method is more precise? ----------------
# like Waples fig 2: R = var(1/Ne_hat) temporal / var(1/Ne_hat) LD, for S = 50 and t = 1
# R > 1: LD is more precise. the ticks at the bottom are the true Ne of all
# living populations before the disturbance (where my runs actually are)

ne_range <- exp(seq(log(50), log(2000), length.out = 100))
col_snps <- c("#86b6ef", "#3987e5", "#184f95")   # light to dark = few to many SNPs

png(file.path(output_dir, "fig2_precision_ratio.png"), width = 2000, height = 1600, res = 250)
par(mar = c(5, 5, 3, 6))

R_all <- c()
for (L in snp_numbers) {
  R_all <- c(R_all, var_inv_ne_temporal(ne_range, main_S, L) / var_inv_ne_ld(ne_range, main_S, L))
}

plot(NA, xlim = range(ne_range), ylim = range(c(R_all, 0.5)), log = "xy",
     xlab = "True Ne", ylab = "R = var temporal / var LD",
     main = paste0("Relative precision of temporal and LD (S = ", main_S, ", t = 1)"))
abline(h = 1, lty = 3, col = "grey40")

for (j in 1:length(snp_numbers)) {
  R <- var_inv_ne_temporal(ne_range, main_S, snp_numbers[j]) / var_inv_ne_ld(ne_range, main_S, snp_numbers[j])
  lines(ne_range, R, lwd = 2, col = col_snps[j])
  text(max(ne_range), R[length(R)], paste(snp_numbers[j], "SNPs"), pos = 4, xpd = TRUE, cex = 0.85)
}

rug(pre$ne_true, col = adjustcolor("grey30", alpha.f = 0.3))
text(60, 0.8, "below: temporal more precise", adj = 0, cex = 0.8, col = "grey40")
dev.off()


# ---------------- Fig 3: error of every method and sampling effort ----------------
# like Waples table 1 / fig 4 bottom: relative RMSE of 1/Ne (%), living populations only
# bars = genetic methods at each sampling effort, horizontal lines = census N and
# the 0.1 x N proxy (they do not depend on the sampling effort)

designs <- c()
for (S in sample_sizes) for (L in snp_numbers) designs <- c(designs, paste0("S", S, "_L", L))
design_labels <- sub("_", "\n", sub("S", "S=", sub("_L", "_L=", designs)))

errors <- data.frame()
for (tm in time_names) {
  x <- d[d$alive & d$time == tm, ]
  for (dn in designs) {
    errors <- rbind(errors, data.frame(time = tm, design = dn,
                                       temporal = rel_rmse(x[, paste0("temporal_", dn)], x$ne_true),
                                       ld = rel_rmse(x[, paste0("ld_", dn)], x$ne_true),
                                       combo = rel_rmse(x[, paste0("combo_", dn)], x$ne_true),
                                       census = rel_rmse(x$census, x$ne_true),
                                       proxy = rel_rmse(x$proxy, x$ne_true)))
  }
}
errors[, 3:7] <- round(errors[, 3:7], 1)
errors
write.csv(errors, file.path(output_dir, "error_by_design.csv"), row.names = FALSE)

png(file.path(output_dir, "fig3_error_by_design.png"), width = 3000, height = 3200, res = 250)
par(mfrow = c(3, 1), mar = c(5, 5, 3, 1), oma = c(3, 0, 0, 0))

for (tm in time_names) {
  e <- errors[errors$time == tm, ]
  
  # 1. Skip if this time point has no rows
  if (nrow(e) == 0) {
    warning(paste("No data found for time point:", tm))
    next
  }
  
  bars <- rbind(e$temporal, e$ld, e$combo)
  
  # 2. Extract only positive, finite numbers for log-scale limits
  valid_vals <- c(bars, e$census, e$proxy)
  valid_vals <- valid_vals[is.finite(valid_vals) & valid_vals > 0]
  
  # 3. Skip if there are no valid positive values to plot
  if (length(valid_vals) == 0) {
    warning(paste("No positive finite values for time point:", tm))
    next
  }
  
  ylim <- c(min(valid_vals) / 1.5, max(valid_vals) * 1.5)
  
  barplot(
    bars,
    beside = TRUE,
    log = "y",
    ylim = ylim,
    names.arg = design_labels,
    col = c(col_temporal, col_ld, col_combo),
    border = "white",
    las = 1,
    ylab = "Relative RMSE of 1/Ne (%)",
    main = paste("Time point:", tm),
    cex.names = 0.85
  )
  
  abline(h = e$census[1], col = col_census, lwd = 2, lty = 2)
  abline(h = e$proxy[1], col = col_proxy, lwd = 2, lty = 2)
}


par(fig = c(0, 1, 0, 1), oma = c(0, 0, 0, 0), mar = c(0, 0, 0, 0), new = TRUE)
plot.new()
legend("bottom", horiz = TRUE, bty = "n", cex = 0.95,
       fill = c(col_temporal, col_ld, col_combo, NA, NA), border = c(NA, NA, NA, NA, NA),
       lwd = c(NA, NA, NA, 2, 2), lty = c(NA, NA, NA, 2, 2),
       col = c(NA, NA, NA, col_census, col_proxy),
       legend = c("temporal", "LD", "combined", "census N as Ne", "proxy 0.1 x N"))
dev.off()


# ---------------- Fig 4: estimated Ne / true Ne ----------------
# like Waples fig 4 top: how far off is each method, main sampling effort,
# all living populations at all three time points

method_cols <- c("census", "proxy", paste0("temporal_", main), paste0("ld_", main), paste0("combo_", main))
method_names <- c("census N", "proxy 0.1 x N", "temporal", "LD", "combined")
method_colours <- c(col_census, col_proxy, col_temporal, col_ld, col_combo)

ratio_breaks <- c(0, 0.25, 0.5, 0.8, 1.25, 2, 4, Inf)
ratio_labels <- c("< 1/4", "1/4-1/2", "1/2-0.8", "0.8-1.25", "1.25-2", "2-4", "> 4 or inf")

x <- d[d$alive, ]
ratio_table <- matrix(NA, nrow = length(method_cols), ncol = length(ratio_labels),
                      dimnames = list(method_names, ratio_labels))
for (m in 1:length(method_cols)) {
  ratio <- x[, method_cols[m]] / x$ne_true
  bins <- cut(ratio, breaks = ratio_breaks, labels = ratio_labels, right = FALSE)
  ratio_table[m, ] <- 100 * as.numeric(table(bins)) / length(ratio)
}
round(ratio_table, 1)

png(file.path(output_dir, "fig4_ratio_distribution.png"), width = 2600, height = 1600, res = 250)
par(mar = c(5, 5, 3, 1), oma = c(2, 0, 0, 0))
barplot(ratio_table, beside = TRUE, col = method_colours, border = "white", las = 1,
        ylab = "% of populations", xlab = "Estimated Ne / true Ne",
        main = paste0("How far off is each method? (S = ", main_S, ", L = ", main_L, " SNPs)"))
par(fig = c(0, 1, 0, 1), oma = c(0, 0, 0, 0), mar = c(0, 0, 0, 0), new = TRUE)
plot.new()
legend("bottom", horiz = TRUE, bty = "n", fill = method_colours, border = NA,
       legend = method_names, cex = 0.9)
dev.off()


# ---------------- Fig 5: the Ne 500 indicator ----------------
# per run: proportion of populations with Ne above 500 (as in 37.1), once with
# the true Ne and once with each method. extinct populations count as below 500.
# error = |estimated indicator - true indicator|, 0 = right, 1 = completely wrong

above <- d[, c("ne_true", method_cols)] > ne_threshold
ind <- aggregate(above, by = list(run = d$run, time = d$time), FUN = mean)
ind <- merge(ind, s[, c("run", "disturbance_type")], by = "run")
ind$disturbance_type <- factor(ind$disturbance_type, levels = c(0, 1),
                               labels = c("individuals removed", "habitat lost"))
head(ind)

# mean error and % of runs exactly right, per method, time and disturbance type
ind_error <- data.frame()
for (dt in levels(ind$disturbance_type)) {
  for (tm in time_names) {
    x <- ind[ind$disturbance_type == dt & ind$time == tm, ]
    for (m in 1:length(method_cols)) {
      err <- abs(x[, method_cols[m]] - x$ne_true)
      ind_error <- rbind(ind_error, data.frame(disturbance_type = dt, time = tm, method = method_names[m],
                                               mean_error = round(mean(err), 3),
                                               pct_runs_right = round(100 * mean(err == 0), 1)))
    }
  }
}
ind_error

png(file.path(output_dir, "fig5_indicator_error.png"), width = 2800, height = 1500, res = 250)
par(mfrow = c(1, 2), mar = c(5, 5, 3, 1), oma = c(2, 0, 0, 0))
y_max <- max(ind_error$mean_error) * 1.1

for (dt in levels(ind$disturbance_type)) {
  e <- ind_error[ind_error$disturbance_type == dt, ]
  bars <- matrix(e$mean_error, nrow = length(method_names), dimnames = list(method_names, time_names))
  barplot(bars, beside = TRUE, col = method_colours, border = "white", las = 1, ylim = c(0, y_max),
          ylab = "Mean |estimated - true| Ne 500 indicator", main = dt,
          names.arg = c("before disturbance", "1971", "2025"))
}

par(fig = c(0, 1, 0, 1), oma = c(0, 0, 0, 0), mar = c(0, 0, 0, 0), new = TRUE)
plot.new()
legend("bottom", horiz = TRUE, bty = "n", fill = method_colours, border = NA,
       legend = method_names, cex = 0.9)
dev.off()


# ---------------- Fig 6: the decline, estimated vs true ----------------
# per population: % of the pre-disturbance Ne still there in 2025
# (disturbance + climate change, like pct_ne_..._kept_pre_dist_2025 in 42)
# the 0.1 x N proxy is a constant times N, so its % kept is the same as census N
# values above 250% are drawn at 250% (some genetic estimates are infinite)

before <- d[d$time == "pre_dist", c("run", "pop", "disturbance_type", "ne_true", method_cols)]
after <- d[d$time == "2025", c("run", "pop", "ne_true", method_cols)]
dec <- merge(before, after, by = c("run", "pop"), suffixes = c("_pre", "_2025"))
nrow(dec)

dec$true_kept <- 100 * dec$ne_true_2025 / dec$ne_true_pre

panel_cols <- c("census", paste0("temporal_", main), paste0("ld_", main), paste0("combo_", main))
panel_names <- c("census N (= proxy 0.1 x N)", "temporal", "LD", "combined")
cap <- 250

png(file.path(output_dir, "fig6_decline.png"), width = 2400, height = 2400, res = 250)
par(mfrow = c(2, 2), mar = c(5, 5, 3, 1), oma = c(2, 0, 2, 0))

for (m in 1:4) {
  est_pre <- dec[, paste0(panel_cols[m], "_pre")]
  est_2025 <- dec[, paste0(panel_cols[m], "_2025")]
  est_kept <- 100 * est_2025 / est_pre
  est_kept[is.infinite(est_pre)] <- 0      # infinite before: any finite value after is ~0%
  est_kept <- pmin(est_kept, cap)          # infinite after, or a huge jump, drawn at the cap

  # how close the estimate is to the true decline
  cat(panel_names[m], ": correlation", round(cor(est_kept, dec$true_kept), 2),
      ", median |estimated - true|", round(median(abs(est_kept - dec$true_kept))), "% points\n")

  plot(dec$true_kept, est_kept, xlim = c(0, cap), ylim = c(0, cap),
       pch = ifelse(dec$disturbance_type == "individuals removed", 1, 2), cex = 0.6,
       col = adjustcolor(ifelse(dec$disturbance_type == "individuals removed", col_individuals, col_habitat),
                         alpha.f = 0.5),
       xlab = "True % of Ne kept (2025 vs before)", ylab = "Estimated % of Ne kept", main = panel_names[m])
  abline(0, 1, lty = 2)
  abline(h = 100, v = 100, col = "grey80", lty = 3)
}

mtext(paste0("Decline from before the disturbance to 2025, per population (S = ", main_S,
             ", L = ", main_L, " SNPs)"), side = 3, outer = TRUE, line = 0.3)
par(fig = c(0, 1, 0, 1), oma = c(0, 0, 0, 0), mar = c(0, 0, 0, 0), new = TRUE)
plot.new()
legend("bottom", horiz = TRUE, bty = "n", pch = c(1, 2), col = c(col_individuals, col_habitat),
       legend = c("individuals removed", "habitat lost"))
dev.off()

cat("Saved everything in", output_dir, "\n")

