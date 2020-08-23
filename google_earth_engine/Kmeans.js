// import the satellite data from the European Space Agency
var S2 = ee.ImageCollection("COPERNICUS/S2");

//filter for Dubai
S2 = S2.filterBounds(Dubai);
print(S2);

//filter for date
S2 = S2.filterDate("2020-01-01", "2020-05-11");
print(S2);

var image = ee.Image(S2.first());
print(image)

//Map.addLayer(image,{min:0,max:3000,bands:"B4,B3,B2"}, "Dubai");

Map.addLayer(image,{min:0,max:3000,bands:"B8,B4,B3"}, "Dubai");

// Create training dataset.
var training = image.sample({
  region: Dubai,
  scale: 20,
  numPixels: 5000
});

// Start unsupervised clusterering algorithm and train it.
var kmeans = ee.Clusterer.wekaKMeans(5).train(training);
// Cluster the input using the trained clusterer.
var result =  image.cluster(kmeans);
// Display the clusters with random colors.
Map.addLayer(result.randomVisualizer(), {}, 'Unsupervised K-means Classification');

// Export the image to Drive
Export.image.toDrive({
  image: result,
  description: 'kmeans_Dubai',
  scale: 20,
  region: Dubai
});
