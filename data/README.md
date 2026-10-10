# Data

The plot dataset (locations and attributes of 1,251 forest plots) belongs to the research group and is **not included** in this repository.

The R scripts expect three semicolon-separated CSV files in this folder, with one row per plot:

| File | Content |
|---|---|
| `plots_indices.csv` | `num_parcela`, `Tipo`, `LON`, `LAT` and the annual index series `NDVI_YYYY`, `EVI_YYYY`, `NDWI_YYYY` (2001–2023), as exported by `gee/extract_spectral_indices.js` |
| `plots_response.csv` | Same as above plus resistance (`Res_evi_YYYY`, `Res_ndvi_YYYY`, `Res_ndwi_YYYY`, for the drought years 2005, 2011, 2015, 2017 and 2019) and recovery (`Rec_evi_YYYY`, `Rec_ndvi_YYYY`, `Rec_ndwi_YYYY`, for the years after each drought) indicators |
| `plots_gam.csv` | Response indicators of the 2005 drought (`Res_*_2005`, `Rec_*_2006`) plus the predictors: `aet_mean`, `pet_mean`, `soil_mean`, `srad_mean`, `slope`, `aspect`, `elevation`, `hillshade`, `Tree_dens` |

`Tipo` is the forest structure class: `DEH` (dehesa), `INT` (intermediate) or `DEN` (dense).
