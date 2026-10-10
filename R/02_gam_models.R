# Generalized Additive Models (GAMs) of forest resistance and recovery.
# One model per spectral index x response x forest type (3 x 2 x 3 = 18 models).
# Run from the repository root:  Rscript R/02_gam_models.R

source("R/00_setup.R")

gam_wide <- read_wide(FILE_GAM)

# Resistance to the 2005 drought and recovery in 2006
RESPONSES <- c(
  resistance_evi  = "Res_evi_2005",
  resistance_ndvi = "Res_ndvi_2005",
  resistance_ndwi = "Res_ndwi_2005",
  recovery_evi    = "Rec_evi_2006",
  recovery_ndvi   = "Rec_ndvi_2006",
  recovery_ndwi   = "Rec_ndwi_2006"
)

# ---- Correlation between predictors ------------------------------------------
png(file.path(FIG_DIR, "predictor_correlation.png"), width = 1400, height = 1400, res = 150)
corrplot(cor(gam_wide[PREDICTORS], use = "pairwise.complete.obs"),
         method = "number", type = "upper", number.cex = 0.8)
dev.off()

# ---- Model fitting ----------------------------------------------------------
# response ~ s(x1, bs = "cr") + s(x2, bs = "cr") + ... (cubic regression splines)
gam_formula <- function(response) {
  smooths <- paste0("s(", PREDICTORS, ", bs = \"cr\")", collapse = " + ")
  as.formula(paste(response, "~", smooths))
}

# As in the original analysis, resistance models only use plots with all three
# resistance values available; mgcv's default smoothing selection (GCV) is kept.
fit_one <- function(response, type) {
  data <- gam_wide %>% filter(Tipo == type)
  if (startsWith(response, "Res_")) {
    data <- data %>% filter(!is.na(Res_evi_2005), !is.na(Res_ndvi_2005), !is.na(Res_ndwi_2005))
  }
  gam(gam_formula(response), data = data)
}

models <- expand_grid(model = names(RESPONSES), type = names(FOREST_TYPES)) %>%
  mutate(response = RESPONSES[model],
         fit = map2(response, type, fit_one))

# ---- Model-level summary (fit quality) ----------------------------------------
model_summary <- models %>%
  mutate(
    forest_type    = FOREST_TYPES[type],
    n              = map_int(fit, ~ nrow(.x$model)),
    r2_adj         = map_dbl(fit, ~ summary(.x)$r.sq),
    deviance_expl  = map_dbl(fit, ~ summary(.x)$dev.expl),
    aic            = map_dbl(fit, AIC)
  ) %>%
  select(model, response, forest_type, n, r2_adj, deviance_expl, aic)

write.csv(model_summary, file.path(RESULTS_DIR, "gam_model_summary.csv"), row.names = FALSE)

# ---- Term-level summary (effect of each predictor) -----------------------------
smooth_terms <- models %>%
  mutate(terms = map(fit, function(m) {
    s <- summary(m)$s.table
    data.frame(term = rownames(s), edf = s[, "edf"], F = s[, "F"], p_value = s[, "p-value"],
               row.names = NULL)
  })) %>%
  mutate(forest_type = FOREST_TYPES[type]) %>%
  select(model, forest_type, terms) %>%
  unnest(terms) %>%
  mutate(significant = p_value < 0.05)

write.csv(smooth_terms, file.path(RESULTS_DIR, "gam_smooth_terms.csv"), row.names = FALSE)

# ---- Diagnostics (gam.check) for every model ----------------------------------
pdf(file.path(RESULTS_DIR, "gam_diagnostics.pdf"), width = 9, height = 9)
sink(file.path(RESULTS_DIR, "gam_diagnostics.txt"))
pwalk(list(models$fit, models$model, models$type), function(fit, model, type) {
  cat("\n=====", model, "-", FOREST_TYPES[[type]], "=====\n")
  gam.check(fit)
  title(paste(model, "-", FOREST_TYPES[[type]]), outer = TRUE, line = -1)
})
sink()
dev.off()

print(model_summary, digits = 3)
message("Results saved in ", RESULTS_DIR, "/")
