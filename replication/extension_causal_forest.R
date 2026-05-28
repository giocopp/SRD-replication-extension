# Extension: heterogeneous treatment effects of depopulation on Vox vote share,
# via a causal forest (grf). Companion to the replication of Table 2 in
# Sánchez-García, Rodon & Delgado-García (2025).
#
# Fits the forest once, writes all tables and figures the document needs into
# replication/outcomes/. Run from the replication/ directory:
#
#   Rscript extension_causal_forest.R

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(readr)
  library(ggplot2)
  library(fixest)
  library(grf)
})

set.seed(2026)

# ---- Paths and constants ----------------------------------------------------

data_path  <- "database/short_time.RData"
tables_dir <- "outcomes/tables"
figs_dir   <- "outcomes/figures"

covars <- c("agriculture_workers", "services_workers", "unemployed",
            "var_older_te", "var_younger_te", "population_log",
            "public_services", "degurba")

# ---- Helpers ----------------------------------------------------------------

load_rdata <- function(path) {
  env <- new.env()
  load(path, envir = env)
  env[[ls(env)[1]]]
}

coeftest_to_tibble <- function(ct) {
  m <- matrix(as.numeric(ct), nrow = nrow(ct), ncol = ncol(ct),
              dimnames = dimnames(ct))
  tibble(
    term      = rownames(m),
    estimate  = m[, "Estimate"],
    std_error = m[, "Std. Error"],
    t_value   = m[, "t value"],
    p_value   = m[, ncol(m)])
}

# ---- Data -------------------------------------------------------------------

df <- load_rdata(data_path)

d_clean <- df |>
  filter(depo_cat_te %in% c("1_no_change", "2_decrease")) |>
  mutate(W               = as.integer(depo_cat_te == "2_decrease"),
         public_services = as.numeric(public_services),
         degurba         = as.numeric(degurba)) |>
  filter(!is.na(vox),
         if_all(all_of(covars), \(x) !is.na(x)))

demeaned <- fixest::demean(
  X = as.matrix(d_clean[, c("vox", "W")]),
  f = as.data.frame(d_clean[, c("mun_code", "year")]))

X       <- as.matrix(d_clean[, covars])
Y_resid <- demeaned[, "vox"]
W_resid <- demeaned[, "W"]

# ---- Fit --------------------------------------------------------------------

cf <- causal_forest(X, Y_resid, W_resid, num.trees = 2000, seed = 2026)

# ---- Derived quantities -----------------------------------------------------

ate         <- average_treatment_effect(cf)
calibration <- test_calibration(cf)
blp         <- best_linear_projection(cf, X)
cates       <- predict(cf)$predictions

ate_tbl <- tibble(estimate = ate[["estimate"]], std_error = ate[["std.err"]])

vi <- tibble(variable   = covars,
             importance = variable_importance(cf)[, 1]) |>
  arrange(importance)

pop_quintile_labels <- c("Q1 (smallest)", "Q2", "Q3", "Q4", "Q5 (largest)")

pop_bins <- tibble(
    pop_quintile = cut(d_clean$population_log,
                       quantile(d_clean$population_log, probs = seq(0, 1, .2)),
                       include.lowest = TRUE,
                       labels         = pop_quintile_labels),
    population   = exp(d_clean$population_log),
    cate         = cates) |>
  group_by(pop_quintile) |>
  summarise(n                 = n(),
            median_population = median(population),
            mean_CATE         = mean(cate),
            median_CATE       = median(cate),
            .groups = "drop")

# ---- Write outputs ----------------------------------------------------------

dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figs_dir,   recursive = TRUE, showWarnings = FALSE)

write_csv(ate_tbl,                          file.path(tables_dir, "ext_ate.csv"))
write_csv(coeftest_to_tibble(calibration),  file.path(tables_dir, "ext_calibration.csv"))
write_csv(coeftest_to_tibble(blp),          file.path(tables_dir, "ext_blp.csv"))
write_csv(vi,                               file.path(tables_dir, "ext_variable_importance.csv"))
write_csv(pop_bins,                         file.path(tables_dir, "ext_population_bins.csv"))
write_csv(tibble(cate = cates),             file.path(tables_dir, "ext_cates.csv"))

p_cate <- ggplot(tibble(cate = cates), aes(cate)) +
  geom_histogram(bins = 60, fill = "#2c7fb8", colour = "white", alpha = 0.9) +
  geom_vline(xintercept = ate_tbl$estimate, colour = "#d7301f", linewidth = 0.7) +
  annotate("text", x = ate_tbl$estimate, y = Inf, vjust = 2,
           hjust = -0.05, label = "ATE", colour = "#d7301f") +
  labs(x = "Conditional ATE on Vox vote share", y = "Number of units") +
  theme_minimal(base_size = 12)

p_vi <- ggplot(vi, aes(importance, factor(variable, levels = variable))) +
  geom_col(fill = "#2c7fb8") +
  labs(x = "Variable importance (share of splits)", y = NULL) +
  theme_minimal(base_size = 12)

ggsave(file.path(figs_dir, "ext_cate_dist.png"),           p_cate,
       width = 7, height = 4, dpi = 300)
ggsave(file.path(figs_dir, "ext_variable_importance.png"), p_vi,
       width = 7, height = 4, dpi = 300)

# ---- Console summary --------------------------------------------------------

print(calibration)
print(blp)
print(pop_bins)
cat(sprintf("\nATE: %.4f (SE %.4f)\n", ate_tbl$estimate, ate_tbl$std_error))
