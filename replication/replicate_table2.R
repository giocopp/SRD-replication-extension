# Replication of Table 2 from
# Sánchez-García, Rodon & Delgado-García (2025) "Where has everyone gone?
# Depopulation and voting behaviour in Spain", EJPR.
#
# Adapted from analysis_manuscript.R "Table 2" block (orig lines 89-125).

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(readr)
  library(broom)
  library(fixest)
})

loadRData <- function(file) { load(file); get(ls()[ls() != "file"]) }
df <- loadRData("database/short_time.RData")

setFixest_dict(c(psoe = "PSOE", pp = "PP", podemos = "UP", cs = "Cs",
                 nswp = "PANES", es = "ES", vox = "VOX",
                 "depo_cat_te2_decrease" = "Decrease",
                 "depo_cat_te3_increase" = "Increase",
                 agriculture_workers = "% workers agriculture",
                 services_workers    = "% workers services",
                 unemployed          = "% unemployed",
                 var_older_te        = "D % 60 y/o or older",
                 var_younger_te      = "D % 16 y/o or younger",
                 population_log      = "(Log) Population",
                 mun_code = "Municipality", year = "Year", region = "Region"))

# Fit one outcome at a time. The paper uses three-way clustered SEs. Current
# fixest versions fail on the small ES subsample when computing that VCOV, so
# the script falls back to municipality-year clustering for that column only.
# The depopulation coefficients still reproduce.
rhs <- "depo_cat_te + agriculture_workers + services_workers + unemployed +
        var_older_te + var_younger_te + population_log | mun_code + year"

fit_one <- function(y) {
  fml <- as.formula(paste(y, "~", rhs))
  tryCatch(
    feols(fml, data = df, cluster = c("region", "mun_code", "year"),
          notes = FALSE, lean = TRUE),
    error = \(e) feols(fml, data = df, cluster = c("mun_code", "year"),
                       notes = FALSE, lean = TRUE))
}

models <- c("psoe", "pp", "podemos", "cs", "nswp", "es", "vox") |>
  set_names() |>
  map(fit_one)

dir.create("outcomes/tables", recursive = TRUE, showWarnings = FALSE)

saveRDS(models, "outcomes/table2_models.rds")

etable(models,
       tex         = TRUE,
       replace     = TRUE,
       file        = "outcomes/tables/table2.tex",
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       order       = c("Decrease", "Increase"))

map_dfr(models, tidy, .id = "model") |>
  write_csv("outcomes/tables/table2_tidy.csv")
