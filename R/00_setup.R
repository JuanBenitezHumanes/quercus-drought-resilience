# Shared setup: packages, paths, data loading and plot style.
# Sourced by the other scripts; run them from the repository root.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(ggplot2)
  library(mgcv)
  library(corrplot)
})

# ---- Paths ------------------------------------------------------------------
DATA_DIR    <- "data"
FIG_DIR     <- "figures"
RESULTS_DIR <- "results"
dir.create(FIG_DIR, showWarnings = FALSE)
dir.create(RESULTS_DIR, showWarnings = FALSE)

# Input tables (semicolon-separated, wide format: one row per plot).
# See data/README.md for the expected columns.
FILE_INDICES  <- file.path(DATA_DIR, "plots_indices.csv")    # spectral index series
FILE_RESPONSE <- file.path(DATA_DIR, "plots_response.csv")   # + resistance / recovery
FILE_GAM      <- file.path(DATA_DIR, "plots_gam.csv")        # + environmental predictors

# ---- Constants --------------------------------------------------------------
INDICES <- c("EVI", "NDVI", "NDWI")
FOREST_TYPES <- c(DEH = "Dehesa", INT = "Intermediate", DEN = "Dense")
TYPE_COLOURS <- c(DEH = "#2ca02c", INT = "#1f77b4", DEN = "#d62728")
INDEX_COLOURS <- c(EVI = "#ff7f0e", NDVI = "#32cd32", NDWI = "#1f77b4")

PREDICTORS <- c("aet_mean", "pet_mean", "soil_mean", "srad_mean",
                "slope", "aspect", "elevation", "hillshade", "Tree_dens")

# ---- Data loading -----------------------------------------------------------
read_wide <- function(path) {
  read.csv(path, header = TRUE, sep = ";")
}

# Wide -> long: columns like NDVI_2001 or Res_evi_2005 become one row per plot
# and year, with one column per variable (NDVI, Res_evi, ...).
to_long <- function(wide) {
  wide %>%
    pivot_longer(
      cols = matches("^(EVI|NDVI|NDWI|Res_evi|Res_ndvi|Res_ndwi|Rec_evi|Rec_ndvi|Rec_ndwi)_\\d{4}$"),
      names_to = c(".value", "year"),
      names_pattern = "(\\w+)_(\\d{4})"
    ) %>%
    mutate(year = as.integer(year))
}

# ---- Plot style -------------------------------------------------------------
theme_tfg <- theme_minimal(base_size = 13) +
  theme(plot.title = element_text(hjust = 0.5, size = 16),
        panel.grid.minor = element_blank(),
        legend.position = "bottom")

save_plot <- function(plot, name, width = 10, height = 5) {
  ggsave(file.path(FIG_DIR, paste0(name, ".png")), plot,
         width = width, height = height, dpi = 150, bg = "white")
}
