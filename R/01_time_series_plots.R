# Time series of spectral indices and drought-response indicators.
# Run from the repository root:  Rscript R/01_time_series_plots.R

source("R/00_setup.R")

indices_long  <- to_long(read_wide(FILE_INDICES))
response_long <- to_long(read_wide(FILE_RESPONSE))

# ---- Helpers ----------------------------------------------------------------

# Boxplots per year of several variables (one fill colour per variable)
boxplot_by_year <- function(data, vars, title, colours) {
  data %>%
    pivot_longer(all_of(vars), names_to = "variable", values_to = "value") %>%
    filter(!is.na(value)) %>%
    ggplot(aes(factor(year), value, fill = variable)) +
    geom_boxplot(outlier.shape = NA) +
    scale_fill_manual(values = colours) +
    labs(title = title, x = NULL, y = NULL, fill = NULL) +
    theme_tfg +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5))
}

# Boxplots per year of one variable split by forest type
boxplot_by_type <- function(data, var, title) {
  data %>%
    filter(!is.na(.data[[var]])) %>%
    ggplot(aes(factor(year), .data[[var]], fill = Tipo)) +
    geom_boxplot(outlier.shape = NA, alpha = 0.7) +
    scale_fill_manual(values = TYPE_COLOURS, labels = FOREST_TYPES) +
    labs(title = title, x = NULL, y = NULL, fill = NULL) +
    theme_tfg +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5))
}

# Yearly mean of one or more variables, optionally split by forest type
mean_lines <- function(data, vars, title, by_type = FALSE, colours = INDEX_COLOURS) {
  groups <- if (by_type) c("year", "Tipo") else "year"
  means <- data %>%
    pivot_longer(all_of(vars), names_to = "variable", values_to = "value") %>%
    group_by(across(all_of(c(groups, "variable")))) %>%
    summarise(mean = mean(value, na.rm = TRUE), .groups = "drop") %>%
    filter(is.finite(mean))

  if (by_type) {
    p <- ggplot(means, aes(year, mean, colour = Tipo, group = Tipo)) +
      scale_colour_manual(values = TYPE_COLOURS, labels = FOREST_TYPES)
  } else {
    p <- ggplot(means, aes(year, mean, colour = variable, group = variable)) +
      scale_colour_manual(values = colours)
  }
  p + geom_line(linewidth = 1) + geom_point() +
    labs(title = title, x = NULL, y = NULL, colour = NULL) +
    theme_tfg
}

# ---- Spectral indices -------------------------------------------------------
save_plot(boxplot_by_year(indices_long, INDICES, "Spectral indices per year", INDEX_COLOURS),
          "indices_boxplot")
save_plot(mean_lines(indices_long, INDICES, "Mean spectral indices per year"),
          "indices_mean")

for (index in INDICES) {
  save_plot(boxplot_by_type(indices_long, index, paste(index, "by forest type")),
            paste0(tolower(index), "_boxplot_by_type"))
  save_plot(mean_lines(indices_long, index, paste("Mean", index, "by forest type"), by_type = TRUE),
            paste0(tolower(index), "_mean_by_type"))
}

# ---- Resistance -------------------------------------------------------------
res_vars <- c("Res_evi", "Res_ndvi", "Res_ndwi")
save_plot(boxplot_by_year(response_long, res_vars, "Resistance",
                          setNames(INDEX_COLOURS, res_vars)),
          "resistance_boxplot")
for (v in res_vars) {
  save_plot(boxplot_by_type(response_long, v, paste(v, "by forest type")),
            paste0(tolower(v), "_by_type"))
}

# ---- Recovery ---------------------------------------------------------------
rec_vars <- c("Rec_evi", "Rec_ndvi", "Rec_ndwi")
save_plot(mean_lines(response_long, rec_vars, "Mean recovery",
                     colours = setNames(INDEX_COLOURS, rec_vars)),
          "recovery_mean")
for (v in rec_vars) {
  save_plot(mean_lines(response_long, v, paste("Mean", v, "by forest type"), by_type = TRUE),
            paste0(tolower(v), "_mean_by_type"))
}

message("Figures saved in ", FIG_DIR, "/")
