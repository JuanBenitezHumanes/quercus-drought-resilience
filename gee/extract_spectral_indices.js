// =============================================================================
// Annual NDVI, EVI and NDWI per forest plot (Google Earth Engine Code Editor)
//
// For every plot and every year it computes the annual median of each index
// and exports one CSV row per plot with columns NDVI_YYYY, EVI_YYYY, NDWI_YYYY.
// =============================================================================

// ---- Inputs -----------------------------------------------------------------
var START_YEAR = 2001;
var END_YEAR = 2023;
var SCALE = 250; // metres per pixel used for the extraction

// Plot locations (FeatureCollection asset). Not included in this repository:
// upload your own plots as an asset and set its path here.
var plots = ee.FeatureCollection('users/YOUR_USERNAME/plots');
var region = plots.geometry().bounds();

var startDate = START_YEAR + '-01-01';
var endDate = END_YEAR + '-12-31';

// ---- Satellite collections --------------------------------------------------
// MODIS Terra 16-day vegetation indices, 500 m. NDVI and EVI are stored
// scaled by 10000 (scale factor 0.0001).
var mod13 = ee.ImageCollection('MODIS/061/MOD13A1')
  .filterBounds(region)
  .filterDate(startDate, endDate);

// MODIS daily NDWI (derived from MCD43A4). Note: this collection is deprecated
// in the Earth Engine catalog; it is kept to reproduce the original analysis.
var ndwiCollection = ee.ImageCollection('MODIS/MCD43A4_006_NDWI')
  .filterBounds(region)
  .filterDate(startDate, endDate);

// ---- Annual medians ---------------------------------------------------------
var years = ee.List.sequence(START_YEAR, END_YEAR);

// Returns a list with one image per year: the annual median of `band`
function annualMedians(collection, band) {
  return years.map(function (year) {
    return collection
      .select(band)
      .filter(ee.Filter.calendarRange(year, year, 'year'))
      .median();
  });
}

// Band names in the same order as the images: NDVI_2001..NDVI_2023, EVI_..., NDWI_...
var indices = ['NDVI', 'EVI', 'NDWI'];
var bandNames = ee.List(indices.map(function (index) {
  return years.map(function (year) {
    return ee.String(index).cat('_').cat(ee.Number(year).format('%d'));
  });
})).flatten();

var annualImages = annualMedians(mod13, 'NDVI')
  .cat(annualMedians(mod13, 'EVI'))
  .cat(annualMedians(ndwiCollection, 'NDWI'));

// One multi-band image: one band per index and year
var stack = ee.ImageCollection.fromImages(annualImages).toBands().rename(bandNames);

// ---- Extraction per plot ----------------------------------------------------
var plotsWithCoords = plots.map(function (plot) {
  var coords = plot.geometry().centroid(1).coordinates();
  return plot.set({LON: coords.get(0), LAT: coords.get(1)});
});

var table = stack.reduceRegions({
  collection: plotsWithCoords,
  reducer: ee.Reducer.mean(),
  scale: SCALE,
  tileScale: 4
});

print('Number of plots:', plots.size());
print('First rows:', table.limit(5));

// ---- Export -----------------------------------------------------------------
Export.table.toDrive({
  collection: table,
  description: 'spectral_indices_' + START_YEAR + '_' + END_YEAR,
  fileFormat: 'CSV'
});
